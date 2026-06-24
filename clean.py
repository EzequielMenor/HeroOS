import re
import os

files_to_clean = {
    'lib/presentation/screens/finance_screen.dart': r'  bool _isSameMonth\(DateTime date\) \{.*?\}\n',
    'lib/presentation/screens/sleep_screen.dart': r'class _BottomPrimaryButton extends StatelessWidget \{.*?\}\n',
    'lib/presentation/screens/tasks_screen.dart': r'class _ZenFab extends StatelessWidget \{.*?\}\n'
}

for filepath, pattern in files_to_clean.items():
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            content = f.read()
        content = re.sub(pattern, '', content, flags=re.DOTALL)
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Cleaned {filepath}")
    else:
        print(f"File not found: {filepath}")
