import os

src_dir = r"D:\Documents\Wide Note\Note"
dest_dir = r"d:\Desktop\Domain Website\azhar457.github.io[note]\note\content"

print("--- Files in content but not in source ---")
for root, dirs, files in os.walk(dest_dir):
    for f in files:
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, dest_dir)
        src_path = os.path.join(src_dir, rel_path)
        if not os.path.exists(src_path):
            print(f"Not in source: {rel_path} ({os.path.getsize(full_path)} bytes)")

print("\n--- Files in source but not in content ---")
for root, dirs, files in os.walk(src_dir):
    for f in files:
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, src_dir)
        dest_path = os.path.join(dest_dir, rel_path)
        if not os.path.exists(dest_path):
            print(f"Not in content: {rel_path} ({os.path.getsize(full_path)} bytes)")
