import { Component, OnInit } from '@angular/core';
import { SocketService } from '../services/socket.service';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { WebsocketService } from '../services/websocket.service';
import { OnDestroy } from '@angular/core/src/metadata/lifecycle_hooks';

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


@Component({
  selector: 'app-main-screen',
  templateUrl: './main-screen.component.html',
  styleUrls: ['./main-screen.component.scss']
})

export class MainScreenComponent implements OnInit, OnDestroy {
  public data: SensorData = null;
  public stringify = JSON.stringify;
  public lua_script = "Lua Text\nLine2";

  constructor( /* private socketService: SocketService, */ private http: HttpClient, private ws: WebsocketService) { }

  ngOnInit() {
    let self = this;
    // this.socketService.subscribe(self,"cdc_data", self.gotCdcData)
    this.ws.subject_data.subscribe(data_str => {
      try{
        let data_json = JSON.parse(data_str);
        self.gotCdcData(data_json);
      } catch(e){

      }
    });
  }

  ngOnDestroy(){
    console.log("MainScreenComponent::ngOnDestroy()");
    this.ws.close();
  }
  private gotCdcData = (packet) => {
    this.data = packet;
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
