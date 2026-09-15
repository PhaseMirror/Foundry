# Section 9. Implementation and Certification Protocol

This section freezes Section 8 conceptually and specifies the reproducible protocol for certifying the textual typing constraint. It separates corpus certification from operator certification, as required.

The deliverable is a reproducible pipeline:

\[
\boxed{
\mathcal C
\to
\mathbf T(\ell)
\to
\mathcal T(\mathcal G)
\to
\Gamma
\to
\rho
\to
\tau(\ell)=O.
}
\]

Section 9 certifies only the left half:

\[
\boxed{
\mathcal C
\to
\mathbf T(\ell)
\to
\mathcal T(\mathcal G).
}
\]

Operator certification belongs to Section 10.

---

## 9.1 Corpus preprocessing

### 9.1.1 Hebrew (Masoretic)

Source text: Leningrad Codex (or a declared equivalent), with full vocalization, cantillation, and accents.

Preprocessing steps:

1. Strip cantillation marks only where required by the morphological tagger. Retain them in the raw layer.
2. Normalize Unicode to NFC.
3. Retain maqqef, sof pasuq, and paseq as clause-boundary markers.
4. Do not remove vocalization. Vowel letters are required for binyan and stem identification.
5. Do not apply any English transliteration at any stage.

Lemma identity is determined by a fixed morphological lexicon (e.g., an open-source Hebrew morphological analyzer with a frozen version hash). Each token receives:

- lemma ID,
- binyan/stem,
- conjugation (perfect, imperfect, wayyiqtol, imperative, infinitive, participle),
- person, gender, number,
- clause position,
- accent class.

### 9.1.2 Aramaic (Peshitta)

Source text: a declared Peshitta edition with full pointing and punctuation.

Preprocessing steps:

1. Normalize Unicode to NFC.
2. Retain Syriac punctuation as clause-boundary markers.
3. Retain vowel pointing where present.
4. Do not apply any English transliteration.

Lemma identity is determined by a fixed Peshitta morphological lexicon with a frozen version hash. Each token receives:

- lemma ID,
- verb stem,
- conjugation (perfect, imperfect, participle, infinitive),
- person, gender, number,
- clause position,
- punctuation class.

### 9.1.3 Parallel alignment

If both corpora are used, alignment is at the clause level. Alignment is declared as a versioned artifact. No alignment is inferred at certification time.

---

## 9.2 Clause boundary rules

Clause boundaries are determined by native punctuation and syntax, not by translation.

### Hebrew

A clause boundary is inserted at:

- sof pasuq (׃),
- paseq (׀),
- atnach (֑) when it coincides with a finite verb boundary,
- maqqef (־) only when it joins a preposition to a non-verb,
- wayyiqtol chain reset.

A **narrative chain** is a maximal sequence of consecutive wayyiqtol clauses sharing a subject or an explicit pronominal continuation.

### Aramaic

A clause boundary is inserted at:

- Syriac period (܀ or ܁),
- Syriac comma (܆) when followed by a finite verb,
- waw + perfect/imperfect narrative reset,
- explicit conjunction reset.

A **narrative chain** is a maximal sequence of consecutive waw + perfect/imperfect clauses sharing a subject or explicit pronominal continuation.

All boundary rules are deterministic. No human judgment is permitted.

---

## 9.3 Temporal frame constructions \(F_1\)–\(F_4\)

Let \(\ell\) be a lemma. Let \(c\) be a clause.

### \(F_1\) — Clause-initial wayyiqtol

For Hebrew:

\[
\ell \in F_1(c)
\iff
\text{root}(c)=\ell
\;\land\;
\text{form}(c)=\text{wayyiqtol}
\;\land\;
\text{position}(c)=1.
\]

For Aramaic, use the analogous clause-initial waw + perfect/imperfect form.

### \(F_2\) — Narrative succession chain

\[
\ell \in F_2(c)
\iff
\text{root}(c)=\ell
\;\land\;
c \in \text{narrative chain}
\;\land\;
\text{position}(c)>1.
\]

### \(F_3\) — Explicit temporal particle or noun

Fix a finite native set:

\[
\mathcal P_{\text{temp}}^{\text{Heb}}
=
\{\text{אז, עתה, טרם, אחר, יום, עת, בקר, ערב, ...}\},
\]

\[
\mathcal P_{\text{temp}}^{\text{Aram}}
=
\{\text{הָידֵין, כְּדֵין, ...}\}.
\]

