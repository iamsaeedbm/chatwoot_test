import 'package:chatwoot_test/layers/domain/entities/message.dart';
import 'package:chatwoot_test/layers/domain/repositories/chatwoot_repository.dart';

class ListenForMessages {
  final ChatRepository repository;

  ListenForMessages(this.repository);

  Stream<Message> call() {
    return repository.getMessagesStream();
  }
}
