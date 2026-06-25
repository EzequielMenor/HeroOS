import os

qc_path = "lib/presentation/widgets/quick_capture_input.dart"
with open(qc_path, "r") as f:
    qc_content = f.read()

# Make the function and sheet public and top-level
qc_content = qc_content.replace("void _showAIVoiceCapture(BuildContext context, QuickCaptureViewModel qcVm) {", 
                                "}\n\nvoid showAIVoiceCapture(BuildContext context, QuickCaptureViewModel qcVm) {")
qc_content = qc_content.replace("_showAIVoiceCapture(context, qcVm)", "showAIVoiceCapture(context, qcVm)")
qc_content = qc_content.replace("_AIVoiceSheet", "AIVoiceSheet")

with open(qc_path, "w") as f:
    f.write(qc_content)

add_path = "lib/presentation/screens/global_add_screen.dart"
with open(add_path, "r") as f:
    add_content = f.read()

# Add import
if "import '../widgets/quick_capture_input.dart';" not in add_content:
    add_content = add_content.replace("import '../../domain/entities/task_entity.dart';",
                                      "import '../../domain/entities/task_entity.dart';\nimport '../widgets/quick_capture_input.dart';\nimport '../viewmodels/quick_capture_viewmodel.dart';")

# Add actions to AppBar
actions_str = """
        actions: [
          IconButton(
            icon: Icon(Icons.mic, color: AppColors.textPrimary),
            onPressed: () {
              final qcVm = Provider.of<QuickCaptureViewModel>(context, listen: false);
              showAIVoiceCapture(context, qcVm);
            },
          ),
          SizedBox(width: 8),
        ],
        centerTitle: true,"""

add_content = add_content.replace("centerTitle: true,", actions_str)

with open(add_path, "w") as f:
    f.write(add_content)
