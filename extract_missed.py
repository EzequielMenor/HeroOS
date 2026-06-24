import os

def extract_method(filepath, signature):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    start_idx = -1
    for i, line in enumerate(lines):
        if signature in line:
            start_idx = i
            break
            
    if start_idx == -1:
        print(f"Signature '{signature}' not found in {filepath}")
        return False
        
    brace_count = 0
    end_idx = -1
    started = False
    
    for i in range(start_idx, len(lines)):
        line = lines[i]
        if '//' in line: line = line.split('//')[0]
        for char in line:
            if char == '{':
                started = True
                brace_count += 1
            elif char == '}':
                brace_count -= 1
        if started and brace_count == 0:
            end_idx = i
            break
            
    if end_idx != -1:
        method_content = lines[start_idx:end_idx+1]
        del lines[start_idx:end_idx+1]
        lines.extend(['\n\n'] + method_content)
        with open(filepath, 'w') as f:
            f.writelines(lines)
        print(f"Extracted '{signature}' in {filepath}")
        return True
    return False

# Finance
extract_method('lib/presentation/screens/finance_screen.dart', 'void _showManageCategories(')

# Habits
extract_method('lib/presentation/screens/habits_screen.dart', 'String _dayLabel(')

# Since they are now at the bottom, we should replace _showManageCategories -> showManageCategories
with open('lib/presentation/screens/finance_screen.dart', 'r') as f: c = f.read()
c = c.replace('_showManageCategories', 'showManageCategories')
with open('lib/presentation/screens/finance_screen.dart', 'w') as f: f.write(c)

with open('lib/presentation/screens/habits_screen.dart', 'r') as f: c = f.read()
c = c.replace('_dayLabel', 'dayLabel')
with open('lib/presentation/screens/habits_screen.dart', 'w') as f: f.write(c)
