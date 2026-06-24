import os

def fix_files():
    for root, _, files in os.walk('lib'):
        for file in files:
            if not file.endswith('.dart'):
                continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            changed = False
            for i, line in enumerate(lines):
                # Fix top level getters that were missing '=>'
                if 'Color get _k' in line and ' = ' in line:
                    lines[i] = line.replace(' = ', ' => ')
                    changed = True
                    
                # Fix globally stripped consts on variable declarations
                stripped_line = line.lstrip()
                if stripped_line.startswith('labels = ['):
                    lines[i] = line.replace('labels = [', 'const labels = [')
                    changed = True
                elif stripped_line.startswith('days = ['):
                    lines[i] = line.replace('days = [', 'const days = [')
                    changed = True
                elif stripped_line.startswith('dayLabels = ['):
                    lines[i] = line.replace('dayLabels = [', 'const dayLabels = [')
                    changed = True
                elif stripped_line.startswith('map = {'):
                    lines[i] = line.replace('map = {', 'const map = {')
                    changed = True
                    
                # Fix undefined getter sageGreen
                if 'AppColors.sageGreen' in line:
                    lines[i] = line.replace('AppColors.sageGreen', 'AppColors.habits')
                    changed = True
                    
            if changed:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.writelines(lines)

if __name__ == '__main__':
    fix_files()
    print("Fixed syntax errors.")
