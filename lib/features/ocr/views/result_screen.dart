import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/utils/clipboard_helper.dart';
import '../controllers/ocr_controller.dart';
import '../models/scan_result.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String text;
  final String imagePath;
  final ScanResult? scanResult; // Null if it's a new scan, non-null if loading from history

  const ResultScreen({
    Key? key,
    required this.text,
    required this.imagePath,
    this.scanResult,
  }) : super(key: key);

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late TextEditingController _textController;
  late FlutterTts _flutterTts;
  bool _isEditing = false;
  bool _isSpeaking = false;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _currentText = widget.text;
    _textController = TextEditingController(text: _currentText);
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _isSpeaking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TTS Error: $msg'), backgroundColor: Colors.redAccent),
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_currentText.isEmpty) return;

    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(_currentText);
    }
  }

  Future<void> _saveEdits() async {
    final updatedText = _textController.text.trim();
    if (updatedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanned text cannot be empty.')),
      );
      return;
    }

    setState(() {
      _currentText = updatedText;
      _isEditing = false;
    });

    final db = ref.read(localDatabaseProvider);
    
    if (widget.scanResult != null) {
      // Update historical record
      final updatedScan = widget.scanResult!.copyWith(text: _currentText);
      await ref.read(scanHistoryProvider.notifier).addScan(updatedScan);
    } else {
      // If it's a brand new scan, search if we just saved it and update it, 
      // or save a new one. Since the OCR controller saves the scan upon success,
      // we can find the latest scan in history and edit it, or write a new entry.
      final history = ref.read(scanHistoryProvider);
      if (history.isNotEmpty) {
        final latest = history.first;
        // Verify it matches the image path to be safe
        if (latest.imagePath == widget.imagePath) {
          final updatedScan = latest.copyWith(text: _currentText);
          await ref.read(scanHistoryProvider.notifier).addScan(updatedScan);
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan results updated successfully.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scanResult != null ? 'Scan Details' : 'OCR Result'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_mute, 
                color: _isSpeaking ? accentColor : null),
              tooltip: 'Speak Text',
              onPressed: _speak,
            ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? 'Save Changes' : 'Edit Text',
            onPressed: () {
              if (_isEditing) {
                _saveEdits();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Embedded Document Image Thumbnail
            if (File(widget.imagePath).existsSync())
              Container(
                height: 140,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(widget.imagePath)),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.crop_original, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Cropped Document Preview',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            // Extracted Text Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    // Card header with quick action items
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEditing ? 'Editing Mode' : 'Extracted Text',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 15,
                                  color: _isEditing ? accentColor : null,
                                ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_all, size: 20),
                                tooltip: 'Copy to Clipboard',
                                onPressed: () {
                                  ClipboardHelper.copyToClipboard(_currentText);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Text copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                tooltip: 'Share Text',
                                onPressed: () {
                                  ClipboardHelper.shareText(_currentText, subject: 'Offline OCR Result');
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    // Main Text Input/Viewer
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _isEditing
                            ? TextFormField(
                                controller: _textController,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Edit scanned text here...',
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                              )
                            : SingleChildScrollView(
                                child: SelectableText(
                                  _currentText,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
