import 'package:chatwoot_test/layers/data/chatwoot_data_source.dart';
import 'package:chatwoot_test/layers/data/chatwoot_repository.dart';
import 'package:chatwoot_test/layers/domain/repositories/chatwoot_repository.dart';
import 'package:chatwoot_test/layers/domain/usecases/initialize_chat.dart';
import 'package:chatwoot_test/layers/domain/usecases/listen_for_messages.dart';
import 'package:chatwoot_test/layers/domain/usecases/send_message.dart';
import 'package:chatwoot_test/layers/presentation/pages/chat_page.dart';
import 'package:chatwoot_test/layers/presentation/provider/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  final ChatDataSource remoteDataSource = ChatRemoteDataSourceImpl();
  final ChatRepository chatRepository = ChatRepositoryImp(
    remoteDataSource: remoteDataSource,
  );

  final initializeChatUseCase = InitializeChat(chatRepository);
  final sendMessageUseCase = SendMessage(chatRepository);
  final listenForMessagesUseCase = ListenForMessages(chatRepository);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatProvider(
        initializeChatUseCase: initializeChatUseCase,
        sendMessageUseCase: sendMessageUseCase,
        listenForMessagesUseCase: listenForMessagesUseCase,
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Clean Chatwoot Client',
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
