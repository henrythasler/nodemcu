"use strict";

const net = require('net');
const fs = require('fs');

const luafile = './../sensor/temperature.lua'
//const luafile = './../flash/flashdaemon.lua'

console.log('Preparing '+luafile);

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

  // reset nodemcu after flash
  chunks.push('RES');

  console.log('Prepared '+chunks.length+' chunks. Connecting...');
  var client = net.connect({host: "node01", port: 80}, () => {
      // 'connect' listener
      console.log('Connected to nodemcu');
      let chunk = chunks.shift()
      console.log('sending chunk with '+chunk.length+' Bytes...');
      client.write(chunk);
      });

    client.on('data', (data) => {
      console.log(data.toString());
      if( (data.toString() === 'ok') && (chunks.length>0))  {
        let chunk = chunks.shift()
        console.log('sending chunk with '+chunk.length+' Bytes...');
        client.write(chunk);
      }
      else {
        console.log('Finished upload');
        client.end();
      }
    });

    client.on('end', () => {
      console.log('Disconnected from nodemcu');
    });
});
