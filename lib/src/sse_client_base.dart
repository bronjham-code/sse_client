import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../sse_client.dart';
import '../sse_client.dart';
import '../sse_client.dart';

/// Server Sent Events class
class SSE {
  final Uri uri;
  Duration _retry;
  int _readyState = 0;
  String _lastEventId;
  HttpClient _httpClient;

  StreamController<int> _onChangeState = StreamController<int>();
  StreamController<Message> _onReciveMessage = StreamController<Message>();

  SSE(this.uri, {String lastEventId, Duration retry}) {
    if (retry != null && retry != 0) {
      _retry = retry;
    } else {
      _retry = Duration(seconds: 10);
    }
  }

  void connect({Map<String, dynamic> headers}) {
    _setState(ReadyState.connecting);
    if (_httpClient == null) {
      _httpClient = HttpClient();
    }
    _httpClient.openUrl('GET', uri).then((HttpClientRequest req) {
      req.bufferOutput = false;
      req.headers.contentType = ContentType.parse('text/event-stream');
      if (headers != null && headers.isNotEmpty) {
        headers.forEach((key, value) => req.headers.set(key, value));
      }
      if (_lastEventId != null && _lastEventId.isNotEmpty) {
        req.headers.set('Last-Event-ID', _lastEventId);
      }
      req.close().then((HttpClientResponse res) {
        if (res.statusCode == 200 &&
            res.headers.contentType != null &&
            res.headers.contentType.toString().toLowerCase() ==
                'text/event-stream') {
          _setState(ReadyState.open);
          res.listen((List<int> data) {
            print(utf8.decode(data));
          });
        }
      });
    }, onError: () => _reconnect());
  }

  void close() {
    _httpClient.close();
    _setState(ReadyState.closed);
  }

  void _reconnect() {
    _setState(ReadyState.connecting);
    connect();
  }

  void _setState(int state) {
    _readyState = state;
    _onChangeState.add(state);
  }

  Stream<int> get onChangeState => _onChangeState.stream;
  Stream<Message> get onReciveMessage => _onReciveMessage.stream;
  Duration get retry => _retry;
  int get readyState => _readyState;
  String get lastEventId => _lastEventId;
}

class ReadyState {
  static final int connecting = 0;
  static final int open = 1;
  static final int closed = 2;
}

class Message {
  final String id;
  final String event;
  final String data;

  Message(this.id, this.event, this.data);

  Map<String, dynamic> toJson() => {'id': id, 'event': event, 'data': data};
}
