import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/clipboard_helper.dart';
import '../../ocr/models/scan_result.dart';
import '../../ocr/views/result_screen.dart';

class HistoryCard extends StatelessWidget {
  final ScanResult scan;
  final VoidCallback onDelete;

  const HistoryCard({
    Key? key,
    required this.scan,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DateFormat.yMMMd().add_jm().format(scan.timestamp);

    // Grab first 2 lines of text for the snippet
    final textLines = scan.text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final textSnippet = textLines.isNotEmpty 
        ? (textLines.length > 1 ? '${textLines[0]}\n${textLines[1]}...' : textLines[0])
        : 'No text extracted';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                text: scan.text,
                imagePath: scan.imagePath,
                scanResult: scan,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: File(scan.imagePath).existsSync()
                    ? Image.file(
                        File(scan.imagePath),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: isDark ? const Color(0xFF161C2C) : Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),

              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFA78BFA) : Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      textSnippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
              
              // Actions (Copy / Delete)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                    tooltip: 'Copy Text',
                    onPressed: () {
                      ClipboardHelper.copyToClipboard(scan.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied text to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Delete Entry',
                    onPressed: onDelete,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
