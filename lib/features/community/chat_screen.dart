import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/community.dart';
import '../../data/models/api_enums.dart';
import '../../providers.dart';
import '../auth/auth_controller.dart';
import 'community_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;

  const ChatScreen({super.key, required this.subjectId, required this.subjectName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(chatControllerProvider(widget.subjectId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ref.read(chatControllerProvider(widget.subjectId).notifier).sendMessage(content: text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(widget.subjectId));

    return Scaffold(
      appBar: AppBar(
        title: Text('مجتمع ${widget.subjectName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true, // Newest messages at bottom
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final msg = state.messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.primary),
              onPressed: () {
                // TODO: Pick file
              },
            ),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final CommunityMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = message.sender.id == ref.watch(authControllerProvider).valueOrNull?.id;
    final isTeacher = message.sender.role == UserRole.teacher;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.sender.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      if (isTeacher)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'معلم',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe ? const Radius.circular(0) : null,
                      bottomLeft: !isMe ? const Radius.circular(0) : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.attachment != null)
                        _buildAttachment(context, ref),
                      if (message.content != null && message.content!.isNotEmpty)
                        Text(
                          message.content!,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  intl.DateFormat('HH:mm').format(message.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundImage: message.sender.avatarUrl != null
          ? NetworkImage(message.sender.avatarUrl!)
          : null,
      child: message.sender.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
    );
  }

  Widget _buildAttachment(BuildContext context, WidgetRef ref) {
    final att = message.attachment!;
    final tokenAsync = ref.watch(tokenStorageProvider.select((s) => s.readToken()));
    
    String fullUrl = att.url;
    if (!fullUrl.startsWith('http')) {
      fullUrl = '${AppConfig.apiBaseUrl.replaceFirst('/api', '')}$fullUrl';
    }

    return FutureBuilder<String?>(
      future: tokenAsync,
      builder: (context, snapshot) {
        final token = snapshot.data;
        if (message.type == CommunityMessageType.image) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
                placeholder: (context, url) => const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file),
              const SizedBox(width: 8),
              Flexible(child: Text(att.fileName, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      },
    );
  }
}
