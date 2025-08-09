import 'dart:async';
import 'package:chatwoot_test/layers/domain/entities/message.dart';
import 'package:chatwoot_test/layers/domain/usecases/initialize_chat.dart';
import 'package:chatwoot_test/layers/domain/usecases/message_stream.dart';
import 'package:chatwoot_test/layers/domain/usecases/send_message.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final InitializeChat initializeChatUseCase;
  final SendMessage sendMessageUseCase;
  final GetMessageStream getMessageStreamUseCase;

  ChatProvider({
    required this.initializeChatUseCase,
    required this.sendMessageUseCase,
    required this.getMessageStreamUseCase,
  });

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Message> _messages = [];
  List<Message> get messages => _messages;

  StreamSubscription? _messageSubscription;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final initialMessages = await initializeChatUseCase();
    _messages = initialMessages.reversed.toList();

    _listenToMessages();

    _isLoading = false;
    notifyListeners();
  }

  void _listenToMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = getMessageStreamUseCase().listen((message) {
      final isDuplicate = _messages.any((m) => m.id == message.id);
      if (!isDuplicate) {
        _messages.insert(0, message);
        notifyListeners();
      }
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    final tempMessage = Message(
      id: Uuid().v4(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, tempMessage);
    notifyListeners();

    await sendMessageUseCase(text);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
