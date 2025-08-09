import 'package:chatwoot_test/layers/data/chatwoot_data_source.dart';
import 'package:chatwoot_test/layers/domain/entities/message.dart';
import 'package:chatwoot_test/layers/domain/repositories/chat_repository.dart';

class ChatRepositoryImp implements ChatRepository {
  final ChatwootDataSource remoteDataSource;

  ChatRepositoryImp({required this.remoteDataSource});

  @override
  Future<List<Message>> initializeChat() async {
    final conversationData = await remoteDataSource.initialize();

    final messagesData = conversationData['messages'] as List?;
    if (messagesData == null || messagesData.isEmpty) {
      return [];
    }

    return messagesData
        .map((data) => _mapToEntity(data))
        .where((entity) => entity != null)
        .cast<Message>()
        .toList();
  }

  @override
  Stream<Message> getMessageStream() {
    return remoteDataSource.getMessageStream().expand((payload) {
      return _processStreamPayload(payload);
    });
  }

  @override
  Future<void> sendMessage(String text) async {
    await remoteDataSource.postMessage(text);
  }

  List<Message> _processStreamPayload(Map<String, dynamic> payload) {
    final event = payload['event'] as String?;
    final data = payload['data'];

    List<Message> messages = [];

    if (event == 'message_created') {
      final message = _mapToEntity(data);
      if (message != null && !message.isMe) {
        messages.add(message);
      }
    } else if (event == 'conversation.updated') {
      final messagesList = data['messages'] as List?;
      if (messagesList != null) {
        for (var msgData in messagesList) {
          final message = _mapToEntity(msgData);
          if (message != null && !message.isMe) {
            messages.add(message);
          }
        }
      }
    }
    return messages;
  }

  Message? _mapToEntity(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final id = data['id']?.toString();
    final text = data['content'] as String?;
    final messageType = data['message_type'] as int?;
    final createdAt = data['created_at'] as int?;

    if (id == null ||
        text == null ||
        messageType == null ||
        createdAt == null) {
      return null;
    }

    return Message(
      id: id,
      text: text,
      isMe: messageType == 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(createdAt * 1000),
    );
  }
}
