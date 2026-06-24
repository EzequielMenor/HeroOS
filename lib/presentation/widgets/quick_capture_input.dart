import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Widget de entrada Quick Capture.
/// TextField con submit que pasa el texto al viewmodel.
class QuickCaptureInput extends StatefulWidget {
  final Function(String text) onSubmit;
  final VoidCallback? onCancel;

  const QuickCaptureInput({
    super.key,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<QuickCaptureInput> createState() => _QuickCaptureInputState();
}

class _QuickCaptureInputState extends State<QuickCaptureInput> {
  final _ctrl = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _ctrl.clear();
    setState(() => _isExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return FloatingActionButton(
        heroTag: 'quick_capture',
        backgroundColor: AppColors.sageGreen,
        onPressed: () => setState(() => _isExpanded = true),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: '¿Qué necesitas recordar?',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _ctrl.clear();
              setState(() => _isExpanded = false);
              widget.onCancel?.call();
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _submit,
          ),
        ],
      ),
      ),
    );
  }
}
