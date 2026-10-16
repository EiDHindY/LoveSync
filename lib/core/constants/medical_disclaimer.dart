import 'package:flutter/material.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/presentation/widgets/cycle_calculation_dialog.dart';

class MedicalDisclaimer {
  static const String shortBanner =
      'Fertility tracking is an estimate, not a guarantee. Typical rhythm method annual failure rate is ~12–24%.';

  static const String fullTitle = 'Important Medical & Contraception Disclaimer';

  static const String fullText = '''
LoveSync is designed to provide awareness and insights into your natural menstrual cycle using calendar-based fertility awareness estimations.

IMPORTANT SAFETY FACTS:
1. Not 100% Effective: Calendar and rhythm calculations have a typical-use annual failure rate of 12% to 24%. It is NOT a foolproof method of contraception.
2. Cycle Fluctuations: Ovulation timing can shift without warning due to stress, travel, illness, sleep changes, diet, or hormone fluctuations.
3. Sperm Viability: Sperm can survive inside the female reproductive tract for up to 5 days before ovulation. Ejaculating inside ("cream pie") during or near the fertile window carries a significant risk of pregnancy.
4. No STI Protection: Natural family planning offers zero protection against sexually transmitted infections (STIs).
5. Medical Advice: This application does not provide medical diagnoses or healthcare advice. Always consult a qualified gynecologist or healthcare professional for family planning.
''';

  static void showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: AppTheme.crimson),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                fullTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullText,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cautionAmberBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cautionAmber),
                ),
                child: const Text(
                  'By using this app, you acknowledge that safe-day predictions are statistical estimations and you assume full responsibility for your contraceptive decisions.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              CycleCalculationDialog.show(context);
            },
            child: const Text('View Calculation Formula'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
