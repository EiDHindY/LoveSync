import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:love_app/core/theme/app_theme.dart';

class PartnerInfoModal extends StatelessWidget {
  final String partnerName;
  final String partnerRole;
  final bool partnerTracksCycle;
  final String inviteCode;
  final String partnerAvatarUrl;
  final VoidCallback onDisconnectPartner;

  const PartnerInfoModal({
    super.key,
    required this.partnerName,
    required this.partnerRole,
    required this.partnerTracksCycle,
    required this.inviteCode,
    this.partnerAvatarUrl = '',
    required this.onDisconnectPartner,
  });

  Future<void> _confirmRemovePartner(BuildContext context) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.person_remove_rounded, color: AppTheme.crimson, size: 24),
            SizedBox(width: 8),
            Text('Remove Partner?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove $partnerName as your partner? You will both return to individual mode and can connect anytime with a new code.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove Partner'),
          ),
        ],
      ),
    );

    if (shouldRemove == true && context.mounted) {
      Navigator.of(context).pop(); // close modal
      onDisconnectPartner();
    }
  }

  Widget _buildFallbackAvatar(String initial) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.crimson, AppTheme.plum],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Partner Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.blush,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.crimson.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: partnerAvatarUrl.isNotEmpty
                  ? Image.network(
                      partnerAvatarUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, _, _) => _buildFallbackAvatar(initial),
                    )
                  : _buildFallbackAvatar(initial),
            ),
          ),
          const SizedBox(height: 12),

          // Partner Name
          Text(
            partnerName.isNotEmpty ? partnerName : 'Your Partner',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.plum,
            ),
          ),
          const SizedBox(height: 6),

          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.safeGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'My Partner • Synced in Real Time',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.safeGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Partner Information Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.blush),
            ),
            child: Column(
              children: [
                // Tracking preference
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: partnerTracksCycle ? AppTheme.blush : Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        partnerTracksCycle ? Icons.calendar_month_rounded : Icons.male_rounded,
                        size: 20,
                        color: partnerTracksCycle ? AppTheme.crimson : Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cycle Tracking Role',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            partnerTracksCycle ? 'Tracks Menstrual Cycle' : 'Does Not Track Cycle',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.plum),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Invite code
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.blush,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.key_rounded, size: 20, color: AppTheme.crimson),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shared Space Code',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            inviteCode,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.plum),
                      tooltip: 'Copy Code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite code copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Remove Partner Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_remove_rounded, color: AppTheme.crimson, size: 18),
              label: const Text(
                'Remove as Partner',
                style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.crimson.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _confirmRemovePartner(context),
            ),
          ),
        ],
      ),
    );
  }
}
