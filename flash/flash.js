"use strict";
/*
nodemcu flashtool
Author: Henry Thasler
Example: nodejs flash.js ./../config.lua 
*/

const net = require('net');
const fs = require('fs');
const path = require('path');


const cfg = {
  host: "car.fritz.box",
  port: 81
};

var source = null;
var header = {
  cmd: 'status',
  file: null,
};

if(process.argv[2].length) {
  source=process.argv[2]
}
else{
  console.log('file not found: ' + source)
  return;
}

console.log('Preparing ' + source);

fs.readFile(source, {encoding: 'utf8'}, (err, data) => {
  if (err) throw err;
  var lines = data.split('\n')

  header.cmd='new'
  header.file=path.basename(source)
  let chunks = [JSON.stringify(header)+'\n'];
  for(let line of lines) {
    if( (chunks[chunks.length-1].length+line.length)>1400 ) {
      header.cmd='append'
      chunks.push(JSON.stringify(header)+'\n'+line+'\n');
    }
    else {
      chunks[chunks.length-1]+=line+'\n';
    }
  }

  // reset nodemcu after flash
  header.cmd='reset'
  chunks.push(JSON.stringify(header));

  console.log('Prepared '+chunks.length+' chunks. Connecting...');
  var client = net.connect(cfg, () => {
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
