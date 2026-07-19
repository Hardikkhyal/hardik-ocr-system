import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/database/local_database.dart';
import '../models/scan_result.dart';

// --- Database Provider ---
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  throw UnimplementedError('Initialize localDatabaseProvider in main.dart');
});

// --- Theme State & Notifier ---
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final LocalDatabase _db;
  ThemeNotifier(this._db) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final modeStr = _db.getThemeMode();
    state = _themeModeFromString(modeStr);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _db.saveThemeMode(mode.name);
  }

  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ThemeNotifier(db);
});

// --- History State & Notifier ---
class ScanHistoryNotifier extends StateNotifier<List<ScanResult>> {
  final LocalDatabase _db;
  ScanHistoryNotifier(this._db) : super([]) {
    loadScans();
  }

  void loadScans() {
    state = _db.getScans();
  }

  Future<void> addScan(ScanResult scan) async {
    await _db.saveScan(scan);
    loadScans(); // Reload history
  }

  Future<void> deleteScan(String id) async {
    await _db.deleteScan(id);
    loadScans(); // Reload history
  }

  Future<void> clearHistory() async {
    await _db.clearHistory();
    state = [];
  }
}

final scanHistoryProvider = StateNotifierProvider<ScanHistoryNotifier, List<ScanResult>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ScanHistoryNotifier(db);
});

// --- OCR State & Notifier ---
enum OcrStatus { idle, pickingImage, croppingImage, processingOcr, success, failure }

class OcrState {
  final OcrStatus status;
  final String? imagePath;
  final String extractedText;
  final String? errorMessage;

  OcrState({
    required this.status,
    this.imagePath,
    this.extractedText = '',
    this.errorMessage,
  });

  OcrState copyWith({
    OcrStatus? status,
    String? imagePath,
    String? extractedText,
    String? errorMessage,
  }) {
    return OcrState(
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OcrNotifier extends StateNotifier<OcrState> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  OcrNotifier(this._ref) : super(OcrState(status: OcrStatus.idle));

  Future<void> pickAndProcessImage(ImageSource source, BuildContext context) async {
    state = OcrState(status: OcrStatus.pickingImage);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90, // Optimize image size for OCR performance
      );

      if (pickedFile == null) {
        state = OcrState(status: OcrStatus.idle);
        return;
      }

      // Step 2: Crop Image
      state = OcrState(status: OcrStatus.croppingImage, imagePath: pickedFile.path);
      final croppedFilePath = await _cropImage(pickedFile.path, context);

      if (croppedFilePath == null) {
        // User cancelled cropping, revert to idle
        state = OcrState(status: OcrStatus.idle);
        return;
      }

      // Step 3: Run OCR
      await processOcr(croppedFilePath);

    } catch (e) {
      state = OcrState(
        status: OcrStatus.failure,
        errorMessage: 'Failed to capture or crop image: $e',
      );
    }
  }

  Future<String?> _cropImage(String filePath, BuildContext context) async {
    final theme = Theme.of(context);
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: theme.colorScheme.surface,
          toolbarWidgetColor: theme.colorScheme.onSurface,
          activeControlsWidgetColor: theme.colorScheme.primary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Document',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );
    return croppedFile?.path;
  }

  Future<void> processOcr(String imagePath) async {
    state = OcrState(status: OcrStatus.processingOcr, imagePath: imagePath);

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text.trim();
      bool textFound = text.isNotEmpty;
      if (!textFound) {
        text = "No text found in the image. Please try again with a clearer document.";
      }

      // Save scan to history if text was actually found
      if (textFound) {
        final scanResult = ScanResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          imagePath: imagePath,
          timestamp: DateTime.now(),
        );

        await _ref.read(scanHistoryProvider.notifier).addScan(scanResult);
      }

      state = OcrState(
        status: OcrStatus.success,
        imagePath: imagePath,
        extractedText: text,
      );
    } catch (e) {
      state = OcrState(
        status: OcrStatus.failure,
        imagePath: imagePath,
        errorMessage: 'OCR processing error: $e',
      );
    } finally {
      await textRecognizer.close();
    }
  }

  void reset() {
    state = OcrState(status: OcrStatus.idle);
  }
}

final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  return OcrNotifier(ref);
});
