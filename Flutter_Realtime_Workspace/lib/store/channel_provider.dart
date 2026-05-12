import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/channel_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/channel_repository.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((_) {
  return ChannelRepository();
});

final channelsProvider =
    FutureProvider.autoDispose.family<List<ChannelModel>, String>(
        (ref, workspaceId) {
  return ref.watch(channelRepositoryProvider).getChannels(workspaceId);
});

final channelDetailProvider =
    FutureProvider.autoDispose.family<ChannelModel, String>((ref, id) {
  return ref.watch(channelRepositoryProvider).getChannel(id);
});

final activeChannelProvider = StateProvider<ChannelModel?>((ref) => null);

final channelMessagesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, channelId) {
  return ref.watch(channelRepositoryProvider).getMessages(channelId);
});

final channelNotifierProvider =
    StateNotifierProvider<ChannelNotifier, AsyncValue<ChannelModel?>>(
        (ref) => ChannelNotifier(ref));

class ChannelNotifier extends StateNotifier<AsyncValue<ChannelModel?>> {
  final Ref _ref;
  ChannelNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<ChannelModel> createChannel(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final channel =
          await _ref.read(channelRepositoryProvider).createChannel(body);
      state = AsyncValue.data(channel);
      return channel;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addMember(String channelId, String userId) async {
    await _ref.read(channelRepositoryProvider).addMember(channelId, userId);
  }

  Future<void> removeMember(String channelId, String memberId) async {
    await _ref.read(channelRepositoryProvider).removeMember(channelId, memberId);
  }
}
