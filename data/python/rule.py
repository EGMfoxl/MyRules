import os

print("规则去重中")

# Get list of all files in current directory
files = os.listdir()

for file in files:
    if os.path.isfile(file) and file.endswith('.txt'):
        with open(file, 'r', encoding='utf8') as f:
            lines = f.readlines()
        
        # Remove duplicates and sort lines
        lines = sorted(set(lines))
        
        with open(file, 'w', encoding='utf8') as f:
            f.writelines(lines)
        
print("规则去重完成")
