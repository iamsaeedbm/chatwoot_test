import 'package:chatwoot_test/layers/domain/entities/message.dart';

abstract class ChatRepository {
  Future<List<Message>> initializeChat();
  Future<void> sendMessage(String text);
  Stream<Message> getMessageStream();
}
