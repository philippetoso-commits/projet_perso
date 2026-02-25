import os

def generate_dart_list():
    assets_dir = 'assets/data'
    output_file = 'lib/services/asset_list.dart'
    
    print(f"Scanning {assets_dir}...")
    
    dart_paths = []
    
    # Walk through assets/data
    for root, dirs, files in os.walk(assets_dir):
        for file in files:
            if file.endswith('.json'):
                # Convert backslash to slash for Dart
                full_path = os.path.join(root, file).replace("\\", "/")
                dart_paths.append(full_path)
    
    print(f"Found {len(dart_paths)} JSON files.")
    
    # Generate Dart content
    dart_content = "/// GENERATED FILE - DO NOT EDIT MANUALLY\n"
    dart_content += "/// Run `python generate_asset_list.py` to update.\n\n"
    dart_content += "class AssetList {\n"
    dart_content += "  static const List<String> jsonPaths = [\n"
    
    for path in dart_paths:
        dart_content += f"    '{path}',\n"
        
    dart_content += "  ];\n"
    dart_content += "}\n"
    
    # Write to file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(dart_content)
        
    print(f"✅ Generated {output_file} successfully.")

if __name__ == "__main__":
    generate_dart_list()
