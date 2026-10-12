import 'package:flutter/material.dart';

/// Result/feedback type for [showAppMessageDialog]. Only [success] forces
/// green — [error] stays red and [info] stays on the app's gold theme.
enum AppMessageType { success, error, info }

/// Branded result dialog — shows the BSE logo plus a status badge, and
/// is used anywhere we need to tell the client "this action worked / failed"
/// (e.g. IPO bid submission) instead of a plain SnackBar. Dark/light aware,
/// using the same card colours as the rest of the app; only the accent
/// (icon, badge ring, button) changes with [type] — green for success.
Future<void> showAppMessageDialog(
  BuildContext context, {
  required bool isDark,
  required AppMessageType type,
  required String title,
  required String message,
  String buttonLabel = 'OK',
  VoidCallback? onButtonPressed,
}) {
  final cardColor = isDark ? const Color(0xFF23201C) : Colors.white;
  final textColor = isDark ? Colors.white : Colors.black87;
  final subtextColor = isDark ? Colors.white70 : Colors.black54;
  final goldAccent = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);

  Color accentColor;
  IconData icon;
  switch (type) {
    case AppMessageType.success:
      accentColor = const Color(0xFF2E7D32); // green — success only
      icon = Icons.check_circle_rounded;
      break;
    case AppMessageType.error:
      accentColor = const Color(0xFFC62828); // red
      icon = Icons.error_rounded;
      break;
    case AppMessageType.info:
      accentColor = goldAccent;
      icon = Icons.info_rounded;
      break;
  }

  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                  Positioned(
                    bottom: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardColor, width: 2),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: subtextColor, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onButtonPressed?.call();
                  },
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
