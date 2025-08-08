import 'dart:async';
import 'package:chatwoot_test/layers/domain/entities/message.dart';
import 'package:chatwoot_test/layers/domain/usecases/initialize_chat.dart';
import 'package:chatwoot_test/layers/domain/usecases/listen_for_messages.dart';
import 'package:chatwoot_test/layers/domain/usecases/send_message.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final InitializeChat initializeChatUseCase;
  final SendMessage sendMessageUseCase;
  final ListenForMessages listenForMessagesUseCase;

  ChatProvider({
    required this.initializeChatUseCase,
    required this.sendMessageUseCase,
    required this.listenForMessagesUseCase,
  }) {
    _listenForMessages();
  }

  List<Message> _messages = [];
  List<Message> get messages => _messages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription? _messageSubscription;
  final Uuid _uuid = const Uuid();

  Future<void> loadInitialMessages() async {
    _isLoading = true;
    notifyListeners();

    final initialMessages = await initializeChatUseCase();
    _messages = initialMessages.reversed.toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    final tempId = _uuid.v4();
    final tempMessage = Message(
      id: tempId,
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, tempMessage);
    notifyListeners();

    await sendMessageUseCase(text);
  }

  void _listenForMessages() {
    _messageSubscription = listenForMessagesUseCase().listen((message) {
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.insert(0, message);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
