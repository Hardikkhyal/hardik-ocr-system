import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ClipboardHelper {
  static Future<void> copyToClipboard(String text) async {
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  static Future<void> shareText(String text, {String? subject}) async {
    if (text.isNotEmpty) {
      await Share.share(text, subject: subject);
    }
  }
}
