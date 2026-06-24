import os

def fix_tasks():
    with open('lib/presentation/screens/tasks_screen.dart', 'r') as f:
        c = f.read()
    c = c.replace('void _showCreateSheet(BuildContext context, TasksViewModel vm) {', 'void showTaskCreateSheet(BuildContext context, TasksViewModel vm, {DateTime? initialDate}) {')
    c = c.replace('DateTime? dueDate =\n        (context.isWeb || _showCalendar) ? _selectedDay : null;', 'DateTime? dueDate = initialDate;')
    c = c.replace('_showCreateSheet(context, vm)', 'showTaskCreateSheet(context, vm, initialDate: _selectedDay)')
    with open('lib/presentation/screens/tasks_screen.dart', 'w') as f:
        f.write(c)

def fix_habits():
    with open('lib/presentation/screens/habits_screen.dart', 'r') as f:
        c = f.read()
    c = c.replace('void _showCreateSheet(BuildContext context, HabitsViewModel vm) {', 'void showHabitCreateSheet(BuildContext context, HabitsViewModel vm) {')
    c = c.replace('_showCreateSheet(context, vm)', 'showHabitCreateSheet(context, vm)')
    with open('lib/presentation/screens/habits_screen.dart', 'w') as f:
        f.write(c)

def fix_finance():
    with open('lib/presentation/screens/finance_screen.dart', 'r') as f:
        c = f.read()
    c = c.replace('void _showAddMenu(BuildContext context, FinanceViewModel vm) {', 'void showFinanceAddMenu(BuildContext context, FinanceViewModel vm) {')
    c = c.replace('_showAddMenu(context, vm)', 'showFinanceAddMenu(context, vm)')
    c = c.replace('void _showCreateAccount(BuildContext context, FinanceViewModel vm) {', 'void showCreateAccount(BuildContext context, FinanceViewModel vm) {')
    c = c.replace('_showCreateAccount(context, vm)', 'showCreateAccount(context, vm)')
    c = c.replace('void _showCreateTransaction(BuildContext context, FinanceViewModel vm) {', 'void showCreateTransaction(BuildContext context, FinanceViewModel vm) {')
    c = c.replace('_showCreateTransaction(context, vm)', 'showCreateTransaction(context, vm)')
    c = c.replace('void _showCreateTransfer(BuildContext context, FinanceViewModel vm) {', 'void showCreateTransfer(BuildContext context, FinanceViewModel vm) {')
    c = c.replace('_showCreateTransfer(context, vm)', 'showCreateTransfer(context, vm)')
    with open('lib/presentation/screens/finance_screen.dart', 'w') as f:
        f.write(c)

def fix_notes():
    with open('lib/presentation/screens/notes_screen.dart', 'r') as f:
        c = f.read()
    c = c.replace('void _showEditSheet(BuildContext context, NotesViewModel vm, NoteEntity? note) {', 'void showNoteEditSheet(BuildContext context, NotesViewModel vm, NoteEntity? note) {')
    c = c.replace('_showEditSheet(context, vm,', 'showNoteEditSheet(context, vm,')
    # wait there's another _showEditSheet inside notes
    with open('lib/presentation/screens/notes_screen.dart', 'w') as f:
        f.write(c)

def fix_sleep():
    with open('lib/presentation/screens/sleep_screen.dart', 'r') as f:
        c = f.read()
    c = c.replace('void _showSleepModal(', 'void showSleepModal(')
    c = c.replace('_showSleepModal(', 'showSleepModal(')
    with open('lib/presentation/screens/sleep_screen.dart', 'w') as f:
        f.write(c)

try:
    fix_tasks()
    fix_habits()
    fix_finance()
    fix_notes()
    fix_sleep()
    print("Exposed sheets successfully.")
except Exception as e:
    print(f"Error: {e}")
