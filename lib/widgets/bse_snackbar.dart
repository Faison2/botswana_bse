import 'package:flutter/material.dart';

/// Message type for [showBseSnackBar]. Only [success] is forced green —
/// [error] stays red and [info] stays on the BSE gold/marigold brand color.
enum BseSnackType { success, error, info }

const _bseMarigoldDark = Color(0xFFA97620);
const _bseErrorRed = Color(0xFFC0392B);
const _bseSuccessGreen = Color(0xFF2E7D32);

/// Branded toast for API-driven feedback (login errors, success messages,
/// etc.) — BSE marigold/gold for neutral info, red for errors, and green
/// specifically for success, always with the BSE roundel logo so it reads
/// as part of the app rather than a generic system SnackBar.
void showBseSnackBar(
  BuildContext context, {
  required String message,
  BseSnackType type = BseSnackType.info,
}) {
  final Color background;
  switch (type) {
    case BseSnackType.success:
      background = _bseSuccessGreen;
      break;
    case BseSnackType.error:
      background = _bseErrorRed;
      break;
    case BseSnackType.info:
      background = _bseMarigoldDark;
      break;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
