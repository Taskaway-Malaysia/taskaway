import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../models/message.dart';

// Mock current user ID
const String currentUserId = 'current-user-id';

// Provider for mock channels data
final mockChannelsProvider = Provider<List<Channel>>((ref) {
  return [
    Channel(
      id: 'channel-1',
      taskId: 'task-1',
      taskTitle: 'Assemble IKEA shelf for bedroom',
      posterId: 'poster-1',
      posterName: 'Lisa M.',
      taskerId: currentUserId,
      taskerName: 'You',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      lastMessageAt: DateTime.now(),
      lastMessageContent: 'Yes, I still have all the parts',
      lastMessageSenderId: 'poster-1',
      unreadCount: 0,
    ),
    Channel(
      id: 'channel-2',
      taskId: 'task-2',
      taskTitle: 'Help put up Christmas decorations',
      posterId: currentUserId,
      posterName: 'You',
      taskerId: 'tasker-2',
      taskerName: 'Mike J.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 20)),
      lastMessageContent: 'Thank you for the great opportunity',
      lastMessageSenderId: 'tasker-2',
      unreadCount: 2,
    ),
    Channel(
      id: 'channel-3',
      taskId: 'task-3',
      taskTitle: 'House renovation',
      posterId: 'poster-3',
      posterName: 'Junior C.',
      taskerId: currentUserId,
      taskerName: 'You',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
      lastMessageContent: 'Okay, thanks!',
      lastMessageSenderId: 'poster-3',
      unreadCount: 0,
    ),
    Channel(
      id: 'channel-4',
      taskId: 'task-4',
      taskTitle: 'Personal shopper',
      posterId: currentUserId,
      posterName: 'You',
      taskerId: 'tasker-4',
      taskerName: 'Qistina Jalil',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      lastMessageAt: DateTime.now().subtract(const Duration(days: 11)),
      lastMessageContent: 'Alright, will do.',
      lastMessageSenderId: 'tasker-4',
      unreadCount: 0,
    ),
  ];
});

// Provider for mock messages as a map of channelId to message list
final mockMessagesProvider = Provider<Map<String, List<Message>>>((ref) {
  final now = DateTime.now();
  
  return {
    'channel-1': [
      Message(
        id: 'msg-1-1',
        channelId: 'channel-1',
        senderId: 'poster-1',
        content: 'Hi there! I was wondering if you still have all the parts for the IKEA shelf?',
        createdAt: now.subtract(const Duration(minutes: 10)),
        senderName: 'Lisa M.',
      ),
      Message(
        id: 'msg-1-2',
        channelId: 'channel-1',
        senderId: currentUserId,
        content: 'Yes, I have everything ready for assembly. When would you like me to come over?',
        createdAt: now.subtract(const Duration(minutes: 5)),
        senderName: 'You',
      ),
      Message(
        id: 'msg-1-3',
        channelId: 'channel-1',
        senderId: 'poster-1',
        content: 'Yes, I still have all the parts',
        createdAt: now,
        senderName: 'Lisa M.',
      ),
    ],
    'channel-2': [
      Message(
        id: 'msg-2-1',
        channelId: 'channel-2',
        senderId: currentUserId,
        content: 'Hello Mike, are you available to help with Christmas decorations this weekend?',
        createdAt: now.subtract(const Duration(hours: 2)),
        senderName: 'You',
      ),
      Message(
        id: 'msg-2-2',
        channelId: 'channel-2',
        senderId: 'tasker-2',
        content: 'Hi! Yes, I am available on Saturday afternoon. Would that work for you?',
        createdAt: now.subtract(const Duration(hours: 1)),
        senderName: 'Mike J.',
      ),
      Message(
        id: 'msg-2-3',
        channelId: 'channel-2',
        senderId: currentUserId,
        content: "Saturday afternoon works perfectly. Let's say 2 PM?",
        createdAt: now.subtract(const Duration(minutes: 30)),
        senderName: 'You',
      ),
      Message(
        id: 'msg-2-4',
        channelId: 'channel-2',
        senderId: 'tasker-2',
        content: 'Thank you for the great opportunity',
        createdAt: now.subtract(const Duration(minutes: 20)),
        senderName: 'Mike J.',
      ),
    ],
  };
});