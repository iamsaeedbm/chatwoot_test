import 'dart:async';
import 'dart:convert';
import 'package:chatwoot_test/layers/data/chatwoot_config.dart';
import 'package:chatwoot_test/layers/domain/entities/message.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String _chatwootInboxIdentifier = chatwootInboxIdentifier;
const String _chatwootBaseUrl = chatwootBaseUrl;

abstract class ChatDataSource {
  Future<List<Message>> initializeChat();
  Future<void> sendMessage(String text);
  Stream<Message> getMessagesStream();
  void dispose();
}

class ChatRemoteDataSourceImpl implements ChatDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: _chatwootBaseUrl));
  WebSocketChannel? _channel;
  final StreamController<Message> _messageStreamController =
      StreamController.broadcast();

  String? _contactIdentifier;
  String? _pubsubToken;
  int? _conversationId;

  @override
  Future<List<Message>> initializeChat() async {
    final contactResponse = await _dio.post(
      '/public/api/v1/inboxes/$_chatwootInboxIdentifier/contacts',
      data: {'name': 'Flutter User', 'email': 'user@flutter.app'},
    );
    _contactIdentifier = contactResponse.data['source_id'];
    _pubsubToken = contactResponse.data['pubsub_token'];

    final conversationResponse = await _dio.post(
      '/public/api/v1/inboxes/$_chatwootInboxIdentifier/contacts/$_contactIdentifier/conversations',
    );
    _conversationId = conversationResponse.data['id'];

    _connectToWebSocket();

    final messagesData = conversationResponse.data['messages'] as List;
    return messagesData.map((msg) => _mapToMessage(msg)).toList();
  }

  @override
  Future<void> sendMessage(String text) async {
    if (text.isEmpty || _contactIdentifier == null || _conversationId == null)
      return;
    await _dio.post(
      '/public/api/v1/inboxes/$_chatwootInboxIdentifier/contacts/$_contactIdentifier/conversations/$_conversationId/messages',
      data: {'content': text},
    );
  }

  void _connectToWebSocket() {
    if (_pubsubToken == null) return;

    final wsUrl = Uri.parse(
      _chatwootBaseUrl.replaceFirst('http', 'ws') + '/cable',
    );
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen((data) {
      final decodedData = jsonDecode(data);
      if (decodedData['type'] == 'welcome') {
        final subscriptionCommand = {
          'command': 'subscribe',
          'identifier': jsonEncode({
            'channel': 'RoomChannel',
            'pubsub_token': _pubsubToken,
          }),
        };
        _channel!.sink.add(jsonEncode(subscriptionCommand));
        return;
      }
      if (decodedData.containsKey('message')) {
        final messagePayload = decodedData['message'];
        if (messagePayload is Map && messagePayload.containsKey('event')) {
          final event = messagePayload['event'];
          final eventData = messagePayload['data'];
          if (event == 'message_created') {
            _processIncomingMessage(eventData);
          } else if (event == 'conversation.updated') {
            if (eventData.containsKey('messages') &&
                eventData['messages'] is List) {
              final incomingMessages = eventData['messages'] as List;
              for (var msgData in incomingMessages) {
                _processIncomingMessage(msgData);
              }
            }
          }
        }
      }
    });
  }

  void _processIncomingMessage(Map messageData) {
    if (messageData['message_type'] == 0) return;
    if (messageData.containsKey('content')) {
      _messageStreamController.add(_mapToMessage(messageData));
    }
  }

  Message _mapToMessage(Map data) {
    return Message(
      id: data['id'].toString(),
      text: data['content'],
      isMe: data['message_type'] == 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data['created_at'] as int) * 1000,
      ),
    );
  }

  @override
  Stream<Message> getMessagesStream() {
    return _messageStreamController.stream;
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageStreamController.close();
  }
}
