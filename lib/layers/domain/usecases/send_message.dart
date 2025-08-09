import 'package:chatwoot_test/layers/domain/repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<void> call(String text) {
    return repository.sendMessage(text);
  }
}
