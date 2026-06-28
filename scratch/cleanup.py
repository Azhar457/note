import os
import shutil

dest_dir = r"d:\Desktop\Domain Website\azhar457.github.io[note]\note\content"

# Paths to delete relative to dest_dir
dirs_to_delete = [
    r"01_Library\Military & Intelligence Tools",
]

files_to_delete = [
    r"00_Atlas\endpoint-security-hierarchy (Open Source & Freeware Edition).md",
    r"00_Atlas\endpoint-security-hierarchy-open-source-freeware-edition.md",
    r"00_Atlas\programming-language-hierarchy.md",
    r"01_Library\Cyber_Security\COMPREHENSIVE_THREAT_DIRECTORY.md",
    r"01_Library\Platform_Technologies\PLATFORM_TECHNOLOGIES_OVERVIEW.md",
    r"01_Library\Signal_Intelligence\MILITARY_SIGINT_DEEPDIVE.md",
    r"03_Resources\attachments\Cloudflare Rules.png",
    r"03_Resources\attachments\Gemini_Generated_Image_.png",
    r"03_Resources\attachments\Pasted image 20260430215147.png",
    r"03_Resources\attachments\Pasted image 20260516160135.png",
]

print("--- Starting Cleanup ---")

for d in dirs_to_delete:
    full_path = os.path.join(dest_dir, d)
    if os.path.exists(full_path):
        print(f"Deleting directory: {full_path}")
        shutil.rmtree(full_path)
    else:
        print(f"Directory not found (already deleted?): {full_path}")

for f in files_to_delete:
    full_path = os.path.join(dest_dir, f)
    if os.path.exists(full_path):
        print(f"Deleting file: {full_path}")
        os.remove(full_path)
    else:
        print(f"File not found (already deleted?): {full_path}")

print("--- Cleanup Finished ---")
