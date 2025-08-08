import 'package:chatwoot_test/layers/data/chatwoot_data_source.dart';
import 'package:chatwoot_test/layers/domain/entities/message.dart';
import 'package:chatwoot_test/layers/domain/repositories/chatwoot_repository.dart';

class ChatRepositoryImp implements ChatRepository {
  final ChatDataSource remoteDataSource;

  ChatRepositoryImp({required this.remoteDataSource});

  @override
  Future<List<Message>> initializeChat() {
    return remoteDataSource.initializeChat();
  }

  @override
  Future<void> sendMessage(String text) {
    return remoteDataSource.sendMessage(text);
  }

  @override
  Stream<Message> getMessagesStream() {
    return remoteDataSource.getMessagesStream();
  }

  @override
  void dispose() {
    remoteDataSource.dispose();
  }
}
