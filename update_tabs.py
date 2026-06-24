import re
import os

filepath = 'lib/presentation/screens/global_add_screen.dart'
if os.path.exists(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # 1. Update TabController length
    content = content.replace("TabController(length: 5, vsync: this)", "TabController(length: 3, vsync: this)")

    # 2. Update Tabs
    tabs_old = """          tabs: const [
            Tab(text: 'MISIÓN'),
            Tab(text: 'HÁBITO'),
            Tab(text: 'FINANZAS'),
            Tab(text: 'NOTA'),
            Tab(text: 'DESCANSO'),
          ],"""
    tabs_new = """          tabs: const [
            Tab(text: 'NOTA'),
            Tab(text: 'MISIÓN'),
            Tab(text: 'FINANZAS'),
          ],"""
    content = content.replace(tabs_old, tabs_new)

    # 3. Update TabBarView children
    view_old = """        children: [
          _TaskForm(),
          _HabitForm(),
          _FinanceForm(),
          _NoteForm(),
          _SleepForm(),
        ],"""
    view_new = """        children: [
          _NoteForm(),
          _TaskForm(),
          _FinanceForm(),
        ],"""
    content = content.replace(view_old, view_new)

    # 4. Remove _HabitForm
    # From class _HabitForm to the end of _HabitFormState
    content = re.sub(r'// ── Hábito ────────────────────────────────────────────────────────\n\nclass _HabitForm.*?Navigator\.pop\(context\);\n            \},\n          \),\n        \],\n      \),\n    \);\n  \}\n\}', '', content, flags=re.DOTALL)

    # 5. Remove _SleepForm
    content = re.sub(r'// ── Descanso ────────────────────────────────────────────────────────\n\nclass _SleepForm.*', '', content, flags=re.DOTALL)

    # 6. Remove viewmodel imports
    content = content.replace("import '../viewmodels/habits_viewmodel.dart';\n", "")
    content = content.replace("import '../viewmodels/sleep_viewmodel.dart';\n", "")

    with open(filepath, 'w') as f:
        f.write(content)
    print("Updated global_add_screen.dart successfully")
else:
    print("File not found")
