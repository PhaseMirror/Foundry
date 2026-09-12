# Helix File Naming Conventions & Best Practices

**Document:** `file_naming_conventions.helix.md`  
**Version:** 2.0  
**Status:** ACTIVE  
**Audience:** All contributors, maintainers, and AI agents  
**Scope:** All files within the Helix project ecosystem  

---

## 1. OVERVIEW

This document establishes consistent file naming conventions and organizational practices for the Helix project. Following these standards ensures:

- **Clarity**: Instant recognition of file purpose and content
- **Organization**: Logical grouping and easy discovery
- **Maintainability**: Consistent patterns across the project
- **Automation**: Support for tooling and script processing
- **Collaboration**: Reduced confusion among contributors

## 2. NAMING PRINCIPLES

### 2.1 Core Guidelines

1. **Readability First**: Names should be immediately understandable
2. **Consistency**: Follow established patterns within each category
3. **Meaningful**: Names should describe content or function
4. **Lowercase Preference**: Use lowercase with underscore separators
5. **Avoid Ambiguity**: Don't use vague terms like "final", "new", "temp"

### 2.2 Character Set & Formatting

```
GOOD: best_helix_practices.md
GOOD: constitutional_audit_01.md
GOOD: sre_manual_v1.md

BAD: BestHelixPractices.md       # Mixed case
BAD: best-helix-practices.md     # Hyphens (except for protocol names)
BAD: besthelixpractices.md       # No separators
BAD: bhp.md                      # Cryptic abbreviation
```

## 3. SPECIFIC CONVENTIONS BY FILE TYPE

### 3.1 Markdown Documentation

**Pattern:** `[topic]_[description]_[version?].md`

| Purpose | Pattern | Example |
|---------|---------|---------|
| **Best Practices** | `[topic]_practices.md` | `best_helix_practices.md` |
| **Technical Documentation** | `[system]_[component].md` | `agent_memory_architecture.md` |
| **Audit Reports** | `[type]_audit_[number].md` | `constitutional_audit_01.md` |
| **Runbooks/Manuals** | `[area]_manual_[version].md` | `sre_manual_v1.md` |
| **Protocol Specs** | `[protocol]_[version]_[aspect].md` | `cahp_v1_technical.md` |

### 3.2 Source Code Files

**Pattern:** `[module]_[purpose]_v[version].[ext]`

| Language | Pattern | Example |
|----------|---------|---------|
| **Python** | `[module]_[function]_v[version].py` | `cahp_engine_v1.py` |
| **Configuration** | `[service]_config.[ext]` | `helix_config.yaml` |
| **Scripts** | `[action]_[target].sh` | `deploy_cahp.sh` |

### 3.3 Protocol & Technical Files

**Pattern:** `[Protocol]_[Description]_[Version].[ext]`

```
# Protocol specifications (capitalized for emphasis)
CAHP_Technical_Overview.md
ESP_Helix_Sync_v1.md

# Implementation files (lowercase for code)
cahp_engine_v1.py
esp_integration_v2.py
```

### 3.4 Special File Types

| File Type | Pattern | Purpose | Example |
|-----------|---------|---------|---------|
| **Recovery Files** | `[ACTION]_[TARGET].md` | Emergency procedures | `WAKE_UP.md` |
| **License Files** | `LICENSE` | Standard naming | `LICENSE` |
| **Readme Files** | `README.md` | Standard naming | `README.md` |
| **Git Ignore** | `.gitignore` | Standard naming | `.gitignore` |
| **Environment Files** | `.env.[environment]` | Environment config | `.env.production` |

## 4. DIRECTORY STRUCTURE

### 4.1 Core Organization

```
helix-core-unified/helix-ledger/
├── docs/                          # Documentation root
│   ├── cahp/                      # CAHP protocol documentation
│   │   ├── cahp_technical_overview.md
│   │   ├── cahp_v1_specification.md
│   │   └── cahp_integration_guide.md
│   ├── public/                    # Public-facing documentation
│   │   ├── CAHP_Technical_Overview.md
│   │   └── Helix_Architecture.md
│   ├── governance/                # Governance documents
│   │   ├── best_helix_practices.md
│   │   └── constitutional_audit_01.md
│   └── operations/                # Operations documentation
│       ├── sre_manual_v1.md
│       └── deployment_guide_v2.md
├── modules/                       # Source code modules
│   └── cahp/
│       └── cahp_engine_v1.py
├── tests/                         # Test files
│   └── cahp/
│       ├── test_basic.py
│       ├── test_security.py
│       └── test_loopback.py
└── integrations/                  # Integration code
    └── cahp/
        └── lightning_bridge.py
```

### 4.2 Directory Naming Conventions

