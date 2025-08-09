import 'dart:async';
import 'dart:convert';
import 'package:chatwoot_test/layers/data/chatwoot_config.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class ChatwootDataSource {
  Future<Map<String, dynamic>> initialize();
  Future<void> postMessage(String text);
  Stream<Map<String, dynamic>> getMessageStream();
}

class ChatwootRemoteDataSourceImpl implements ChatwootDataSource {
  final Dio _dio;
  WebSocketChannel? _channel;
  String? _contactIdentifier;
  String? _pubsubToken;
  int? _conversationId;

  static const String chatwootIdentifier = chatwootInboxIdentifier;
  static const String chatwootUrl = chatwootBaseUrl;

  ChatwootRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> initialize() async {
    final contactResponse = await _dio.post(
      '/public/api/v1/inboxes/$chatwootIdentifier/contacts',
      data: {'name': 'Clean User', 'email': 'user.clean@flutter.app'},
    );
    final contactData = contactResponse.data;
    _contactIdentifier = contactData['source_id'];
    _pubsubToken = contactData['pubsub_token'];

    final conversationResponse = await _dio.post(
      '/public/api/v1/inboxes/$chatwootIdentifier/contacts/$_contactIdentifier/conversations',
    );
    _conversationId = conversationResponse.data['id'];
    return conversationResponse.data;
  }

  @override
  Future<void> postMessage(String text) async {
    await _dio.post(
      '/public/api/v1/inboxes/$chatwootIdentifier/contacts/$_contactIdentifier/conversations/$_conversationId/messages',
      data: {'content': text},
    );
  }

  @override
  Stream<Map<String, dynamic>> getMessageStream() {
    final controller = StreamController<Map<String, dynamic>>();

    final wsUrl = Uri.parse(chatwootUrl.replaceFirst('http', 'ws') + '/cable');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen((data) {
      final decodedData = jsonDecode(data);
      if (decodedData['type'] == 'welcome') {
        final subCmd = {
          'command': 'subscribe',
          'identifier': jsonEncode({
            'channel': 'RoomChannel',
            'pubsub_token': _pubsubToken,
          }),
        };
        _channel!.sink.add(jsonEncode(subCmd));
      } else if (decodedData.containsKey('message')) {
        controller.add(decodedData['message']);
      }
    });

    return controller.stream;
  }
}
