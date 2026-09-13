with open("packages/Foundry/ADR/ADR/Examples.lean", "r") as f:
    text = f.read()

text = text.replace("exact List.Mem.tail _ hc", "apply Or.inr\n    exact List.Mem.tail _ hc")

with open("packages/Foundry/ADR/ADR/Examples.lean", "w") as f:
    f.write(text)
