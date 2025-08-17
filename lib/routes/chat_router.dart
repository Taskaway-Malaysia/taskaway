import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/messages/screens/message_list_screen.dart';
import '../features/messages/screens/message_screen.dart';
import '../features/messages/screens/chat_wrapper_screen.dart';
import '../features/messages/models/channel.dart';

/// Chat and messaging-related routes for the app
class ChatRouter {
  static List<RouteBase> get routes => [
    GoRoute(
      path: '/home/chat',
      name: 'chat',
      builder: (context, state) => const MessageListScreen(),
      routes: [
        GoRoute(
          path: ':id',
          name: 'chat-room',
          builder: (context, state) {
            final channelId = state.pathParameters['id'] ?? '';
            final channel = state.extra as Channel?;
            
            // If channel is provided via extra, use it directly
            if (channel != null) {
              return MessageScreen(channel: channel);
            }
            
            // Otherwise, wrap in a loader that will fetch the channel
            return ChatWrapperScreen(channelId: channelId);
          },
        ),
      ],
    ),
  ];
}
