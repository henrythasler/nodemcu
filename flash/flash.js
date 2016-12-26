"use strict";

const net = require('net');
const fs = require('fs');

const luafile = './../sensor/temperature.lua'
//const luafile = './../flash/flashdaemon.lua'

console.log('Flashing '+luafile);

fs.readFile(luafile, {encoding: 'utf8'}, (err, data) => {
  if (err) throw err;
  var lines = data.split('\n')
 
  let chunks = ['NEW\n'];
  for(let line of lines) {
    if( (chunks[chunks.length-1].length+line.length)>1400 ) {
      chunks.push('APP\n'+line+'\n');
    }
    else {
      chunks[chunks.length-1]+=line+'\n';
    }
  }    

  // send chunks
  for(let chunk of chunks) {
    console.log('sending '+chunk.length+' bytes');
    send(chunk);
  }

  // reset node after completion
  send("RES");
});


function send(payload)
{
var res=false; 
var client = net.connect({host: "node01", port: 80}, () => {
    // 'connect' listener
    console.log('connected to server!');
    client.write(payload);
    });  

  client.on('data', (data) => {
    console.log(data.toString());
    client.end();
  });

  client.on('end', () => {
    res = true;
    console.log('disconnected from server');
  });
}
