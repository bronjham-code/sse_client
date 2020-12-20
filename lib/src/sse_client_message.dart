//SSE message class
class SSEMessage {
  final String id;
  final String event;
  final String data;

  SSEMessage(this.id, this.event, this.data);

  //Convert this message to JSON
  Map<String, dynamic> toJson() => {'id': id, 'event': event, 'data': data};
}
