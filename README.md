## sse_client

A library for receive EventSource sent from the server. 

## Usage

A simple usage example:

```dart
import 'package:sse_client/sse_client.dart';

main() async {
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
```

## Licensing

This project is available under the MIT license, as can be found in the LICENSE file.
