#!/usr/bin/env python3
"""
validate_naming.py - Check file naming conventions
"""

import os
import re
from pathlib import Path

class NamingValidator:
    """Validate file names against Helix conventions"""
    
    PATTERNS = {
        'markdown': r'^[a-z][a-z0-9_]+\.md$',
        'helix_doc': r'^[a-z][a-z0-9_]+\.helix\.md$',
        'python': r'^[a-z][a-z0-9_]+(_v\d+)?\.py$',
        'protocol_doc': r'^[A-Z]+_[A-Z][a-z]+(_v\d+)?\.md$',
    }
    
    def validate_directory(self, path):
        """Validate all files in directory"""
        issues = []
        for root, dirs, files in os.walk(path):
            for file in files:
                full_path = os.path.join(root, file)
                issue = self.validate_file(full_path)
                if issue:
                    issues.append(issue)
        return issues
    
    def validate_file(self, filepath):
        """Validate single file name"""
        filename = os.path.basename(filepath)
        ext = Path(filepath).suffix
        
        # Skip certain files
        if filename in ['README.md', 'LICENSE', '.gitignore']:
            return None
        
        # Check pattern based on extension
        if ext == '.md':
            if 'helix.md' in filename:
                if not re.match(self.PATTERNS['helix_doc'], filename):
                    return f"Invalid helix doc name: {filename}"
            elif not re.match(self.PATTERNS['markdown'], filename):
                # Allow capitalized protocol docs
                if not re.match(self.PATTERNS['protocol_doc'], filename):
                    return f"Invalid markdown name: {filename}"
        elif ext == '.py':
            if not re.match(self.PATTERNS['python'], filename):
                return f"Invalid python file name: {filename}"
        
        return None

if __name__ == '__main__':
    validator = NamingValidator()
    issues = validator.validate_directory('.')
    if issues:
        print("Naming convention issues found:")
        for issue in issues:
            print(f"  - {issue}")
        exit(1)
    else:
        print("All files follow naming conventions")

