#!/usr/bin/env python3
import pathlib

src_dir = pathlib.Path('/home/citizen/Multiplicity/UAC/lean/src')
out_path = pathlib.Path('/home/citizen/Multiplicity/UAC/docs/generated_lean_status.tex')

modules = sorted(src_dir.glob('*.lean'))
lines = []
for mod in modules:
    name = mod.name
    content = mod.read_text(encoding='utf-8')
    if 'sorry' in content:
        status = '$\times$ Missing'
        sorries = '≥1'
    else:
        status = '$\checkmark$ Complete'
        sorries = '0'
    lines.append(f'\texttt{{{name}}} & {status} & {sorries} \\')
out_path.write_text('\n'.join(lines), encoding='utf-8')
print(f'Generated {len(lines)} entries to {out_path}')
