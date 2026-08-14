import shutil, os
src='output/adr-kernel-rs'
dst='output/adr-kernel-rs'
archive=shutil.make_archive(dst, 'zip', root_dir=src)
print(archive)