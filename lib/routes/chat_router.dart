import 'package:go_router/go_router.dart';
import '../features/messages/screens/message_list_screen.dart';
import '../features/messages/screens/message_screen.dart';
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
          builder: (context, state) => MessageScreen(
            channel: state.extra as Channel,
          ),
        ),
      ],
    ),
  ];
}
