from pathlib import Path
text = Path('backend/src/services/inventory.service.js').read_text(encoding='utf-8').splitlines()
for i,line in enumerate(text,1):
    if 'processBulkScans' in line or 'acceptedIds' in line or 'rejected' in line:
        print(f"{i}:{line}")
