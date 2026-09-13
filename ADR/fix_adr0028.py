with open("ADR/Examples.lean", "r") as f:
    text = f.read()

import re

# Fix ADR0028
text = re.sub(r"exact List\.Mem\.tail _ \(List\.Mem\.tail.*?hc\)\)+", 
"exact List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ hc))))))", text, flags=re.DOTALL)

with open("ADR/Examples.lean", "w") as f:
    f.write(text)
