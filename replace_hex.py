import os

def replace_hardcoded_colors():
    dirs_to_check = ['lib/presentation/screens', 'lib/presentation/widgets']
    for d in dirs_to_check:
        for root, dirs, files in os.walk(d):
            for file in files:
                if file.endswith('.dart'):
                    filepath = os.path.join(root, file)
                    with open(filepath, 'r') as f:
                        content = f.read()
                    
                    # Store original to check if modified
                    original = content
                    
                    # Replacements
                    content = content.replace('Color(0xFF060606)', 'AppColors.scaffold')
                    content = content.replace('Color(0xFF0B0B0B)', 'AppColors.surface')
                    content = content.replace('Color(0xFF111111)', 'AppColors.surface')
                    content = content.replace('Color(0xFFF0EDE8)', 'AppColors.textPrimary')
                    
                    # Note: We need to make sure AppColors is imported if we modified the file
                    if original != content and "import '../../core/theme/app_colors.dart';" not in content:
                        # For widgets, the path might be different depending on depth
                        # Actually, let's just use a relative import or package import
                        if "import 'package:heroos/core/theme/app_colors.dart';" not in content:
                            content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:heroos/core/theme/app_colors.dart';")
                    
                    if original != content:
                        with open(filepath, 'w') as f:
                            f.write(content)

replace_hardcoded_colors()
print("Replaced all remaining hardcoded hex colors successfully.")
