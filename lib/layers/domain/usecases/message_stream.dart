import 'package:chatwoot_test/layers/domain/entities/message.dart';
import 'package:chatwoot_test/layers/domain/repositories/chat_repository.dart';

class GetMessageStream {
  final ChatRepository repository;

  GetMessageStream(this.repository);

  Stream<Message> call() {
    return repository.getMessageStream();
  }
}
