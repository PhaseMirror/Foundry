with open("ADR/Examples.lean", "r") as f:
    text = f.read()

text = text.replace("/-!\n# ADR Registry Examples\nInstantiations of the core ADR structures for all accepted ADRs.\n-/\nimport ADR.Core", "import ADR.Core\n/-!\n# ADR Registry Examples\nInstantiations of the core ADR structures for all accepted ADRs.\n-/")

with open("ADR/Examples.lean", "w") as f:
    f.write(text)
