import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/message_repository.dart';
import '../models/message.dart';
import '../models/channel.dart';
import '../../auth/controllers/auth_controller.dart';

final messageControllerProvider = Provider<MessageController>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return MessageController(ref: ref, repository: repository);
});

final userChannelsProvider = StreamProvider.autoDispose<List<Channel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(messageControllerProvider).watchUserChannels(user.id);
});

final channelMessagesProvider = StreamProvider.autoDispose.family<List<Message>, String>((ref, channelId) {
  return ref.watch(messageControllerProvider).watchChannelMessages(channelId);
});

class MessageController {
  final Ref _ref;
  final MessageRepository repository;

  MessageController({
    required Ref ref,
    required this.repository,
  }) : _ref = ref;

  Future<Channel> createChannel({
    required String taskId,
    required String taskTitle,
    required String posterId,
    required String posterName,
    required String taskerId,
    required String taskerName,
  }) async {
    return repository.createChannel(
      taskId: taskId,
      taskTitle: taskTitle,
      posterId: posterId,
      posterName: posterName,
      taskerId: taskerId,
      taskerName: taskerName,
    );
  }

  Future<Channel?> getChannelByTaskId(String taskId) {
    return repository.getChannelByTaskId(taskId);
  }

  Stream<List<Channel>> watchUserChannels(String userId) {
    return repository.watchUserChannels(userId);
  }

  Future<Message> sendMessage({
    required String channelId,
    required String content,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User must be logged in to send messages');

    return repository.sendMessage(
      channelId: channelId,
      senderId: user.id,
      content: content,
    );
  }

  Stream<List<Message>> watchChannelMessages(String channelId) {
    return repository.watchChannelMessages(channelId);
  }

  Future<List<Message>> getChannelMessages(String channelId) {
    return repository.getChannelMessages(channelId);
  }
} 