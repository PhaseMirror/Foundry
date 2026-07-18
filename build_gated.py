#!/usr/bin/env python3
import os
import sys
import shutil
import subprocess
import argparse

PRIME_DIR = os.path.dirname(os.path.abspath(__file__))
LEAN_DIR = os.path.join(PRIME_DIR, "lean")
GATED_DIR = os.path.join(LEAN_DIR, "gated")
LAKEFILE = os.path.join(LEAN_DIR, "lakefile.lean")

def get_gated_components():
    if not os.path.exists(GATED_DIR):
        return []
    return [d for d in os.listdir(GATED_DIR) if os.path.isdir(os.path.join(GATED_DIR, d))]

def ensure_in_lakefile(component):
    with open(LAKEFILE, "r") as f:
        content = f.read()
    
    lib_decl = f"lean_lib {component}"
    if lib_decl not in content:
        with open(LAKEFILE, "a") as f:
            f.write(f"\n{lib_decl} where\n  srcDir := \"{component}\"\n")
        print(f"Added {component} to lakefile.lean")

def remove_from_lakefile(component):
    with open(LAKEFILE, "r") as f:
        lines = f.readlines()
    
    new_lines = []
    skip = False
    for line in lines:
        if line.strip().startswith(f"lean_lib {component}"):
            skip = True
            continue
        if skip:
            if line.strip() == "" or line.startswith("  srcDir"):
                continue
            skip = False
        new_lines.append(line)
        
    with open(LAKEFILE, "w") as f:
        f.writelines(new_lines)

def enable_component(component):
    source = os.path.join(GATED_DIR, component)
    target = os.path.join(LEAN_DIR, component)
    
    if not os.path.exists(target):
        print(f"Enabling {component}...")
        shutil.copytree(source, target)
        ensure_in_lakefile(component)
        
        # Build it
        subprocess.run(["lake", "build", component], cwd=LEAN_DIR)
    else:
        print(f"{component} is already enabled.")

def disable_component(component):
    target = os.path.join(LEAN_DIR, component)
    if os.path.exists(target):
        print(f"Disabling {component}...")
        shutil.rmtree(target)
        remove_from_lakefile(component)
    else:
        print(f"{component} is not enabled.")

def main():
    parser = argparse.ArgumentParser(description="Manage gated Lean components.")
    parser.add_argument("--enable", type=str, help="Enable a specific component (or 'all')")
    parser.add_argument("--disable", type=str, help="Disable a specific component (or 'all')")
    parser.add_argument("--list", action="store_true", help="List available gated components")
    
    args = parser.parse_args()
    available = get_gated_components()
    
    if args.list:
        print("Available gated components:")
        for c in available:
            print(f"  - {c}")
        return

    if args.enable:
        if args.enable == "all":
            for c in available:
                enable_component(c)
        else:
            if args.enable in available:
                enable_component(args.enable)
            else:
                print(f"Component {args.enable} not found in gated/.")
                
    if args.disable:
        if args.disable == "all":
            for c in available:
                disable_component(c)
        else:
            if args.disable in available:
                disable_component(args.disable)
            else:
                print(f"Component {args.disable} not found in gated/.")

if __name__ == "__main__":
    main()