\[
\ell \in F_3(c)
\iff
\ell \in \mathcal P_{\text{temp}}
\;\land\;
\text{position}(c)\le 2.
\]

### \(F_4\) — Temporal construct head

\[
\ell \in F_4(c)
\iff
\ell \text{ is the head of a construct chain}
\;\land\;
\text{the chain is in preverbal or clause-initial position}.
\]

Then:

\[
\#\{c:\ell\in c \text{ and } c\in\mathcal F\}
=
\sum_{i=1}^{4}
\#\{c:\ell\in F_i(c)\}.
\]

No double counting: if \(\ell\in F_i(c)\) and \(\ell\in F_j(c)\) for \(i\neq j\), count once.

---

## 9.4 Invariant definitions

### TFSI

\[
TFSI(\ell)
=
\frac{
\#\{c:\ell\in c \text{ and } c\in\mathcal F\}
}{
\#\{c:\ell\in c\}
}.
\]

If denominator is zero, \(TFSI(\ell)=0\).

### GESI

Build the clause graph \(G_{\mathcal C}\):

- Nodes: clauses.
- Edge \(c\to c'\) if \(c'\) is the immediate successor of \(c\) in the same narrative chain.

Let:

\[
GESI(\ell)
=
\frac{
\#\{c:\text{root}(c)=\ell \;\land\; \text{outdeg}_{G_{\mathcal C}}(c)>0\}
}{
\#\{c:\text{root}(c)=\ell\}
}.
\]

If denominator is zero, \(GESI(\ell)=0\).

### Other invariants

- \(AspectVar(\ell)\): Shannon entropy of the distribution over perfect/imperfect/participle forms of \(\ell\).
- \(DepDepth(\ell)\): mean depth of \(\ell\) in the dependency tree over all clauses containing \(\ell\).
- \(AdjRank(\ell)\): eigenvector centrality of \(\ell\) in the lemma co-occurrence graph.
- \(Morphology(\ell)\): one-hot or embedded vector of binyan/stem classes.

The typing vector is:

\[
\mathbf T(\ell)
=
\bigl(
TFSI,
GESI,
AspectVar,
DepDepth,
AdjRank,
Morphology
\bigr).
\]

All components are computed from the native corpus. No physics enters here.

---

## 9.5 Null models

Four null models are specified. Each preserves progressively more structure.

### Null A — Lemma shuffle

Shuffle lemma IDs across all tokens while preserving:

- token count,
- lemma frequency,
- clause length distribution.

Destroys morphology and syntax. Used as a baseline.

### Null B — Morphology-preserving shuffle

Shuffle lemma IDs within morphological tag classes. Preserves:

- binyan/stem distribution,
- conjugation distribution,
- clause position distribution.

Destroys lexical identity. Used to test whether TFSI/GESI are driven by morphology alone.

### Null C — Clause-order shuffle

Shuffle clause order within each narrative chain. Preserves:

- lemma frequency,
- morphology,
- clause internal syntax.

Destroys narrative succession. Used to test whether GESI is driven by chain structure.

### Null D — Dependency-tree permutation

Permute dependency trees within clauses while preserving:

- depth distribution,
- dependency label distribution,
- lemma frequency.

Destroys syntactic relations. Used to test whether DepDepth and AdjRank are driven by dependency structure.

For each null model, compute \(TFSI\), \(GESI\), and all other invariants for every lemma.

---

## 9.6 Threshold estimation

For each invariant \(X\in\{TFSI,GESI,AspectVar,DepDepth,AdjRank\}\), define:

\[
\theta_X
=
\text{95th percentile of } X \text{ across all null models}.
\]

For the operator class \(\mathcal G_{\mathrm{time}}\):

\[
\mathcal T(\mathcal G_{\mathrm{time}})
=
\left\{
\mathbf T:
TFSI>\theta_T
\;\land\;
GESI>\theta_G
\;\land\;
AspectVar>\theta_A
\right\}.
\]

For the stationary class:

\[
\mathcal T(\mathcal G_{\mathrm{stat}})
=
\left\{
\mathbf T:
TFSI<\theta_T
\;\land\;
GESI<\theta_G
\right\}.
\]

Thresholds are estimated on the **training split only**. They are frozen before test evaluation.

---

## 9.7 Multiple-testing correction

For each lemma, compute a permutation \(p\)-value:

