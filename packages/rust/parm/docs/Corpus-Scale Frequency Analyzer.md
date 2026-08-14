A corpus-scale frequency analyzer that batch-processes **OSHB** and **ETCBC/BHSA** would give PARM a real discovery pipeline rather than just curated-root demos, because OSHB supplies lemma-tagged Hebrew Bible text and BHSA exposes a sizeable Hebrew lexicon file you can use as a root/lexeme backbone.[^1][^2]

## System design

The clean architecture is a two-source pipeline:

- **OSHB / morphhb** as the corpus-frequency layer, because its word tags include lemma attributes and morphology across the Hebrew Bible.[^2]
- **ETCBC/BHSA lexicon** as the lexeme normalization and reference layer, since its `lexicon_hbo.txt` is a large Hebrew lexicon resource.

That suggests three modules:

- `parm_corpus_ingest.py` — parse OSHB lemma-bearing text and count forms/lemmas.[^2]
- `parm_lexicon_link.py` — align OSHB lemmas to BHSA lexicon entries for canonical root labels.
- `parm_frequency_analyzer.py` — compute PARM metrics and produce ranked outputs.


## What to compute

For each canonical root or lemma entry, compute:

- Frequency in OSHB corpus.[^2]
- Shape primes, numeric primes, and optionally future channels.
- $V_{\text{actual}}, V_{\min}, V_{\max}$ per channel.
- $RQ_s, RQ_n, C, \Delta, R$.
- Extremal diagnostics, e.g. whether the actual ordering is near-maximal, near-minimal, or central in permutation space.[^2]

Then create ranking views such as:

- Highest $RQ_s$ among frequent roots.
- Highest $RQ_n$ among frequent roots.
- Highest $C$ among roots above a frequency threshold.
- Most asymmetric roots by $|\Delta|$ or Ratio.
- Frequency-weighted resonance, e.g. $f \cdot C$, to identify roots that are both structurally significant and textually prominent.

That last metric is especially useful for “systemic gematria validation,” because it prevents rare exotic roots from dominating the analysis purely by extreme resonance.

## Practical corpus workflow

A concrete workflow would be:

1. **Extract OSHB lemma counts**
Parse the OSHB XML or JSON conversion and count each lemma across all books, chapters, and verses; the morphhb repository explicitly documents lemma-tagged word records for the Hebrew Bible.[^2]
2. **Normalize lemmas to root entries**
Use BHSA/ETCBC lexicon entries as the canonical lexeme layer, and map OSHB lemmas into a normalized Hebrew root inventory.
3. **Generate PARM metrics**
For each normalized root, run your current 2-channel PARM engine; if the extremal-ordering shortcut is not yet proven, restrict exact enumeration to short roots and use heuristic/fallback logic for longer forms.
4. **Rank and export**
Output:
    - `root_frequency_metrics.csv`
    - `root_frequency_metrics.json`
    - optionally a dashboard-ready table for live exploration
5. **Visualize frequency vs resonance**
Suggested plots:
    - $RQ_s$ vs frequency
    - $RQ_n$ vs frequency
    - $C$ vs frequency
    - bubble chart: $(RQ_s, RQ_n)$, bubble size = corpus frequency

## Mathematical and theoretical value

This extension is strong because it lets PARM answer a deeper question than “what is the resonance of this root?” It asks: **which resonant structures are actually central in the corpus?** That matters because the paper’s current empirical sweep is small and deliberately polarized; a frequency analyzer moves you toward distributional validation over the Hebrew Bible itself.[^2]

It also creates a bridge between:

- PARM as a structural engine,
- lexicons as semantic reference systems,
- corpus frequency as usage salience.

That combination is much closer to what peer reviewers or external analysts will recognize as a serious linguistic study.

## Risks and failure points

The main implementation risks are lexical alignment problems rather than PARM math:

- OSHB lemmas may not map cleanly one-to-one to BHSA root entries.[^2]
- Some entries will be forms, not roots; you’ll need a normalization policy.
- Homographs may collapse distinct senses into one root bucket.
- Final forms and orthographic variants must be normalized consistently before PARM mapping.

So the analyzer should explicitly emit:

- unmatched lemmas,
- ambiguous mappings,
- normalized-vs-original spelling columns,
- mapping confidence flags.

That will save you from silent lexicon drift.

## Recommended outputs

The minimum useful outputs are:

- **CSV table** with columns like
`label, hebrew, corpus_freq, rq_shape, rq_num, c, delta, ratio, v_shape_actual, v_shape_min, v_shape_max, v_num_actual, v_num_min, v_num_max`
- **Top-k reports**:
    - top 100 by frequency
    - top 100 by $C$
    - top 100 by frequency-weighted $C$
    - bottom 100 by $C$
- **Dashboard feed** for your PARM visualizer


## Best immediate build

The fastest implementation path is:

- Start with **OSHB-only lemma counts** first, because the morphology repository already exposes lemma-tagged words across the Hebrew Bible.[^2]
- Then add **BHSA lexicon linking** as a second phase for richer normalization and metadata.

That gives you a usable analyzer quickly, even before perfect lexicon reconciliation.

If you want, I can next draft the **data schema and module layout** for this Corpus-Scale Frequency Analyzer so you can implement it directly in your PARM codebase.

<div align="center">⁂</div>

[^1]: https://github.com/openscriptures/HebrewLexicon

[^2]: Position_Aware_Recursive_Multiplicity__PARM__for_Hebrew_Roots.pdf

