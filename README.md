## sse_client

A library for connecting to DNS-over-HTTPS (DoH). 

## Usage

A simple usage example:

```dart
import 'package:sse_client/sse_client.dart';

main() async {
  var dohResponse = await DoH(DoHProvider.google)
      .lookup('google.com', RecordType.A, dnssec: true);
  if (dohResponse != null) {
    dohResponse.answer.forEach((answer) {
      print(answer.data);
    });
  }
}
```

## Licensing

This project is available under the MIT license, as can be found in the LICENSE file.
