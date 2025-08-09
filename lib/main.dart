import 'package:chatwoot_test/layers/data/chat_repository_imp.dart';
import 'package:chatwoot_test/layers/data/chatwoot_data_source.dart';
import 'package:chatwoot_test/layers/domain/repositories/chat_repository.dart';
import 'package:chatwoot_test/layers/domain/usecases/initialize_chat.dart';
import 'package:chatwoot_test/layers/domain/usecases/message_stream.dart';
import 'package:chatwoot_test/layers/domain/usecases/send_message.dart';
import 'package:chatwoot_test/layers/presentation/pages/chat_page.dart';
import 'package:chatwoot_test/layers/presentation/provider/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>(
          create: (_) => Dio(
            BaseOptions(baseUrl: ChatwootRemoteDataSourceImpl.chatwootUrl),
          ),
        ),
        Provider<ChatwootDataSource>(
          create: (context) =>
              ChatwootRemoteDataSourceImpl(context.read<Dio>()),
        ),
        Provider<ChatRepository>(
          create: (context) => ChatRepositoryImp(
            remoteDataSource: context.read<ChatwootDataSource>(),
          ),
        ),

        Provider<InitializeChat>(
          create: (context) => InitializeChat(context.read<ChatRepository>()),
        ),
        Provider<SendMessage>(
          create: (context) => SendMessage(context.read<ChatRepository>()),
        ),
        Provider<GetMessageStream>(
          create: (context) => GetMessageStream(context.read<ChatRepository>()),
        ),

        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(
            initializeChatUseCase: context.read<InitializeChat>(),
            sendMessageUseCase: context.read<SendMessage>(),
            getMessageStreamUseCase: context.read<GetMessageStream>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: ' Chatwoot Client',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const ChatPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
