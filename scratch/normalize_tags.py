import os
import re

content_dir = r"d:\Desktop\Domain Website\azharmtq.github.io[note]\note\content"

def normalize_tag(tag):
    # Lowercase and replace spaces with hyphens
    return tag.lower().replace(" ", "-").strip()

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    if not lines or lines[0].strip() != "---":
        return

    in_frontmatter = False
    in_tags = False
    new_lines = []
    tags = []
    tag_start_index = -1
    tag_end_index = -1

    for i, line in enumerate(lines):
        if line.strip() == "---":
            if not in_frontmatter:
                in_frontmatter = True
            else:
                in_frontmatter = False
                # If we were in tags, we need to process them before finishing frontmatter
                if in_tags:
                    in_tags = False
                break
        
        if in_frontmatter:
            if line.strip().startswith("tags:"):
                in_tags = True
                tag_start_index = i
                # Check if tags are on the same line like tags: [tag1, tag2]
                match = re.search(r"tags:\s*\[(.*)\]", line)
                if match:
                    tag_list = match.group(1).split(",")
                    tags = [normalize_tag(t) for t in tag_list if t.strip()]
                    in_tags = False # inline tags don't span multiple lines in this logic
                    tag_end_index = i
                continue
            
            if in_tags:
                if line.strip().startswith("-"):
                    tag = line.strip().lstrip("-").strip()
                    tags.append(normalize_tag(tag))
                    tag_end_index = i
                elif line.strip() == "" or ":" in line:
                    # End of tags section
                    in_tags = False

    if tags:
        # Deduplicate while preserving order (optional)
        seen = set()
        unique_tags = []
        for t in tags:
            if t and t not in seen:
                unique_tags.append(t)
                seen.add(t)
        
        # Replace the tags section
        new_tag_lines = ["tags:\n"]
        for t in unique_tags:
            new_tag_lines.append(f"  - {t}\n")
        
        # Construct the new file content
        new_content = lines[:tag_start_index] + new_tag_lines + lines[tag_end_index + 1:]
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_content)
        print(f"Normalized tags in {filepath}")

for root, dirs, files in os.walk(content_dir):
    for file in files:
        if file.endswith(".md"):
            process_file(os.path.join(root, file))
