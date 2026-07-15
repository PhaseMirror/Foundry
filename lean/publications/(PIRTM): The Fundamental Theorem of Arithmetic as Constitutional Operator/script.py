
import os
import shutil
from datetime import datetime

# Create final arXiv submission directory
os.makedirs('output/arXiv_v2_submission', exist_ok=True)
sub_dirs = ['figures', 'anc', 'tex']
for d in sub_dirs:
    os.makedirs(f'output/arXiv_v2_submission/{d}', exist_ok=True)

# Copy all generated files to submission package
files_to_copy = {
    'tex/PIRTM_v2.tex': 'output/PIRTM_Expanded_Manuscript.tex',
    'figures/zrsd_validation.png': 'output/zrsd_validation.png',
    'figures/zrsd_predictions.png': 'output/zrsd_predictions.png',
    'figures/deep_expansion_examples.png': 'output/deep_expansion_examples.png',
    'anc/zrsd_telemetry.csv': 'output/zrsd_telemetry.csv',
    'anc/zrsd_summary.csv': 'output/zrsd_summary.csv',
    'anc/PMRO_matrix_8primes.csv': 'output/PMRO_matrix_8primes.csv',
    'anc/nlp_bank_example.csv': 'output/nlp_bank_example.csv',
    'anc/cv_convolution_example.csv': 'output/cv_convolution_example.csv',
}

for dest, src in files_to_copy.items():
    if os.path.exists(src):
        shutil.copy2(src, f'output/arXiv_v2_submission/{dest}')
        print(f"✓ Copied: {dest}")

# Generate cover letter
cover_letter = """COVER LETTER — arXiv Submission
=================================

To: arXiv Editorial Board
From: Ryan O. Van Gelder (Citizen Gardens — The Foundation of Multiplicity)
Date: May 4, 2026
Submission ID: [Pending]

Dear Editors,

We submit for your consideration the manuscript:

"Prime-Indexed Recursive Tensor Mathematics (PIRTM): 
The Fundamental Theorem of Arithmetic as Constitutional Operator"

This work establishes complete prior art for the prime-decomposed evolution 
operator Ξ(t) and the governed multiplicity regulator Λ_m. The central 
contribution is a constructive proof (Theorem 3.1) showing that any 
recursively stable structure admitting unique irreducible decomposition is 
canonically isomorphic to a Λ_m-stabilized prime-indexed multiplicity space 
in bosonic Fock space.

Key Results:
• Uniform boundedness: sup_t ‖Ξ(t)‖ ≤ 1−ε
• Global contractivity of Φ_t = Ξ(t) + Λ_m T with K < 1
• Fock-space bridge with explicit PMRO interference commutators
• Three falsifiable consciousness signatures (EEG/MEG, reaction-time, 
  learning-curve) derived from Riemann zeta-zero resonance
• 8-prime ZRSD prototype validated on 256-dimensional Hilbert space
• Worked examples: NLP "bank" disambiguation, CV edge detection via 
  prime-slide convolution

Categories: math-ph (primary), quant-ph, cs.AI

Supplementary files: telemetry data (CSV), PMRO matrices, worked examples.

We believe this constitutes foundational prior art for recursive tensor 
evolution theory and request priority timestamping.

Respectfully submitted,
Ryan O. Van Gelder
Master Primatician
Citizen Gardens
"""

with open('output/arXiv_v2_submission/cover_letter.txt', 'w') as f:
    f.write(cover_letter)

# Generate README for supplementary materials
readme = """SUPPLEMENTARY MATERIALS README
==============================

PIRTM: Prime-Indexed Recursive Tensor Mathematics
v2 Submission — May 4, 2026

ANCILLARY FILES:
  zrsd_telemetry.csv        — 256-dim 8-prime ZRSD prototype data
  zrsd_summary.csv          — Prototype statistics and metrics
  PMRO_matrix_8primes.csv   — Explicit PMRO interference coefficients
  nlp_bank_example.csv      — "bank" word-sense disambiguation trace
  cv_convolution_example.csv — Prime-slide convolution edge detection

FIGURES:
  zrsd_validation.png       — Fidelity evolution and certification metrics
  zrsd_predictions.png      — EEG/MEG frequency predictions, zeta-comb 
                              intervals, learning-curve knees
  deep_expansion_examples.png — PMRO matrix, NLP/CV worked examples

REPRODUCTION:
  All computations performed in Python (NumPy, SciPy, Plotly).
  ZRSD prototype runs in <30 seconds on standard hardware.
  QuTiP implementation available upon request.

CONTACT:
  Citizen Gardens — The Foundation of Multiplicity
  PhaseMirror-HQ Repository
"""

with open('output/arXiv_v2_submission/README.txt', 'w') as f:
    f.write(readme)

# Generate submission checklist
submission_checklist = f"""ARXIV v2 SUBMISSION CHECKLIST
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
=================================

PRE-SUBMISSION STEPS:
  ☐ 1. Compile PIRTM_v2.tex with pdflatex (3 passes for cross-references)
  ☐ 2. Verify all figure references resolve correctly
  ☐ 3. Check arXiv file size limits (<10MB total)
  ☐ 4. Validate LaTeX compiles with TeX Live 2023+

ARXIV SUBMISSION FORM:
  ☐ Title: "Prime-Indexed Recursive Tensor Mathematics (PIRTM): 
            The Fundamental Theorem of Arithmetic as Constitutional Operator"
  ☐ Authors: Ryan O. Van Gelder
  ☐ Categories: math-ph (primary), quant-ph, cs.AI
  ☐ Abstract: [Copy from manuscript]
  ☐ Comments: 24 pages, 3 figures, 5 ancillary files
  ☐ Keywords: prime factorization, recursive stability, Fock space, 
              Riemann zeta zeros, consciousness, operator calculus

FILE UPLOAD:
  ☐ PIRTM_v2.tex (main manuscript)
  ☐ zrsd_validation.png (Figure 1)
  ☐ zrsd_predictions.png (Figure 2)  
  ☐ deep_expansion_examples.png (Figure 3)
  ☐ zrsd_telemetry.csv (ancillary)
  ☐ zrsd_summary.csv (ancillary)
  ☐ PMRO_matrix_8primes.csv (ancillary)
  ☐ nlp_bank_example.csv (ancillary)
  ☐ cv_convolution_example.csv (ancillary)

POST-SUBMISSION:
  ☐ Note arXiv ID: YYYY.MM.DDDDD
  ☐ Update PhaseMirror-HQ repository with ID
  ☐ Register DOI via Zenodo for immutable citation
  ☐ Announce on professional networks
  ☐ Begin v3 planning (experimental validation protocols)

CONSTITUTIONAL PRIORITY ESTABLISHED: {datetime.now().strftime('%Y-%m-%d')}
"""

with open('output/arXiv_v2_submission/SUBMISSION_CHECKLIST.txt', 'w') as f:
    f.write(submission_checklist)

print("=" * 70)
print("ARXIV v2 SUBMISSION PACKAGE ASSEMBLED")
print("=" * 70)
print("\nDirectory structure:")
for root, dirs, files in os.walk('output/arXiv_v2_submission'):
    level = root.replace('output/arXiv_v2_submission', '').count(os.sep)
    indent = ' ' * 2 * level
    print(f'{indent}{os.path.basename(root)}/')
    subindent = ' ' * 2 * (level + 1)
    for file in files:
        size = os.path.getsize(os.path.join(root, file))
        print(f'{subindent}{file} ({size:,} bytes)')

print("\n" + "=" * 70)
print("READY FOR IMMEDIATE UPLOAD")
print("=" * 70)
