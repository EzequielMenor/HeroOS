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
        
    # Check if it's already top level (e.g. before the class, or class already ended)
    # Actually, we can just look backwards to see if there is a 'class _...State' before it.
    
    brace_count = 0
    end_idx = -1
    started = False
    
    for i in range(start_idx, len(lines)):
        line = lines[i]
        # Ignore comments
        if '//' in line:
            line = line.split('//')[0]
            
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
        
        # We need to remove it from where it is and append it at the end of the file
        del lines[start_idx:end_idx+1]
        lines.extend(['\n\n'] + method_content)
        
        with open(filepath, 'w') as f:
            f.writelines(lines)
        print(f"Extracted '{signature}' in {filepath}")
        return True
    return False

# Run for tasks
extract_method('lib/presentation/screens/tasks_screen.dart', 'void showTaskCreateSheet(')

# Run for habits
extract_method('lib/presentation/screens/habits_screen.dart', 'void showHabitCreateSheet(')

# Run for finance (4 methods)
extract_method('lib/presentation/screens/finance_screen.dart', 'void showFinanceAddMenu(')
extract_method('lib/presentation/screens/finance_screen.dart', 'void showCreateAccount(')
extract_method('lib/presentation/screens/finance_screen.dart', 'void showCreateTransaction(')
extract_method('lib/presentation/screens/finance_screen.dart', 'void showCreateTransfer(')

# Run for notes
# Notes has two _showEditSheet, wait! I renamed it to showNoteEditSheet, so it should be unique.
extract_method('lib/presentation/screens/notes_screen.dart', 'void showNoteEditSheet(')

# For notes, there is a second 'void showEditSheet(BuildContext context)' which we shouldn't touch.
