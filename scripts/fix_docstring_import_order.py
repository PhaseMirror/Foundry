#!/usr/bin/env python3
"""ADR: Fix docstring-before-import ordering (lint/fix tool).

Lean 4 (this toolchain) rejects `import` commands once a doc-command
(`/--`, `/-!`) has appeared. Many legacy files open with a module header and
only then import — that parse fails on a cold build and was masked by stale
Lake fingerprints.

This script rewrites such files in place to the canonical order:

    import A
    import B

    /-!
    # Module Doc
    -/

    <body>

It is a no-op (exit 0, no edits) for files that already comply.

Usage:
  python3 scripts/fix_docstring_import_order.py --check   # report only, exit 1 on dirty
  python3 scripts/fix_docstring_import_order.py           # rewrite in place
  python3 scripts/fix_docstring_import_order.py --scope ADR Care WordLove
"""

import argparse
import os
import sys

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# mirror scripts/check_adr_sorry.py policy
DEFAULT_SCOPE = ["ADR", "Care", "Foundations", "WordLove"]

DOC_OPEN = ("/--", "/-!")
IMPORT_PREFIX = "import "


def has_own_lakefile(dirpath: str) -> bool:
    return (
        os.path.exists(os.path.join(dirpath, "lakefile.lean"))
        or os.path.exists(os.path.join(dirpath, "lakefile.toml"))
    )


def new_src_for(path: str) -> tuple[bool, str]:
    """Return (changed, new_source) for a file needing import reordering."""
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        src_lines = f.readlines()
    n = len(src_lines)

    # Find the first `import` line; everything above it must be blank lines,
    # `--` comments, or `/--`../-/ doc blocks (with interior lines consumed).
    in_doc = False
    first_imp = None
    for idx, line in enumerate(src_lines):
        s = line.strip()
        if in_doc:
            if "-/" in line:
                in_doc = False
            continue
        if s.startswith(DOC_OPEN):
            in_doc = True
            continue
        if s.startswith(IMPORT_PREFIX):
            first_imp = idx
            break
        if s.startswith("--") or not s:
            continue
        return (False, "".join(src_lines))  # other content: unsafe to move

    if first_imp is None:
        return (False, "".join(src_lines))  # no imports => nothing to fix

    head_is_blank = all(not l.strip() for l in src_lines[:first_imp])
    if head_is_blank:
        return (False, "".join(src_lines))  # nothing to move

    # Collect the consecutive import block.
    last_imp = first_imp
    while last_imp + 1 < n and src_lines[last_imp + 1].startswith(IMPORT_PREFIX):
        last_imp += 1

    import_block = src_lines[first_imp : last_imp + 1]
    rest = src_lines[last_imp + 1 :]
    if rest and not rest[0].strip():
        rest = rest[1:]  # drop one blank line (re-added below)

    non_blank_head = [l for l in src_lines[:first_imp] if l.strip()]
    new_lines = []
    new_lines.extend(import_block)
    if non_blank_head:
        new_lines.append("\n")
        new_lines.extend(non_blank_head)
    new_lines.append("\n")
    new_lines.extend(rest)

    new_src = "".join(new_lines)
    return (new_src != "".join(src_lines), new_src)


def rewrite(path: str) -> bool:
    changed, new_src = new_src_for(path)
    if changed:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_src)
    return changed


def collect_targets(scope: list[str]) -> list[str]:
    out = []
    for root in scope:
        base = os.path.join(PROJECT_DIR, root)
        if not os.path.isdir(base):
            continue
        for dp, dns, fns in os.walk(base):
            dns[:] = [d for d in dns if d != ".lake" and not has_own_lakefile(os.path.join(dp, d))]
            for fn in sorted(fns):
                if fn.endswith(".lean"):
                    out.append(os.path.join(dp, fn))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="report only; exit 1 if any file needs fixing")
    ap.add_argument("--scope", nargs="*", default=DEFAULT_SCOPE)
    args = ap.parse_args()

    changed = []
    for path in collect_targets(args.scope):
        is_changed, _ = new_src_for(path)
        if is_changed:
            if args.check:
                changed.append(path)
            elif rewrite(path):
                changed.append(path)

    for p in changed:
        print(f"FIXED: {os.path.relpath(p, PROJECT_DIR)}")
    print(f"{len(changed)} file(s) had docstring-before-import and were "
          f"{'would be rewritten' if args.check else 'rewritten'}.")
    return 1 if (args.check and changed) else 0


if __name__ == "__main__":
    sys.exit(main())