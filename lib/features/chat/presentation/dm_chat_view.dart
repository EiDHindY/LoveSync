import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/chat/domain/chat_message.dart';
import 'package:love_app/features/chat/presentation/widgets/view_once_photo_viewer.dart';

class DmChatView extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onOpenPairing;

  const DmChatView({
    super.key,
    this.onClose,
    this.onOpenPairing,
  });

  @override
  ConsumerState<DmChatView> createState() => _DmChatViewState();
}

class _DmChatViewState extends ConsumerState<DmChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;


  final List<String> _reactionEmojis = ['❤️', '🔥', '💋', '🥂', '🥰', '🥺'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      ref.read(coupleRepositoryProvider.notifier).markChatMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = textToSend ?? _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (textToSend == null) {
      _textController.clear();
    }

    setState(() => _isSending = true);
    try {
      await ref.read(coupleRepositoryProvider.notifier).sendChatMessage(text);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendPhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        // Full quality preserved as requested by the user
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      final extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';

      if (!mounted) return;

      // Show confirmation dialog before sending
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.blush.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: AppTheme.crimson, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Send View-Once Photo?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.plum,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your partner can view it in full quality. It will be permanently burned and erased from cloud storage the moment they close it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.crimson,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed == true && mounted) {
        setState(() => _isSending = true);
        try {
          await ref.read(coupleRepositoryProvider.notifier).sendViewOncePhoto(
                bytes: bytes,
                fileExtension: extension,
              );
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        } finally {
          if (mounted) setState(() => _isSending = false);
        }
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  void _showReactionPicker(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'React to Message',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _reactionEmojis.map((emoji) {
                  final isSelected = message.reactions[ref.read(coupleRepositoryProvider).currentUserId] == emoji;
                  return InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref.read(coupleRepositoryProvider.notifier).reactToChatMessage(message.id, emoji);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.blush : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: AppTheme.crimson, width: 1.5) : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  String _formatDateSeparator(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('EEEE, MMM d').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(coupleRepositoryProvider);
    final messages = repo.chatMessages;

    // When viewing, mark any unread messages from partner as read
    if (messages.any((m) => m.senderId != repo.currentUserId && m.readAt == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(coupleRepositoryProvider.notifier).markChatMessagesAsRead();
      });
    }

    if (!repo.isPaired) {
      return _buildUnpairedState(context);
    }

    return Column(
      children: [
        // DM Header
        _buildHeader(context, repo),

        // Message List
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyChatState(repo)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg.isMine(repo.currentUserId);

                    // Date separator check
                    bool showSeparator = false;
                    if (index == 0) {
                      showSeparator = true;
                    } else {
                      final prev = messages[index - 1].createdAt.toLocal();
                      final curr = msg.createdAt.toLocal();
                      if (prev.year != curr.year || prev.month != curr.month || prev.day != curr.day) {
                        showSeparator = true;
                      }
                    }

                    return Column(
                      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (showSeparator) _buildDateSeparator(msg.createdAt),
                        _buildMessageBubble(context, msg, isMine, repo),
                      ],
                    );
                  },
                ),
        ),

        // Input Field
        _buildInputBar(context, repo),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, CoupleRepository repo) {
    final partnerName = repo.partnerName.isNotEmpty ? repo.partnerName : 'Your Partner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.plum, size: 22),
              onPressed: widget.onClose,
              tooltip: 'Back to Inbox',
            ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.blush,
            backgroundImage: repo.partnerAvatarUrl.isNotEmpty ? NetworkImage(repo.partnerAvatarUrl) : null,
            child: repo.partnerAvatarUrl.isEmpty
                ? Text(
                    partnerName[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.plum,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Synced in Realtime',
                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) async {
              if (val == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Clear Chat History?', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text(
                      'This will delete all messages in this direct chat for both you and your partner.',
                      style: TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(coupleRepositoryProvider.notifier).clearChatHistory();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Clear Chat History', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime dt) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDateSeparator(dt),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage msg,
    bool isMine,
    CoupleRepository repo,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.blush,
                  backgroundImage: repo.partnerAvatarUrl.isNotEmpty ? NetworkImage(repo.partnerAvatarUrl) : null,
                  child: repo.partnerAvatarUrl.isEmpty
                      ? Text(
                          repo.partnerName.isNotEmpty ? repo.partnerName[0].toUpperCase() : 'P',
                          style: const TextStyle(fontSize: 10, color: AppTheme.crimson, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showReactionPicker(context, msg),
                  child: msg.isViewOnce
                      ? _buildViewOnceCard(context, msg, isMine, repo)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isMine
                                ? const LinearGradient(
                                    colors: [AppTheme.secondaryContainer, AppTheme.crimson],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isMine ? null : Colors.grey.shade100,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMine ? 18 : 4),
                              bottomRight: Radius.circular(isMine ? 4 : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: isMine ? Colors.white : AppTheme.plum,
                              fontSize: 14.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                ),
              ),
              if (isMine) const SizedBox(width: 4),
            ],
          ),

          // Metadata & Reactions
          Padding(
            padding: EdgeInsets.only(
              top: 3,
              left: isMine ? 0 : 32,
              right: isMine ? 4 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(msg.createdAt),
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.readAt != null ? Icons.done_all_rounded : Icons.check_rounded,
                    size: 14,
                    color: msg.readAt != null ? AppTheme.crimson : Colors.grey.shade400,
                  ),
                ],
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showReactionPicker(context, msg),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Reactions row
          if (msg.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 2,
                left: isMine ? 0 : 30,
              ),
              child: Wrap(
                spacing: 4,
                children: msg.reactions.entries.map((entry) {
                  final isMyReaction = entry.key == repo.currentUserId;
                  return InkWell(
                    onTap: () {
                      ref.read(coupleRepositoryProvider.notifier).reactToChatMessage(msg.id, entry.value);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMyReaction ? AppTheme.blush : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMyReaction ? AppTheme.crimson : Colors.grey.shade300,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewOnceCard(
    BuildContext context,
    ChatMessage msg,
    bool isMine,
    CoupleRepository repo,
  ) {
    if (msg.isViewed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_rounded, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              'View-Once Photo · Opened',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (isMine) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B0029), AppTheme.crimson],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'View-Once Photo Sent',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Incoming unread view-once photo
    return InkWell(
      onTap: () {
        if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) {
          ViewOncePhotoViewer.show(
            context,
            imageUrl: msg.imageUrl!,
            senderName: repo.partnerName,
            onBurn: () {
              ref.read(coupleRepositoryProvider.notifier).viewAndBurnPhoto(msg.id);
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC70039), Color(0xFF8B0029)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC70039).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.photo_camera_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View-Once Photo 📸',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                Text(
                  'Tap to view · Burns once closed 🔥',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildInputBar(BuildContext context, CoupleRepository repo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera_back_rounded, color: AppTheme.crimson, size: 24),
              tooltip: 'Send View-Once Photo',
              onPressed: _isSending ? null : _pickAndSendPhoto,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Message ${repo.partnerName.isNotEmpty ? repo.partnerName : 'partner'}...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.secondaryContainer, AppTheme.crimson],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: _isSending ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatState(CoupleRepository repo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.blush.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppTheme.crimson),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat with ${repo.partnerName.isNotEmpty ? repo.partnerName : 'Your Partner'}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.plum,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send private love notes, flirty whispers, or view-once photos directly in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpairedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.blush.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 36, color: AppTheme.crimson),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pair to Start Chatting',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.plum,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Direct messaging and view-once photo sharing are private between you and your partner. Link your couple space to chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onOpenPairing,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add Partner', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.crimson,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
