import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../ssevents_client.dart';

/// Server Sent Events base class
class SSE {
  // SSE server host
  final Uri uri;
  //SSE reconnect timeout
  Duration _retry;
  //SSE current state
  int _state;
  //SSE last event ID
  String _lastEventId;
  //HTTP client
  HttpClient _httpClient;

  // Stream of state change
  StreamController<int> _onChangeState = StreamController<int>();
  // Stream of message recive
  StreamController<SSEMessage> _onMessage = StreamController<SSEMessage>();
  // Stream of error recive
  StreamController<dynamic> _onError = StreamController<dynamic>();

  SSE(this.uri, {String lastEventId, Duration retry}) {
    //if lastEventId is not null, set _lastEventId to lastEventId
    if (lastEventId != null && lastEventId.isNotEmpty) {
      _lastEventId = lastEventId;
    }
    //if retry is null, set retru to default 10 seconds
    if (retry != null && retry != 0) {
      _retry = retry;
    } else {
      _retry = Duration(seconds: 10);
    }
  }

  //Start SSE connect to the server
  void connect({Map<String, dynamic> headers}) {
    _setState(SSEState.connecting);
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
          _setState(SSEState.open);
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

  //Close SSE connection if http client is not null
  void close() {
    if (_httpClient != null) {
      _httpClient.close();
      _setState(SSEState.closed);
    }
  }

  //Parse SSE message
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
          _onMessage.add(new SSEMessage(__id, __event, __data));
        }
        if (__id != null && __id.isNotEmpty) _lastEventId = __id;
      }
    });
  }

  //SSE reconnect use timer
  void _reconnect() {
    _setState(SSEState.connecting);
    Timer(_retry, connect);
  }

  //Set state & send state to stream
  void _setState(int state) {
    if (state != _state) {
      _state = state;
      _onChangeState.add(state);
    }
  }

  //Getters
  Stream<int> get onChangeState => _onChangeState.stream;
  Stream<SSEMessage> get onMessage => _onMessage.stream;
  Stream<dynamic> get onError => _onError.stream;
  Duration get retry => _retry;
  int get state => _state;
  String get lastEventId => _lastEventId;
}
