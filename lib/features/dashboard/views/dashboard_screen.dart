import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../ocr/controllers/ocr_controller.dart';
import '../../ocr/views/result_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../widgets/history_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrProvider);
    final history = ref.watch(scanHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to OCR state change to navigate to results screen
    ref.listen<OcrState>(ocrProvider, (previous, next) {
      if (next.status == OcrStatus.success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              text: next.extractedText,
              imagePath: next.imagePath!,
            ),
          ),
        ).then((_) {
          // Reset the state to idle when returning
          ref.read(ocrProvider.notifier).reset();
        });
      } else if (next.status == OcrStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'An error occurred during OCR.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        ref.read(ocrProvider.notifier).reset();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient decoration for premium look
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF0B0F19)]
                      : [Colors.grey.shade50, Colors.grey.shade100],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Main Scrollable Dashboard Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium Styled Custom Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OmniOCR',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Secure On-Device Scanning',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.accentViolet : AppTheme.primaryViolet,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        // Settings Button
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2638) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade200,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scanning Actions Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Camera Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            label: 'Camera Scan',
                            subtitle: 'Capture document',
                            icon: Icons.camera_alt_outlined,
                            isPrimary: true,
                            onTap: () => ref.read(ocrProvider.notifier).pickAndProcessImage(
                                  ImageSource.camera,
                                  context,
                                ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Gallery Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            label: 'Import Image',
                            subtitle: 'Select from gallery',
                            icon: Icons.photo_library_outlined,
                            isPrimary: false,
                            onTap: () => ref.read(ocrProvider.notifier).pickAndProcessImage(
                                  ImageSource.gallery,
                                  context,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // History Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Scans',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                        if (history.isNotEmpty)
                          Text(
                            '${history.length} items',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Scan History List
                if (history.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2638) : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.document_scanner_outlined,
                                size: 48,
                                color: isDark ? AppTheme.accentViolet : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Scans Yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Scan a document or import an image to begin extracting text offline.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final scan = history[index];
                          return HistoryCard(
                            scan: scan,
                            onDelete: () => ref.read(scanHistoryProvider.notifier).deleteScan(scan.id),
                          );
                        },
                        childCount: history.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Glassmorphic Loading Overlay
          if (ocrState.status != OcrStatus.idle &&
              ocrState.status != OcrStatus.success &&
              ocrState.status != OcrStatus.failure)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2638) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _getLoadingText(ocrState.status),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getLoadingText(OcrStatus status) {
    switch (status) {
      case OcrStatus.pickingImage:
        return 'Importing image...';
      case OcrStatus.croppingImage:
        return 'Opening image editor...';
      case OcrStatus.processingOcr:
        return 'Processing text recognition offline...';
      default:
        return 'Loading...';
    }
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isPrimary
        ? const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final border = isPrimary
        ? null
        : Border.all(
            color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade300,
            width: 1.5,
          );

    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: gradient,
        color: isPrimary ? null : (isDark ? const Color(0xFF161C2C) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: border,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppTheme.primaryViolet.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isPrimary ? Colors.white : (isDark ? AppTheme.accentViolet : AppTheme.primaryViolet),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: isPrimary ? Colors.white70 : Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
