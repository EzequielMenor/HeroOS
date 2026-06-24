import os
import re

def fix_stuff():
    # Fix default values
    for fpath in ['lib/data/models/note_model.dart', 'lib/domain/entities/note_entity.dart', 'lib/presentation/viewmodels/notes_viewmodel.dart']:
        if os.path.exists(fpath):
            with open(fpath, 'r') as f:
                c = f.read()
            c = c.replace('= []', '= const []')
            with open(fpath, 'w') as f:
                f.write(c)
                
    # Fix storage service
    fpath = 'lib/data/services/storage_service.dart'
    if os.path.exists(fpath):
        with open(fpath, 'r') as f:
            c = f.read()
        c = c.replace('opts =', 'const opts =')
        with open(fpath, 'w') as f:
            f.write(c)

    # Fix habits_screen.dart
    fpath = 'lib/presentation/screens/habits_screen.dart'
    if os.path.exists(fpath):
        with open(fpath, 'r') as f:
            c = f.read()
        c = re.sub(r'(?<!const\s)days\s*=', 'const days =', c)
        c = re.sub(r'(?<!const\s)dayLabels\s*=', 'const dayLabels =', c)
        with open(fpath, 'w') as f:
            f.write(c)
            
    # Fix tasks_screen.dart missing function body
    fpath = 'lib/presentation/screens/tasks_screen.dart'
    if os.path.exists(fpath):
        with open(fpath, 'r') as f:
            c = f.read()
        c = c.replace('Color get _kDivider;', 'Color get _kDivider => AppColors.divider;')
        c = c.replace('Color get _kDanger;', 'Color get _kDanger => AppColors.danger;')
        with open(fpath, 'w') as f:
            f.write(c)

if __name__ == '__main__':
    fix_stuff()
    print("Fixed remnants")
