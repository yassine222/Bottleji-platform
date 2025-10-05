import 'package:botleji/core/services/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final chatConnectionProvider = StreamProvider<bool>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return chatService.isConnected;
  });
});
