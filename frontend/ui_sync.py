import re

with open('lib/presentation/widgets/quotations/add_quotation_dialog.dart', 'r', encoding='utf-8') as f:
    add_content = f.read()

with open('lib/presentation/widgets/quotations/edit_quotation_dialog.dart', 'r', encoding='utf-8') as f:
    edit_content = f.read()

def extract_method(content, method_name, is_class=False):
    start = content.find(method_name)
    if start == -1: return None
    braces = 0
    in_method = False
    for i in range(start, len(content)):
        if content[i] == '{':
            braces += 1
            in_method = True
        elif content[i] == '}':
            braces -= 1
        if in_method and braces == 0:
            return content[start:i+1]
    return None

build_add = extract_method(add_content, 'Widget build(BuildContext context) {')
build_edit = extract_method(edit_content, 'Widget build(BuildContext context) {')

items_add = extract_method(add_content, 'Widget _buildItemsTable() {')
items_edit = extract_method(edit_content, 'Widget _buildItemsTable() {')

cust_add = extract_method(add_content, 'Widget _buildCustomerSelection() {')
cust_edit = extract_method(edit_content, 'Widget _buildCustomerSelection() {')

summary_add = extract_method(add_content, 'Widget _buildSummary() {')
summary_edit = extract_method(edit_content, 'Widget _buildSummary() {')

footer_add = extract_method(add_content, 'Widget _buildFooter() {')
footer_edit = extract_method(edit_content, 'Widget _buildFooter() {')

try:
    new_build = build_edit.replace('width: 85.w', 'width: 90.w').replace('height: 90.h', 'height: 96.h')
    new_build = new_build.replace('insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20)', 'insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)')
    new_build = new_build.replace('padding: const EdgeInsets.fromLTRB(32, 24, 32, 0)', 'padding: const EdgeInsets.fromLTRB(24, 16, 24, 0)')
    new_build = new_build.replace('padding: EdgeInsets.symmetric(horizontal: 32)', 'padding: EdgeInsets.symmetric(horizontal: 24)')
    new_build = new_build.replace('padding: const EdgeInsets.all(20)', 'padding: const EdgeInsets.all(16)')
    new_build = new_build.replace('padding: const EdgeInsets.all(32)', 'padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)')
    new_build = new_build.replace('child: ScrollConfiguration(\n                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),\n                            child: SingleChildScrollView(\n                              child: Column(', 'child: ScrollConfiguration(\n                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),\n                            child: SingleChildScrollView(\n                              padding: const EdgeInsets.only(bottom: 24),\n                              child: Column(')

    if build_edit and new_build:
        edit_content = edit_content.replace(build_edit, new_build)
        print('Replaced build')
    if items_edit and items_add:
        edit_content = edit_content.replace(items_edit, items_add)
        print('Replaced items')
    if cust_edit and cust_add:
        edit_content = edit_content.replace(cust_edit, cust_add)
        print('Replaced cust')
    if summary_edit and summary_add:
        edit_content = edit_content.replace(summary_edit, summary_add)
        print('Replaced summary')

    # Custom adjustments to footer
    if footer_edit and footer_add:
        new_footer = footer_add.replace('\"GENERATE QUOTE\"', '\"UPDATE QUOTATION\"')
        edit_content = edit_content.replace(footer_edit, new_footer)
        print('Replaced footer')

    # Fix missing import if needed for AddCustomerDialog
    if 'AddCustomerDialog' not in edit_content:
        edit_content = edit_content.replace(\"import '../globals/drop_down.dart';\", \"import '../globals/drop_down.dart';\\nimport '../customer/add_customer_dialog.dart';\")
except Exception as e:
    print(e)

with open('lib/presentation/widgets/quotations/edit_quotation_dialog.dart', 'w', encoding='utf-8') as f:
    f.write(edit_content)
print('Done copying Add styles to Edit style.')
