import os
import sys

try:
    from rjsmin import jsmin
    from csscompressor import compress as cssmin
except ImportError:
    print("❌ please install required packages: rjsmin, csscompressor")
    sys.exit(1)

FILE_MAP = {
    'lib/web_src/controller.js': 'kControllerJs',
    'lib/web_src/pagination.css': 'kPaginationCss',
    'lib/web_src/skeleton.css': 'kSkeletonCss',
}

OUTPUT_PATH = 'lib/web_src/reader_assets.dart'

def generate_assets():
    for path in FILE_MAP.keys():
        if not os.path.exists(path):
            print(f"❌ could not find file: {path}")
            sys.exit(1)

    content_map = {}

    print("🔍 Processing web assets:")
    for path, var_name in FILE_MAP.items():
        with open(path, 'r', encoding='utf-8') as f:
            raw_content = f.read()

        print(f"  com: {path}")
        if path.endswith('.js'):
            minified = jsmin(raw_content)
        elif path.endswith('.css'):
            minified = cssmin(raw_content)
        else:
            minified = raw_content

        content_map[var_name] = minified.strip()

    generated_content = (
        "// ==========================================\n"
        "// 🚨 GENERATED CODE - DO NOT MODIFY BY HAND\n"
        "// ==========================================\n\n"
    )

    for var_name, content in content_map.items():
        generated_content += f"const String {var_name} = r'''\n{content}\n''';\n\n"

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

    with open(OUTPUT_PATH, 'w', encoding='utf-8') as out_file:
        out_file.write(generated_content)

    print(f"✅ Web assets are generated successfully at: {OUTPUT_PATH}")

if __name__ == "__main__":
    generate_assets()