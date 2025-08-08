import 'package:chatwoot_test/layers/domain/entities/message.dart';
import 'package:chatwoot_test/layers/domain/repositories/chatwoot_repository.dart';

class InitializeChat {
  final ChatRepository repository;

  InitializeChat(this.repository);

  Future<List<Message>> call() {
    return repository.initializeChat();
  }
}