\[
p(\ell)
=
\frac{
\#\{\text{null permutations with } X(\ell)\ge X_{\text{obs}}(\ell)\}
}{
N_{\text{perm}}
}.
\]

Apply Benjamini–Hochberg at \(q=0.01\) across all lemmas. Report both raw and adjusted \(p\)-values.

A lemma is **admissible** for \(\mathcal G\) only if:

- its adjusted \(p<\ 0.01\),
- its typing vector lies in \(\mathcal T(\mathcal G)\).

---

## 9.8 Train/test split

Split the corpus into:

\[
\mathcal C
=
\mathcal C_{\text{train}}
\cup
\mathcal C_{\text{test}},
\qquad
\mathcal C_{\text{train}}\cap\mathcal C_{\text{test}}=\varnothing.
\]

Split at the book or major-section level to avoid leakage.

Estimate thresholds and thresholds only on \(\mathcal C_{\text{train}}\).  
Freeze \(\mathcal T(\mathcal G)\).  
Evaluate controls on \(\mathcal C_{\text{test}}\).

Report all results on the held-out split.

---

## 9.9 Control-separation table

Let the control sets be:

Negative controls (static nouns):

\[
\mathcal N
=
\{\text{אבן, מים, בית, מלך, ...}\}.
\]

Positive temporal controls:

\[
\mathcal P_T
=
\{\text{עתה, אז, יום, עת, ...}\}.
\]

Positive generative controls:

\[
\mathcal P_G
=
\{\text{היה, עשה, בא, הלך, ...}\}.
\]

For each control \(\ell\), report:

| Lemma | TFSI | GESI | AspectVar | DepDepth | AdjRank | \(\mathbf T\in\mathcal T(\mathcal G_{\mathrm{time}})\)? | \(p_{\text{adj}}\) |
|---|---|---|---|---|---|---|---|
| אבן | | | | | | | |
| מים | | | | | | | |
| בית | | | | | | | |
| מלך | | | | | | | |
| עתה | | | | | | | |
| אז | | | | | | | |
| יום | | | | | | | |
| עת | | | | | | | |
| היה | | | | | | | |
| עשה | | | | | | | |
| בא | | | | | | | |
| הלך | | | | | | | |

Success criterion:

\[
\boxed{
\mathcal N\cap\mathcal T(\mathcal G_{\mathrm{time}})=\varnothing
}
\]

and

\[
\boxed{
\mathcal P_T\cup\mathcal P_G
\subseteq
\mathcal T(\mathcal G_{\mathrm{time}})
}
\]

on \(\mathcal C_{\text{test}}\).

Failure of either condition forces revision of \(\mathcal F\), \(G_{\mathcal C}\), or the thresholds. The constraint is falsifiable.

---

## 9.10 What Section 9 certifies

Section 9 certifies:

\[
\boxed{
\text{The typing vector } \mathbf T(\ell) \text{ is reproducibly computed from the native corpus.}
}
\]

Section 9 does **not** certify:

- the operator class assignment \(\Gamma\),
- the representation \(\rho\),
- the claim \(\tau(\ell)=H\) for any specific \(\ell\),
- any physical interpretation.

The logical direction remains:

\[
\boxed{
\tau(\ell)\in\mathcal G
\;\Longrightarrow\;
\mathbf T(\ell)\in\mathcal T(\mathcal G).
}
\]

And the exclusion test remains:

\[
\boxed{
\mathbf T(\ell)\notin\mathcal T(\mathcal G)
\;\Longrightarrow\;
\tau(\ell)\notin\mathcal G.
}
\]

This gives the framework a genuine falsifiability condition: a representation assignment can be rejected without requiring an alternative interpretation to be accepted.

---

## 9.11 Deliverables

A reproducible Section 9 implementation must publish:

1. Frozen corpus version hashes.
2. Frozen morphological analyzer version hashes.
3. Clause-boundary rule set as executable code.
4. \(F_1\)–\(F_4\) definitions as executable code.
5. \(G_{\mathcal C}\) construction as executable code.
6. All four null models as executable code.
7. Threshold estimation code.
8. Multiple-testing correction code.
9. Train/test split specification.
10. Control-separation table with raw and adjusted \(p\)-values.
11. Bootstrap stability intervals for every reported invariant.

Section 10 then takes the certified typing constraint and tests whether the operator representation \(\rho\) preserves the algebraic relations found in the native textual graph.