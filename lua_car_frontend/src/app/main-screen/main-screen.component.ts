import { Component, OnInit, ElementRef, ViewChild } from '@angular/core';
import { SocketService } from '../services/socket.service';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { WebsocketService } from '../services/websocket.service';
import { OnDestroy } from '@angular/core/src/metadata/lifecycle_hooks';

var Quaternion = require('quaternion');
var slerp = require('quat-slerp')

interface SensorData {
  ay: number;
  ax: number;
  az: number;
  utc: number;
  gx: number;
  gy: number;
  gz: number;
  temp: number;
  timestamp: number;
}
const FPS: number = 60;

@Component({
  selector: 'app-main-screen',
  templateUrl: './main-screen.component.html',
  styleUrls: ['./main-screen.component.scss']
})

export class MainScreenComponent implements OnInit, OnDestroy {
  public data: SensorData = null;
  public stringify = JSON.stringify;
  public lua_script = "Lua Text\nLine2";
  private lastPacket: any;
  private lastAngles: any = {};
  private q: number[] = [1.0, 1.0, 1.0, 1.0];
  public flipped: boolean = false;
  private QrawGyro;
  private QrawAccel;
  private Qfiltered;
  @ViewChild("canvas") canvas: ElementRef;

  constructor( /* private socketService: SocketService, */ private http: HttpClient, private ws: WebsocketService) { }

  ngOnInit() {
    this.QrawGyro = new Quaternion(1, [0, 0, 0]);
    this.QrawAccel = new Quaternion(1, [0, 0, 0]);
    this.Qfiltered = new Quaternion(1, [0, 0, 0]);

    let self = this;
    // this.socketService.subscribe(self,"cdc_data", self.gotCdcData)
    this.ws.subject_data.subscribe(data_str => {
      try {
        let data_json = JSON.parse(data_str);
        self.gotCdcData(data_json);
      } catch (e) {

      }
    });

    // let counter = 0;
    // let json = this.http.get('assets/rec.json').subscribe(
    //   data => {
    //     setInterval(() => {
    //       self.gotCdcData(data[counter]);
    //       counter++;
    //       if (counter >= data.length) {
    //         counter = 0;
    //       }
    //     }, 33);
    //   },
    //   error => {
    //     console.log("err");
    //   }
    // );

    let context: CanvasRenderingContext2D = this.canvas.nativeElement.getContext("2d");

    context.beginPath();
    context.arc(125,125, 125, 0, 2 * Math.PI, false);
    context.clip();

    context.beginPath();
    context.fillStyle = "rgb(49, 94, 192)";
    context.fillRect(0, 0, this.canvas.nativeElement.width, this.canvas.nativeElement.height);

    setInterval(() => {
      this.loop();
    }, 1000 / FPS);
  }

  loop() {
    if (!this.data) {
      return;
    }

    const context: CanvasRenderingContext2D = this.canvas.nativeElement.getContext("2d");
    context.fillStyle = "rgba(255, 255, 255, .05)";
    context.fillRect(0, 0, this.canvas.nativeElement.width, this.canvas.nativeElement.height);

    const nVec = this.Qfiltered.rotateVector([0, 0, 1]);

    const posX = nVec[0] * 100 + this.canvas.nativeElement.width / 2;
    const posY = nVec[1] * 100 + this.canvas.nativeElement.width / 2;

    this.flipped = nVec[2] > 0;

    context.beginPath();
    context.fillStyle = "rgb(49, 94, 192)";
    context.moveTo(posX, posY);
    context.arc(posX, posY, 3, 0, Math.PI * 2, true);
    context.fill();
  }

  ngOnDestroy() {
    console.log("MainScreenComponent::ngOnDestroy()");
    this.ws.close();
  }
  private gotCdcData = (packet) => {
    this.lastPacket = this.data;
    this.data = packet;

    if (!this.lastPacket) {
      return;
    }

    // let Roll = Math.atan2(packet.ay, packet.az) * 180 / Math.PI;
    // let Pitch = Math.atan2(-packet.ax, Math.sqrt(packet.ay * packet.ay + packet.az * packet.az)) * 180 / Math.PI;

    // let accel_angle_x = Math.atan2(packet.ay, Math.sqrt(Math.pow(packet.ax, 2) + Math.pow(packet.az, 2))) * 180 / Math.PI;
    // let accel_angle_y = Math.atan2(-1 * packet.ax, Math.sqrt(Math.pow(packet.ay, 2) + Math.pow(packet.az, 2))) * 180 / Math.PI;

    // let alpha = 0.96;

    // let temp_gyro_angle_x = packet.gx * dt + this.lastAngles.x;
    // let temp_gyro_angle_y = packet.gy * dt + this.lastAngles.y;
    // this.lastAngles.x = alpha * temp_gyro_angle_x + (1.0 - alpha) * accel_angle_x;
    // this.lastAngles.y = alpha * temp_gyro_angle_y + (1.0 - alpha) * accel_angle_y;

    const dt = (packet.timestamp - this.lastPacket.timestamp) / 1000000.0;
    const deg2rad = Math.PI / 180;
    let gx = packet.gx * deg2rad;
    let gy = packet.gy * deg2rad;
    let gz = packet.gz * deg2rad;

    const transformedGvec = this.Qfiltered.rotateVector([0, 0, 1]);
    const projectionOntoGravityDirection = transformedGvec[0] * gx + transformedGvec[1] * gy + transformedGvec[2] * gz;
    gx -= projectionOntoGravityDirection * transformedGvec[0];
    gy -= projectionOntoGravityDirection * transformedGvec[1];
    gz -= projectionOntoGravityDirection * transformedGvec[2];

    const absomega = Math.sqrt(gx * gx + gy * gy + gz * gz);
    const theta = absomega * dt;
    const vx = gx / absomega;
    const vy = gy / absomega;
    const vz = gz / absomega;
    const sinTheta2 = Math.sin(theta / 2);
    const QgyroUpdate = new Quaternion(Math.cos(theta / 2), [vx * sinTheta2, vy * sinTheta2, vz * sinTheta2]); //TODO: remove world z axis part from gyroupdate quat

    this.QrawAccel = Quaternion.fromBetweenVectors([0, 0, -1], [packet.ax, packet.ay, packet.az]);
    //this.QrawGyro = this.QrawGyro.mul(QgyroUpdate);

    const Qtemp = this.Qfiltered.mul(QgyroUpdate);
    let slerpRes = [];
    slerp(slerpRes, [this.QrawAccel.real(), ...this.QrawAccel.imag()], [Qtemp.real(), ...Qtemp.imag()], 0.94);
    this.Qfiltered = new Quaternion(slerpRes);

    const gravityVecBCS = this.Qfiltered.rotateVector([0, 0, -1]);
    const effectiveAccelerationBCS = [packet.ax - gravityVecBCS[0], packet.ay - gravityVecBCS[1], packet.az - gravityVecBCS[2]];

    console.log(effectiveAccelerationBCS);
  }

  public submitScript = () => {
    let url = environment.base_url + "/executeScript";
    let req_body = this.lua_script;
    console.log("submitScript: ", url, req_body);
    this.http.post(url, req_body).subscribe((response) => {
      console.log("executeScript response: ", response);
    }, (error) => {
      console.error("executeScript error: ", error);
    });
  }
}
