import os
import subprocess

def run_analyze():
    print("Running flutter analyze --machine...")
    result = subprocess.run(['flutter', 'analyze', '--machine'], capture_output=True, text=True)
    return result.stdout.split('\n')

def fix_errors():
    lines = run_analyze()
    files_to_lines = {}
    
    for line in lines:
        if not line.strip() or not line.startswith(('ERROR', 'WARNING', 'INFO')):
            continue
        parts = line.split('|')
        if len(parts) >= 8:
            err_code = parts[2]
            file_path = parts[3]
            line_num = int(parts[4])
            col_num = int(parts[5])
            
            if file_path not in files_to_lines:
                with open(file_path, 'r', encoding='utf-8') as f:
                    files_to_lines[file_path] = f.readlines()
            
            file_lines = files_to_lines[file_path]
            
            if err_code == 'undefined_getter' and 'sageGreen' in parts[7]:
                l_idx = line_num - 1
                file_lines[l_idx] = file_lines[l_idx].replace('sageGreen', 'habits')
                
            elif err_code == 'invalid_constant':
                l_idx = line_num - 1
                c_idx = col_num - 1
                for i in range(l_idx, max(-1, l_idx - 10), -1):
                    search_str = file_lines[i][:c_idx] if i == l_idx else file_lines[i]
                    if 'const ' in search_str:
                        last_idx = search_str.rfind('const ')
                        file_lines[i] = file_lines[i][:last_idx] + file_lines[i][last_idx+6:]
                        break
                        
            elif err_code == 'const_initialized_with_non_constant_value':
                l_idx = line_num - 1
                line_str = file_lines[l_idx]
                if 'Color(' in line_str or 'AppColors' in line_str:
                    if '_kScaffold' in line_str:
                        file_lines[l_idx] = 'Color get _kScaffold => AppColors.scaffold;\n'
                    elif '_kSurface' in line_str:
                        file_lines[l_idx] = 'Color get _kSurface => AppColors.surface;\n'
                    elif '_kTextPrimary' in line_str or '_kTextPrim' in line_str:
                        name = '_kTextPrim' if '_kTextPrim' in line_str else '_kTextPrimary'
                        file_lines[l_idx] = f'Color get {name} => AppColors.textPrimary;\n'
                    elif '_kTextSecondary' in line_str or '_kTextSec' in line_str:
                        name = '_kTextSec' if '_kTextSec' in line_str else '_kTextSecondary'
                        file_lines[l_idx] = f'Color get {name} => AppColors.textSecondary;\n'
                    elif '_kDivider' in line_str:
                        file_lines[l_idx] = 'Color get _kDivider => AppColors.divider;\n'
                    elif '_kSageGreen' in line_str or '_kAccent' in line_str:
                        name = '_kAccent' if '_kAccent' in line_str else '_kSageGreen'
                        file_lines[l_idx] = f'Color get {name} => AppColors.accent;\n'
                    elif '_kDanger' in line_str:
                        file_lines[l_idx] = 'Color get _kDanger => AppColors.danger;\n'
                    else:
                        file_lines[l_idx] = line_str.replace('const Color ', 'Color get ').replace('const _', 'Color get _').replace(' = ', ' => ')

    for file_path, file_lines in files_to_lines.items():
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(file_lines)

if __name__ == '__main__':
    for _ in range(4):
        fix_errors()
    print("Done")
