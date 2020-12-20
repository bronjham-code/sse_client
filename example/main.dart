import '../lib/sse_client.dart';

main(List<String> args) {
  var hostUri =
      Uri(scheme: 'http', host: 'localhost', port: 80, path: 'example/sse/');
  var retry = Duration(seconds: 10);
  SSE sse = SSE(hostUri, retry: retry);
  sse.onChangeState.listen((int state) {
    switch (state) {
      case 0:
        print('State: Connecting');
        break;
      case 1:
        print('State: Connected');
        break;
      case 2:
        print('State: Closed');
        break;
    }
  });
  sse.onMessage.listen((Message message) => print(message.toJson()));
  sse.connect();
}
