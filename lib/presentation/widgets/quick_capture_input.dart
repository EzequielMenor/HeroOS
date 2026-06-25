import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../viewmodels/quick_capture_viewmodel.dart';
import '../screens/global_add_screen.dart';

/// Floating buttons persistence in Dashboard:
/// - Main '+' button: opens a universal Add Menu to select what to add.
/// - Mic button: opens the AI voice capture interface.
class QuickCaptureButtons extends StatelessWidget {
  final QuickCaptureViewModel qcVm;
  const QuickCaptureButtons({super.key, required this.qcVm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AI Voice Capture Button (Smaller, simpler)
          InkWell(
            onTap: () => showAIVoiceCapture(context, qcVm),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Icon(Icons.mic_none, size: 18, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          // Main Add Button (Medium size, elegant)
          InkWell(
            onTap: () => _showUniversalAddMenu(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(Icons.add, size: 22, color: AppColors.scaffold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Universal Add Menu ───────────────────────────────────────────────────

  void _showUniversalAddMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GlobalAddScreen()),
    );
  }

  // ── AI Voice Capture ─────────────────────────────────────────────────────

  }

void showAIVoiceCapture(BuildContext context, QuickCaptureViewModel qcVm) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => AIVoiceSheet(qcVm),
    );
  }



class AIVoiceSheet extends StatefulWidget {
  final QuickCaptureViewModel vm;
  const AIVoiceSheet(this.vm);

  @override
  State<AIVoiceSheet> createState() => AIVoiceSheetState();
}

class AIVoiceSheetState extends State<AIVoiceSheet> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    widget.vm.capture(text);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Procesando con IA...', style: TextStyle(color: AppColors.scaffold)),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CAPTURA RÁPIDA IA',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Escribe para añadir...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submit(),
                    autofocus: true,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.mic_none,
                    color: AppColors.habits,
                    size: 28,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Captura por voz próximamente')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (vm.isLoading)
              LinearProgressIndicator(
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.habits),
              ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
