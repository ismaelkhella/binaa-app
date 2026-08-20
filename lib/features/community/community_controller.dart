import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/community.dart';
import '../../providers.dart';

final communitySubjectsProvider = FutureProvider<List<CommunitySubject>>((ref) {
  return ref.read(communityRepositoryProvider).getSubjects();
});

class ChatState {
  final List<CommunityMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  ChatState copyWith({
    List<CommunityMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final Ref _ref;
  final String _subjectId;
  StreamSubscription? _messageSub;
  StreamSubscription? _deleteSub;

  ChatController(this._ref, this._subjectId) : super(ChatState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _ref.read(communityRepositoryProvider).getMessages(_subjectId);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        hasMore: messages.length >= 30,
      );
      
      final socket = _ref.read(socketServiceProvider);
      await socket.connect();
      socket.joinSubject(_subjectId);
      
      // Listen for live updates
      _messageSub = socket.onNewMessage.listen((msg) {
        if (msg.subjectId == _subjectId) {
          addMessage(msg);
        }
      });

      _deleteSub = socket.onMessageDeleted.listen((data) {
        if (data['subjectId'] == _subjectId) {
          removeMessage(data['id']!);
        }
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addMessage(CommunityMessage msg) {
    if (state.messages.any((m) => m.id == msg.id)) return;
    state = state.copyWith(messages: [msg, ...state.messages]);
  }

  void removeMessage(String id) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != id).toList(),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final before = state.messages.isEmpty ? null : state.messages.last.id;
      final more = await _ref.read(communityRepositoryProvider).getMessages(_subjectId, before: before);
      state = state.copyWith(
        messages: [...state.messages, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 30,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> sendMessage({String? content, File? file, CommunityMessageType? type}) async {
    try {
      final msg = await _ref.read(communityRepositoryProvider).sendMessage(
        _subjectId,
        content: content,
        file: file,
        type: type,
      );
      // Add immediately for better UX
      addMessage(msg);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _deleteSub?.cancel();
    _ref.read(socketServiceProvider).leaveSubject(_subjectId);
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController, ChatState, String>((ref, id) {
  final controller = ChatController(ref, id);
  // Using a post-frame callback or similar to init if needed, 
  // but usually we init manually from the UI.
  return controller;
});
