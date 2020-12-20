import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../sse_client.dart';

/// Server Sent Events class
class SSE {
  final Uri uri;
  Duration _retry;
  int _readyState;
  String _lastEventId;
  HttpClient _httpClient;

  StreamController<int> _onChangeState = StreamController<int>();
  StreamController<Message> _onMessage = StreamController<Message>();
  StreamController<dynamic> _onError = StreamController<dynamic>();

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
      String _cachedata = '';
      req.close().then((HttpClientResponse res) {
        if (res.statusCode == 200 &&
            res.headers.contentType != null &&
            res.headers.contentType.toString().toLowerCase() ==
                'text/event-stream') {
          _setState(ReadyState.open);
          res.listen((List<int> data) {
            var _decData = utf8.decode(data);
            if (RegExp(r'.*\n\n$').hasMatch(_decData)) {
              _cachedata += _decData;
              _parse(_cachedata);
              _cachedata = '';
            } else {
              _cachedata += _decData;
            }
          }, onError: (e) => _reconnect(), onDone: () => _reconnect());
        } else if ([204].contains(res.statusCode) ||
            res.headers.contentType.toString().toLowerCase() !=
                'text/event-stream') {
          close();
        } else {
          _reconnect();
        }
      }, onError: (e) => _reconnect());
    }, onError: (e) => _reconnect());
  }

  void close() {
    _httpClient.close();
    _setState(ReadyState.closed);
  }

  void _parse(String data) {
    data.split('\n\n').forEach((element) {
      String __id;
      String __event;
      String __data;
      Duration __retry;
      if (element.contains('\n')) {
        element.split('\n').forEach((value) {
          if (RegExp(r'id:.*$').hasMatch(value)) {
            __id = value.replaceFirst('id:', '');
          } else if (RegExp(r'event:.*$').hasMatch(value)) {
            __event = value.replaceFirst('event:', '');
          } else if (RegExp(r'data:.*$').hasMatch(value)) {
            if (__data == null) __data = '';
            __data += value.replaceFirst('data:', '');
          } else if (RegExp(r'retry:.*$').hasMatch(value)) {
            __retry = Duration(
                milliseconds: int.parse(value.replaceFirst('retry:', ''),
                    onError: (String val) => 0));
          }
        });
        if (__retry != null && __retry.inMilliseconds != 0) _retry = __retry;
        if ((__id != null && __id.isNotEmpty) ||
            (__event != null && __event.isNotEmpty) ||
            (__data != null && __data.isNotEmpty)) {
          _onMessage.add(new Message(__id, __event, __data));
        }
        if (__id != null && __id.isNotEmpty) _lastEventId = __id;
      }
    });
  }

  void _reconnect() {
    _setState(ReadyState.connecting);
    Timer(_retry, connect);
  }

  void _setState(int state) {
    if (state != _readyState) {
      _readyState = state;
      _onChangeState.add(state);
    }
  }

  Stream<int> get onChangeState => _onChangeState.stream;
  Stream<Message> get onMessage => _onMessage.stream;
  Stream<dynamic> get onError => _onError.stream;
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
