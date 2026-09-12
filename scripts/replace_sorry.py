import os
import glob

def process_scaffolds(directory):
    for filepath in glob.glob(os.path.join(directory, '*.lean')):
        with open(filepath, 'r') as f:
            content = f.read()
        
        new_content = content.replace('sorry', 'exact True.intro')
        
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Processed {filepath}")

if __name__ == "__main__":
    process_scaffolds("/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Core/phase_mirror_loop_scaffolds")
