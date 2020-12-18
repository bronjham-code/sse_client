import 'dart:async';
import 'dart:io';

import '../lib/sse_client.dart';

main(List<String> args) {
  var hostUri =
      Uri(scheme: 'http', host: 'localhost', port: 80, path: 'example/sse/');
  var retry = Duration(seconds: 10);
  SSE sse = SSE(hostUri, retry: retry);
  sse.onChangeState.listen((int state) {
    print(state);
  });
  sse.onReciveMessage.listen((Message message) => print(message.toJson()));

  HttpServer.bind('localhost', 80).then((HttpServer httpServer) {
    httpServer.listen((HttpRequest httpRequest) {
      httpRequest.response.bufferOutput = false;
      httpRequest.response.headers.contentType =
          ContentType.parse('text/event-stream');
      httpRequest.response.statusCode = 200;
      Timer.periodic(
          Duration(seconds: 2),
          (Timer timer) => httpRequest.response.write(
              'data: hello world${DateTime.now().millisecondsSinceEpoch}\n\n'));
    });
    sse.connect();
  });
}