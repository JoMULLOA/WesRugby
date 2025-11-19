import re
from pathlib import Path
base = Path('backend/src/entity')
for path in sorted(base.glob('*.js')):
    text = path.read_text(encoding='utf-8', errors='ignore')
    if 'relations' not in text:
        continue
    rel = None
    m = re.search(r"relations\s*:\s*\{([\s\S]*?)\}\s*,\s*indices", text)
    if not m:
        m = re.search(r"relations\s*:\s*\{([\s\S]*?)\}\s*\}\s*;", text)
    if m:
        rel = m.group(1)
    print('====', path.name)
    print(rel.strip() if rel else '(no block found)')
    print()
