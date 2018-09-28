import { Injectable, OnDestroy } from '@angular/core';
import * as socketIo from 'socket.io-client';
import { takeWhile } from 'rxjs/operators';
import { serviceObjectId } from './object_id';
import { environment } from '../../environments/environment';

export type SocketPacketCallback = (packet: {}) => void;

@Injectable()
export class SocketService  implements OnDestroy {
  private iAmAlive = true;
  private connected = false;
  private socket: socketIo;
  private ident_to_caller_callback: { [s: string]: { [i: string]: SocketPacketCallback; }; } = {};

  constructor() {
    let self = this;
    let url = environment.base_url;
    // Todo: Open up the socket, reopen the socket, ...
    this.socket = socketIo(url, {
      autoConnect: false // create socket without connecting
    });
    // Error handling:
    this.socket.on('error', (error) => {
      console.log("SocketService - Socket Error: ", error);
      self.connected = false;
    });
    this.socket.on('disconnect', (reason) => {
      console.log("SocketService - Socket Disconnected: ", reason);
      self.connected = false;
    });
    this.socket.on('connect', () => {
      console.log("SocketService - Socket Connected");
      self.connected = true;
      // will be called after "reconnect" in case of reconnect was performed
    });
    this.socket.on('reconnect_attempt', (attemptNumber) => {
      // console.log("SocketService - Socket Reconnect Attempt, # ", attemptNumber);
      // before 'reconnecting'
    });
    this.socket.on('reconnecting', (attemptNumber) => {
      console.log("SocketService - Socket Reconnecting, # : ", attemptNumber);
    });
    this.socket.on('reconnect_error', (error) => {
      // console.log("SocketService - Socket Reconnect Error: ", error);
      // after 'reconnecting', if not sucessfull
    });
    this.socket.on('reconnect', (attemptNumber) => {
      console.log("SocketService - Socket Reconnected: ", attemptNumber);
      // will be called in addition to "connect";
    });
    this.socket.on('reconnect_failed', () => {
      console.log("SocketService - Socket Reconnect Failed ");
      // Fired when couldn't reconnect within reconnectionAttempts
      // reconnectionAttempts is "infinity" by default according to Doc (https://socket.io/docs/client-api/)
    });
    self.socketOpen();
  }
  private socketOpen = () => {
    console.log("SocketService - Socket Open()");
    this.socket.open(); // connect to the socket manually
  }
  private socketClose = () => {
    console.log("SocketService - Socket Close()");
    this.socket.close(); // disconnect the socket
  }
  private receivedMessage(ident: string, data: {}) {
    if (this.ident_to_caller_callback.hasOwnProperty(ident)) {
      let keys = Object.keys(this.ident_to_caller_callback[ident]);
      for (let key of keys) {
        let callback = this.ident_to_caller_callback[ident][key];
        callback(data);
      }
    }
  }
  public transmit = (ident: string, data: {}): boolean => {
    if (this.connected) {
      console.log("SocketService - transmit(), ident: ", ident);
      this.socket.emit(ident, data);
      return true;
    } else {
      console.warn("SocketService - transmit(), Could not transmit, not conncted !!! ident: ", ident);
      return false;
    }
  }
  public subscribe(caller: Object, ident: string, callback: SocketPacketCallback): void {
    let id = serviceObjectId.getObjectID(caller);
    if (!this.ident_to_caller_callback.hasOwnProperty(ident)) {
      this.ident_to_caller_callback[ident] = {};
      this.socket.on(ident, (data) => this.receivedMessage(ident, data));
    }
    this.ident_to_caller_callback[ident][id] = callback;
  }
  public unSubscribe(caller: Object, ident: string): void {
    let id = serviceObjectId.getObjectID(caller);
    if (this.ident_to_caller_callback.hasOwnProperty(ident)) {
      let keys = Object.keys(this.ident_to_caller_callback[ident]);
      if (this.ident_to_caller_callback[ident].hasOwnProperty(id)) {
        delete (this.ident_to_caller_callback[ident][id]);
      }
      if (keys.length === 0) {
        delete (this.ident_to_caller_callback[ident]);
      }
    }
  }
  ngOnDestroy(): void {
    this.iAmAlive = false;
  }
}