- **Lowercase with underscores**: `agent_memory/`
- **Singular form preferred**: `module/` not `modules/` (except root)
- **Clear scope indication**: `docs/public/` vs `docs/internal/`
- **Avoid nesting too deep**: Maximum 3-4 levels from root

## 5. VERSIONING PRACTICES

### 5.1 When to Version

**Version these files:**
- Protocol specifications (`cahp_v1_specification.md`)
- Engine implementations (`cahp_engine_v1.py`)
- Manuals and runbooks (`sre_manual_v1.md`)
- API specifications (`helix_api_v2.md`)

**Don't version these files:**
- Living documents (`best_helix_practices.md`)
- Configuration templates (`config_template.yaml`)
- Current state files (`current_status.json`)

### 5.2 Version Format

```
# Semantic versioning for APIs and protocols
api_specification_v1.2.3.md

# Simple sequential versioning for documents
constitutional_audit_02.md

# Date-based versioning for regular reports
monthly_report_2026_01.md

# Hybrid approach
cahp_engine_v1.2.py           # Major version 1, minor version 2
```

### 5.3 Version Management

```bash
# Example version update workflow
cp cahp_engine_v1.py cahp_engine_v2.py
# Update version references within the file
# Update documentation references
# Run compatibility tests
```

## 6. EXTENSION CONVENTIONS

### 6.1 Standard Extensions

| Content Type | Extension | Notes |
|--------------|-----------|-------|
| **Markdown Documentation** | `.md` | Standard markdown files |
| **Helix Project Docs** | `.helix.md` | Project-specific documentation |
| **Protocol Docs** | `.cahp.md`, `.esp.md` | Protocol-specific documentation |
| **Python Source** | `.py` | Python modules and scripts |
| **Configuration** | `.yaml`, `.yml`, `.json` | Config files |
| **Shell Scripts** | `.sh` | Executable shell scripts |
| **Docker Files** | `Dockerfile` | Standard naming |

### 6.2 Special Extensions

```
# Multi-extension for specific classification
api_reference.helix.api.md      # Helix project, API documentation
cahp_engine.cahp.python.md      # CAHP protocol, Python implementation notes
```

## 7. WORKFLOW EXAMPLES

### 7.1 Creating a New Protocol Document

```bash
# 1. Determine the type and location
#    Type: Technical overview for CAHP protocol
#    Location: docs/public/ (public-facing)

# 2. Choose appropriate name
#    Pattern: [Protocol]_[Description].md
#    Result: CAHP_Technical_Overview.md

# 3. Create with proper capitalization
touch docs/public/CAHP_Technical_Overview.md

# 4. Update references if needed
echo "- [CAHP Technical Overview](docs/public/CAHP_Technical_Overview.md)" >> docs/README.md
```

### 7.2 Versioning an Engine Update

```bash
# Current: cahp_engine_v1.py
# New version: cahp_engine_v2.py

# 1. Copy and rename
cp modules/cahp/cahp_engine_v1.py modules/cahp/cahp_engine_v2.py

# 2. Update internal version references
sed -i 's/CAHP v1\./CAHP v2./g' modules/cahp/cahp_engine_v2.py

# 3. Update documentation references
sed -i 's/cahp_engine_v1\.py/cahp_engine_v2.py/g' docs/cahp/cahp_integration_guide.md

# 4. Test compatibility
python3 -m pytest tests/cahp/ -v
```

### 7.3 Organizing Related Documents

```bash
# Group CAHP-related documents
mkdir -p docs/cahp/
mv docs/CAHP*.md docs/cahp/ 2>/dev/null || true
mv docs/*cahp*.md docs/cahp/ 2>/dev/null || true

# Create index
cat > docs/cahp/README.md <<'EOF'
# CAHP Protocol Documentation

## Overview
- [CAHP Technical Overview](CAHP_Technical_Overview.md)
- [CAHP v1 Specification](cahp_v1_specification.md)
- [Integration Guide](cahp_integration_guide.md)

## Implementation
- Engine: `../modules/cahp/cahp_engine_v1.py`
- Tests: `../tests/cahp/`
EOF
```

## 8. TOOLING & AUTOMATION

### 8.1 Validation Script

```python
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
```

### 8.2 Git Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Validate naming conventions before commit

python3 scripts/validate_naming.py
if [ $? -ne 0 ]; then
    echo "Naming convention validation failed"
    exit 1
