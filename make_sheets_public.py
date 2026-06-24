import os

replacements = {
    'tasks_screen.dart': [('_TaskEditSheet', 'TaskEditSheet')],
    'habits_screen.dart': [('_HabitEditSheet', 'HabitEditSheet')],
    'finance_screen.dart': [
        ('_CreateTransactionSheet', 'CreateTransactionSheet'),
        ('_CreateAccountSheet', 'CreateAccountSheet'),
        ('_CreateTransferSheet', 'CreateTransferSheet'),
        ('_ZenSheet', 'ZenSheet'),
        ('_ZenMenuTile', 'ZenMenuTile'),
    ],
    'notes_screen.dart': [('_NoteEditorSheet', 'NoteEditorSheet')],
    'sleep_screen.dart': [('_SleepModal', 'SleepModal')],
}

for filename, reps in replacements.items():
    filepath = os.path.join('lib/presentation/screens', filename)
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            content = f.read()
        for old, new in reps:
            content = content.replace(old, new)
        with open(filepath, 'w') as f:
            f.write(content)
print("Renamed sheets successfully.")
