import re

filepath = 'lib/presentation/widgets/quick_capture_input.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Remove unused imports
content = re.sub(r"import 'package:provider/provider\.dart';\n?", "", content)
content = re.sub(r"import '\.\./viewmodels/tasks_viewmodel\.dart';\n?", "", content)
content = re.sub(r"import '\.\./viewmodels/habits_viewmodel\.dart';\n?", "", content)
content = re.sub(r"import '\.\./viewmodels/finance_viewmodel\.dart';\n?", "", content)
content = re.sub(r"import '\.\./viewmodels/notes_viewmodel\.dart';\n?", "", content)
content = re.sub(r"import '\.\./viewmodels/sleep_viewmodel\.dart';\n?", "", content)
content = re.sub(r"import '\.\./screens/tasks_screen\.dart';\n?", "", content)
content = re.sub(r"import '\.\./screens/habits_screen\.dart';\n?", "", content)
content = re.sub(r"import '\.\./screens/finance_screen\.dart';\n?", "", content)
content = re.sub(r"import '\.\./screens/notes_screen\.dart';\n?", "", content)
content = re.sub(r"import '\.\./screens/sleep_screen\.dart';\n?", "", content)

# But we DO need provider for QuickCaptureViewModel in _AIVoiceSheet!
# Let's add it back at the top.
content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';")

# Fix _AIVoiceSheet constructor
content = content.replace("class _AIVoiceSheet extends StatefulWidget {\n  final QuickCaptureViewModel vm;\n  const _AIVoiceSheet(this.vm);", "class _AIVoiceSheet extends StatefulWidget {\n  const _AIVoiceSheet({super.key});")

# Remove _MenuOption class
# It starts at class _MenuOption and ends before class _AIVoiceSheet
content = re.sub(r'class _MenuOption extends StatelessWidget \{.*?\}(?=\s*class _AIVoiceSheet)', '', content, flags=re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print("Cleaned up quick_capture_input.dart")
