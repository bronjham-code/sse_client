import '../lib/ssevents_client.dart';

void main(List<String> args) {
  SSE sse = SSE(Uri(scheme: 'http', host: 'localhost', port: 80),
      retry: Duration(seconds: 15));
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
  sse.onMessage.listen((SSEMessage message) => print(message.toJson()));
  sse.connect();
}
