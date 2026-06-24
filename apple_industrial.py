import os
import re

# 1. Update Colors
app_colors_path = "lib/core/theme/app_colors.dart"
if os.path.exists(app_colors_path):
    with open(app_colors_path, "r") as f:
        content = f.read()
    content = re.sub(r'static const Color scaffold = Color\(0xFF060606\);', r'static const Color scaffold = Color(0xFF1C1C1E);', content)
    content = re.sub(r'static const Color surface = Color\(0xFF0B0B0B\);', r'static const Color surface = Color(0xFF2C2C2E);', content)
    with open(app_colors_path, "w") as f:
        f.write(content)

# 2. Update Typography
def update_typography(filepath):
    with open(filepath, "r") as f:
        content = f.read()
    
    # We replace: GoogleFonts.cormorantGaramond( ... fontWeight: FontWeight.w300 ... )
    # with: GoogleFonts.inter( ... fontWeight: FontWeight.w600 ... )
    # or just replace "GoogleFonts.cormorantGaramond" with "GoogleFonts.inter" and "FontWeight.w300" with "FontWeight.w600"
    if "GoogleFonts.cormorantGaramond" in content:
        # Import google_fonts if not present
        if "package:google_fonts/google_fonts.dart" not in content and "GoogleFonts" not in content.replace("GoogleFonts.cormorantGaramond", ""):
            # We might still need it if we replace with GoogleFonts.inter
            pass
        
        # Split by GoogleFonts.cormorantGaramond( to ensure we only replace w300 inside it
        parts = content.split("GoogleFonts.cormorantGaramond(")
        new_content = parts[0]
        for part in parts[1:]:
            # Find the closing parenthesis of this call
            paren_count = 1
            idx = 0
            for i, char in enumerate(part):
                if char == '(':
                    paren_count += 1
                elif char == ')':
                    paren_count -= 1
                if paren_count == 0:
                    idx = i
                    break
            
            inside = part[:idx]
            outside = part[idx:]
            
            # Change w300 to w600
            inside = inside.replace("FontWeight.w300", "FontWeight.w600")
            
            new_content += "GoogleFonts.inter(" + inside + outside
            
        with open(filepath, "w") as f:
            f.write(new_content)

for root, dirs, files in os.walk("lib"):
    for file in files:
        if file.endswith(".dart"):
            update_typography(os.path.join(root, file))

# 3. Add Blur to Dashboard
dashboard_path = "lib/presentation/screens/dashboard_screen.dart"
if os.path.exists(dashboard_path):
    with open(dashboard_path, "r") as f:
        content = f.read()
    
    if "import 'dart:ui';" not in content:
        content = "import 'dart:ui';\n" + content
        
    content = content.replace("Widget _buildMobileLayout() {\n    return Scaffold(\n      body: IndexedStack(", 
                              "Widget _buildMobileLayout() {\n    return Scaffold(\n      extendBody: true,\n      body: IndexedStack(")
    
    old_nav = """      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),"""
        
    new_nav = """      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),"""
            
    content = content.replace(old_nav, new_nav)
    
    # We must add an extra closing parenthesis for the ClipRect and BackdropFilter.
    # The bottomNavigationBar ends just before `floatingActionButton: _buildQuickCapture(),`
    old_nav_end = """              );
            }),
          ),
        ),
      ),
      floatingActionButton: _buildQuickCapture(),"""
      
    new_nav_end = """              );
            }),
          ),
        ),
      ))),
      floatingActionButton: _buildQuickCapture(),"""
      
    content = content.replace(old_nav_end, new_nav_end)
    
    with open(dashboard_path, "w") as f:
        f.write(content)
