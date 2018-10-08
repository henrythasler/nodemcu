import { Injectable } from '@angular/core';
import * as socket from 'websocket';
import { Subject } from 'rxjs/internal/Subject';

@Injectable({
  providedIn: 'root'
})
export class WebsocketService {
  private websocket: WebSocket;

  private lastTimestamp = 0;
  private avgFramerate = 0;
  public subject_data = new Subject<string>();

  constructor() { 
    let url_test = "ws://95.118.15.8"
    this.open(url_test);
  }

  public open = (wsUri: string) => {
    console.log("WebsocketService::open() => " + wsUri);
    this.websocket = new WebSocket(wsUri);
    try {
      this.websocket.onopen = this.onOpen;
      this.websocket.onclose = this.onClose;
      this.websocket.onmessage = this.onMessage;
      this.websocket.onerror = this.onError;
    } catch (exception) {
        console.log('ERROR - ' + exception);
    }
  }

  public close = () => {
    console.log("WebsocketService -> CLOSE");
      this.websocket.close()
  }


  private onOpen = (evt) => {
      console.log("WebsocketService -> CONNECTED");
      //doSend("WebSocket rocks");
  }

  private onClose = (evt: Event) => {
      console.log("WebsocketService -> DISCONNECTED");
  }

  private onMessage = (evt) => {
      let data = JSON.parse(JSON.stringify(evt.data));
      console.log("WebsocketService::onMessage() ", data);
      let curTimestamp = this.getMsNow();
      // console.log(curTimestamp - this.lastTimestamp)
      this.avgFramerate = (this.avgFramerate + (curTimestamp - this.lastTimestamp)) / 2
      this.lastTimestamp = curTimestamp;

      this.subject_data.next(data); 
  }

  private onError = (evt) => {
      console.log("WebsocketService -> ERROR: " + evt.data);
  }

  private doSend = (message) => {
      console.log("SENT: " + message);
      this.websocket.send(message);
  }
  private getMsNow(){
    return (new Date()).valueOf();
  }
}
