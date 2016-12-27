// Non-js dependencies
require('normalize.css/normalize.css');
require('./main.styl');

var Elm = require('./App.elm');
var mqtt = require('mqtt');
var msgpack = require('msgpack-lite');

var app = Elm.App.fullscreen();

// TODO: 내 MQTT 서버로 돌리기, TLS websocket 쓰기
var client = mqtt.connect('ws://test.mosquitto.org:8080/mqtt');

// TODO: 채널에 맞춰서 subscribe 하게 만들기
client.subscribe('SW5pdFNlcnZlcg==,I2E=', function(err, granted) {
  // TODO: 아래 라인 삭제, 올바르게 처리하기
  console.log(`Subscribe 완료 (err: ${err}, granted: ${granted})`);
});

app.ports.onMessage.subscribe(function(payload) {
  // Base64 encode both serverName and channelName then join them with ','
  //
  //     ['InitServer', '#a'] => 'SW5pdFNlcnZlcg==,I2E='
  var topic = payload.namePair.map(window.btoa).join();
  var msg = msgpack.encode(payload.line);

  // TODO: 랜덤 임시 ID 만들기

  // TODO: QoS 2 쓰기
  client.publish(topic, msg, function(err) {
    if (err) {
      // TODO: 에러핸들링
      return;
    }

    // TODO: Elm에 송신 완료되었다고 신호 보내기
  });
});

client.on('message', function(topic, msg, _packet) {
  var payload = {
    // Split the string with ',' and base64 decode each of it
    //
    //     'SW5pdFNlcnZlcg==,I2E=' => ['InitServer', '#a']
    namePair: topic.split(',').map(atob),
    line: msgpack.decode(msg)
  };

  // TODO: Remove the line below
  console.log(
    `%c${payload.line.status} %c<@${payload.line.nick}> ${payload.line.text}`,
    'color: gray;',
    'color: blue; font-weight: bold;'
  );


  app.ports.newMessage.send(payload);
});