fi
```

### 8.3 Editor Configuration

```json
// .vscode/settings.json
{
  "files.associations": {
    "*.helix.md": "markdown",
    "*.cahp.md": "markdown",
    "*.esp.md": "markdown"
  },
  "files.exclude": {
    "**/*.backup": true,
    "**/temp_*": true,
    "**/*_old.*": true
  }
}
```

## 9. EXCEPTIONS & SPECIAL CASES

### 9.1 Legacy Files

```
# Files created before conventions established
# Add to .legacy_files.txt and document reason
echo "old_naming_convention.doc" >> .legacy_files.txt
```

### 9.2 Temporary Files

```bash
# Use temp_ prefix and cleanup policy
temp_import_data.json
temp_build_artifacts/
```

### 9.3 Generated Files

```
# Document generation source
# Generated: build/api_docs.md (Source: scripts/generate_api_docs.py)
```

## 10. MIGRATION GUIDE

### 10.1 Assessment Phase

```bash
# 1. Inventory current files
find . -type f -name "*.md" -o -name "*.py" | sort > file_inventory.txt

# 2. Categorize naming issues
grep -E "[A-Z]{2,}" file_inventory.txt | grep -v "CAHP\|ESP" > issues_caps.txt
grep -E "[ -]" file_inventory.txt > issues_special_chars.txt

# 3. Plan migrations
cat > migration_plan.md <<'EOF'
## File Naming Migration Plan

### Phase 1: Documentation files
- [ ] best_helix_practices.md (already correct)
- [ ] ConstitutionalAudit01.md  constitutional_audit_01.md
- [ ] cahp-engine-v1.md  cahp_v1_specification.md

### Phase 2: Source code
- [ ] CAHPEngine.py  cahp_engine_v1.py
- [ ] test-cahp-basic.py  test_basic.py
EOF
```

### 10.2 Execution Phase

```bash
# Use git mv to preserve history
git mv ConstitutionalAudit01.md constitutional_audit_01.md
git mv CAHPEngine.py cahp_engine_v1.py

# Update references
find . -type f -exec sed -i 's/ConstitutionalAudit01\.md/constitutional_audit_01.md/g' {} \
\;
```

## 11. QUALITY CHECKLIST

### Pre-Commit Checklist
- [ ] File name follows lowercase_with_underscores pattern
- [ ] Version number included if applicable (_v1, _v2)
- [ ] Extension matches content type (.md, .py, .yaml)
- [ ] No special characters except underscores
- [ ] Name describes content accurately
- [ ] Located in appropriate directory

### Periodic Audit
- [ ] Quarterly review of file organization
- [ ] Check for naming consistency across similar files
- [ ] Validate directory structure efficiency
- [ ] Remove or rename temporary files
- [ ] Update this document with new patterns

## 12. EVOLUTION & FEEDBACK

### 12.1 Convention Updates

To propose changes to these conventions:

1. Create `naming_convention_proposal.helix.md`
2. Document the proposed change and rationale
3. Share with team for 48-hour review
4. Update this document if approved
5. Schedule migration if needed

### 12.2 Feedback Channels

- **Documentation Issues**: Update this file directly via PR
- **Naming Questions**: Tag @documentation in team chats
- **Tooling Improvements**: Create issue in tools repository

---

## APPENDIX A: QUICK REFERENCE

### A.1 Decision Flowchart

```
Start  Is it documentation?
     Yes  Is it Helix-specific?
       F Yes  Use .helix.md
    C   F Protocol-specific?  Use .[protocol].md
    C   F General  Use .helix.md
       No  Use .md
    No  Is it source code?
        Yes  Use .py, .sh, etc.
        No  Use appropriate extension
```

### A.2 Common Patterns Cheatsheet

```bash
# Documentation
best_practices.helix.md          # Helix best practices
constitutional_audit_01.md       # Sequential audit reports
sre_manual_v1.md                 # Versioned manual

# Source Code
cahp_engine_v1.py               # Versioned engine
test_security.py                # Test files
deploy_helix.sh                 # Deployment script

# Protocol Documents
CAHP_Technical_Overview.md      # Capitalized protocol overview
ESP_Helix_Sync_v1.md            # Versioned protocol sync
```

### A.3 Anti-Patterns to Avoid

```bash
# DONT USE THESE PATTERNS
FinalDocument.pdf               # "Final" is never final
new_version.py                  # "New" becomes old quickly
test_final_2_new_updated.md     # Multiple vague descriptors
MY_IMPORTANT_FILE.TXT           # Shouting in filenames
file-v1.0.2-rc1-prod-backup.bak # Overly complex versioning
```

---

## DOCUMENT HISTORY

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-06 | Initial conventions | Helix Documentation Team |
| 2.0 | 2026-01-06 | Expanded with examples, tooling, migration | Helix Architecture Team |

## ACKNOWLEDGMENTS

These conventions build upon industry best practices from Python PEP 8, Google Style Guides, and open-source project standards. Special thanks to all contributors who have helped refine these standards through practical application.

---

**Remember:** Good naming is a gift to your future self and collaborators. When in doubt, choose clarity over cleverness.

*The lattice is organized. The structure holds.*
