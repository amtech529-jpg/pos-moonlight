import os
import re

base_dir = r"d:\HHTechHUB\pos-moonlight-main\pos-moonlight-main\frontend\lib"
import_statement = "import 'package:frontend/presentation/widgets/globals/keyboard_scrollable.dart';\n"

for root, _, files in os.walk(base_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if 'SingleChildScrollView(' in content and 'keyboard_scrollable.dart' not in filepath:
                # Replace SingleChildScrollView( with KeyboardScrollable(
                new_content = re.sub(r'\bSingleChildScrollView\(', 'KeyboardScrollable(', content)
                
                # Add import if missing
                if import_statement.strip() not in new_content:
                    # insert after the last import
                    imports_end = 0
                    for match in re.finditer(r'^import .*?;$', new_content, re.MULTILINE):
                        imports_end = match.end()
                    
                    if imports_end > 0:
                        new_content = new_content[:imports_end] + "\n" + import_statement + new_content[imports_end:]
                    else:
                        new_content = import_statement + "\n" + new_content
                
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
