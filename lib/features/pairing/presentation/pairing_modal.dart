import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';

class PairingModal extends StatefulWidget {
  final String inviteCode;
  final bool isPaired;
  final String partnerName;
  final Function(String code) onPairCode;
  final VoidCallback onRegenerateCode;

  const PairingModal({
    super.key,
    required this.inviteCode,
    required this.isPaired,
    required this.partnerName,
    required this.onPairCode,
    required this.onRegenerateCode,
  });

  @override
  State<PairingModal> createState() => _PairingModalState();
}

class _PairingModalState extends State<PairingModal> {
  final _codeController = TextEditingController();
  bool _copied = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.inviteCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _submitPair() {
    final raw = _codeController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Please enter an invite code.');
      return;
    }
    final code = CoupleRepository.normalizeInviteCode(raw);
    widget.onPairCode(code);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 18),
            Row(
              children: const [
                Icon(Icons.link_rounded, color: AppTheme.crimson),
                SizedBox(width: 8),
                Text(
                  'Couple Pairing & Sync',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.plum,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Connect your phone privately with your partner.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Share Your Code Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.blush.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR INVITE CODE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.plum,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    widget.inviteCode,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: AppTheme.crimson,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.crimson,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: _copyCode,
                        icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
                        label: Text(_copied ? 'Copied!' : 'Copy Code'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: widget.onRegenerateCode,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('New Code'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Or Enter Partner's Code",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.plum),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. LOVE-9123',
                errorText: _error,
                filled: true,
                fillColor: AppTheme.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.blush),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.crimson),
                  onPressed: _submitPair,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitPair,
                child: const Text('Pair With Partner'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
