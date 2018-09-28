import { Component, OnInit } from '@angular/core';
import { SocketService } from '../services/socket.service';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-main-screen',
  templateUrl: './main-screen.component.html',
  styleUrls: ['./main-screen.component.scss']
})

export class MainScreenComponent implements OnInit {
  public data = "No Data Yet";
  public lua_script = "Lua Text\nLine2";

  constructor(private socketService: SocketService, private http: HttpClient) { }

  ngOnInit() {
    let self = this;
    this.socketService.subscribe(self,"cdc_data", self.gotCdcData)
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
