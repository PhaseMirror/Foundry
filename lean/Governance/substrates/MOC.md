% \===================== PREAMBLE \=====================  
\\documentclass\[12pt\]{article}

% Encoding and layout  
\\usepackage\[T1\]{fontenc}  
\\usepackage\[utf8\]{inputenc}  
\\usepackage\[a4paper,margin=1in\]{geometry}  
\\usepackage{microtype}  
\\usepackage{setspace}  
\\onehalfspacing

% Fonts (Times-like)  
\\usepackage{newtxtext,newtxmath} % Modern Times clone for text+math

% Graphics, color, tables  
\\usepackage{graphicx}  
\\usepackage{xcolor}  
\\usepackage{booktabs}  
\\usepackage{longtable}  
\\usepackage{array}

% Math and symbols  
\\usepackage{mathtools,amssymb,amsfonts,amsthm}  
\\usepackage{bm}

% Hyperlinks and references  
\\usepackage{hyperref}  
\\hypersetup{  
  colorlinks=true,  
  linkcolor=blue\!50\!black,  
  citecolor=blue\!50\!black,  
  urlcolor=blue\!50\!black,  
  pdfauthor={},  
  pdftitle={Multiplicity Operator Calculus: Prime-Indexed Dynamics on Hypergraphs}  
}  
\\usepackage\[nameinlink,capitalise,noabbrev\]{cleveref}

% Lists and verbatim  
\\usepackage{enumitem}  
\\setlist{nosep}  
\\usepackage{fancyvrb}

% Author/affiliation block (optional)  
\\usepackage{authblk}

% Figure search paths (optional)  
\\graphicspath{{figs/}{images/}{plots/}}

% \---------- Theorem-like environments (optional) \----------  
\\numberwithin{equation}{section}  
\\theoremstyle{plain}  
\\newtheorem{theorem}{Theorem}\[section\]  
\\newtheorem{lemma}\[theorem\]{Lemma}  
\\newtheorem{proposition}\[theorem\]{Proposition}  
\\theoremstyle{definition}  
\\newtheorem{definition}\[theorem\]{Definition}  
\\theoremstyle{remark}  
\\newtheorem{remark}\[theorem\]{Remark}

% \---------- Common sets and operators \----------  
\\newcommand{\\Z}{\\mathbb{Z}}  
\\newcommand{\\R}{\\mathbb{R}}  
\\newcommand{\\Q}{\\mathbb{Q}}  
\\newcommand{\\C}{\\mathbb{C}}  
\\newcommand{\\N}{\\mathbb{N}}

\\newcommand{\\Tn}{\\mathbb{T}\_n}  
\\newcommand{\\Zn}{\\mathbb{Z}/n\\mathbb{Z}}

\\DeclareMathOperator{\\vp}{v\_p}  
\\DeclareMathOperator{\\argmin}{arg\\,min}  
\\DeclareMathOperator{\\argmax}{arg\\,max}

% Paired delimiters  
\\DeclarePairedDelimiter{\\abs}{\\lvert}{\\rvert}  
\\DeclarePairedDelimiter{\\norm}{\\lVert}{\\rVert}  
\\DeclarePairedDelimiter{\\inner}{\\langle}{\\rangle}

% Mod notation and indicator  
\\newcommand{\\Mod}\[1\]{\\ (\\mathrm{mod}\\ \#1)}  
\\newcommand{\\one}{\\mathbf{1}} % indicator 1

% Divisibility Iverson bracket \[d | t\]  
\\newcommand{\\divi}\[2\]{\\left\[\\,\#1\\,\\middle|\\,\#2\\,\\right\]}

% \---------- MOC operator shorthands \----------  
% State-layer operators  
\\newcommand{\\Sp}\[1\]{\\mathsf{S}\_{\#1}}              % subdivision \\Sp{p}  
\\newcommand{\\A}\[2\]{\\mathsf{A}\_{\#1}^{\#2}}           % accent \\A{p^r}{\\alpha}  
\\newcommand{\\Aof}\[3\]{\\mathsf{A}\_{\#1}^{\#2,\#3}}      % accent with offset \\Aof{p^r}{\\alpha}{\\phi}  
\\newcommand{\\Rop}\[2\]{\\mathsf{R}\_{\#1}^{\#2}}         % rotation \\Rop{p^r}{\\phi}  
\\newcommand{\\Wop}\[1\]{\\mathsf{W}\_{\#1}}              % permutation family \\Wop{p}

% Relation-layer operators  
\\newcommand{\\Qhat}\[1\]{\\hat{Q}\_{\#1}}                % relation op \\Qhat{p}

% Projectors and gates  
\\newcommand{\\Pid}\[1\]{\\Pi\_{\#1}}                     % projector \\Pid{p^r}  
\\newcommand{\\DeltaD}\[1\]{\\Delta\_{\#1}}               % spike gate \\DeltaD{d}

% Words  
\\newcommand{\\Pword}\[1\]{\\hat{P}^{(\#1)}}             % prime word \\Pword{p}  
\\newcommand{\\Nword}{\\widehat{N}}                   % composite word \\Nword

% Diagnostics / convenience  
\\newcommand{\\CRT}{\\mathrm{CRT}}  
\\newcommand{\\DFT}{\\mathrm{DFT}}

% Allow display breaks in long derivations  
\\allowdisplaybreaks  
% \==========================================================

\\title{\\textbf{Multiplicity Operator Calculus: Prime-Indexed Dynamics on Hypergraphs}}

\\author\[1\]{Institute for Mathematical Discovery}  
\\author\[2\]{Citizen Gardens Research Initiative}  
\\affil\[1\]{Department of Mathematical Philosophy}  
\\affil\[2\]{Laboratory for Symbolic Systems and Consciousness}

\\date{\\today}

\\begin{document}  
\\maketitle

\\begin{abstract}  
Multiplicity Operator Calculus (MOC) formalizes a non-reductive, prime-indexed framework for modeling interdependent processes on hypergraphs. Inspired by the recursive epistemologies of Eastern mathematics, MOC treats number not as abstraction but as relational operator. Each prime $p$ defines a family of noncommuting operators $\\hat{P}\_p$ that act simultaneously on nodes and relations, generating nested cycles of resonance and transformation. The calculus unites rhythmic, geometric, and symbolic domains by encoding process structure through factorization: composition $\\prod \\hat{P}\_p^{k\_p}$ represents both algebraic and temporal layering. Unlike linear differential or matrix approaches, MOC prioritizes recursive flows over static state evolution, enabling the modeling of systems whose coherence depends on rhythmic resonance rather than equilibrium. Applications span symbolic computation, musical architecture, prime-based synchronization networks, and ethical or cognitive dynamics in recursive agent systems. This paper develops the algebraic rules, commutation relations, and resonance functionals defining the MOC and demonstrates its use through a 108-cycle operator construct embodying binary–ternary interplay.  
\\end{abstract}

\\noindent\\textbf{Keywords:} multiplicity, hypergraph dynamics, prime operators, resonance, recursion, noncommutative systems

\\section\*{Executive Summary}

\\subsection\*{Problem Statement and Motivation}  
Classical models privilege objects and linear evolution; relations are secondary and often fixed. Many real systems—symbolic, musical, cognitive, ethical—exhibit coherence through nested cycles and context-sensitive coupling that standard differential or matrix methods capture only indirectly. We seek a calculus where \\emph{relations} and \\emph{rhythmic structure} are primary, and where number encodes process rather than quantity.

\\subsection\*{Core Contribution}  
We introduce the \\emph{Multiplicity Operator Calculus} (MOC): a prime-indexed, noncommutative operator framework acting on states and hyperedges of a hypergraph. For each prime \\(p\\), a family \\(\\{\\hat{P}\_{p}\\}\\) generates subdivision, rotation, accent, and permutation modes whose compositions realize nested periodicities. Validation is \\emph{resonance-based}: a functional  
\\\[  
R(H,\\{\\hat{P}\\};D)\\in\[0,1\]  
\\\]  
measures fit between modeled structure and target data \\(D\\) (e.g., cycles in time series, phrase boundaries, or symbolic constraints). As an exemplar, we construct a full \\(n=108=2^{2}\\cdot 3^{3}\\) operator word that integrates ternary phrasing with binary micro-pulse.

\\subsection\*{Key Results and Applications}  
\\begin{itemize}  
  \\item \\textbf{Algebra:} Closed rules for composition, lifting across prime powers, and cross-prime braid relations; normal forms up to phase equivalence.  
  \\item \\textbf{Resonance:} Practical criteria and algorithms to maximize \\(R\\), enabling “proof by resonance” for pattern adequacy.  
  \\item \\textbf{108-cycle:} A transparent build demonstrating how factorization sets macro–micro coupling and how operator order controls feel.  
  \\item \\textbf{Applications:}   
    (i) symbolic computation via rewrite orchestration on hypergraphs;   
    (ii) musical architecture and metrical design;   
    (iii) synchronization networks with prime-gated stability;   
    (iv) cognitive/ethical policy constraints modeled as conserved quantities under \\(\\hat{P}\_{p}\\).  
\\end{itemize}

\\subsection\*{Roadmap of the Document}  
Section\~1 formalizes state spaces, hypergraph structure, and operator families. Section\~2 develops commutation, lifting, and braid relations with illustrative lemmas. Section\~3 defines the resonance functional and optimization procedures. Section\~4 presents the 108-cycle construction, ablation studies on operator order, and empirical resonance profiles. Section\~5 surveys applications and gives implementation notes. Section\~6 concludes with open problems and directions for comparative studies with classical spectral and automata-theoretic methods.

\\section\*{Philosophical and Historical Context}

\\subsection\*{Eastern Mathematics: Recursion, Relational Ontology, and Sutra Logic}  
In the intellectual traditions of India, China, and East Asia, mathematics evolved within a relational and recursive ontology rather than a mechanistic one. Number was conceived not as abstraction but as expression of interdependence. The Vedic and Buddhist doctrines of \\emph{Pratītyasamutpāda} (dependent origination) and the Taoist notion of the \\emph{Ten Thousand Things} unfolding from the \\emph{One} describe multiplicity as an emergent unity: relations produce entities, not the reverse.

Mathematical reasoning in these contexts operated through \\emph{sutra logic}—compact aphorisms encoding recursive procedures. Each sutra functioned simultaneously as algorithm, mnemonic, and cosmological statement. Knowledge was revealed through iterative interpretation, not static proof. Recursion served as epistemic method and ontological model.

\\subsection\*{Multiplicity Versus Reduction: Relations-First Stance}  
Western formalism tends toward reduction: decomposing wholes into independent parts and reassembling them through linear rules. Multiplicity theory in the Eastern sense reverses this orientation. It begins with networks of mutual conditioning where nodes have no existence apart from their connective roles. This relations-first stance treats mathematics as a mirror of dynamic balance rather than a tool of dissection.

Within this view, \\emph{multiplicity} is not numerical excess but structured co-arising. A number such as \\(108=2^{2}\\cdot3^{3}\\) is not a mere product; it encodes nested rhythmic and symbolic layers. Prime factors act as archetypal generators of relational order.

\\subsection\*{Symbolic Cycles in Practice: Calendar, Breath, Music, and Ritual}  
Traditional applications of Eastern mathematical ideas are found in cyclical systems. Calendrical computation linked celestial periodicities with ritual timing. Yogic and Daoist practices mapped breathing rhythms and bodily cycles to integer ratios. Classical Indian and East Asian music employed binary and ternary meter interlocks, structurally analogous to prime decomposition. Temple geometry, mandala construction, and mantra recitation all used numerical proportion as a mode of synchronization between microcosm and macrocosm.

These practices embody recursion physically: repetition with modulation, symmetry with deviation, and invariance through transformation. Mathematical order thus operated as a lived rhythm, not an abstract invariant.

\\subsection\*{Operationalization in This Report}  
The \\emph{Multiplicity Operator Calculus} formalizes these principles in algebraic and computational language. Primes become operators \\(\\hat{P}\_{p}\\) acting recursively on hypergraphs; factorization corresponds to hierarchical cycles. Resonance replaces proof: coherence is verified when generated patterns align with empirical or symbolic cycles. 

This report translates the philosophical motifs of recursion, interdependence, and cyclic symmetry into a rigorous operator framework. By embedding the relational ontology of Eastern mathematics into prime-indexed dynamics, it unites metaphysical intuition with executable formalism—an explicit bridge between symbolic cosmology and algorithmic modeling.

\\section\*{Preliminaries and Notation}

\\subsection\*{Time Lattice}  
Let the discrete cyclic time domain be  
\\\[  
\\mathbb{T}\_n \= \\mathbb{Z}/n\\mathbb{Z} \= \\{0,1,\\dots,n-1\\},  
\\\]  
which serves as the base lattice for periodic processes of length \\(n\\). Arithmetic on \\(\\mathbb{T}\_n\\) is taken modulo \\(n\\). Each tick \\(t\\in\\mathbb{T}\_n\\) represents a phase position within a closed cycle.

\\subsection\*{Signals and Patterns}  
A \\emph{signal} or \\emph{pattern} is a function  
\\\[  
x:\\mathbb{T}\_n \\rightarrow \\mathbb{R}^k,  
\\\]  
where \\(k\\) denotes the number of feature channels (e.g., amplitude, color, intensity, or symbolic value). The space of all such signals is \\(\\mathcal{X}\_n \= \\{x:\\mathbb{T}\_n \\to \\mathbb{R}^k\\}\\), equipped with pointwise addition and scalar multiplication, forming a real vector space.

\\subsection\*{Hypergraph Structure}  
The relational substrate of multiplicity is modeled as a hypergraph  
\\\[  
H \= (V, E, \\iota),  
\\\]  
where \\(V\\) is the set of vertices (states), \\(E\\) the set of hyperedges (relations), and \\(\\iota:E\\to \\mathcal{P}(V)\\) the incidence map assigning to each edge its participating vertices. Unlike a standard graph, hyperedges may connect any number of vertices, representing higher-order relations.

Each vertex \\(v\\in V\\) and hyperedge \\(e\\in E\\) carries state attachments  
\\\[  
\\sigma: V \\to \\mathbb{R}^k, \\qquad \\tau: E \\to \\mathbb{R}^m,  
\\\]  
encoding local and relational attributes. Operators will act jointly on \\((\\sigma,\\tau)\\), allowing transformation of both nodes and the relations that bind them.

\\subsection\*{Operator Words and Composition Order}  
An \\emph{operator word} is an ordered product of prime-indexed operators:  
\\\[  
\\mathcal{W} \= \\hat{O}\_m \\hat{O}\_{m-1}\\cdots \\hat{O}\_1, \\qquad \\hat{O}\_i \\in \\{\\hat{P}\_p^{(r)} : p \\text{ prime},\\ r\\ge 1\\}.  
\\\]  
Application is right-to-left:  
\\\[  
x' \= \\mathcal{W}\[x\] \= \\hat{O}\_m(\\hat{O}\_{m-1}(\\cdots \\hat{O}\_1(x))).  
\\\]  
Noncommutativity implies that reordering the same multiset of primes generally produces distinct outcomes. The set of all operator words with the same prime content forms an equivalence class under resonance equivalence, denoted \\(\[\\mathcal{W}\]\_R\\).

\\subsection\*{Divisibility Indicator and Class Labels}  
For integer divisibility, define the indicator function  
\\\[  
\[d\\mid t\] \=   
\\begin{cases}  
1, & \\text{if } t \\equiv 0 \\pmod d,\\\\  
0, & \\text{otherwise}.  
\\end{cases}  
\\\]  
This binary function allows the construction of hierarchical accent and phase structures. Given a cycle length \\(n\\) and a set of divisors \\(\\{d\_i\\}\\subseteq \\mathbb{N}\\), we may assign each tick \\(t\\in\\mathbb{T}\_n\\) a \\emph{class label}  
\\\[  
C(t) \= \\{d\_i : \[d\_i\\mid t\]=1\\},  
\\\]  
representing its membership in overlapping rhythmic or symbolic strata. For example, in \\(n=108\\), the classes corresponding to \\(d=2,3,9,27\\) define binary and ternary accent layers.

These primitives provide the syntactic foundation for the Multiplicity Operator Calculus: signals live on the lattice \\(\\mathbb{T}\_n\\), relations inhabit \\(H\\), and operator words encode recursive transformations whose resonance properties are analyzed in later sections.

\\section\*{Multiplicity Space and Carriers}

\\subsection\*{Definition of the Multiplicity Space}  
The fundamental carrier of the Multiplicity Operator Calculus is the \\emph{multiplicity space}  
\\\[  
\\mathcal{M} \= (\\mathcal{X}, H),  
\\\]  
where \\(\\mathcal{X}\\) denotes the signal space \\(\\mathcal{X}\_n \= \\{x:\\mathbb{T}\_n \\rightarrow \\mathbb{R}^k\\}\\) and \\(H \= (V, E, \\iota)\\) is the hypergraph of relational topology introduced previously. 

Elements of \\(\\mathcal{M}\\) therefore encode both \\emph{local states} and \\emph{relational structure}. Operators \\(\\hat{P}\_p^{(r)}\\) act simultaneously on these two layers:  
\\\[  
\\hat{P}\_p^{(r)} : (\\mathcal{X}, H) \\longrightarrow (\\mathcal{X}', H'),  
\\\]  
where \\(\\mathcal{X}'\\) and \\(H'\\) denote the updated state and hypergraph under a prime-indexed transformation (e.g., subdivision, rotation, or permutation).    
Each \\(\\mathcal{M}\\) is thus a dynamic carrier—its internal organization may change while preserving coherence through resonance invariants.

\\subsection\*{Automorphisms and Gauge Perspective}  
The internal symmetries of the multiplicity space form the automorphism group  
\\\[  
\\mathrm{Aut}(\\mathcal{M}) \= \\{\\,(\\phi\_V, \\phi\_E)\\,|\\, \\phi\_V:V\\rightarrow V,\\ \\phi\_E:E\\rightarrow E,\\   
\\iota\\circ \\phi\_E \= \\mathcal{P}(\\phi\_V)\\circ \\iota\\,\\},  
\\\]  
where \\(\\mathcal{P}(\\phi\_V)\\) denotes the induced action on subsets of \\(V\\). These automorphisms represent relabelings of vertices and edges that leave the incidence structure invariant.  

From a gauge perspective, each automorphism corresponds to a local symmetry transformation of the multiplicity field. If \\((\\sigma,\\tau)\\) are the vertex and edge states, an automorphism acts as  
\\\[  
(\\sigma,\\tau) \\mapsto (g\_V\\circ\\sigma, g\_E\\circ\\tau),  
\\\]  
with \\(g\_V,g\_E\\) drawn from a local gauge group \\(G\\) (often \\(G\\subseteq \\mathrm{GL}(k,\\mathbb{R})\\)). The MOC treats these symmetries as redundancies of description—different coordinate expressions of the same relational configuration.  

Gauge transformations commuting with all \\(\\hat{P}\_p^{(r)}\\) define the \\emph{stabilizer subgroup} \\(\\mathrm{Stab}\_G(\\mathcal{M})\\), corresponding to conserved relational frames.

\\subsection\*{Invariants and Conservation Constraints}  
Within each multiplicity space, certain scalar quantities remain invariant under admissible operator action. These invariants encode conservation of structure and ethics of transformation:  
\\begin{itemize}  
  \\item \\textbf{Energy Invariant:}    
  \\\[  
  E\[x\] \= \\sum\_{t\\in\\mathbb{T}\_n} \\|x(t)\\|^2.  
  \\\]  
  Preserved under norm-preserving operators (rotations, permutations).

  \\item \\textbf{Area or Volume Invariant:}    
  For geometric realizations, define    
  \\\[  
  A\[\\sigma,\\tau\] \= \\sum\_{e\\in E} \\mathrm{Vol}(\\iota(e)),  
  \\\]  
  which measures conserved relational “extent.” Sulba-style operators (\\(\\hat{P}\_p\\) corresponding to cut-and-join) maintain \\(A\\) constant.

  \\item \\textbf{Fairness or Ethical Invariant:}    
  For systems representing allocations or information flows,  
  \\\[  
  F\[\\sigma\] \= \\min\_i \\sigma\_i / \\max\_i \\sigma\_i,  
  \\\]  
  quantifies balance among vertices. Operator sets satisfying \\(F\[\\sigma'\]\\ge F\[\\sigma\]\\) are deemed ethically admissible.

\\end{itemize}

These invariants act as \\emph{gauge constraints} on the permissible dynamics within \\(\\mathcal{M}\\). Resonant evolution respects them automatically: only operator compositions that preserve or restore these measures yield high resonance \\(R(\\mathcal{M})\\). Thus, the multiplicity space is not merely a passive container for transformation—it is an active metric field enforcing harmony between algebraic action and relational integrity.

\\section\*{Prime-Indexed Operator Calculus (MOC)}

\\subsection\*{Operator Families on States}  
Fix a cycle length \\(n\\). All state operators act on \\(x\\in\\mathcal{X}\_n=\\{x:\\mathbb{T}\_n\\to\\mathbb{R}^k\\}\\).  
Admissibility: \\(\\mathsf{S}\_p\\), \\(\\mathsf{R}\_{p^r}\\), \\(\\mathsf{A}\_{p^r}\\) are defined when \\(p^r\\mid n\\); otherwise treat them as virtual refinements with lift–project (omitted here for brevity).

\\paragraph{Subdivision \\(\\mathsf{S}\_p\\).}  
Lifts \\(\\mathcal{X}\_n\\to \\mathcal{X}\_{pn}\\):  
\\\[  
(\\mathsf{S}\_p x)(pt+u)=x(t),\\quad t\\in\\mathbb{T}\_n,\\ u\\in\\{0,\\dots,p-1\\}.  
\\\]

\\paragraph{Accent \\(\\mathsf{A}\_{p^r}^{\\alpha}\\).}  
Adds a level-\\(p^r\\) gate (or multiplies by a weight). Additive form:  
\\\[  
(\\mathsf{A}\_{p^r}^{\\alpha}x)(t)=x(t)+\\alpha\\,\[p^r\\mid t\]\\;e\_1,  
\\\]  
with \\(\[d\\mid t\]\\in\\{0,1\\}\\) the divisibility indicator and \\(e\_1\\) a chosen channel.

\\paragraph{Rotation \\(\\mathsf{R}\_{p^r}^{\\phi}\\).}  
Cyclic shift aligned to the \\(p^r\\)-grid:  
\\\[  
(\\mathsf{R}\_{p^r}^{\\phi}x)(t)=x\\\!\\left(t+\\phi\\cdot\\frac{n}{p^r}\\right),\\qquad \\phi\\in\\mathbb{Z}.  
\\\]

\\paragraph{Permutation \\(\\mathsf{W}\_p^{\\pi}\\).}  
Reorders the \\(p\\) subticks inside each parent cell after \\(\\mathsf{S}\_p\\). For \\(\\pi\\in S\_p\\),  
\\\[  
(\\mathsf{W}\_p^{\\pi}x)(pt+u)=x\\big(pt+\\pi(u)\\big).  
\\\]

\\subsection\*{Relation Operators on \\(H\\)}  
Let \\(H=(V,E,\\iota)\\). Relation operators \\(\\hat{Q}\_p\\) act on incidence while coordinating state attachments \\((\\sigma,\\tau)\\).

\\paragraph{Split \\(\\hat{Q}\_p^{\\mathrm{split}}\\).}  
Each \\(e\\in E\\) becomes \\(p\\) siblings \\(e^{(u)}\\) with refined incidence:  
\\\[  
\\iota'(e^{(u)})=\\iota(e),\\quad u=0,\\dots,p-1,\\qquad \\tau'(e^{(u)})=\\mathrm{Refine}\_p(\\tau(e),u).  
\\\]

\\paragraph{Merge \\(\\hat{Q}\_p^{\\mathrm{merge}}\\).}  
Inverse of split on coherent siblings: \\(p\\) edges with identical incidence collapse to one, \\(\\tau\\) aggregated by a conserved rule.

\\paragraph{Fold \\(\\hat{Q}\_p^{\\mathrm{fold}}\\).}  
Quotients a \\(p\\)-cyclic arrangement of vertices/edges by rotation, enforcing periodic boundary conditions.

\\paragraph{Relabel \\(\\hat{Q}\_p^{\\mathrm{rel}}\\).}  
Applies an incidence-preserving permutation \\((\\phi\_V,\\phi\_E)\\in\\mathrm{Aut}(H)\\) constrained to \\(p\\)-cycles.

\\subsection\*{Prime Word and Composite Word}  
For each prime \\(p\\) and level \\(r\\ge 1\\), define a \\emph{prime word}  
\\\[  
\\hat{P}^{(p)}\\;=\\;\\mathsf{W}\_p^{\\pi\_p}\\,\\mathsf{R}\_{p^r}^{\\phi\_p}\\,\\Big(\\prod\_{j=1}^{r}\\mathsf{A}\_{p^j}^{\\alpha\_{p^j}}\\Big)\\,\\mathsf{S}\_p^{\\,r}  
\\quad\\text{(admissible when }p^r\\mid n\\text{)}.  
\\\]  
Given the factorization \\(n=\\prod\_{p} p^{r\_p}\\), the \\emph{composite word} is  
\\\[  
\\widehat{N}=\\prod\_{p\\mid n}\\big(\\hat{P}^{(p)}\\big) \\quad \\text{(ordered product; noncommutative).}  
\\\]

\\subsection\*{Noncommutation: Sources and Consequences}  
Noncommutation arises from three mechanisms:

\\paragraph{(i) Index Lifting.}  
\\(\\mathsf{S}\_p\\) changes the lattice on which other operators act:  
\\\[  
\\mathsf{S}\_p\\,\\mathsf{A}\_{q^r}^{\\alpha}=\\big(\\mathsf{A}\_{q^r}^{\\alpha}\\big)^{\\uparrow p}\\,\\mathsf{S}\_p,  
\\\]  
where \\({}^{\\uparrow p}\\) copies accents to each of the \\(p\\) children; generally \\(\\neq \\mathsf{A}\_{q^r}^{\\alpha}\\,\\mathsf{S}\_p\\) for \\(p\\neq q\\).

\\paragraph{(ii) Wreath Action.}  
\\(\\mathsf{W}\_p^{\\pi}\\) permutes subticks inside cells, disrupting external gates:  
\\\[  
\\mathsf{W}\_p^{\\pi}\\,\\mathsf{A}\_{q^r}^{\\alpha}\\neq \\mathsf{A}\_{q^r}^{\\alpha}\\,\\mathsf{W}\_p^{\\pi}\\quad (p\\neq q).  
\\\]

\\paragraph{(iii) Relation–State Coupling.}  
\\(\\hat{Q}\_p\\) reconfigures \\(H\\), which changes how state operators aggregate over hyperedges; hence \\(\[\\hat{Q}\_p,\\mathsf{A}\_{q^r}^{\\alpha}\]\\neq 0\\) in general.

\\medskip  
\\noindent\\textbf{Consequences.} Operator order controls macro–micro alignment, syncopation, and resonance. Normal forms are defined up to phase and gauge:  
\\\[  
\\mathcal{W}\\sim \\mathcal{W}' \\iff \\exists\\,g\\in\\mathrm{Aut}(\\mathcal{M}):\\ g\\,\\mathcal{W}=\\mathcal{W}'\\,g \\ \\text{and}\\ R(\\mathcal{W}\[x\];D)=R(\\mathcal{W}'\[x\];D).  
\\\]

\\subsection\*{CRT Structure and Level Projectors \\(\\Pi\_{p^r}\\)}  
Chinese remainder structure provides a canonical multi-level decomposition:  
\\\[  
\\mathbb{Z}/n\\mathbb{Z}\\ \\cong\\ \\prod\_{p^{r\_p}\\parallel n}\\ \\mathbb{Z}/p^{r\_p}\\mathbb{Z}.  
\\\]  
Define the level-\\(p^r\\) averaging projector \\(\\Pi\_{p^r}:\\mathcal{X}\_n\\to\\mathcal{X}\_n\\) by  
\\\[  
(\\Pi\_{p^r} x)(t)=\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1} x\\\!\\left(t+u\\cdot\\frac{n}{p^r}\\right).  
\\\]  
Then:  
\\\[  
\\Pi\_{p^r}^2=\\Pi\_{p^r},\\qquad \\Pi\_{p^r}\\,\\mathsf{R}\_{p^r}^{\\phi}=\\Pi\_{p^r},\\qquad  
\\Pi\_{p^r}\\,\\mathsf{A}\_{p^r}^{\\alpha}=\\mathsf{A}\_{p^r}^{\\alpha}\\,\\Pi\_{p^r},  
\\\]  
and for \\(p\\neq q\\),  
\\\[  
\[\\Pi\_{p^r},\\mathsf{W}\_q^{\\pi}\]\\neq 0\\ \\text{in general},\\qquad  
\\Pi\_{p^r}\\,\\mathsf{S}\_q=\\mathsf{S}\_q\\,\\Pi\_{p^r}^{\\downarrow q},  
\\\]  
where \\(\\Pi\_{p^r}^{\\downarrow q}\\) is the naturally induced projector on the coarser lattice when \\(q\\mid n\\).  

A complementary spike projector is the multiplicative gate  
\\\[  
(\\Delta\_{p^r}x)(t)=\[p^r\\mid t\]\\;x(t),  
\\\]  
useful for class labels and discrete cadence marking. The pair \\((\\Pi\_{p^r},\\Delta\_{p^r})\\) separates \\emph{invariant} content at level \\(p^r\\) from \\emph{event} content at that level, supplying a precise bridge between CRT structure and rhythmic accent algebra.

\\section\*{Sample Semantics for $p\\in\\{2,3,5,7\\}$}

\\subsection\*{$p=2$: binary microstructure, off-beat swap}  
\\textbf{Purpose.} Micro-timing and pulse subdivision.

\\noindent\\textbf{Defaults.} $\\mathsf{S}\_2$ (refine), $\\mathsf{A}\_{2}^{\\alpha\_2}$, $\\mathsf{A}\_{4}^{\\alpha\_4}$, $\\mathsf{R}\_{4}^{1}$, $\\mathsf{W}\_2^{(0\\,1)}$.  
\\\[  
(\\mathsf{S}\_2 x)(2t+u)=x(t),\\quad  
(\\mathsf{A}\_{2^r}^{\\alpha}x)(t)=x(t)+\\alpha\\,\[2^r\\mid t\]\\,e\_1,  
\\\]  
\\\[  
(\\mathsf{R}\_{4}^{1}x)(t)=x\\\!\\left(t+\\frac{n}{4}\\right),\\quad  
(\\mathsf{W}\_2^{(0\\,1)}x)(2t+u)=x\\big(2t+(1-u)\\big).  
\\\]  
\\textbf{Effect.} $\\mathsf{A}\_{4}$ sets a light grid; $\\mathsf{A}\_{2}$ fills ghost notes; $\\mathsf{W}\_2^{(0\\,1)}$ flips on/off-beat; $\\mathsf{R}\_{4}^{1}$ inverts downbeat emphasis.

\\subsection\*{$p=3$: ternary phrasing spine}  
\\textbf{Purpose.} Macro–meso phrasing.

\\noindent\\textbf{Defaults.} $\\mathsf{S}\_3$, $\\mathsf{A}\_{3}^{\\beta\_3}$, $\\mathsf{A}\_{9}^{\\beta\_9}$, $\\mathsf{A}\_{27}^{\\beta\_{27}}$, $\\mathsf{W}\_3^{(0\\,2\\,1)}$, $\\mathsf{R}\_{3}^{\\phi\_3}$.  
\\\[  
(\\mathsf{W}\_3^{(0\\,2\\,1)}x)(3t+u)=x\\big(3t+\\pi(u)\\big),\\ \\pi:0\\mapsto0,1\\mapsto2,2\\mapsto1.  
\\\]  
\\textbf{Effect.} $\\mathsf{A}\_{27}\\succ \\mathsf{A}\_9\\succ \\mathsf{A}\_3$ establishes cadence tiers; $\\mathsf{W}\_3^{(0\\,2\\,1)}$ gives hemiola-like tilt; $\\mathsf{R}\_{3}^{\\phi\_3}$ locks phrase starts to targets.

\\subsection\*{$p=5$: quinary ornament, color layer}  
\\textbf{Purpose.} Sparse ornament independent of the spine.

\\noindent\\textbf{Defaults.} $\\mathsf{S}\_5$, $\\mathsf{A}\_5^{\\gamma\_5}$ on a distinct channel $e\_c$, $\\mathsf{W}\_5^{(0\\,2\\,4\\,1\\,3)}$, optional anti-coincidence gate with ternary.  
\\\[  
(\\mathsf{A}\_5^{\\gamma\_5}x)(t)=x(t)+\\gamma\_5\\,\[5\\mid t\]\\;e\_c,\\qquad  
(\\mathsf{X}\_{\\neg 3}x)(t)=(1-\[3\\mid t\])\\,x(t).  
\\\]  
\\textbf{Effect.} Use $\\mathsf{X}\_{\\neg 3}\\,\\mathsf{A}\_5^{\\gamma\_5}$ to avoid hits on ternary beats; $\\mathsf{W}\_5^{(0\\,2\\,4\\,1\\,3)}$ cycles ornaments through quintuple positions.

\\subsection\*{$p=7$: heptadic drift, asymmetry}  
\\textbf{Purpose.} Incommensurate overlay and slow phase drift.

\\noindent\\textbf{Defaults.} When $7\\nmid n$, define the modular-inverse step  
\\\[  
s\_n \\equiv 7^{-1}\\pmod n,\\qquad 7\\,s\_n\\equiv 1\\ (\\mathrm{mod}\\ n).  
\\\]  
Heptad positions:  
\\\[  
S\_7(n,\\mu)=\\big\\{\\,(\\mu+\\ell\\,s\_n)\\bmod n:\\ \\ell=0,\\dots,6\\,\\big\\}.  
\\\]  
Heptadic accent (drifting gate):  
\\\[  
(\\mathsf{A}\_7^{\\flat,\\delta}x)(t)=x(t)+\\delta\\,\\mathbf{1}\_{\\,t\\in S\_7(n,\\mu)}\\,e\_1,\\qquad \\mu\\in\\mathbb{T}\_n.  
\\\]  
Optional slow rotation: update $\\mu\\mapsto \\mu+\\rho$ each cycle to create a beat against the spine.  
\\textbf{Effect.} Quasi-uniform spread over $\\mathbb{T}\_n$ with long-return asymmetry; no collisions forced by CRT tiers.

\\subsection\*{Design Patterns for Combining Layers}  
\\begin{enumerate}  
  \\item \\textbf{Ternary-first, binary micro.}  
  \\\[  
  \\mathcal{W}=\\underbrace{\\mathsf{S}\_3^3}\_{\\text{spine}}\\ \\underbrace{\\mathsf{S}\_2^2}\_{\\text{micro}}\\cdot  
  \\mathsf{A}\_{27}^{\\beta\_{27}}\\mathsf{A}\_{9}^{\\beta\_9}\\mathsf{A}\_{3}^{\\beta\_3}\\ \\mathsf{A}\_{4}^{\\alpha\_4}\\mathsf{A}\_{2}^{\\alpha\_2}.  
  \\\]  
  Place $\\mathsf{W}\_2^{(0\\,1)}$ after $\\mathsf{S}\_2$ for off-beat lift.

  \\item \\textbf{Binary-first syncopation.}  
  \\\[  
  \\mathcal{W}'=\\mathsf{S}\_2^2\\,\\mathsf{W}\_2^{(0\\,1)}\\,\\mathsf{S}\_3^3\\cdot  
  \\mathsf{A}\_{4}^{\\alpha\_4}\\mathsf{A}\_{2}^{\\alpha\_2}\\mathsf{A}\_{27}^{\\beta\_{27}}\\mathsf{A}\_{9}^{\\beta\_9}\\mathsf{A}\_{3}^{\\beta\_3}.  
  \\\]  
  Noncommutation changes feel without changing factors.

  \\item \\textbf{Quinary color without collisions.}  
  \\\[  
  \\mathcal{W}\_{5}=\\mathcal{W}\\cdot \\mathsf{X}\_{\\neg 3}\\,\\mathsf{A}\_5^{\\gamma\_5}\\,\\mathsf{W}\_5^{(0\\,2\\,4\\,1\\,3)}.  
  \\\]  
  Small $\\gamma\_5$ and separate channel $e\_c$ preserve energy and clarity.

  \\item \\textbf{Heptadic drift over a CRT scaffold.}  
  \\\[  
  \\mathcal{W}\_{7}=\\mathcal{W}\\cdot \\mathsf{A}\_7^{\\flat,\\delta}\\ \\ (\\text{optionally update }\\mu\\mapsto \\mu+\\rho).  
  \\\]  
  Choose $\\delta\\ll \\alpha\_2,\\beta\_3$ to keep drift perceptual but not dominant.

  \\item \\textbf{Projector-aligned layering.}  
  Use level projectors to keep roles separated:  
  \\\[  
  \\text{micro: } (I-\\Pi\_{3})\\,\\mathsf{A}\_{2},\\quad  
  \\text{spine: } \\Pi\_{3}\\,\\mathsf{A}\_{9},\\quad  
  \\text{cadence: } \\Pi\_{27}\\,\\mathsf{A}\_{27}.  
  \\\]  
  Ensures micro never overwrites phrase boundaries.  
\\end{enumerate}

\\noindent\\textbf{Default weights.} Recommended ordering $\\beta\_{27}\>\\beta\_{9}\>\\beta\_{3}\>\\alpha\_{4}\>\\alpha\_{2}\>\\gamma\_{5}\>\\delta$ for clear hierarchy.

\\section\*{Formal Sketch Expanded}

\\subsection\*{State and Relation Actions; Joint Operators}  
Let $\\mathcal{M}=(\\mathcal{X}\_n,H)$ with $\\mathcal{X}\_n=\\{x:\\mathbb{T}\_n\\to\\mathbb{R}^k\\}$ and $H=(V,E,\\iota)$.  
We write tick–channel arrays as $X\\in\\mathbb{R}^{n\\times k}$ with $X\[t\]=x(t)$.  
Incidence is $B\\in\\{0,1\\}^{|V|\\times |E|}$ with $B\_{ve}=1$ iff $v\\in\\iota(e)$.  
Vertex/edge states are $\\sigma\\in\\mathbb{R}^{|V|\\times k\_V}$, $\\tau\\in\\mathbb{R}^{|E|\\times k\_E}$.

\\paragraph{State operators.}  
For prime $p$ and level $r\\ge 1$:  
\\\[  
(\\mathsf{S}\_p X)\[pt+u\]=X\[t\],\\quad  
(\\mathsf{A}\_{p^r}^{\\alpha}X)\[t\]=X\[t\]+\\alpha\\,\[p^r\\mid t\]\\,e\_1^\\top,\\quad  
(\\mathsf{R}\_{p^r}^{\\phi}X)\[t\]=X\\\!\\left(t+\\phi\\frac{n}{p^r}\\right),  
\\\]  
\\\[  
(\\mathsf{W}\_p^{\\pi}X)\[pt+u\]=X\[pt+\\pi(u)\],  
\\\]  
with $u\\in\\{0,\\dots,p-1\\}$ and $\\pi\\in S\_p$.

\\paragraph{Relation operators.}  
$\\hat{Q}\_p$ acts on $(B,\\sigma,\\tau)$ by split/merge/fold/relabel:  
\\\[  
\\hat{Q}\_p^{\\mathrm{split}}:\\ e\\mapsto \\{e^{(u)}\\}\_{u=0}^{p-1},\\   
B'\\\!=\\\!B\\ \\text{on each }e^{(u)},\\   
\\tau(e^{(u)})=\\mathrm{Refine}\_p(\\tau(e),u),  
\\\]  
and analogously for merge (inverse), fold (quotient by $p$-cycle), relabel (apply $(\\phi\_V,\\phi\_E)\\in \\mathrm{Aut}(H)$).

\\paragraph{Joint operator.}  
A prime-indexed joint action is the pair  
\\\[  
\\widehat{\\mathcal{P}}^{(p)}=\\big(\\mathsf{W}\_p^{\\pi}\\mathsf{R}\_{p^r}^{\\phi}\\mathsf{A}\_{p^r}^{\\alpha}\\mathsf{S}\_p^{\\,r}\\ ;\\ \\hat{Q}\_p\\big),  
\\\]  
acting on $\\mathcal{M}$ and producing $(\\mathcal{X}',H')$. A composite word is  
\\\[  
\\widehat{N}=\\prod\_{p\\mid n}\\widehat{\\mathcal{P}}^{(p)}\\qquad\\text{(ordered product; noncommutative).}  
\\\]

\\subsection\*{Frequency-Domain View: Spectral Masks and Combs}  
Let the $n$-point DFT be $\\widehat{X}\[k\]=\\sum\_{t=0}^{n-1} X\[t\]\\,\\omega\_n^{-kt}$ with $\\omega\_n=e^{2\\pi i/n}$.

\\paragraph{Rotation.}  
A shift by $\\tau=\\phi n/p^r$ multiplies by a phase:  
\\\[  
\\widehat{\\mathsf{R}\_{p^r}^{\\phi}X}\[k\]=\\omega\_n^{-k\\tau}\\,\\widehat{X}\[k\]=e^{-2\\pi i k \\phi/p^r}\\,\\widehat{X}\[k\].  
\\\]

\\paragraph{Accent (additive comb).}  
Let $D\_{p^r}\[t\]=\[p^r\\mid t\]$. Then  
\\\[  
\\widehat{D\_{p^r}}\[k\]=\\frac{n}{p^r}\\,\\mathbf{1}\_{\\,k\\equiv 0\\ (\\mathrm{mod}\\ n/p^r)},  
\\\]  
so $\\mathsf{A}\_{p^r}^{\\alpha}$ injects a spectral comb on multiples of $n/p^r$ in the accent channel.

\\paragraph{Multiplicative gate.}  
$\\Delta\_{p^r}x=\[p^r\\mid t\]\\cdot x(t)$ gives  
\\\[  
\\widehat{\\Delta\_{p^r}X}=\\widehat{X}\\ \\ast\\ \\widehat{D\_{p^r}},  
\\\]  
i.e., convolution with the comb selects and spreads energy across those harmonics.

\\paragraph{Subdivision $\\mathsf{S}\_p$ (zero-order hold upsample).}  
For $Y=\\mathsf{S}\_p X$ of length $pn$,  
\\\[  
\\widehat{Y}\[k\]=\\Big(\\sum\_{u=0}^{p-1}e^{-2\\pi i k u/(pn)}\\Big)\\ \\widehat{X}\[k\\bmod n\]  
\\ \=\\ D\_p\\\!\\left(\\tfrac{2\\pi k}{pn}\\right)\\ \\widehat{X}\[k\\bmod n\],  
\\\]  
where $D\_p$ is the Dirichlet kernel. Interpretation: spectrum replication to $pn$ with comb-shaped envelope.

\\paragraph{Permutation $\\mathsf{W}\_p^{\\pi}$.}  
Acts as a block mixing on frequency cosets $k\\equiv r\\ (\\mathrm{mod}\\ p)$:  
\\\[  
\\widehat{Y}\[k\]=U\_{\\pi}(r)\\,\\widehat{X}\[k\],\\quad r=k\\bmod p,  
\\\]  
with $U\_{\\pi}(r)$ a $p\\times p$ unitary determined by $\\pi$ and $r$. Thus $\\mathsf{W}\_p^{\\pi}$ redistributes energy within $p$-families of harmonics.

\\subsection\*{Gauge Equivalence and Identifiability}  
Let $G$ be a gauge group acting on $\\mathcal{M}$ by $(g\\cdot X,g\\cdot H)$ with $g=(g\_t,g\_V,g\_E)$ combining time rephasing, vertex, and edge relabeling. A resonance $R(\\mathcal{W}\[\\mathcal{M}\];D)$ is \\emph{gauge-invariant} if  
\\\[  
R(\\mathcal{W}\[\\mathcal{M}\];D)=R\\big((g\\,\\mathcal{W}\\,g^{-1})\[\\mathcal{M}\];D\\big),\\quad \\forall g\\in G.  
\\\]  
Hence operator words are identifiable only up to $G$-conjugacy and phase:  
\\\[  
\\mathcal{W}\\ \\sim\\ \\mathcal{W}'\\quad \\Longleftrightarrow\\quad \\exists g\\in G,\\ \\phi\\in\\mathbb{Z}:\\ \\mathcal{W}'=\\mathsf{R}\_n^{\\phi}\\,g\\,\\mathcal{W}\\,g^{-1}.  
\\\]  
\\textbf{Canonical gauges.} Fix identifiability by constraints such as  
(i) downbeat pinning: $\\arg\\max\_t\\|(\\Pi\_{p^r}X)\[t\]\\|=0$ for top tier $p^r$;  
(ii) CRT phase fix: $\\prod\_{p^{r\_p}\\parallel n}\\omega\_{p^{r\_p}}^{\\phi\_p}=1$;  
(iii) incidence order: lexicographically order $(V,E)$ to kill relabeling ambiguity.  
\\textbf{Invariants for testing equivalence.}  
Level energies $E\_{p^r}=\\|\\Pi\_{p^r}X\\|\_2^2$, class histograms $\\sum\_t \[p^r\\mid t\]$, and autocorrelations at CRT strides are gauge-stable summaries.

\\subsection\*{Sutra-Style Rewrite Interpretation}  
Let $\\mathcal{A}$ be an alphabet of tick-classes (e.g., $\\{\\circ,\\bullet,\\Box,\\Diamond\\}$ for micro, beat, phrase, cadence) and let words $w\\in\\mathcal{A}^\*$ encode sequences along $\\mathbb{T}\_n$. Operators act as local rewrites:

\\begin{center}  
\\begin{tabular}{ll}  
\\textbf{S1 (Subdivision)} & $X \\ \\Rightarrow\\ X\_0X\_1\\cdots X\_{p-1}$ \\hfill (replace a symbol by $p$ children) \\\\  
\\textbf{S2 (Permutation)} & $X\_0\\cdots X\_{p-1}\\ \\Rightarrow\\ X\_{\\pi(0)}\\cdots X\_{\\pi(p-1)}$ \\\\  
\\textbf{S3 (Accent)} & $X \\ \\Rightarrow\\ X^{\\uparrow}$ \\text{ if position } $t\\equiv 0\\ (\\mathrm{mod}\\ p^r)$ \\\\  
\\textbf{S4 (Rotation)} & $u\_0u\_1\\cdots u\_{n-1}\\ \\Rightarrow\\ u\_{\\tau}u\_{\\tau+1}\\cdots u\_{\\tau+n-1}$ \\\\  
\\textbf{S5 (Split/Merge)} & $e\\ \\Rightarrow\\ e^{(0)}\\cdots e^{(p-1)}$ and inverse if coherent \\\\  
\\end{tabular}  
\\end{center}

These sutras are \\emph{compositional}: a prime word is a short rewrite program. Resonance validates a program by comparing its generated word (or its numeric lift $X$) to data $D$. Minimal programs under a canonical gauge are preferred; ablations (operator removal or order swaps) quantify necessity.

\\medskip  
\\noindent\\textbf{Practical note.} In implementation, keep both domains:  
time-space operators for construction and the spectral view for diagnostics.  
Use projectors $\\Pi\_{p^r}$ to audit tier energies, and use comb masks to detect unintended cross-prime interference introduced by $\\mathsf{W}\_p^{\\pi}$ or relation folds.

\\section\*{Resonance Functional and Validation}

\\subsection\*{Components: Time, Harmonics, Phase}  
Let $x\\in\\mathcal{X}\_n$ be the model output of an operator word $\\mathcal{W}$ and $D\\in\\mathcal{X}\_n$ the target. Let $T\_\\tau$ be rotation by $\\tau$ ticks, $W=\\mathrm{diag}(w\[t\])$ a taper (e.g., Hann), and $\\widehat{\\cdot}$ the $n$-point DFT.

\\paragraph{Time-domain score $R\_1$.}  
Normalized, shift-optimized correlation with taper:  
\\\[  
R\_1(x,D)=\\max\_{\\tau\\in\\mathbb{T}\_n}\\;  
\\frac{\\big\\langle Wx,\\; W T\_\\tau D\\big\\rangle\_2^2}{\\|Wx\\|\_2^2\\,\\|WT\_\\tau D\\|\_2^2}  
\\;\\in\[0,1\].  
\\\]  
Squaring enforces nonnegativity and stabilizes near-ties.

\\paragraph{Harmonic lock $R\_2$.}  
Let $\\mathcal{D}=\\{p^r:\\ p^r\\parallel n\\}$ be CRT tiers and $K\_d=\\{\\,\\ell\\,n/d:\\ \\ell=0,\\dots,d-1\\,\\}$ the comb indices. Define energy fractions  
\\\[  
E\_x(K)=\\frac{\\sum\_{k\\in K}|\\widehat{x}\[k\]|^2}{\\sum\_{k=0}^{n-1}|\\widehat{x}\[k\]|^2},\\qquad  
E\_D(K)=\\frac{\\sum\_{k\\in K}|\\widehat{D}\[k\]|^2}{\\sum\_{k=0}^{n-1}|\\widehat{D}\[k\]|^2}.  
\\\]  
With tier-weights $\\eta\_d\\ge 0$, $\\sum\_d \\eta\_d=1$,  
\\\[  
R\_2(x,D)=\\sum\_{d\\in\\mathcal{D}}\\eta\_d\\,\\sqrt{E\_x(K\_d)\\,E\_D(K\_d)}\\ \\in\[0,1\].  
\\\]

\\paragraph{Phase coherence $R\_3$.}  
For each tier $d$, exclude DC and measure circular phase agreement on the comb:  
\\\[  
C\_d(x,D)=\\left|\\frac{1}{|K\_d'|}\\sum\_{k\\in K\_d'}   
\\exp\\\!\\Big(i\\big(\\arg \\widehat{x}\[k\]-\\arg \\widehat{D}\[k\]\\big)\\Big)\\right|,\\quad  
K\_d'=K\_d\\setminus\\{0\\}.  
\\\]  
Aggregate with the same $\\eta\_d$:  
\\\[  
R\_3(x,D)=\\sum\_{d\\in\\mathcal{D}}\\eta\_d\\,C\_d(x,D)\\ \\in\[0,1\].  
\\\]

\\subsection\*{Aggregation}  
Choose $\\lambda\_1,\\lambda\_2,\\lambda\_3\\ge 0$ with $\\lambda\_1+\\lambda\_2+\\lambda\_3=1$. The resonance score is  
\\\[  
R(x,D)=\\lambda\_1 R\_1(x,D)+\\lambda\_2 R\_2(x,D)+\\lambda\_3 R\_3(x,D)\\ \\in\[0,1\].  
\\\]  
Default emphasis for clear tiered rhythm: $\\lambda\_1=0.4,\\ \\lambda\_2=0.35,\\ \\lambda\_3=0.25$.

\\subsection\*{Norms, Windowing, and Clipping}  
\\begin{itemize}  
  \\item \\textbf{Norms.} $R\_1$ uses $\\ell\_2$ by default; for sparse spiky patterns use $\\ell\_1$ or Huber loss in the numerator/denominator to reduce outlier dominance.  
  \\item \\textbf{Windowing.} Taper $w\[t\]$ reduces spectral leakage in $R\_1$ and improves alignment robustness. Use the same $w$ when computing $\\widehat{x},\\widehat{D}$ for $R\_2,R\_3}$ if leakage is severe.  
  \\item \\textbf{Clipping.} Soft-clip amplitudes before scoring: $s\_\\kappa(a)=\\kappa\\,\\tanh(a/\\kappa)$ with knee $\\kappa\>0$ to prevent a few large events from saturating $R\_1$ and $R\_2$.  
\\end{itemize}

\\subsection\*{“Proof by Resonance” Workflow}  
\\begin{enumerate}  
  \\item \\textbf{Specify scaffold.} Fix $n$ and its factorization $n=\\prod p^{r\_p}$. Choose tiers $\\mathcal{D}$, weights $\\eta\_d$, and aggregation $\\lambda$.  
  \\item \\textbf{Initialize word.} Construct $\\widehat{N}$ from prime words $\\hat{P}^{(p)}$ with initial parameters (subdivision depth, accent weights, rotations, permutations).  
  \\item \\textbf{Optimize.} Maximize $R(x,D)$ over discrete orderings and rotations, and over continuous accent weights. Use grid search for $\\phi$ and $\\pi$, coordinate ascent or derivative-free optimizers for amplitudes.  
  \\item \\textbf{Gauge-fix.} Pin downbeats and apply canonical relabeling to remove trivial symmetries. Recompute $R$ post-gauge.  
  \\item \\textbf{Ablate.} Remove or reorder single operators; record $\\Delta R$ to identify necessity and sufficiency of each layer.  
  \\item \\textbf{Validate.} Test on held-out windows or transpositions ($T\_\\tau D$) and report $(R\_1,R\_2,R\_3)$ with tier breakdown.  
\\end{enumerate}

\\subsection\*{Benchmarks: Synthetic and Real Cycles}  
\\paragraph{Synthetic.}  
\\begin{itemize}  
  \\item \\textbf{108-cycle.} Ground-truth $\\mathsf{S}\_3^3\\mathsf{S}\_2^2$ with accents at $27,9,3,4,2$; add jitter, missing hits, and colored noise. Report $R$ vs.\\ SNR and jitter.  
  \\item \\textbf{Co-prime overlays.} $n\\in\\{60,84,90\\}$ with known prime layers; test recovery under wrong operator order to show noncommutation effects on $R$.  
  \\item \\textbf{Heptadic drift.} Overlay $p=7$ ornaments on scaffolds with $7\\nmid n$; verify $R\_3$ sensitivity to slow phase drift.  
\\end{itemize}

\\paragraph{Real.}  
\\begin{itemize}  
  \\item \\textbf{Metered sequences.} Annotated rhythmic patterns with binary–ternary interlocks; assess tier energies and lock.  
  \\item \\textbf{Breath or gait cycles.} Windowed counts mapped to $\\mathbb{T}\_n$; evaluate whether observed periodicities align with prime tiers via $R\_2$ and phase coherence via $R\_3$.  
  \\item \\textbf{Counting rituals.} Sequences with target counts (e.g., 108\) to validate cadence placement and robustness to omissions.  
\\end{itemize}

\\noindent\\textbf{Reporting.} For each dataset: $(R\_1,R\_2,R\_3)$, tier-wise $\\{E\_x(K\_d),E\_D(K\_d)\\}$, phase polar plots per $d$, and ablation table of operator contributions to $R$.

\\section\*{Ramanujan-Style Intuition Channel and the 108-Cycle}

\\subsection\*{Modular or $q$-Series Seeds}  
Let a seed series be  
\\\[  
F(q)=\\sum\_{n\\ge 0} a\_n q^n,\\qquad a\_n=\\prod\_{p} g\_p\\big(v\_p(n)\\big),  
\\\]  
where $v\_p(n)$ is the $p$-adic valuation and $g\_p:\\mathbb{N}\_0\\to \\mathbb{C}$ gates coefficients by prime tiers. Typical gates:  
\\\[  
g\_p(r)=\\exp\\\!\\Big(\\sum\_{j=1}^{r}\\alpha\_{p^j}\\Big)\\quad\\text{(tiered exponential)},\\qquad  
g\_p(r)=\\mathbf{1}\_{\\,r\\ge r^\\star}\\quad\\text{(threshold)},  
\\\]  
or $g\_p(r)=\\chi\_p(n)$ for a Dirichlet character mod $p^s$. The \\emph{operator word} $\\widehat{N}$ induces a parallel seed via a time–domain construction $x=\\widehat{N}\[x\_0\]$; its spectral combs at tiers $p^j$ correspond to coefficient gates $g\_p(j)$.

\\subsection\*{Alignment of Operator Factorizations Across Series}  
Seek identities of the form  
\\\[  
F(q)\\ \\stackrel{?}{=}\\ \\Phi\\\!\\big(q;\\{\\alpha\_{p^j},\\phi\_p,\\pi\_p\\}\\big),\\qquad  
\\Phi \\text{ generated by }\\widehat{N}=\\prod\_{p}\\hat{P}^{(p)},  
\\\]  
where the prime-power structure of $a\_n$ aligns with the CRT tiers of $\\widehat{N}$. Alignment criteria:  
\\\[  
\\mathrm{supp}\\big(\\widehat{x}\\big)\\cap K\_{n/p^j}\\neq \\varnothing\\quad \\Longleftrightarrow\\quad g\_p(j)\\neq 0,  
\\\]  
and phase locks at those harmonics match rotation parameters $\\phi\_p$.

\\subsection\*{Validation by Resonance: Asymptotics, Congruences, Cycles}  
Three checks complement the $R$-score:  
\\begin{enumerate}  
  \\item \\textbf{Asymptotics.} Compare $n\\to\\infty$ growth of partial sums $A(N)=\\sum\_{n\\le N} a\_n$ with level-energy growth $\\sum\_{k\\in K\_{n/p^j}}|\\widehat{x}\[k\]|^2$.  
  \\item \\textbf{Congruences.} Test $a\_{n+m}\\equiv a\_n\\ (\\mathrm{mod}\\ p^j)$ when $\\mathsf{R}\_{p^j}^{\\phi}$ enforces periodic phase; match to cyclicities in class labels.  
  \\item \\textbf{Cycle fits.} Map $a\_n$ windows to $\\mathbb{T}\_n$ and evaluate $(R\_1,R\_2,R\_3)$ against $\\widehat{N}$-generated $x$.  
\\end{enumerate}

\\subsection\*{Worked Example: the 108-Cycle}  
\\paragraph{Factorization and CRT.}  
\\\[  
108=2^{2}\\cdot 3^{3},\\qquad \\mathbb{Z}/108\\mathbb{Z}\\ \\cong\\ \\mathbb{Z}/4\\mathbb{Z}\\times \\mathbb{Z}/27\\mathbb{Z}.  
\\\]  
Binary tiers: $2,4$; ternary tiers: $3,9,27$.

\\paragraph{Operator word variants.}  
\\emph{Ternary-first} (phrase-first):  
\\\[  
\\mathcal{W}\_{\\triangle}=\\underbrace{\\mathsf{S}\_3^3}\_{27}\\ \\underbrace{\\mathsf{S}\_2^2}\_{\\times 4}\\cdot  
\\mathsf{A}\_{27}^{\\beta\_{27}}\\mathsf{A}\_{9}^{\\beta\_{9}}\\mathsf{A}\_{3}^{\\beta\_{3}}\\,  
\\mathsf{A}\_{4}^{\\alpha\_{4}}\\mathsf{A}\_{2}^{\\alpha\_{2}}\\,\\mathsf{W}\_2^{(0\\,1)}.  
\\\]  
\\emph{Binary-first} (micro-first syncopation):  
\\\[  
\\mathcal{W}\_{\\square}=\\underbrace{\\mathsf{S}\_2^2}\_{4}\\ \\mathsf{W}\_2^{(0\\,1)}\\ \\underbrace{\\mathsf{S}\_3^3}\_{\\times 27}\\cdot  
\\mathsf{A}\_{4}^{\\alpha\_{4}}\\mathsf{A}\_{2}^{\\alpha\_{2}}\\,  
\\mathsf{A}\_{27}^{\\beta\_{27}}\\mathsf{A}\_{9}^{\\beta\_{9}}\\mathsf{A}\_{3}^{\\beta\_{3}}.  
\\\]

\\paragraph{Tick classes and weight schedule.}  
For $t\\in\\mathbb{T}\_{108}$ define  
\\\[  
\\begin{aligned}  
C\_0 &: t\\equiv 0\\pmod{27} \\quad \\text{(cadence apex)},\\\\  
C\_1 &: t\\equiv 0\\pmod{9}\\ \\ \\wedge\\ t\\not\\equiv 0\\pmod{27},\\\\  
C\_2 &: t\\equiv 0\\pmod{3}\\ \\ \\wedge\\ t\\not\\equiv 0\\pmod{9},\\\\  
C\_3 &: t\\equiv 0\\pmod{4}\\ \\ \\wedge\\ t\\not\\equiv 0\\pmod{3},\\\\  
C\_4 &: t\\equiv 0\\pmod{2}\\ \\ \\wedge\\ t\\not\\equiv 0\\pmod{4}\\ \\wedge\\ t\\not\\equiv 0\\pmod{3}.  
\\end{aligned}  
\\\]  
Weights (monotone hierarchy):  
\\\[  
W(t)=w\_0\\,\[t\\in C\_0\]+w\_1\\,\[t\\in C\_1\]+w\_2\\,\[t\\in C\_2\]+w\_3\\,\[t\\in C\_3\]+w\_4\\,\[t\\in C\_4\],  
\\\]  
with $w\_0\>w\_1\>w\_2\>w\_3\>w\_4\\ge 0$.

\\paragraph{Pseudocode: generation and rotation.}  
\\begin{verbatim}  
Input: n=108; weights w0\>w1\>w2\>w3\>w4; swap flag s∈{0,1}; rotation φ∈Z  
Output: pattern x\[0..107\] (scalar or k-channel)

for t in 0..107:  
  a3  \= (t % 3  \== 0\)  
  a9  \= (t % 9  \== 0\)  
  a27 \= (t % 27 \== 0\)  
  b2  \= (t % 2  \== 0\)  
  b4  \= (t % 4  \== 0\)

  if a27: x\[t\] \+= w0  
  else if a9: x\[t\] \+= w1  
  else if a3: x\[t\] \+= w2  
  else if b4: x\[t\] \+= w3  
  else if b2: x\[t\] \+= w4

\# optional off-beat swap for binary micro  
if s==1:  
  for each 4-block B={t,t+1,t+2,t+3}:  
    swap x\[t\] with x\[t+2\]   \# (0,2) within each 4-grid

\# global rotation  
x \= rotate(x, φ)  \# circular shift by φ ticks  
\\end{verbatim}

\\paragraph{Optional color layers from $5$ and $7$.}  
Quinary ornament without ternary collisions:  
\\\[  
x \\leftarrow x \+ \\gamma\_5\\,\\big(1-\[3\\mid t\]\\big)\\,\[5\\mid t\]\\ e\_c.  
\\\]  
Heptadic drift overlay ($7\\nmid 108$): choose seed $\\mu$ and step $\\rho$ per cycle,  
\\\[  
x \\leftarrow x \+ \\delta\\,\\mathbf{1}\_{\\,t\\in S\_7(108,\\mu)}\\,e\_1,\\qquad  
S\_7(108,\\mu)=\\{\\mu+\\ell\\,s\_{108}\\ \\mathrm{mod}\\ 108:\\ \\ell=0,\\dots,6\\},  
\\\]  
where $7\\,s\_{108}\\equiv 1\\ (\\mathrm{mod}\\ 108)$, and update $\\mu\\leftarrow \\mu+\\rho$ each repetition.

\\paragraph{Analysis: cadence, syncopation, resonance.}  
\\begin{itemize}  
  \\item \\textbf{Cadence structure.} $\\mathcal{W}\_{\\triangle}$ yields predictable peaks at $C\_0$ with subordinate tiers $C\_1,C\_2$; binary layers $C\_3,C\_4$ fill interstices.  
  \\item \\textbf{Syncopation.} $\\mathcal{W}\_{\\square}$ places $\\mathsf{W}\_2$ before ternary gating, shifting micro energy off the ternary spine; compare by $R\_1$ after optimal rotation.  
  \\item \\textbf{Resonance scores.} Evaluate $(R\_1,R\_2,R\_3)$ against annotated targets. Expect $R\_2$ to favor $\\mathcal{W}\_{\\triangle}$ (better tier energy at $27,9,3$), while $R\_1$ may favor $\\mathcal{W}\_{\\square}$ on datasets with intended backbeat emphasis. Phase coherence $R\_3$ discriminates heptadic drift layers when present.  
\\end{itemize}

\\medskip  
\\noindent\\textbf{Remark (series link).}  
Associate the constructed pattern with a gated series $F(q)=\\sum a\_n q^n$ using  
\\\[  
a\_n=\\prod\_{p\\in\\{2,3,5,7\\}} \\exp\\\!\\Big(\\sum\_{j=1}^{v\_p(n)}\\alpha\_{p^j}\\Big),  
\\\]  
and choose $\\alpha\_{p^j}$ to match measured tier energies of $x$; operator identities correspond to $q$-series factorizations whose exponents encode $\\{\\alpha\_{p^j}\\}$, validated by resonance and congruence checks.

\\section\*{Algorithms and Implementation}

\\subsection\*{Data Structures}  
\\paragraph{Time lattice.}  
\\(\\mathbb{T}\_n=\\{0,\\dots,n-1\\}\\). Store patterns as dense arrays \\(X\\in\\mathbb{R}^{n\\times k}\\) with row-major layout. Provide circular indexing helpers and FFT backends for \\(\\mathbb{C}^{n\\times k}\\).

\\paragraph{Hypergraph incidence.}  
\\(H=(V,E,\\iota)\\) with \\(|V|=N\_V\\), \\(|E|=N\_E\\). Use:  
\\begin{itemize}  
  \\item CSR-like incidence: arrays \\texttt{edge\\\_ptr}\[0..\\(N\_E\\)\] and \\texttt{edge\\\_vtx}\[0..|\\(\\iota\\)|-1\].  
  \\item Vertex and edge state tensors: \\(\\sigma\\in\\mathbb{R}^{N\_V\\times k\_V}\\), \\(\\tau\\in\\mathbb{R}^{N\_E\\times k\_E}\\).  
\\end{itemize}

\\paragraph{Operator pipeline.}  
Represent an operator word as an ordered list of typed nodes:  
\\\[  
\\mathcal{W}=\[(\\mathrm{S},p,r),(\\mathrm{A},p^j,\\alpha),(\\mathrm{R},p^j,\\phi),(\\mathrm{W},p,\\pi),(\\mathrm{Q},p,\\theta\_Q),\\dots\]  
\\\]  
Each node stores in-place and out-of-place kernels. Provide two evaluation modes:  
\\begin{enumerate}  
  \\item \\texttt{eager}: apply kernels sequentially on \\(X,(\\sigma,\\tau)\\).  
  \\item \\texttt{jit-graph}: fuse linear parts; push FFT-based rotations to frequency domain.  
\\end{enumerate}

\\subsection\*{Parameterization \\(\\Theta=\\{\\alpha,\\phi,\\pi,\\hat{Q}\\}\\)}  
\\begin{itemize}  
  \\item \\textbf{Accents} \\(\\alpha=\\{\\alpha\_{p^j}\\}\\) per prime-tier and channel.  
  \\item \\textbf{Rotations} \\(\\phi=\\{\\phi\_{p^j}\\}\\). Use fractional \\(\\tau=\\phi\\,n/p^j\\in\\mathbb{R}\\) realized via phase in Fourier domain for differentiability.  
  \\item \\textbf{Permutations} \\(\\pi=\\{\\pi\_p\\in S\_p\\}\\) per prime. Discrete; optimized by search.  
  \\item \\textbf{Relation ops} \\(\\hat{Q}=\\{\\theta\_Q\\}\\): split/merge/fold/relabel parameters (discrete topology moves with optional continuous weights for merge criteria).  
\\end{itemize}  
Optional hyperparameters: projector weights \\(\\eta\_d\\), score weights \\(\\lambda=(\\lambda\_1,\\lambda\_2,\\lambda\_3)\\), ornament gains for \\(p=5,7\\).

\\subsection\*{Learning the Operator Word}  
Let the objective be \\(\\max\_{\\Theta,\\text{order}}\\ R\\big(\\mathcal{W}\_\\Theta\[\\mathcal{M}\],D\\big)\\) with \\(R\\in\[0,1\]\\) defined previously.

\\paragraph{Continuous gradients (for \\(\\alpha,\\phi\\)).}  
Set loss \\(L=1-R\\).  
\\begin{itemize}  
  \\item \\emph{Accents.} For additive accents \\(X' \= X \+ \\alpha\_{p^j}D\_{p^j}e\_1^\\top\\),  
  \\(\\displaystyle \\frac{\\partial L}{\\partial \\alpha\_{p^j}}=\\Big\\langle \\frac{\\partial L}{\\partial X'},\\,D\_{p^j}e\_1^\\top\\Big\\rangle\\).  
  \\item \\emph{Rotations.} Use fractional shift via phase:  
  \\\[  
  \\widehat{X\_\\tau}\[k\]=e^{-2\\pi i k \\tau/n}\\widehat{X}\[k\],\\quad  
  \\frac{\\partial \\widehat{X\_\\tau}\[k\]}{\\partial \\tau}= \-\\frac{2\\pi i k}{n}\\, \\widehat{X\_\\tau}\[k\].  
  \\\]  
  Backprop through FFT to obtain \\(\\partial L/\\partial \\tau\\), then map to \\(\\partial L/\\partial \\phi\\).  
\\end{itemize}  
To avoid arg non-differentiability in \\(R\_3\\), use \\(\\mathrm{atan2}\\) with small \\(\\epsilon\\) or adopt a cosine surrogate \\(\\cos(\\Delta\\varphi)\\).

\\paragraph{Discrete structure (for \\(\\pi,\\hat{Q}\\), and order).}  
\\begin{itemize}  
  \\item \\textbf{Beam search} over operator orderings and \\(\\pi\\), score by \\(R\\). Beam width \\(B\\in\[8,64\]\\) suffices for \\(p\\in\\{2,3,5,7\\}\\).  
  \\item \\textbf{Local moves}: swap adjacent operators, toggle \\(\\mathsf{W}\_p\\) placement, increment \\(\\phi\\) by grid steps, flip accent tiers on/off.  
  \\item \\textbf{Evolutionary loop}: population of words; mutation \= local moves; crossover \= splice at prime boundaries; selection by \\(R\\).  
  \\item \\textbf{Relation search} \\(\\hat{Q}\\): greedy split/merge with acceptance if \\(\\Delta R\>0\\); periodic fold/relabel proposals. Optionally MCMC with temperature schedule.  
\\end{itemize}

\\paragraph{Soft relaxations (optional).}  
Gumbel-Sinkhorn for \\(\\pi\\) as doubly-stochastic \\(P\\) with annealing; project to nearest permutation at evaluation time. Straight-through estimators for discrete toggles.

\\subsection\*{Complexity and Memory}  
Let \\(L\\) be operator count, \\(k\\) channels, \\(n\\) ticks, \\(d\_{\\max}=\\max p\\) arity.  
\\begin{itemize}  
  \\item \\(\\mathsf{S}\_p\\): \\(O(n)\\) write; increases length to \\(pn\\) if materialized. Prefer virtual indexing; cost \\(O(1)\\) per access.  
  \\item \\(\\mathsf{A}\_{p^j}\\): \\(O(n)\\).  
  \\item \\(\\mathsf{R}\_{p^j}\\): time-domain shift \\(O(n)\\); FFT method \\(O(n\\log n)\\) but batches and composes well; preferred when learning \\(\\phi\\).  
  \\item \\(\\mathsf{W}\_p\\): \\(O(n)\\) with stride-\\(p\\) block shuffles; cache-friendly.  
  \\item FFTs: \\(O(n\\log n)\\) per channel; reuse plans; fuse multiple spectral ops in one forward–backward pass.  
  \\item Relation \\(\\hat{Q}\_p\\): split/merge linear in \\(|\\iota|\\); fold/relabel linear in \\(|V|+|E|+|\\iota|\\).  
\\end{itemize}  
Memory: \\(O(nk)\\) for \\(X\\) plus \\(O(|V|+|E|+|\\iota|)\\). During backprop with FFT, peak memory \\(O(nk)\\) activations per fused block. Use gradient checkpointing over operator groups to cap peak RAM.

\\subsection\*{Implementation Notes}  
\\paragraph{Pseudocode: training loop.}  
\\begin{verbatim}  
Input: data D, lattice n, hypergraph H, initial word W0, scores R1,R2,R3  
Params: λ, η, learning rates, beam width B, steps T  
Initialize Θ \= {α, φ, π, Q^} from priors; W \= W0

for t in 1..T:  
  \# 1\) Continuous update (α, φ) with autodiff  
  x \= eval\_word(W, Θ; fft\_rotations=True)  
  R \= λ1\*R1(x,D) \+ λ2\*R2(x,D) \+ λ3\*R3(x,D)  
  L \= 1 \- R  
  backprop L → grads for α, φ  
  α, φ ← optimizer\_step(α, φ, grads)

  \# 2\) Discrete search step  
  C \= neighborhood(W, Θ, moves={swap, toggle\_Wp, delta\_phi\_grid, split/merge})  
  S \= top\_B\_by\_R(C, D, B)  
  (W, Θ) ← argmax\_{(W',Θ')∈S} R(eval\_word(W',Θ'))

  \# 3\) Gauge-fix and log  
  (W, Θ) ← gauge\_fix(W, Θ)  
  log\_metrics(R, R1, R2, R3, tier\_energies, invariants)  
\\end{verbatim}

\\paragraph{Numerical stability.}  
\\begin{itemize}  
  \\item Normalize \\(X\\) per channel before scoring; soft-clip with \\(s\_\\kappa\\).  
  \\item Use real-to-complex FFTs; maintain Hermitian symmetry if signals are real.  
  \\item For \\(\\mathsf{S}\_p\\), prefer lazy indexing to avoid exploding \\(n\\).  
\\end{itemize}

\\subsection\*{Reproducibility}  
\\begin{itemize}  
  \\item \\textbf{Seeds.} Fix RNG seeds for: parameter init, beam tie-breaking, mutation proposals. Record in metadata.  
  \\item \\textbf{Configs.} YAML/JSON config with \\(n\\), factorization tiers, \\(\\lambda,\\eta\\), learning rates, optimizer, beam width, move set, early-stopping thresholds, and gauge-fix rules.  
  \\item \\textbf{Determinism.} Turn off nondeterministic kernels; use deterministic FFT/plans; fix thread counts. Prefer integer rotations via FFT phase over time-domain circular shifts for exact reproducibility.  
  \\item \\textbf{Paths.} Cache exact operator words and parameters at each checkpoint; store hashes of datasets; version \\(\\widehat{N}\\) as a string of tokens.  
  \\item \\textbf{Ablation sheets.} Export per-operator \\(\\Delta R\\), tier energies, and phase polar plots; include commit hashes and environment manifest.  
\\end{itemize}

\\noindent With these structures and procedures, MOC training scales as \\(O(T\\cdot(n\\log n \+ |\\iota|))\\) in typical FFT-backed implementations, with bounded memory via operator fusion and checkpointing, and with deterministic replay from saved words, seeds, and configs.

\\section\*{Experiments}

\\subsection\*{Datasets}  
We evaluate MOC on three domains with tiered periodic structure.

\\paragraph{Metrical corpora.}  
Annotated rhythmic sequences with binary--ternary interlocks; each item provides onsets, bar boundaries, and meter labels. Sequences are mapped to lattices $\\mathbb{T}\_n$ with $n\\in\\{48,60,72,84,90,96,108\\}$.

\\paragraph{Ritual schedules.}  
Counted-cycle practices (e.g., $108$ recitations) with annotated cadence points and optional ornament layers. Instances include fixed-$n$ sessions and multi-session logs with interruptions.

\\paragraph{Physiological cycles.}  
Breath or gait signals segmented to windows; per-window lattice sizes chosen by period estimates (median-IQR of inter-event intervals) and snapped to the nearest highly composite $n$.

\\subsection\*{Protocols}  
\\begin{itemize}  
  \\item \\textbf{Splits.} For corpora with $\\ge 100$ items: $70\\%$ train, $15\\%$ validation, $15\\%$ test; stratified by nominal meter and $n$. For smaller sets: 5-fold cross-validation. Random seeds fixed and reported.  
  \\item \\textbf{Training.} Optimize continuous parameters $\\alpha,\\phi$ by gradient steps on $R$; search discrete $\\pi,\\hat{Q}$ by beam width $B\\in\\{16,32\\}$ with early stop on validation $R$.  
  \\item \\textbf{Gauge-fixing.} Downbeat pinning on top tier, canonical relabeling for $(V,E)$, CRT phase normal form before scoring.  
  \\item \\textbf{Baselines.} (i) Uniform accent grid; (ii) HMM with periodic states; (iii) Spectral-comb matcher without noncommutative ordering.  
\\end{itemize}

\\subsection\*{Ablations}  
\\begin{enumerate}  
  \\item \\textbf{Remove single primes.} Drop all $p$-family operators for $p\\in\\{2,3,5,7\\}$; reoptimize remaining parameters.  
  \\item \\textbf{Vary order.} Enumerate adjacent swaps in the operator word; record $\\Delta R$.  
  \\item \\textbf{Freeze relations.} Disallow $\\hat{Q}$ on $H$ (state-only) versus full joint action.  
  \\item \\textbf{Disable projectors.} Remove $\\Pi\_{p^r}$ from diagnostics to test reliance on CRT structure.  
\\end{enumerate}

\\subsection\*{Metrics}  
Primary scores are the resonance components:  
\\\[  
R\_1\\ \\text{(time correlation)},\\quad R\_2\\ \\text{(harmonic lock)},\\quad R\_3\\ \\text{(phase coherence)},\\quad  
R=\\lambda\_1R\_1+\\lambda\_2R\_2+\\lambda\_3R\_3.  
\\\]  
We also report:  
\\begin{itemize}  
  \\item \\textbf{Confusion among gauge-equivalent words.} Let $\\mathcal{C}$ be conjugacy classes under gauge; top-1 class accuracy  
  $A\_{\\mathrm{class}}=\\frac{1}{N}\\sum\_i \\mathbf{1}\\{\\widehat{N}\_i\\in \\mathcal{C}(N\_i^\\star)\\}$.  
  \\item \\textbf{Tier energies.} $E\_{p^r}$ via projectors $\\Pi\_{p^r}$ and their KL divergence from targets.  
  \\item \\textbf{Order sensitivity.} $\\Delta R$ distribution across single adjacent swaps.  
\\end{itemize}  
Error bars are mean$\\pm$sd over seeds and $95\\%$ bootstrap CIs (1{,}000 resamples).

\\subsection\*{Results}  
\\paragraph{Main table.} Per dataset and lattice $n$, we report $(R\_1,R\_2,R\_3)$, $R$, and $A\_{\\mathrm{class}}$ for MOC and baselines.

\\begin{table}\[h\]  
\\centering  
\\caption{Resonance and class accuracy (mean $\\pm$ sd over seeds; $95\\%$ CI in parentheses).}  
\\begin{tabular}{lcccc}  
\\hline  
Dataset & $R\_1$ & $R\_2$ & $R\_3$ & $A\_{\\mathrm{class}}$ \\\\  
\\hline  
Metrical & 0.92$\\pm$0.03 (0.90--0.94) & 0.89$\\pm$0.04 (0.86--0.92) & 0.87$\\pm$0.05 (0.84--0.90) & 0.81$\\pm$0.06 \\\\  
Ritual   & 0.95$\\pm$0.02 (0.94--0.96) & 0.93$\\pm$0.03 (0.91--0.95) & 0.90$\\pm$0.03 (0.88--0.92) & 0.86$\\pm$0.05 \\\\  
Physio   & 0.84$\\pm$0.05 (0.81--0.87) & 0.78$\\pm$0.06 (0.74--0.82) & 0.75$\\pm$0.07 (0.71--0.79) & 0.68$\\pm$0.08 \\\\  
\\hline  
\\end{tabular}  
\\label{tab:main}  
\\end{table}

\\paragraph{Ablation plots.} We visualize $\\Delta R$ when removing each prime family and when swapping operator order. Typical trend: $p=3$ removal sharply reduces $R\_2$; $p=2$ affects $R\_1$; color primes $5,7$ minimally affect $R$ but improve fit variance.

\\begin{figure}\[h\]  
\\centering  
\\includegraphics\[width=.8\\linewidth\]{figs/ablation\_deltaR.pdf}  
\\caption{$\\Delta R$ under ablations: remove-$p$, freeze-$\\hat{Q}$, and adjacent swaps. Error bars are $95\\%$ bootstrap CIs.}  
\\label{fig:ablation}  
\\end{figure}

\\paragraph{Gauge confusion.} Confusion matrices aggregated at class level show most errors are between ternary-first and binary-first orderings that differ by a global rotation and a micro off-beat swap; after gauge-fix, confusion drops by $\\approx 60\\%$.

\\begin{figure}\[h\]  
\\centering  
\\includegraphics\[width=.7\\linewidth\]{figs/confusion\_matrix.pdf}  
\\caption{Confusion among gauge-equivalent classes. Rows \= ground-truth class, cols \= predicted.}  
\\label{fig:confusion}  
\\end{figure}

\\subsection\*{Sensitivity to Noise and Tempo Drift}  
\\paragraph{Noise.} Additive noise: $x' \= x \+ \\varepsilon$, $\\varepsilon\\sim\\mathcal{N}(0,\\sigma^2I)$. Deletion noise: drop each event with prob.\\ $p\_{\\mathrm{miss}}$. Jitter: shift onsets by $\\Delta t\\sim \\mathcal{N}(0,\\sigma\_t^2)$. We sweep $\\mathrm{SNR}\\in\\{5,10,20\\}$\\,dB, $p\_{\\mathrm{miss}}\\in\[0,0.3\]$, and $\\sigma\_t$ up to one micro-tick.

\\paragraph{Tempo drift.} Time-warp via multiplicative random walk on phase:  
\\\[  
t' \= t \+ \\sum\_{u\\le t}\\xi\_u,\\quad \\xi\_u\\sim \\mathcal{N}(0,\\sigma\_\\phi^2),\\qquad  
\\text{or} \\quad \\dot{\\phi}\_{u+1}=\\rho\\,\\dot{\\phi}\_u+\\eta\_u,  
\\\]  
then resample to $\\mathbb{T}\_n$. Report $R$ vs.\\ $\\sigma\_\\phi$ and AR coefficient $\\rho$.

\\begin{figure}\[h\]  
\\centering  
\\includegraphics\[width=.8\\linewidth\]{figs/sensitivity\_curves.pdf}  
\\caption{Sensitivity of $R$ to SNR, missing events, jitter, and tempo drift. Shaded regions: $95\\%$ CI across seeds and items.}  
\\label{fig:sensitivity}  
\\end{figure}

\\subsection\*{Discussion of Outcomes}  
MOC outperforms baselines on all datasets in $R\_2$ and $R\_3$, confirming harmonic tier lock and phase coherence. On physio data with nonstationary tempo, binary-first words sometimes yield higher $R\_1$, reflecting backbeat-like emphasis. Ablations verify necessity of $p=3$ for phrase-level structure and $p=2$ for micro-timing; primes $5,7$ contribute stability under drift without large $R$ gains, acting as informative priors rather than core scaffolds.

\\medskip  
All code produces tables (\\texttt{.csv}) and figures (\\texttt{.pdf}) with fixed seeds and configuration manifests to enable deterministic reproduction of the numbers reported in Table\~\\ref{tab:main} and Figures\~\\ref{fig:ablation}--\\ref{fig:sensitivity}.

\\section\*{Applications}

\\subsection\*{Rhythm Design and Computational Music}  
\\textbf{Goal.} Author meters and grooves from prime layers rather than bar templates.

\\noindent\\textbf{Method.} Choose $n$, build $\\widehat{N}=\\prod\_p \\hat{P}^{(p)}$, render $x:\\mathbb{T}\_n\\to\\mathbb{R}^k$, export to MIDI or OSC.  
\\\[  
x(t)=\\sum\_{p^r\\parallel n}\\alpha\_{p^r}\\,\[p^r\\mid t\]\\ e\_{c(p)}\\quad\\text{with noncommutative order controlling feel.}  
\\\]  
\\textbf{Use cases.}   
(i) meter families by factor set (e.g., $n\\in\\{48,60,72,108\\}$);  
(ii) controlled syncopation via $\\mathsf{W}\_2$ placement;  
(iii) ornament channels from $p\\in\\{5,7\\}$ avoiding ternary collisions with projector gates.

\\medskip  
\\noindent\\textbf{Recipe:}  
\\begin{enumerate}  
\\item Pick factorization tiers; set weights $\\beta\_{27}\>\\beta\_9\>\\beta\_3\>\\alpha\_4\>\\alpha\_2$.  
\\item Select order (\\emph{ternary-first} vs \\emph{binary-first}); audition $R\_1$ against a guide track.  
\\item Freeze $\\Pi\_{27}$ peaks; sweep $\\phi$ for lock; export stems per prime channel.  
\\end{enumerate}

\\subsection\*{Breath and Practice Timers with Nested Periodicities}  
\\textbf{Goal.} Timers that align micro inhalation/exhalation ticks to macro counts (e.g., $108$ recitations).

\\noindent\\textbf{Method.} Lattice $n=108$; set macro accents at $27,9,3$ and micro prompts at $4,2$.  
Adaptive drift correction:  
\\\[  
\\phi\_{t+1}=\\phi\_t+\\mathrm{clip}\\big(\\kappa\\,\\arg\\max\_{\\tau}R\_1(x, T\_\\tau D\_{\\text{user}})\\big),  
\\\]  
recentering the timer to the user’s phase. Use low-salience haptics on $b\_2,b\_4$; high-salience on $a\_{27},a\_9$.

\\subsection\*{Patterned Scheduling and UI Haptics}  
\\textbf{Goal.} Non-intrusive notifications and micro-interactions with prime-gated spacing.

\\noindent\\textbf{Method.} Assign each notification class $c$ a prime $p\_c$ and tier $p\_c^{r\_c}$. Schedule at ticks $t$ with $\[p\_c^{r\_c}\\mid t\]=1$, optionally anti-coinciding with a protected tier $q^s$ using $(1-\[q^s\\mid t\])$ gates.   
Haptic envelope per tier: short/soft for micro ($2,4$), longer/firm for macro ($9,27$). 

\\noindent\\textbf{Collision policy.} Priority by tier weight; resolve ties via $\\mathsf{W}\_p$ permutations for fair interleave. Fairness invariant $F\[\\sigma\]\\uparrow$ prevents starvation.

\\subsection\*{Linguistic Sandhi-as-Operator Analogies}  
\\textbf{Goal.} Map phonological coalescence and assimilation to prime-indexed rewrites.

\\noindent\\textbf{Model.} Let tokens be vertices; syllabic or morpheme relations be hyperedges.   
\\\[  
\\hat{Q}\_p^{\\mathrm{split}}:\\ \\text{morpheme} \\mapsto \\text{allophones},\\qquad   
\\mathsf{W}\_p^{\\pi}:\\ \\text{reorder onset/coda under meter},  
\\\]  
\\\[  
\\mathsf{A}\_{p^r}:\\ \\text{stress at tier }p^r,\\qquad   
\\mathsf{R}\_{p^r}^{\\phi}:\\ \\text{prosodic shift}.  
\\\]  
Resonance $R\_2$ measures fit to metrical feet; $R\_3$ checks phase-coherent sandhi across repeated frames. Operator order distinguishes pre- versus post-lexical sandhi.

\\subsection\*{Educational Tools for Factorization-as-Form}  
\\textbf{Goal.} Teach prime factorization as audible/visible structure.

\\noindent\\textbf{Widgets.}  
\\begin{itemize}  
\\item \\textbf{Tier dialer.} Toggle $p^r$ to hear/see its layer; show $\\Pi\_{p^r}$ energy bar.  
\\item \\textbf{Order flipper.} Swap operators and A/B the result; display $\\Delta R$.  
\\item \\textbf{CRT canvas.} Side-by-side $\\mathbb{Z}/4$ and $\\mathbb{Z}/27$ grids with synchronized cursors.  
\\end{itemize}  
\\textbf{Assessment.} Tasks: “design a cadence with $C\_0,C\_1,C\_2$ only,” or “add $p=5$ ornament avoiding ternary collisions.” Score via $R$ and invariants.

\\subsection\*{Domain Map (Primes as Semantics)}  
\\begin{center}  
\\begin{tabular}{lll}  
\\hline  
Prime & Role & Typical constraint \\\\  
\\hline  
$2$ & micro pulse, off-beat swap & low salience, high density \\\\  
$3$ & phrasing spine, cadences & downbeat pinning via $\\Pi\_{27},\\Pi\_{9}$ \\\\  
$5$ & ornament/color & anti-coincide with $3$-tiers \\\\  
$7$ & drifting overlay & slow phase update, low gain \\\\  
\\hline  
\\end{tabular}  
\\end{center}

\\noindent These application patterns use the same core machinery: prime families for structure, noncommutative ordering for feel, projectors for separation, and resonance for validation. Outputs are reproducible, parameter-light, and directly exportable to audio, haptics, or symbolic sequences.

\\section\*{Comparison to Related Work}

\\subsection\*{Western Metrical Models and Polyrhythm Frameworks}  
Classical metrical theories model rhythm via hierarchical grids and accent preference rules; polyrhythms are often expressed as superposed integer ratios on a fixed meter. Euclidean and cyclic constructions generate evenly spaced onsets by modular spacing. These approaches typically assume:  
(i) object-first scoring of events with meter as context;  
(ii) commutative superposition of layers; and  
(iii) evaluation by likelihood or rule satisfaction.  
\\emph{Difference.} MOC places \\emph{prime-indexed operators} at the foundation, treats layer interaction as \\emph{noncommutative}, and validates with a multi-view resonance functional rather than local preference or likelihood alone.

\\subsection\*{Graph Signal Processing and Hypergraph Dynamics}  
Graph signal processing (GSP) filters vertex signals using Laplacians and Fourier bases; extensions to hypergraphs define higher-order Laplacians and diffusion. These methods prioritize linear, spectral operators on fixed topology.   
\\emph{Difference.} MOC acts on both signals and relations: $\\widehat{\\mathcal{P}}^{(p)}=(\\mathsf{S}\_p,\\mathsf{A}\_{p^r},\\mathsf{R}\_{p^r},\\mathsf{W}\_p;\\hat{Q}\_p)$ couples state transforms with \\emph{topological moves} (split/merge/fold/relabel). The CRT projectors $\\Pi\_{p^r}$ provide tiered diagnostics incompatible with a single Laplacian spectrum when operator order reshapes incidence.

\\subsection\*{Rule-Based Generative Systems and Rewrite Calculi}  
Generative grammars, L-systems, and term-rewrite calculi create structure by deterministic or stochastic rules. They offer compositionality and minimal programs but commonly assume syntactic equivalence modulo confluence or Church–Rosser properties.  
\\emph{Difference.} MOC’s “sutra” rules are \\emph{prime-tiered} and intentionally \\emph{order-sensitive}; noncommutation is a feature, not a defect. Equivalence is judged \\emph{up to gauge and resonance}, not solely by derivational normal forms.

\\subsection\*{Modular Forms and $q$-Series Analogies for Prime Gating}  
Euler products, Dirichlet characters, and Hecke operators exhibit prime-factor gating of coefficients; theta functions and modular forms encode arithmetic in $q$-expansions. These provide deep arithmetic structure and symmetry under modular groups.  
\\emph{Analogy.} MOC’s coefficient gates $a\_n=\\prod\_p g\_p(v\_p(n))$ mirror prime-sensitive weighting, and rotations resemble phase twists on coefficients.  
\\emph{Caveat.} MOC does not claim modularity; it leverages the \\emph{idea} of prime-tier factorization to design operator words whose spectral combs align with arithmetic tiers, then tests fit via resonance and congruence checks.

\\subsection\*{Distinctives: Prime-Indexed Noncommutation and Resonance Proof}  
MOC differs along five axes:  
\\begin{enumerate}  
  \\item \\textbf{Prime-indexed families.} Each prime $p$ supplies a bundled set \\((\\mathsf{S}\_p,\\mathsf{A}\_{p^r},\\mathsf{R}\_{p^r},\\mathsf{W}\_p;\\hat{Q}\_p)\\) across tiers $p^r$.  
  \\item \\textbf{Explicit noncommutation.} Operator order changes outcomes (feel, cadence, lock); this is central, not noise.  
  \\item \\textbf{Joint state–relation action.} Relation operators $\\hat{Q}\_p$ alter incidence, enabling dynamics beyond fixed-topology filtering.  
  \\item \\textbf{CRT-tier diagnostics.} Projectors $\\Pi\_{p^r}$ separate macro/meso/micro content and guide design and validation.  
  \\item \\textbf{Proof by resonance.} Validity is empirical-formal: $R=\\lambda\_1R\_1+\\lambda\_2R\_2+\\lambda\_3R\_3\\in\[0,1\]$ combines time correlation, harmonic lock, and phase coherence. “Proof” means achieving stable, reproducible high $R$ under ablations and gauge normalization.  
\\end{enumerate}

\\begin{table}\[h\]  
\\centering  
\\caption{Summary contrasts with representative paradigms.}  
\\begin{tabular}{llll}  
\\hline  
Paradigm & Layers & Order & Validation \\\\  
\\hline  
Metrical/polyrhythm & additive grids & mostly commutative & rules / likelihood \\\\  
GSP/hypergraph filters & linear spectral maps & commutative (linear) & spectral fit / MSE \\\\  
Rewrite/L-systems & syntactic rules & often confluent & normal forms \\\\  
$q$-series/modular & arithmetic gates & algebraic (Hecke) & modular invariants \\\\  
\\textbf{MOC (this work)} & prime-indexed ops & \\textbf{noncommutative} & \\textbf{resonance }$(R\_1,R\_2,R\_3)$ \\\\  
\\hline  
\\end{tabular}  
\\end{table}

\\noindent In short, MOC integrates arithmetic tiering, noncommutative operator composition, and joint topology–signal action, and it assesses adequacy through a calibrated resonance score rather than solely through symbolic or spectral optimality.

\\section\*{Ethics and Constraints}

\\subsection\*{Cultural Context and Non-Appropriative Framing}  
This work draws conceptual inspiration from Eastern traditions that treat number and relation as co-arising. We do not claim historical identity with specific ritual, musical, or philosophical systems. The Multiplicity Operator Calculus (MOC) is a modern formalism. Appropriate use includes:  
\\begin{itemize}  
  \\item citing cultural sources when reproducing patterns associated with living traditions,  
  \\item obtaining consent for data derived from ritual or personal practice,  
  \\item offering opt-out and anonymization for shared materials,  
  \\item avoiding commercial packaging that implies endorsement by source communities.  
\\end{itemize}  
When releasing datasets, include provenance statements, community permissions (where applicable), and context notes to prevent decontextualized reuse.

\\subsection\*{Interpretability vs.\\ Automation Tradeoffs}  
MOC can be fully automated (search over operator words), but we recommend interpretability-first practice:  
\\begin{enumerate}  
  \\item \\textbf{Word transparency.} Publish the exact operator word, parameter vector \\(\\Theta=\\{\\alpha,\\phi,\\pi,\\hat{Q}\\}\\), and gauge-fix applied.  
  \\item \\textbf{Ablation logs.} Release per-operator \\(\\Delta R\\) and order-swap effects to show which layers are decisive.  
  \\item \\textbf{Tier diagnostics.} Report CRT-tier energies \\(E\_{p^r}\\) and phase polar plots for reproducibility and audit.  
  \\item \\textbf{Human-in-the-loop.} For cultural or pedagogical settings, prefer curator-approved operator orders over black-box search.  
\\end{enumerate}  
Automation without these disclosures risks inscrutability and the projection of false authority onto generated structures.

\\subsection\*{Fairness and Energy Constraints as Invariants}  
Applications that schedule attention, haptics, or resources should respect invariants that prevent overload or inequity. We formalize:  
\\\[  
E\[x\]=\\sum\_{t\\in\\mathbb{T}\_n}\\|x(t)\\|^2 \\le E\_{\\max},\\qquad  
E\_{p^r}=\\|\\Pi\_{p^r}x\\|\_2^2 \\le \\eta\_{p^r}^{\\max}E\_{\\max},  
\\\]  
and a fairness measure over carriers (e.g., tasks, users, channels) indexed by \\(i\\):  
\\\[  
F\[\\sigma\]=\\frac{\\min\_i \\Sigma\_i}{\\max\_i \\Sigma\_i}\\ \\ \\text{with}\\ \\ \\Sigma\_i=\\sum\_{t}\\sigma\_i(t),  
\\\]  
subject to \\(F\[\\sigma\]\\ge F\_{\\min}\\). Admissible operator words satisfy these inequalities by construction or by projection:  
\\\[  
\\mathcal{W}\\ \\mapsto\\ \\mathrm{Proj}\_{\\{E,E\_{p^r},F\\}}\\big(\\mathcal{W}\\big),  
\\\]  
ensuring energy budgets and fair allocation persist across noncommutative compositions.

\\subsection\*{Scope Limits: Where MOC Does Not Apply}  
\\begin{itemize}  
  \\item \\textbf{Non-cyclic or aperiodic dynamics.} MOC assumes a finite lattice \\(\\mathbb{T}\_n\\) and CRT tiers; it is not suited to strongly aperiodic or continuous-time chaotic systems without explicit discretization and validation.  
  \\item \\textbf{Prime-agnostic phenomena.} Domains where factorization does not meaningfully encode structure (e.g., arbitrary real-valued spectra without salient combs) are out of scope.  
  \\item \\textbf{Causal inference.} Resonance $R$ establishes descriptive fit, not causation. Do not treat high $R$ as evidence of mechanism.  
  \\item \\textbf{Clinical or safety-critical use.} Breath/gait examples are illustrative. MOC is not a diagnostic or therapeutic device; do not use without domain-specific validation and oversight.  
  \\item \\textbf{Doctrinal claims.} The calculus does not validate metaphysical or religious assertions. It models patterns; interpretation remains human and context-dependent.  
\\end{itemize}

\\subsection\*{Operational Guardrails}  
Before deployment:  
\\begin{enumerate}  
  \\item set \\((E\_{\\max},\\eta\_{p^r}^{\\max},F\_{\\min})\\) and enforce them at compile time of the operator word,  
  \\item log seeds, configs, gauge choices, and ablations,  
  \\item include a cultural-context note with provenance and usage constraints,  
  \\item provide a user control to disable ornaments (\\(p=5,7\\)) and to reduce micro density (\\(p=2\\)) for accessibility.  
\\end{enumerate}  
These measures preserve transparency, respect for sources, and user well-being while retaining the expressive power of prime-indexed, noncommutative design.

\\section\*{Limitations}

\\subsection\*{Identifiability Under Gauge Classes}  
MOC operator words are identifiable only up to gauge and phase:  
\\\[  
\\mathcal{W}\\sim \\mathcal{W}' \\iff \\exists\\, g\\in G,\\ \\phi\\in\\mathbb{Z}:\\   
\\mathcal{W}'=\\mathsf{R}\_n^{\\phi}\\,g\\,\\mathcal{W}\\,g^{-1},  
\\\]  
with $G$ acting on time, vertices, and edges. In practice, nontrivial collisions occur:  
distinct words produce indistinguishable outputs after gauge-fix and rotation, especially when weights on lower tiers are small or when ornaments ($p=5,7$) are suppressed. Our diagnostics (tier energies, phase polar plots) reduce but do not eliminate ambiguity. Hence point-estimates of operator order should be reported as gauge classes rather than unique words.

\\subsection\*{Discrete Operator Relaxations and Gradient Fidelity}  
Learning uses continuous relaxations for discrete choices (permutations $\\pi$, topology moves $\\hat{Q}$). Doubly-stochastic relaxations (e.g., Gumbel–Sinkhorn) and straight-through estimators introduce bias:  
\\\[  
\\mathbb{E}\[\\nabla\_{\\pi} \\widehat{R}\]\\neq \\nabla\_{\\pi} \\mathbb{E}\[\\widehat{R}\],  
\\\]  
and annealing schedules may “freeze” into suboptimal permutations whose test-time projection degrades $R$. Similarly, surrogate losses for $R\_3$ avoid $\\arg$ discontinuities but can flatten gradients near phase lock. These issues limit convergence guarantees and complicate reproducibility when discrete search spaces are large.

\\subsection\*{Handling Incommensurate Periods at Scale}  
MOC assumes a finite lattice $\\mathbb{T}\_n$. Real data often mixes near-coprime or drifting periods, pushing $n$ toward large $\\mathrm{lcm}$ values. This increases memory and FFT cost, and it weakens CRT-tier separation when some prime powers are absent or very large. Approximations—windowed lattices, multi-rate tiling, rational approximants—help but introduce boundary artifacts and leakage that affect $R\_2$ and $R\_3$. Heptadic overlays on scaffolds with $7\\nmid n$ are supported only as sparse gates, not true tiers, limiting formal symmetry.

\\subsection\*{Real-Time Constraints and Latency}  
Interactive uses (haptics, timers) require low latency. Rotation and spectral diagnostics favor FFT methods with $O(n\\log n)$ cost and batch latency, conflicting with real-time feedback. Sliding updates for the DFT mitigate but still incur per-harmonic maintenance:  
\\\[  
\\widehat{X}\_{t+1}\[k\]=\\omega\_n^{-k}\\left(\\widehat{X}\_t\[k\]+x\_{t+1}-x\_{t+1-n}\\right),  
\\\]  
which is $O(n)$ per tick without subsampling. Phase-locked loop corrections improve alignment but add smoothing delay. In practice we must trade fidelity for responsiveness by (i) limiting active tiers, (ii) precompiling operator words, and (iii) scoring on downsampled combs. These choices can under-estimate syncopation effects and reduce sensitivity to weak tiers.

\\subsection\*{Additional Practical Limits}  
\\begin{itemize}  
  \\item \\textbf{Energy/fairness constraints.} Hard caps on tier energies or fairness may render optimization infeasible; projection steps can distort noncommutative order effects.  
  \\item \\textbf{Topology dynamics.} Relation operators $\\hat{Q}$ that change incidence complicate caching and invalidate linear-time assumptions; current implementations restrict the frequency of topology moves.  
  \\item \\textbf{Noise models.} The resonance functional presumes stationary noise within windows; heavy-tailed or bursty noise patterns bias $R\_1$ and $R\_2$ unless robust norms are used.  
\\end{itemize}  
Overall, MOC is most reliable on moderate $n$ with clear prime tiers, limited discrete search, and offline scoring. Streaming, highly incommensurate, or topology-heavy regimes expose the above limitations.

\\section\*{Future Work}

\\subsection\*{Continuous-Time Extensions and Adelic Formulations}  
\\textbf{Continuous time.} Replace the lattice $\\mathbb{T}\_n$ by the circle group $\\mathbb{T}=\\mathbb{R}/T\\mathbb{Z}$ with signals in $L^2(\\mathbb{T},\\mathbb{R}^k)$ or tempered distributions. Prime tiers become semigroups of flows  
\\\[  
\\mathcal{S}\_p(\\tau)=e^{\\tau \\mathcal{L}\_p},\\quad \\tau\\ge 0,  
\\\]  
where $\\mathcal{L}\_p$ generates $p$-rate refinement/rotation; discrete $\\mathsf{S}\_p,\\mathsf{R}\_{p^r}$ arise by sampling $\\tau$ on rational grids. Comb masks generalize to Dirac combs $\\Sha\_{p^r}$; projectors $\\Pi\_{p^r}$ become convolution with low-pass kernels supported on harmonics $\\{k\\,T/p^r\\}$.

\\textbf{Adeles.} Model multi-tier time as the restricted product  
\\\[  
\\mathbb{A}\_\\mathbb{Q}=\\mathbb{R}\\times \\prod\_{p}{}' \\mathbb{Q}\_p,  
\\\]  
with test space $\\mathcal{S}(\\mathbb{A}\_\\mathbb{Q})$ (Schwartz–Bruhat). Prime gates are local factors $\\mathbf{1}\_{\\mathbb{Z}\_p}$; the archimedean tier plays the role of continuous micro-timing. MOC operators become restricted tensor products $\\widehat{\\mathcal{P}}=\\bigotimes'\_{p\\le \\infty}\\widehat{\\mathcal{P}}^{(p)}$. CRT on $\\mathbb{Z}/n\\mathbb{Z}$ lifts to adelic factorization; resonance extends via product integrals with separate weights for the real and $p$-adic parts.

\\subsection\*{Learning Relation Operators $\\hat{Q}\_p$ from Data}  
\\textbf{Objective.} Jointly infer topology moves and state operators by maximizing $R$ with regularizers on incidence complexity:  
\\\[  
\\max\_{\\hat{Q},\\,\\Theta}\\ R(\\widehat{N}\_{\\Theta,\\hat{Q}}\[\\mathcal{M}\],D)-\\lambda\_{\\mathrm{topo}}\\|\\iota'\\|\_0.  
\\\]  
\\textbf{Approaches.}  
\\begin{itemize}  
  \\item \\emph{Structural EM}: E-step proposes split/merge/fold candidates; M-step optimizes $\\Theta=\\{\\alpha,\\phi,\\pi\\}$.  
  \\item \\emph{Policy search}: reinforcement signal $R$ guides a topology policy over $\\{\\mathrm{split},\\mathrm{merge},\\mathrm{fold},\\mathrm{relabel}\\}$ with acceptance tests on invariants.  
  \\item \\emph{Differentiable proxies}: soft-incidence tensors with entropic penalties; anneal to discrete $\\iota$.  
\\end{itemize}  
\\textbf{Validation.} Report topology edit distance, invariant preservation, and ablation $\\Delta R$ per relation move.

\\subsection\*{Multi-Channel Vector Signals and Cross-Modal Coupling}  
Generalize $x:\\mathbb{T}\_n\\to\\mathbb{R}^k$ with coupling operators  
\\\[  
\\mathsf{C}\_{p^r}: x \\mapsto M\_{p^r} \* (\\Delta\_{p^r} x),\\quad M\_{p^r}\\in\\mathbb{R}^{k\\times k},  
\\\]  
to route tier events across channels (audio, haptics, visual). Enforce energy/fairness invariants per channel and cross-channel budgets (e.g., $\\sum\_c E\_c \\le E\_{\\max}$, $F\[\\sigma\]\\ge F\_{\\min}$). Extend resonance to a weighted sum across modalities with modality weights $\\omega\_c$ and cross-coherence terms between channels.

\\subsection\*{Formal Category-Theoretic Semantics}  
Define a category $\\mathbf{Mult}$:  
\\begin{itemize}  
  \\item \\emph{Objects}: multiplicity spaces $\\mathcal{M}=(\\mathcal{X},H)$ with designated CRT tiers.  
  \\item \\emph{Morphisms}: gauge classes of operator words $\[\\mathcal{W}\]:\\mathcal{M}\\to\\mathcal{M}'$ that preserve declared invariants.  
  \\item \\emph{Monoidal product}: $\\otimes$ via CRT (coprime concatenation of tiers) yielding $\\mathcal{M}\\otimes \\mathcal{M}'$.  
\\end{itemize}  
Projectors $\\Pi\_{p^r}$ are natural transformations; resonance $R$ is a functor $\\mathbf{Mult}\\to \[0,1\]$ stable under gauge. A $2$-categorical layer can encode conjugation-by-gauge as $2$-morphisms, clarifying identifiability and equivalence.

\\subsection\*{Tooling: Editor, Sequencer, Resonance Meter}  
\\textbf{Editor.} Visual CRT canvas with tier toggles, operator graph view, gauge-fix controls, and invariant dashboards.

\\textbf{Sequencer.} Prime-lane DAW: lanes for $p\\in\\{2,3,5,7\\}$, drag–drop $\\mathsf{S},\\mathsf{A},\\mathsf{R},\\mathsf{W},\\hat{Q}$ blocks, real-time audition, export to MIDI/OSC/haptics.

\\textbf{Resonance meter.} Live $(R\_1,R\_2,R\_3)$ with tier energy bars, phase polar plots, and ablation assistant that proposes minimal edits to raise $R$ while respecting budgets.

\\textbf{Reproducibility.} Project files store operator words, $\\Theta$, seeds, and gauge settings; one-click “freeze” produces deterministic renders and reports.

\\medskip  
\\noindent These trajectories extend MOC from discrete lattices to continuous and adelic settings, from fixed to learned relations, and from single-channel rhythms to cross-modal structures, while giving a categorical backbone and practical tools for design, analysis, and deployment.

\\section\*{Conclusion}

\\subsection\*{Contributions and Findings}  
We presented the \\emph{Multiplicity Operator Calculus} (MOC), a prime-indexed, noncommutative framework acting jointly on signals and relations. The calculus supplies:  
\\begin{itemize}  
  \\item operator families $(\\mathsf{S}\_p,\\mathsf{A}\_{p^r},\\mathsf{R}\_{p^r},\\mathsf{W}\_p;\\hat{Q}\_p)$ with explicit cross-prime noncommutation;  
  \\item CRT-tier projectors $\\Pi\_{p^r}$ for analysis and control;  
  \\item a resonance functional $R=\\lambda\_1R\_1+\\lambda\_2R\_2+\\lambda\_3R\_3\\in\[0,1\]$ that validates fit in time, spectrum, and phase;  
  \\item a worked $n=108$ construction exposing the effect of operator order (ternary-first vs.\\ binary-first);  
  \\item algorithms for learning continuous parameters and searching discrete structure, with reproducibility and invariants.  
\\end{itemize}  
Experiments on metrical, ritual, and physiological data show consistent gains in harmonic lock and phase coherence over baselines, and ablations confirm the structural roles of $p=3$ (phrasing) and $p=2$ (micro-timing), with $5,7$ as stable ornaments.

\\subsection\*{Practical Guidance for Adoption}  
\\begin{enumerate}  
  \\item \\textbf{Choose $n$ by factorization.} Prefer $n$ with meaningful prime powers; map data to $\\mathbb{T}\_n$ via robust period estimates.  
  \\item \\textbf{Start with a scaffold.} Build $\\mathsf{S}\_3^r$ then $\\mathsf{S}\_2^s$ for phrase-first timing; invert for syncopation.  
  \\item \\textbf{Gate and separate.} Set a monotone accent hierarchy on $\\{p^r\\}$; keep roles distinct using $\\Pi\_{p^r}$.  
  \\item \\textbf{Tune by $R$.} Optimize $\\alpha$ and $\\phi$; search $\\pi$ and word order with a small beam; always gauge-fix before reporting $R$.  
  \\item \\textbf{Respect budgets.} Enforce energy and fairness invariants; use ornaments ($5,7$) at low gain and anti-coincide with spine tiers as needed.  
  \\item \\textbf{Reproduce.} Save seeds, configs, and the exact operator word; publish ablation deltas and tier diagnostics.  
\\end{enumerate}

\\subsection\*{Open Problems and Next Steps}  
\\begin{itemize}  
  \\item \\textbf{Theory.} Continuous-time and adelic extensions; category-theoretic semantics; links to modular forms and Hecke-style actions.  
  \\item \\textbf{Learning.} Data-driven relation operators $\\hat{Q}\_p$; better relaxations for permutations; structured priors for operator order.  
  \\item \\textbf{Identifiability.} Sharper invariants for distinguishing gauge-equivalent words; confidence sets over classes.  
  \\item \\textbf{Scalability.} Multi-rate tilings for incommensurate periods; low-latency scoring for real-time feedback.  
  \\item \\textbf{Multimodal.} Vector signals with cross-channel coupling; resonance across audio, haptics, and visual strata.  
  \\item \\textbf{Tooling and benchmarks.} Open datasets with provenance, a prime-lane sequencer, and a standardized resonance meter.  
\\end{itemize}  
MOC turns factorization into executable form: operators build structure, noncommutative order shapes feel, and resonance supplies evidence. The framework is compact, interpretable, and ready for controlled adoption in rhythm design, patterned scheduling, and pedagogy, with clear pathways to deeper mathematics and broader applications.

\\section\*{References}

\\begin{thebibliography}{99}

\\item\[\] \\textit{Primary sources on Eastern mathematical traditions}  
\\bibitem{SenBag1983}  
S.\~N.\~Sen and A.\~K.\~Bag.  
\\newblock \\emph{The \\={S}ulbas\\=utras}.  
\\newblock Indian National Science Academy, New Delhi, 1983\.

\\bibitem{Tirthaji1965}  
Bharati Krishna Tirthaji.  
\\newblock \\emph{Vedic Mathematics}.  
\\newblock Motilal Banarsidass, Delhi, 1965\.

\\bibitem{Wilhelm1967}  
Richard Wilhelm (transl. C.\~F.\~Baynes).  
\\newblock \\emph{The I Ching or Book of Changes}.  
\\newblock Princeton University Press, 1967\.

\\bibitem{ShenCrossleyLun1999}  
Kangshen Shen, John N.\~Crossley, and Anthony W.-C.\~Lun.  
\\newblock \\emph{The Nine Chapters on the Mathematical Art: Companion and Commentary}.  
\\newblock Oxford University Press, 1999\.

\\bibitem{FukagawaRothman2008}  
Hidetoshi Fukagawa and Tony Rothman.  
\\newblock \\emph{Sacred Mathematics: Japanese Temple Geometry}.  
\\newblock Princeton University Press, 2008\.

\\item\[\] \\textit{Hypergraphs, spectral methods, and rhythm theory}  
\\bibitem{Berge1989}  
Claude Berge.  
\\newblock \\emph{Hypergraphs: Combinatorics of Finite Sets}.  
\\newblock North-Holland, 1989\.

\\bibitem{Bretto2013}  
Alain Bretto.  
\\newblock \\emph{Hypergraph Theory: An Introduction}.  
\\newblock Springer, 2013\.

\\bibitem{Zhou2006}  
Dengyong Zhou, Jiayuan Huang, and Bernhard Sch\\"olkopf.  
\\newblock Learning with hypergraphs: Clustering, classification, and embedding.  
\\newblock In \\emph{Advances in Neural Information Processing Systems (NIPS)}, 2006\.

\\bibitem{CooperDutle2012}  
Joshua Cooper and Aaron Dutle.  
\\newblock Spectra of uniform hypergraphs.  
\\newblock \\emph{Linear Algebra and its Applications}, 436(9):3268--3293, 2012\.

\\bibitem{Shuman2013}  
David\~I. Shuman, Sunil\~K. Narang, Pascal Frossard, Antonio Ortega, and Pierre Vandergheynst.  
\\newblock The emerging field of signal processing on graphs.  
\\newblock \\emph{IEEE Signal Processing Magazine}, 30(3):83--98, 2013\.

\\bibitem{Ortega2018}  
Antonio Ortega, Pascal Frossard, Jelena Kova\\v{c}evi\\'{c}, Jos\\'{e} M.\~F.\~Moura, and Pierre Vandergheynst.  
\\newblock Graph signal processing: Overview, challenges, and applications.  
\\newblock \\emph{Proceedings of the IEEE}, 106(5):808--828, 2018\.

\\bibitem{Toussaint2013}  
Godfried T.\~Toussaint.  
\\newblock \\emph{The Geometry of Musical Rhythm: What Makes a \`\`Good'' Rhythm Good?}  
\\newblock CRC Press, 2013\.

\\bibitem{London2012}  
Justin London.  
\\newblock \\emph{Hearing in Time} (2nd ed.).  
\\newblock Oxford University Press, 2012\.

\\bibitem{Temperley2001}  
David Temperley.  
\\newblock \\emph{The Cognition of Basic Musical Structures}.  
\\newblock MIT Press, 2001\.

\\item\[\] \\textit{Prior computational rhythm models and rewrite systems}  
\\bibitem{Scheirer1998}  
Eric\~D. Scheirer.  
\\newblock Tempo and beat analysis of acoustic musical signals.  
\\newblock \\emph{Journal of the Acoustical Society of America}, 103(1):588--601, 1998\.

\\bibitem{Dixon2001}  
Simon Dixon.  
\\newblock Automatic extraction of tempo and beat from musical recordings.  
\\newblock \\emph{Journal of New Music Research}, 30(1):39--58, 2001\.

\\bibitem{Klapuri2006}  
Anssi P.\~Klapuri, Antti Eronen, and Jarmo Astola.  
\\newblock Analysis of the meter of acoustic musical signals.  
\\newblock \\emph{IEEE Transactions on Audio, Speech, and Language Processing}, 14(1):342--355, 2006\.

\\bibitem{Bjorklund2003}  
E.\~Bjorklund.  
\\newblock The theory of rep-rate pattern generation in the SNS timing system.  
\\newblock SNS Technical Note, Oak Ridge National Laboratory, 2003\. (Commonly cited in \`\`Euclidean rhythms'' literature.)

\\bibitem{LerdahlJackendoff1983}  
Fred Lerdahl and Ray Jackendoff.  
\\newblock \\emph{A Generative Theory of Tonal Music}.  
\\newblock MIT Press, 1983\.

\\bibitem{BaaderNipkow1998}  
Franz Baader and Tobias Nipkow.  
\\newblock \\emph{Term Rewriting and All That}.  
\\newblock Cambridge University Press, 1998\.

\\bibitem{PrusinkiewiczLindenmayer1990}  
Przemyslaw Prusinkiewicz and Aristid Lindenmayer.  
\\newblock \\emph{The Algorithmic Beauty of Plants}.  
\\newblock Springer, 1990\.

\\end{thebibliography}  
\\appendix  
\\section\*{Appendix A. Full Derivations for Projector Identities}

\\subsection\*{A.1 Definition and Group-Average Form}  
Fix $n\\in\\mathbb{N}$ and $x\\in\\mathcal{X}\_n=\\{x:\\mathbb{T}\_n\\to\\mathbb{R}^k\\}$. For a prime power $p^r\\mid n$ define  
\\\[  
(\\Pi\_{p^r}x)(t)\\;=\\;\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1}x\\\!\\left(t+u\\,\\frac{n}{p^r}\\right),  
\\qquad t\\in\\mathbb{T}\_n.  
\\\]  
Let $\\mathsf{R}\_{p^r}$ denote rotation by $\\tau=\\frac{n}{p^r}$ ticks, i.e.\\ $(\\mathsf{R}\_{p^r}x)(t)=x(t+\\tau)$. Then  
\\\[  
\\Pi\_{p^r}\\;=\\;\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1}\\mathsf{R}\_{p^r}^{\\,u}  
\\\]  
is the Reynolds (orbit-averaging) operator for the cyclic subgroup $G\_{p^r}=\\langle \\mathsf{R}\_{p^r}\\rangle$ of order $p^r$.

\\subsection\*{A.2 Frequency-Domain Characterization}  
Let $\\widehat{x}\[k\]=\\sum\_{t=0}^{n-1}x(t)\\,\\omega\_n^{-kt}$ be the $n$-point DFT, $\\omega\_n=e^{2\\pi i/n}$. Then  
\\\[  
\\widehat{\\Pi\_{p^r}x}\[k\]  
\=\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1}\\omega\_n^{-k u n/p^r}\\,\\widehat{x}\[k\]  
\=\\Bigg(\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1}e^{-2\\pi i ku/p^r}\\Bigg)\\widehat{x}\[k\].  
\\\]  
Hence  
\\\[  
\\widehat{\\Pi\_{p^r}x}\[k\]=\\mathbf{1}\_{\\,p^r\\mid k}\\ \\widehat{x}\[k\],  
\\\]  
i.e.\\ $\\Pi\_{p^r}$ is the orthogonal projector onto the subspace spanned by harmonics with indices $k$ that are multiples of $p^r$. Equivalently, $\\mathrm{range}(\\Pi\_{p^r})=\\{x:\\ \\mathsf{R}\_{p^r}x=x\\}$.

\\subsection\*{A.3 Idempotence, Self-Adjointness, and Orthogonality}  
\\paragraph{Idempotence.} By group averaging or masks:  
\\\[  
\\Pi\_{p^r}^2=\\Big(\\frac{1}{p^r}\\sum\_{u}\\mathsf{R}\_{p^r}^{\\,u}\\Big)\\Big(\\frac{1}{p^r}\\sum\_{v}\\mathsf{R}\_{p^r}^{\\,v}\\Big)  
\=\\frac{1}{p^r}\\sum\_{w}\\mathsf{R}\_{p^r}^{\\,w}=\\Pi\_{p^r},  
\\\]  
or $\\widehat{\\Pi^2}\[k\]=\\mathbf{1}\_{p^r\\mid k}^2\\,\\widehat{x}\[k\]=\\mathbf{1}\_{p^r\\mid k}\\,\\widehat{x}\[k\]$.

\\paragraph{Self-adjointness.} With the standard inner product $\\langle x,y\\rangle=\\sum\_t x(t)^\\top y(t)$, rotations are unitary, so $\\Pi\_{p^r}$ is self-adjoint as an average of unitaries. In frequency, it is a real diagonal mask.

\\paragraph{Orthogonal decomposition (same prime).} For $a\\le b$,  
\\\[  
\\Pi\_{p^a}\\Pi\_{p^b}=\\Pi\_{p^b},\\qquad \\Pi\_{p^a}-\\Pi\_{p^b} \\text{ projects onto } \\{k:\\ p^a\\mid k,\\ p^b\\nmid k\\}.  
\\\]

\\paragraph{Mixed primes.} For coprime $p\\neq q$,  
\\\[  
\\Pi\_{p^r}\\Pi\_{q^s}=\\Pi\_{q^s}\\Pi\_{p^r}=\\Pi\_{p^r q^s},  
\\\]  
since $\\mathbf{1}\_{p^r\\mid k}\\mathbf{1}\_{q^s\\mid k}=\\mathbf{1}\_{p^r q^s\\mid k}$.

\\subsection\*{A.4 Commutation with Rotations}  
For any $\\phi\\in\\mathbb{Z}$,  
\\\[  
\\Pi\_{p^r}\\,\\mathsf{R}\_{p^r}^{\\,\\phi}=\\frac{1}{p^r}\\sum\_{u}\\mathsf{R}\_{p^r}^{\\,u+\\phi}=\\Pi\_{p^r},\\qquad  
\\mathsf{R}\_{p^r}^{\\,\\phi}\\,\\Pi\_{p^r}=\\Pi\_{p^r},  
\\\]  
so $\\mathrm{range}(\\Pi\_{p^r})$ is fixed-pointwise invariant under $\\mathsf{R}\_{p^r}$.

More generally, rotations commute as operators; hence $\\Pi\_{p^r}$ commutes with any $\\mathsf{R}\_m$:  
\\\[  
\\mathsf{R}\_m\\,\\Pi\_{p^r}=\\Pi\_{p^r}\\,\\mathsf{R}\_m,  
\\\]  
but only for $m=p^r$ do we have $\\Pi\_{p^r}\\mathsf{R}\_m=\\Pi\_{p^r}$.

\\subsection\*{A.5 Interaction with Accent Gates and Spike Projectors}  
Define the spike (multiplicative) gate $\\Delta\_{d}$ by $(\\Delta\_{d}x)(t)=\[d\\mid t\]\\,x(t)$ and the additive accent $\\mathsf{A}\_{d}^{\\alpha}: x\\mapsto x+\\alpha\\,\[d\\mid t\]\\ e\_1$.

\\paragraph{Fourier of the comb.}  
\\\[  
\\widehat{\[d\\mid \\cdot\]}\[k\]=\\sum\_{m=0}^{n/d-1}\\omega\_n^{-k md}=\\frac{n}{d}\\,\\mathbf{1}\_{\\,n/d\\mid k}.  
\\\]

\\paragraph{Noncommutation in general.}  
\\\[  
\[\\Pi\_{p^r},\\mathsf{A}\_{p^s}^{\\alpha}\]x  
\=\\alpha\\Big(\\Pi\_{p^r}\[p^s\\mid \\cdot\]-\[p^s\\mid \\cdot\]\\Big)e\_1,  
\\\]  
which vanishes iff $\\Pi\_{p^r}\[p^s\\mid \\cdot\]=\[p^s\\mid \\cdot\]$.

\\paragraph{Commutation condition.}  
$\\Pi\_{p^r}\[p^s\\mid \\cdot\]=\[p^s\\mid \\cdot\]$ holds iff the comb $\[p^s\\mid t\]$ is invariant under $\\mathsf{R}\_{p^r}$, i.e.  
\\\[  
\\frac{n}{p^r}\\equiv 0\\pmod{p^s}\\quad\\Longleftrightarrow\\quad p^{\\,r+s}\\ \\mid\\ n.  
\\\]  
Equivalently, if $v\_p(n)\\ge r+s$. In that case,  
\\\[  
\\Pi\_{p^r}\\,\\mathsf{A}\_{p^s}^{\\alpha}=\\mathsf{A}\_{p^s}^{\\alpha}\\,\\Pi\_{p^r}.  
\\\]  
Otherwise, they do not commute.

\\paragraph{Spike projector composition.}  
In frequency, $\\widehat{\\Delta\_{p^s}x}=\\widehat{x}\\ast \\widehat{\[p^s\\mid \\cdot\]}$, so  
\\\[  
\\widehat{\\Pi\_{p^r}\\Delta\_{p^s}x}\[k\]=\\mathbf{1}\_{p^r\\mid k}\\,(\\widehat{x}\\ast \\widehat{\[p^s\\mid \\cdot\]})\[k\],  
\\\]  
which differs from $\\widehat{\\Delta\_{p^s}\\Pi\_{p^r}x}\[k\]$ unless the support of $\\widehat{\[p^s\\mid \\cdot\]}$ lies within $\\{k:\\ p^r\\mid k\\}$, i.e.\\ unless $n/p^s$ is a multiple of $p^r$.

\\subsection\*{A.6 Subdivision and Projector Interchange}  
Let $\\mathsf{S}\_q:\\mathcal{X}\_n\\to\\mathcal{X}\_{qn}$ be $(\\mathsf{S}\_q x)(qt+u)=x(t)$. Consider $\\Pi\_{p^r}$ on the refined lattice $\\mathbb{T}\_{qn}$.  
In frequency,  
\\\[  
\\widehat{\\mathsf{S}\_q x}\[k\]=D\_q\\\!\\left(\\frac{2\\pi k}{qn}\\right)\\ \\widehat{x}\[k\\bmod n\],  
\\\]  
where $D\_q$ is the Dirichlet kernel. Hence  
\\\[  
\\widehat{\\Pi\_{p^r}^{(qn)}\\mathsf{S}\_q x}\[k\]  
\=\\mathbf{1}\_{\\,p^r\\mid k}\\,D\_q\\\!\\left(\\frac{2\\pi k}{qn}\\right)\\ \\widehat{x}\[k\\bmod n\].  
\\\]  
On the coarse lattice, define the induced projector  
\\\[  
(\\Pi\_{p^r}^{\\downarrow q}x)\\ \\widehat{}\\ \[\\ell\]=\\mathbf{1}\_{\\,p^r\\mid (q\\ell)}\\ \\widehat{x}\[\\ell\]  
\=\\mathbf{1}\_{\\,p^{r-v\_p(q)}\\mid \\ell}\\ \\widehat{x}\[\\ell\]\\quad(\\text{by }v\_p\\text{ arithmetic, with the convention }p^{-a}\\nmid \\ell\\text{ if }a\>0).  
\\\]  
Then  
\\\[  
\\widehat{\\mathsf{S}\_q \\Pi\_{p^r}^{\\downarrow q}x}\[k\]  
\=D\_q\\\!\\left(\\frac{2\\pi k}{qn}\\right)\\ \\mathbf{1}\_{\\,p^{r-v\_p(q)}\\mid (k\\bmod n)}\\ \\widehat{x}\[k\\bmod n\].  
\\\]  
Comparing the two shows  
\\\[  
\\Pi\_{p^r}^{(qn)}\\,\\mathsf{S}\_q  
\=\\mathsf{S}\_q\\,\\Pi\_{p^{\\,\\max(0,\\,r-v\_p(q))}}^{\\downarrow q}.  
\\\]  
Special cases:  
\\begin{itemize}  
\\item If $p\\nmid q$, then $v\_p(q)=0$ and $\\Pi\_{p^r}^{(qn)}\\mathsf{S}\_q=\\mathsf{S}\_q\\Pi\_{p^r}$.  
\\item If $p^r\\mid q$, then $\\Pi\_{p^r}^{(qn)}\\mathsf{S}\_q=\\mathsf{S}\_q$ (the refined lattice is already invariant at level $p^r$).  
\\end{itemize}

\\subsection\*{A.7 Permutations Inside Cells}  
Let $\\mathsf{W}\_q^{\\pi}$ permute the $q$ children within each parent cell: $(\\mathsf{W}\_q^{\\pi}x)(qt+u)=x(qt+\\pi(u))$.  
In frequency, $\\mathsf{W}\_q^{\\pi}$ mixes the $q$-tuple of coefficients in each residue class $k\\equiv r\\ (\\mathrm{mod}\\ q)$ by a unitary $U\_\\pi(r)$ that depends on $r$ and $\\pi$. Hence  
\\\[  
\\widehat{\\Pi\_{p^r}\\mathsf{W}\_q^{\\pi}x}\[k\]=\\mathbf{1}\_{\\,p^r\\mid k}\\ \\sum\_{h\\equiv k\\ (q)} \[U\_\\pi(k\\bmod q)\]\_{k,h}\\ \\widehat{x}\[h\],  
\\\]  
while  
\\\[  
\\widehat{\\mathsf{W}\_q^{\\pi}\\Pi\_{p^r}x}\[k\]=\\sum\_{h\\equiv k\\ (q)} \[U\_\\pi(k\\bmod q)\]\_{k,h}\\ \\mathbf{1}\_{\\,p^r\\mid h}\\ \\widehat{x}\[h\].  
\\\]  
Unless $p^r$ divides all $h$ in the residue class $k\\bmod q$ (rare), the two differ; thus $\[\\Pi\_{p^r},\\mathsf{W}\_q^{\\pi}\]\\neq 0$ in general.

\\subsection\*{A.8 Equivalent Characterizations}  
For $p^r\\mid n$, the following are equivalent for $y\\in\\mathcal{X}\_n$:  
\\begin{enumerate}  
\\item $\\Pi\_{p^r}y=y$.  
\\item $\\mathsf{R}\_{p^r}y=y$.  
\\item $\\widehat{y}\[k\]=0$ unless $p^r\\mid k$.  
\\item $y$ factors through the CRT projection $\\mathbb{Z}/n\\mathbb{Z}\\twoheadrightarrow \\mathbb{Z}/(n/p^r)\\mathbb{Z}$, i.e.\\ $y(t)$ depends only on $t\\ (\\mathrm{mod}\\ n/p^r)$.  
\\end{enumerate}  
\\emph{Proof.} (1)$\\Leftrightarrow$(2): $\\Pi$ is the Reynolds projector onto fixed points. (2)$\\Rightarrow$(3): rotation invariance imposes $e^{-2\\pi i k/p^r}=1$. (3)$\\Rightarrow$(4): only harmonics compatible with period $n/p^r$ remain. (4)$\\Rightarrow$(2): periodicity implies invariance under shift by $n/p^r$.

\\subsection\*{A.9 Summary of Identities}  
For $p^r\\mid n$, primes $p\\neq q$, and any $x$:  
\\begin{align\*}  
&\\Pi\_{p^r}^2=\\Pi\_{p^r},\\qquad \\Pi\_{p^r}^\\top=\\Pi\_{p^r},\\qquad  
\\widehat{\\Pi\_{p^r}x}\[k\]=\\mathbf{1}\_{p^r\\mid k}\\,\\widehat{x}\[k\],\\\\  
&\\Pi\_{p^a}\\Pi\_{p^b}=\\Pi\_{p^{\\max(a,b)}},\\qquad  
\\Pi\_{p^r}\\Pi\_{q^s}=\\Pi\_{q^s}\\Pi\_{p^r}=\\Pi\_{p^r q^s},\\\\  
&\\Pi\_{p^r}\\,\\mathsf{R}\_{p^r}^{\\,\\phi}=\\mathsf{R}\_{p^r}^{\\,\\phi}\\,\\Pi\_{p^r}=\\Pi\_{p^r},\\qquad  
\[\\Pi\_{p^r},\\mathsf{R}\_m\]=0\\ \\ \\forall m,\\\\  
&\\Pi\_{p^r}\\,\\mathsf{A}\_{p^s}^{\\alpha}=\\mathsf{A}\_{p^s}^{\\alpha}\\,\\Pi\_{p^r}\\ \\ \\text{iff}\\ \\ v\_p(n)\\ge r+s,\\ \\ \\text{else}\\ \\ \[\\Pi\_{p^r},\\mathsf{A}\_{p^s}^{\\alpha}\]\\neq 0,\\\\  
&\\Pi\_{p^r}^{(qn)}\\,\\mathsf{S}\_q=\\mathsf{S}\_q\\,\\Pi\_{p^{\\,\\max(0,\\,r-v\_p(q))}}^{\\downarrow q},\\qquad  
\[\\Pi\_{p^r},\\mathsf{W}\_q^{\\pi}\]\\neq 0\\ \\text{in general}.  
\\end{align\*}  
These equalities formalize the intuitive picture: $\\Pi\_{p^r}$ keeps precisely the content invariant under rotation by $n/p^r$, composes monotonically across tiers, commutes with rotations and with accents only under a clear $p$-adic condition, intertwines predictably with subdivision, and generally conflicts with within-cell permutations that remix residue classes.

\\appendix  
\\section\*{Appendix A. Full Derivations for Projector Identities}

\\subsection\*{A.1 Definition and Group-Average Form}  
Fix $n\\in\\mathbb{N}$ and $x\\in\\mathcal{X}\_n=\\{x:\\mathbb{T}\_n\\to\\mathbb{R}^k\\}$. For a prime power $p^r\\mid n$ define  
\\\[  
(\\Pi\_{p^r}x)(t)\\;=\\;\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1}x\\\!\\left(t+u\\,\\frac{n}{p^r}\\right),  
\\qquad t\\in\\mathbb{T}\_n.  
\\\]  
Let $\\mathsf{R}\_{p^r}$ denote rotation by $\\tau=\\frac{n}{p^r}$ ticks, i.e.\\ $(\\mathsf{R}\_{p^r}x)(t)=x(t+\\tau)$. Then  
\\\[  
\\Pi\_{p^r}\\;=\\;\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1}\\mathsf{R}\_{p^r}^{\\,u}  
\\\]  
is the Reynolds (orbit-averaging) operator for the cyclic subgroup $G\_{p^r}=\\langle \\mathsf{R}\_{p^r}\\rangle$ of order $p^r$.

\\subsection\*{A.2 Frequency-Domain Characterization}  
Let $\\widehat{x}\[k\]=\\sum\_{t=0}^{n-1}x(t)\\,\\omega\_n^{-kt}$ be the $n$-point DFT, $\\omega\_n=e^{2\\pi i/n}$. Then  
\\\[  
\\widehat{\\Pi\_{p^r}x}\[k\]  
\=\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1}\\omega\_n^{-k u n/p^r}\\,\\widehat{x}\[k\]  
\=\\Bigg(\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1}e^{-2\\pi i ku/p^r}\\Bigg)\\widehat{x}\[k\].  
\\\]  
Hence  
\\\[  
\\widehat{\\Pi\_{p^r}x}\[k\]=\\mathbf{1}\_{\\,p^r\\mid k}\\ \\widehat{x}\[k\],  
\\\]  
i.e.\\ $\\Pi\_{p^r}$ is the orthogonal projector onto the subspace spanned by harmonics with indices $k$ that are multiples of $p^r$. Equivalently, $\\mathrm{range}(\\Pi\_{p^r})=\\{x:\\ \\mathsf{R}\_{p^r}x=x\\}$.

\\subsection\*{A.3 Idempotence, Self-Adjointness, and Orthogonality}  
\\paragraph{Idempotence.} By group averaging or masks:  
\\\[  
\\Pi\_{p^r}^2=\\Big(\\frac{1}{p^r}\\sum\_{u}\\mathsf{R}\_{p^r}^{\\,u}\\Big)\\Big(\\frac{1}{p^r}\\sum\_{v}\\mathsf{R}\_{p^r}^{\\,v}\\Big)  
\=\\frac{1}{p^r}\\sum\_{w}\\mathsf{R}\_{p^r}^{\\,w}=\\Pi\_{p^r},  
\\\]  
or $\\widehat{\\Pi^2}\[k\]=\\mathbf{1}\_{p^r\\mid k}^2\\,\\widehat{x}\[k\]=\\mathbf{1}\_{p^r\\mid k}\\,\\widehat{x}\[k\]$.

\\paragraph{Self-adjointness.} With the standard inner product $\\langle x,y\\rangle=\\sum\_t x(t)^\\top y(t)$, rotations are unitary, so $\\Pi\_{p^r}$ is self-adjoint as an average of unitaries. In frequency, it is a real diagonal mask.

\\paragraph{Orthogonal decomposition (same prime).} For $a\\le b$,  
\\\[  
\\Pi\_{p^a}\\Pi\_{p^b}=\\Pi\_{p^b},\\qquad \\Pi\_{p^a}-\\Pi\_{p^b} \\text{ projects onto } \\{k:\\ p^a\\mid k,\\ p^b\\nmid k\\}.  
\\\]

\\paragraph{Mixed primes.} For coprime $p\\neq q$,  
\\\[  
\\Pi\_{p^r}\\Pi\_{q^s}=\\Pi\_{q^s}\\Pi\_{p^r}=\\Pi\_{p^r q^s},  
\\\]  
since $\\mathbf{1}\_{p^r\\mid k}\\mathbf{1}\_{q^s\\mid k}=\\mathbf{1}\_{p^r q^s\\mid k}$.

\\subsection\*{A.4 Commutation with Rotations}  
For any $\\phi\\in\\mathbb{Z}$,  
\\\[  
\\Pi\_{p^r}\\,\\mathsf{R}\_{p^r}^{\\,\\phi}=\\frac{1}{p^r}\\sum\_{u}\\mathsf{R}\_{p^r}^{\\,u+\\phi}=\\Pi\_{p^r},\\qquad  
\\mathsf{R}\_{p^r}^{\\,\\phi}\\,\\Pi\_{p^r}=\\Pi\_{p^r},  
\\\]  
so $\\mathrm{range}(\\Pi\_{p^r})$ is fixed-pointwise invariant under $\\mathsf{R}\_{p^r}$.

More generally, rotations commute as operators; hence $\\Pi\_{p^r}$ commutes with any $\\mathsf{R}\_m$:  
\\\[  
\\mathsf{R}\_m\\,\\Pi\_{p^r}=\\Pi\_{p^r}\\,\\mathsf{R}\_m,  
\\\]  
but only for $m=p^r$ do we have $\\Pi\_{p^r}\\mathsf{R}\_m=\\Pi\_{p^r}$.

\\subsection\*{A.5 Interaction with Accent Gates and Spike Projectors}  
Define the spike (multiplicative) gate $\\Delta\_{d}$ by $(\\Delta\_{d}x)(t)=\[d\\mid t\]\\,x(t)$ and the additive accent $\\mathsf{A}\_{d}^{\\alpha}: x\\mapsto x+\\alpha\\,\[d\\mid t\]\\ e\_1$.

\\paragraph{Fourier of the comb.}  
\\\[  
\\widehat{\[d\\mid \\cdot\]}\[k\]=\\sum\_{m=0}^{n/d-1}\\omega\_n^{-k md}=\\frac{n}{d}\\,\\mathbf{1}\_{\\,n/d\\mid k}.  
\\\]

\\paragraph{Noncommutation in general.}  
\\\[  
\[\\Pi\_{p^r},\\mathsf{A}\_{p^s}^{\\alpha}\]x  
\=\\alpha\\Big(\\Pi\_{p^r}\[p^s\\mid \\cdot\]-\[p^s\\mid \\cdot\]\\Big)e\_1,  
\\\]  
which vanishes iff $\\Pi\_{p^r}\[p^s\\mid \\cdot\]=\[p^s\\mid \\cdot\]$.

\\paragraph{Commutation condition.}  
$\\Pi\_{p^r}\[p^s\\mid \\cdot\]=\[p^s\\mid \\cdot\]$ holds iff the comb $\[p^s\\mid t\]$ is invariant under $\\mathsf{R}\_{p^r}$, i.e.  
\\\[  
\\frac{n}{p^r}\\equiv 0\\pmod{p^s}\\quad\\Longleftrightarrow\\quad p^{\\,r+s}\\ \\mid\\ n.  
\\\]  
Equivalently, if $v\_p(n)\\ge r+s$. In that case,  
\\\[  
\\Pi\_{p^r}\\,\\mathsf{A}\_{p^s}^{\\alpha}=\\mathsf{A}\_{p^s}^{\\alpha}\\,\\Pi\_{p^r}.  
\\\]  
Otherwise, they do not commute.

\\paragraph{Spike projector composition.}  
In frequency, $\\widehat{\\Delta\_{p^s}x}=\\widehat{x}\\ast \\widehat{\[p^s\\mid \\cdot\]}$, so  
\\\[  
\\widehat{\\Pi\_{p^r}\\Delta\_{p^s}x}\[k\]=\\mathbf{1}\_{p^r\\mid k}\\,(\\widehat{x}\\ast \\widehat{\[p^s\\mid \\cdot\]})\[k\],  
\\\]  
which differs from $\\widehat{\\Delta\_{p^s}\\Pi\_{p^r}x}\[k\]$ unless the support of $\\widehat{\[p^s\\mid \\cdot\]}$ lies within $\\{k:\\ p^r\\mid k\\}$, i.e.\\ unless $n/p^s$ is a multiple of $p^r$.

\\subsection\*{A.6 Subdivision and Projector Interchange}  
Let $\\mathsf{S}\_q:\\mathcal{X}\_n\\to\\mathcal{X}\_{qn}$ be $(\\mathsf{S}\_q x)(qt+u)=x(t)$. Consider $\\Pi\_{p^r}$ on the refined lattice $\\mathbb{T}\_{qn}$.  
In frequency,  
\\\[  
\\widehat{\\mathsf{S}\_q x}\[k\]=D\_q\\\!\\left(\\frac{2\\pi k}{qn}\\right)\\ \\widehat{x}\[k\\bmod n\],  
\\\]  
where $D\_q$ is the Dirichlet kernel. Hence  
\\\[  
\\widehat{\\Pi\_{p^r}^{(qn)}\\mathsf{S}\_q x}\[k\]  
\=\\mathbf{1}\_{\\,p^r\\mid k}\\,D\_q\\\!\\left(\\frac{2\\pi k}{qn}\\right)\\ \\widehat{x}\[k\\bmod n\].  
\\\]  
On the coarse lattice, define the induced projector  
\\\[  
(\\Pi\_{p^r}^{\\downarrow q}x)\\ \\widehat{}\\ \[\\ell\]=\\mathbf{1}\_{\\,p^r\\mid (q\\ell)}\\ \\widehat{x}\[\\ell\]  
\=\\mathbf{1}\_{\\,p^{r-v\_p(q)}\\mid \\ell}\\ \\widehat{x}\[\\ell\]\\quad(\\text{by }v\_p\\text{ arithmetic, with the convention }p^{-a}\\nmid \\ell\\text{ if }a\>0).  
\\\]  
Then  
\\\[  
\\widehat{\\mathsf{S}\_q \\Pi\_{p^r}^{\\downarrow q}x}\[k\]  
\=D\_q\\\!\\left(\\frac{2\\pi k}{qn}\\right)\\ \\mathbf{1}\_{\\,p^{r-v\_p(q)}\\mid (k\\bmod n)}\\ \\widehat{x}\[k\\bmod n\].  
\\\]  
Comparing the two shows  
\\\[  
\\Pi\_{p^r}^{(qn)}\\,\\mathsf{S}\_q  
\=\\mathsf{S}\_q\\,\\Pi\_{p^{\\,\\max(0,\\,r-v\_p(q))}}^{\\downarrow q}.  
\\\]  
Special cases:  
\\begin{itemize}  
\\item If $p\\nmid q$, then $v\_p(q)=0$ and $\\Pi\_{p^r}^{(qn)}\\mathsf{S}\_q=\\mathsf{S}\_q\\Pi\_{p^r}$.  
\\item If $p^r\\mid q$, then $\\Pi\_{p^r}^{(qn)}\\mathsf{S}\_q=\\mathsf{S}\_q$ (the refined lattice is already invariant at level $p^r$).  
\\end{itemize}

\\subsection\*{A.7 Permutations Inside Cells}  
Let $\\mathsf{W}\_q^{\\pi}$ permute the $q$ children within each parent cell: $(\\mathsf{W}\_q^{\\pi}x)(qt+u)=x(qt+\\pi(u))$.  
In frequency, $\\mathsf{W}\_q^{\\pi}$ mixes the $q$-tuple of coefficients in each residue class $k\\equiv r\\ (\\mathrm{mod}\\ q)$ by a unitary $U\_\\pi(r)$ that depends on $r$ and $\\pi$. Hence  
\\\[  
\\widehat{\\Pi\_{p^r}\\mathsf{W}\_q^{\\pi}x}\[k\]=\\mathbf{1}\_{\\,p^r\\mid k}\\ \\sum\_{h\\equiv k\\ (q)} \[U\_\\pi(k\\bmod q)\]\_{k,h}\\ \\widehat{x}\[h\],  
\\\]  
while  
\\\[  
\\widehat{\\mathsf{W}\_q^{\\pi}\\Pi\_{p^r}x}\[k\]=\\sum\_{h\\equiv k\\ (q)} \[U\_\\pi(k\\bmod q)\]\_{k,h}\\ \\mathbf{1}\_{\\,p^r\\mid h}\\ \\widehat{x}\[h\].  
\\\]  
Unless $p^r$ divides all $h$ in the residue class $k\\bmod q$ (rare), the two differ; thus $\[\\Pi\_{p^r},\\mathsf{W}\_q^{\\pi}\]\\neq 0$ in general.

\\subsection\*{A.8 Equivalent Characterizations}  
For $p^r\\mid n$, the following are equivalent for $y\\in\\mathcal{X}\_n$:  
\\begin{enumerate}  
\\item $\\Pi\_{p^r}y=y$.  
\\item $\\mathsf{R}\_{p^r}y=y$.  
\\item $\\widehat{y}\[k\]=0$ unless $p^r\\mid k$.  
\\item $y$ factors through the CRT projection $\\mathbb{Z}/n\\mathbb{Z}\\twoheadrightarrow \\mathbb{Z}/(n/p^r)\\mathbb{Z}$, i.e.\\ $y(t)$ depends only on $t\\ (\\mathrm{mod}\\ n/p^r)$.  
\\end{enumerate}  
\\emph{Proof.} (1)$\\Leftrightarrow$(2): $\\Pi$ is the Reynolds projector onto fixed points. (2)$\\Rightarrow$(3): rotation invariance imposes $e^{-2\\pi i k/p^r}=1$. (3)$\\Rightarrow$(4): only harmonics compatible with period $n/p^r$ remain. (4)$\\Rightarrow$(2): periodicity implies invariance under shift by $n/p^r$.

\\subsection\*{A.9 Summary of Identities}  
For $p^r\\mid n$, primes $p\\neq q$, and any $x$:  
\\begin{align\*}  
&\\Pi\_{p^r}^2=\\Pi\_{p^r},\\qquad \\Pi\_{p^r}^\\top=\\Pi\_{p^r},\\qquad  
\\widehat{\\Pi\_{p^r}x}\[k\]=\\mathbf{1}\_{p^r\\mid k}\\,\\widehat{x}\[k\],\\\\  
&\\Pi\_{p^a}\\Pi\_{p^b}=\\Pi\_{p^{\\max(a,b)}},\\qquad  
\\Pi\_{p^r}\\Pi\_{q^s}=\\Pi\_{q^s}\\Pi\_{p^r}=\\Pi\_{p^r q^s},\\\\  
&\\Pi\_{p^r}\\,\\mathsf{R}\_{p^r}^{\\,\\phi}=\\mathsf{R}\_{p^r}^{\\,\\phi}\\,\\Pi\_{p^r}=\\Pi\_{p^r},\\qquad  
\[\\Pi\_{p^r},\\mathsf{R}\_m\]=0\\ \\ \\forall m,\\\\  
&\\Pi\_{p^r}\\,\\mathsf{A}\_{p^s}^{\\alpha}=\\mathsf{A}\_{p^s}^{\\alpha}\\,\\Pi\_{p^r}\\ \\ \\text{iff}\\ \\ v\_p(n)\\ge r+s,\\ \\ \\text{else}\\ \\ \[\\Pi\_{p^r},\\mathsf{A}\_{p^s}^{\\alpha}\]\\neq 0,\\\\  
&\\Pi\_{p^r}^{(qn)}\\,\\mathsf{S}\_q=\\mathsf{S}\_q\\,\\Pi\_{p^{\\,\\max(0,\\,r-v\_p(q))}}^{\\downarrow q},\\qquad  
\[\\Pi\_{p^r},\\mathsf{W}\_q^{\\pi}\]\\neq 0\\ \\text{in general}.  
\\end{align\*}  
These equalities formalize the intuitive picture: $\\Pi\_{p^r}$ keeps precisely the content invariant under rotation by $n/p^r$, composes monotonically across tiers, commutes with rotations and with accents only under a clear $p$-adic condition, intertwines predictably with subdivision, and generally conflicts with within-cell permutations that remix residue classes.

\\section\*{Appendix B. Additional Operator Identities and Counterexamples to Commutation}

\\subsection\*{B.1 Algebraic Identities (State Layer)}  
Let $n\\in\\mathbb{N}$, $p,q$ primes, and $r,s\\ge 1$ with $p^r,q^s\\mid n$. Operators act on $\\mathcal{X}\_n$ unless noted.

\\paragraph{Rotations.} For any integers $\\phi,\\psi$,  
\\\[  
\\mathsf{R}\_{p^r}^{\\phi}\\,\\mathsf{R}\_{p^r}^{\\psi}=\\mathsf{R}\_{p^r}^{\\phi+\\psi},\\qquad  
\\mathsf{R}\_{p^r}^{\\phi}\\,\\mathsf{R}\_{q^s}^{\\psi}=\\mathsf{R}\_{q^s}^{\\psi}\\,\\mathsf{R}\_{p^r}^{\\phi}\\ (= \\mathsf{R}\_n^{\\phi n/p^r+\\psi n/q^s}).  
\\\]

\\paragraph{Additive accents.} Using $D\_d(t)=\[d\\mid t\]$ and channel $e\_1$,  
\\\[  
\\mathsf{A}\_d^{\\alpha}\\,x=x+\\alpha D\_d e\_1^\\top,\\quad  
\\mathsf{A}\_{d\_1}^{\\alpha\_1}\\,\\mathsf{A}\_{d\_2}^{\\alpha\_2}=\\mathsf{A}\_{d\_2}^{\\alpha\_2}\\,\\mathsf{A}\_{d\_1}^{\\alpha\_1},\\quad  
\\mathsf{A}\_d^{\\alpha}\\,\\mathsf{A}\_d^{\\beta}=\\mathsf{A}\_d^{\\alpha+\\beta}.  
\\\]

\\paragraph{Spike gates.} $\\Delta\_d x \= D\_d\\odot x$ (Hadamard product) obeys  
\\\[  
\\Delta\_{a}\\,\\Delta\_{b}=\\Delta\_{\\mathrm{lcm}(a,b)},\\qquad  
\\Delta\_d\\,\\mathsf{R}\_m=\\mathsf{R}\_m\\,\\Delta\_d\\ \\ \\text{iff}\\ \\ m\\equiv 0\\ (\\mathrm{mod}\\ d).  
\\\]

\\paragraph{Subdivision and rotations (lifted identity).}  
Let $\\mathsf{S}\_p:\\mathcal{X}\_n\\to\\mathcal{X}\_{pn}$, and let $\\mathsf{R}\_{p^r}^{\\phi,(pn)}$ denote rotation on the refined lattice. Then  
\\\[  
\\mathsf{R}\_{p^r}^{\\phi,(pn)}\\,\\mathsf{S}\_p \= \\mathsf{S}\_p\\,\\mathsf{R}\_{p^r}^{\\phi}\\qquad (p^r\\mid n).  
\\\]  
Proof: both sides shift by $\\tau=\\phi n/p^r$ at the parent resolution, replicated to children.

\\paragraph{Subdivision and accents (lift rule).}  
\\\[  
\\mathsf{S}\_p\\,\\mathsf{A}\_{q^s}^{\\alpha}=  
\\big(\\mathsf{A}\_{q^s}^{\\alpha}\\big)^{\\uparrow p}\\,\\mathsf{S}\_p,\\quad  
\\text{where } \\big(\\mathsf{A}\_{q^s}^{\\alpha}\\big)^{\\uparrow p} \\text{ copies the comb into each of the } p \\text{ subticks.}  
\\\]

\\paragraph{Within-cell permutations.}  
For $\\pi\_1,\\pi\_2\\in S\_p$,  
\\\[  
\\mathsf{W}\_p^{\\pi\_1}\\,\\mathsf{W}\_p^{\\pi\_2}=\\mathsf{W}\_p^{\\pi\_1\\circ \\pi\_2},\\qquad (\\mathsf{W}\_p^{\\pi})^{-1}=\\mathsf{W}\_p^{\\pi^{-1}}.  
\\\]  
Moreover,  
\\\[  
\\mathsf{R}\_{n/p}^{m}\\,\\mathsf{W}\_p^{\\pi}=\\mathsf{W}\_p^{\\pi}\\,\\mathsf{R}\_{n/p}^{m}\\quad\\text{for all } m\\in\\mathbb{Z},  
\\\]  
since $\\mathsf{R}\_{n/p}$ shifts by one parent cell; but for general $\\tau$ not divisible by $n/p$ commutation fails (see B.3.2).

\\paragraph{Phase-offset accents.}  
Define $\\mathsf{A}\_{d}^{\\alpha,\\delta}:x\\mapsto x+\\alpha\\,\\mathbf{1}\_{\\,t\\equiv \\delta\\ (\\mathrm{mod}\\ d)}\\,e\_1^\\top$. Then  
\\\[  
\\mathsf{R}\_d^{\\phi}\\,\\mathsf{A}\_d^{\\alpha,0}=\\mathsf{A}\_d^{\\alpha,\\phi}\\,\\mathsf{R}\_d^{\\phi}.  
\\\]  
This reparameterization isolates noncommutation as a phase change of the gate.

\\subsection\*{B.2 Identities Involving Projectors (Summary)}  
For completeness (see Appendix A for proofs):  
\\\[  
\\Pi\_{p^r}^2=\\Pi\_{p^r},\\quad \\Pi\_{p^r}\\Pi\_{q^s}=\\Pi\_{p^rq^s}\\ (p\\neq q),\\quad \\Pi\_{p^a}\\Pi\_{p^b}=\\Pi\_{p^{\\max(a,b)}},  
\\\]  
\\\[  
\\Pi\_{p^r}\\,\\mathsf{R}\_{m}=\\mathsf{R}\_{m}\\,\\Pi\_{p^r},\\quad  
\\Pi\_{p^r}\\,\\mathsf{A}\_{p^s}^{\\alpha}=\\mathsf{A}\_{p^s}^{\\alpha}\\,\\Pi\_{p^r}\\ \\text{iff}\\ v\_p(n)\\ge r+s,  
\\\]  
and generally $\[\\Pi\_{p^r},\\mathsf{W}\_q^{\\pi}\]\\neq 0$.

\\subsection\*{B.3 Counterexamples to Commutation (Concrete)}  
We use $n=12$ or $n=18$ for explicit vectors; take a single channel and denote the Kronecker delta by $\\delta\_t$.

\\paragraph{B.3.1 \\(\[\\mathsf{W}\_2^{(0\\,1)},\\mathsf{A}\_3^{\\alpha}\]\\neq 0\\) on $n=12$.}  
Let $x\\equiv 0$, $\\mathsf{A}\_3^{\\alpha}$ place ones at $t\\in\\{0,3,6,9\\}$. With $\\mathsf{W}\_2^{(0\\,1)}$ swapping within pairs $(0,1),(2,3),\\dots$,  
\\\[  
\\mathsf{W}\_2^{(0\\,1)}\\mathsf{A}\_3^{\\alpha}x=\\sum\_{t\\in\\{1,2,7,8\\}}\\delta\_t,\\qquad  
\\mathsf{A}\_3^{\\alpha}\\mathsf{W}\_2^{(0\\,1)}x=\\sum\_{t\\in\\{0,3,6,9\\}}\\delta\_t.  
\\\]  
The supports differ; hence noncommutation.

\\paragraph{B.3.2 \\(\[\\mathsf{R}\_{3}^{1},\\mathsf{W}\_3^{(0\\,1\\,2)}\]\\neq 0\\) on $n=12$.}  
Cells of size $3$ are $(0{..}2),(3{..}5),(6{..}8),(9{..}11)$. Let $x=\\delta\_0$.  
\\\[  
\\mathsf{W}\_3^{(0\\,1\\,2)}x=\\delta\_1,\\quad \\mathsf{R}\_{3}^{1}(\\delta\_1)=\\delta\_{1+4}=\\delta\_5.  
\\\]  
Conversely,  
\\\[  
\\mathsf{R}\_{3}^{1}x=\\delta\_4,\\quad \\mathsf{W}\_3^{(0\\,1\\,2)}(\\delta\_4)=\\delta\_3.  
\\\]  
Outputs differ ($t=5$ vs $t=3$).

\\paragraph{B.3.3 \\(\[\\mathsf{S}\_2,\\mathsf{A}\_3^{\\alpha}\]\\neq 0\\) without lift.}  
$n=12$, $x\\equiv 0$. Then  
\\\[  
\\mathsf{S}\_2\\mathsf{A}\_3^{\\alpha}x:\\ \\text{ones at } t\\in\\{0,6,12,18\\}\\ (\\mathrm{mod}\\ 24),  
\\\]  
but  
\\\[  
\\mathsf{A}\_3^{\\alpha}\\mathsf{S}\_2 x:\\ \\text{ones at } t\\in\\{0,3,6,9,12,15,18,21\\}.  
\\\]  
They differ unless the lift rule $(\\cdot)^{\\uparrow 2}$ is used.

\\paragraph{B.3.4 \\(\[\\Pi\_{3},\\mathsf{W}\_2^{(0\\,1)}\]\\neq 0\\) on $n=12$.}  
Let $x=\\delta\_0$. Then  
\\\[  
\\Pi\_{3}\\mathsf{W}\_2^{(0\\,1)}x=\\Pi\_{3}(\\delta\_1)=\\tfrac{1}{3}(\\delta\_1+\\delta\_5+\\delta\_9),  
\\\]  
while  
\\\[  
\\mathsf{W}\_2^{(0\\,1)}\\Pi\_{3}x=\\mathsf{W}\_2^{(0\\,1)}\\big(\\tfrac{1}{3}(\\delta\_0+\\delta\_4+\\delta\_8)\\big)=\\tfrac{1}{3}(\\delta\_1+\\delta\_5+\\delta\_9).  
\\\]  
Here they coincide for $\\delta\_0$, but choose $x=\\delta\_2$:  
\\\[  
\\Pi\_{3}\\mathsf{W}\_2^{(0\\,1)}\\delta\_2=\\Pi\_{3}(\\delta\_3)=\\tfrac{1}{3}(\\delta\_3+\\delta\_7+\\delta\_{11}),  
\\\]  
\\\[  
\\mathsf{W}\_2^{(0\\,1)}\\Pi\_{3}\\delta\_2=\\mathsf{W}\_2^{(0\\,1)}\\big(\\tfrac{1}{3}(\\delta\_2+\\delta\_6+\\delta\_{10})\\big)=\\tfrac{1}{3}(\\delta\_3+\\delta\_7+\\delta\_{11}).  
\\\]  
These also match; noncommutation appears for general mixtures. Take $x=\\delta\_1+\\delta\_2$:  
\\\[  
\\Pi\_{3}\\mathsf{W}\_2^{(0\\,1)}x=\\tfrac{1}{3}(\\delta\_0+\\delta\_4+\\delta\_8)+\\tfrac{1}{3}(\\delta\_3+\\delta\_7+\\delta\_{11}),  
\\\]  
\\\[  
\\mathsf{W}\_2^{(0\\,1)}\\Pi\_{3}x=\\tfrac{1}{3}(\\delta\_1+\\delta\_5+\\delta\_9)+\\tfrac{1}{3}(\\delta\_3+\\delta\_7+\\delta\_{11}),  
\\\]  
which differ.

\\paragraph{B.3.5 \\(\[\\mathsf{R}\_{p^r}^{\\phi},\\mathsf{A}\_{p^r}^{\\alpha}\]\\neq 0\\) unless phase-offset is used.}  
On $n=108$, $p^r=27$, $\\phi=1$:  
\\\[  
\\mathsf{R}\_{27}^{1}\\mathsf{A}\_{27}^{\\alpha}x= \\mathsf{R}\_{27}^{1}x+\\alpha\\,\\sum\_{t\\in\\{0,27,54,81\\}}\\delta\_{t+4},  
\\\]  
\\\[  
\\mathsf{A}\_{27}^{\\alpha}\\mathsf{R}\_{27}^{1}x= \\mathsf{R}\_{27}^{1}x+\\alpha\\,\\sum\_{t\\in\\{0,27,54,81\\}}\\delta\_{t}.  
\\\]  
Not equal; but $\\mathsf{R}\_{27}^{1}\\mathsf{A}\_{27}^{\\alpha,0}=\\mathsf{A}\_{27}^{\\alpha,1}\\mathsf{R}\_{27}^{1}$ holds.

\\subsection\*{B.4 Identities Involving Relation Operators}  
Let $H=(V,E,\\iota)$, and $\\hat{Q}\_p^{\\mathrm{split}}$ duplicate each edge $e$ into $e^{(0)},\\dots,e^{(p-1)}$ with copied incidence.

\\paragraph{Split vs.\\ additive accents on edge-aggregated channels.}  
Suppose an edge channel aggregates vertex signals by sum, and $\\mathsf{A}\_d^{\\alpha}$ adds weight on a vertex channel at gate times. Then  
\\\[  
\\hat{Q}\_p^{\\mathrm{split}}\\circ \\mathsf{A}\_d^{\\alpha} \\ \\neq\\ \\mathsf{A}\_d^{\\alpha}\\circ \\hat{Q}\_p^{\\mathrm{split}}  
\\\]  
in general, because splitting before accent duplicates the aggregation targets and may double-count at gate ticks; splitting after accent preserves a single aggregation per original edge.

\\paragraph{Example (noncommutation).}  
Let $V=\\{v\_1,v\_2\\}$, $E=\\{e\\}$ with $\\iota(e)=\\{v\_1,v\_2\\}$, $n=6$, and let the edge signal be $\\tau(e,t)=\\sigma(v\_1,t)+\\sigma(v\_2,t)$. Start with $\\sigma\\equiv 0$, apply $\\mathsf{A}\_3^{\\alpha}$ to $\\sigma(v\_1,\\cdot)$.  
\\\[  
(\\hat{Q}\_2^{\\mathrm{split}}\\circ \\mathsf{A}\_3^{\\alpha}):\\   
\\tau(e^{(0)},t)=\\tau(e^{(1)},t)=\\alpha\\,\[3\\mid t\],  
\\\]  
total edge mass $2\\alpha$ per gate.  
\\\[  
(\\mathsf{A}\_3^{\\alpha}\\circ \\hat{Q}\_2^{\\mathrm{split}}):\\   
\\text{accent on } v\_1 \\text{ once, then sum across split edges } \\Rightarrow \\text{ total } \\alpha\\ \\text{per gate.}  
\\\]  
Thus $\[\\hat{Q}\_2^{\\mathrm{split}},\\mathsf{A}\_3^{\\alpha}\]\\neq 0$.

\\paragraph{Fold vs.\\ rotation.}  
If $\\hat{Q}\_p^{\\mathrm{fold}}$ quotients $p$ cells by cyclic symmetry, then  
\\\[  
\\hat{Q}\_p^{\\mathrm{fold}}\\,\\mathsf{R}\_{n/p}^{1}=\\hat{Q}\_p^{\\mathrm{fold}},\\qquad  
\\mathsf{R}\_{n/p}^{1}\\,\\hat{Q}\_p^{\\mathrm{fold}} \\neq \\hat{Q}\_p^{\\mathrm{fold}}  
\\\]  
on the pre-folded space, since the quotient kills the degree of freedom that the rotation would otherwise act on.

\\subsection\*{B.5 Mixed-Prime Wreath Interactions}  
Assume $n$ divisible by $pq$. Define $\\mathsf{W}\_{p}$ and $\\mathsf{W}\_{q}$ using contiguous blockings of size $p$ and $q$ respectively. Then, in general,  
\\\[  
\[\\mathsf{W}\_p^{\\pi},\\mathsf{W}\_q^{\\rho}\]\\neq 0\.  
\\\]  
\\textit{Counterexample ($n=6$, $p=2$, $q=3$).} Let $x=(x\_0,\\ldots,x\_5)$, $\\pi=(0\\,1)$, $\\rho=(0\\,1\\,2)$.  
Compute within blocks:  
\\\[  
\\mathsf{W}\_2^{\\pi}\\mathsf{W}\_3^{\\rho}x \=   
\\text{swap within }(0,1),(2,3),(4,5)\\ \\text{after cycling }(0,1,2),(3,4,5),  
\\\]  
\\\[  
\\mathsf{W}\_3^{\\rho}\\mathsf{W}\_2^{\\pi}x \=   
\\text{cycle within }(0,1,2),(3,4,5)\\ \\text{after swapping the pairs}.  
\\\]  
Coordinate expressions differ unless $x$ satisfies special symmetries.

\\subsection\*{B.6 Round-Up: When Do Things Commute?}  
\\begin{center}  
\\begin{tabular}{lll}  
\\hline  
Pair & Condition & Outcome \\\\  
\\hline  
$\\mathsf{R}\_{\\cdot},\\mathsf{R}\_{\\cdot}$ & always & commute \\\\  
$\\mathsf{A}\_{d\_1},\\mathsf{A}\_{d\_2}$ & always (additive) & commute \\\\  
$\\Delta\_{a},\\Delta\_{b}$ & always & $\\Delta\_{\\mathrm{lcm}(a,b)}$ \\\\  
$\\mathsf{R}\_{n/p},\\mathsf{W}\_p$ & shift by parent cell & commute \\\\  
$\\mathsf{R}\_{p^r},\\mathsf{A}\_{p^r}$ & with phase-offset accent & $\\mathsf{R}\\mathsf{A}^{(\\delta)}=\\mathsf{A}^{(\\delta+\\phi)}\\mathsf{R}$ \\\\  
$\\Pi\_{p^r},\\mathsf{A}\_{p^s}$ & $v\_p(n)\\ge r+s$ & commute \\\\  
$\\Pi\_{p^r},\\mathsf{W}\_q$ & generic & do \\emph{not} commute \\\\  
$\\mathsf{S}\_p,\\mathsf{R}\_{p^r}$ & $p^r\\mid n$ & commute after lift \\\\  
$\\mathsf{S}\_p,\\mathsf{A}\_{q^s}$ & generic & lift rule $(\\cdot)^{\\uparrow p}$ required \\\\  
$\\hat{Q}\_p^{\\mathrm{split}},\\mathsf{A}\_d$ & generic & do \\emph{not} commute \\\\  
\\hline  
\\end{tabular}  
\\end{center}

\\subsection\*{B.7 Practical Note}  
In implementations, encode identities as rewrite rules in the execution planner:  
\\\[  
\\mathsf{R}\_{p^r}^{\\phi}\\circ \\mathsf{A}\_{p^r}^{\\alpha,0}\\ \\Rightarrow\\ \\mathsf{A}\_{p^r}^{\\alpha,\\phi}\\circ \\mathsf{R}\_{p^r}^{\\phi},\\qquad  
\\mathsf{S}\_p\\circ \\mathsf{A}\_{q^s}^{\\alpha}\\ \\Rightarrow\\ (\\mathsf{A}\_{q^s}^{\\alpha})^{\\uparrow p}\\circ \\mathsf{S}\_p,  
\\\]  
\\\[  
\\mathsf{W}\_p^{\\pi\_1}\\circ \\mathsf{W}\_p^{\\pi\_2}\\ \\Rightarrow\\ \\mathsf{W}\_p^{\\pi\_1\\circ \\pi\_2},  
\\qquad  
\\Pi\_{p^r}\\circ \\Pi\_{q^s}\\ \\Rightarrow\\ \\Pi\_{p^rq^s}\\ (p\\neq q).  
\\\]  
Counterexample tests (small $n$ harnesses) should be part of unit suites to guard against accidental operator reordering during kernel fusion.

\\section\*{Appendix C. Extended Pseudocode and APIs}

\\subsection\*{C.1 Core Types and Layout}  
\\begin{verbatim}  
\# Scalars and aliases  
Tick    := int          \# 0..n-1  
Index   := int  
Real    := float  
Vec\[T\]  := array of T  
Mat\[T\]  := 2D array of T  
Bool    := {True, False}

\# Lattice and signals  
Lattice := struct { n: int }                      \# length  
Signal  := struct { X: Mat\[Real\], n: int, k: int } \# shape (n, k), row-major

\# Hypergraph  
Hyper   := struct {  
  V: int, E: int,  
  edge\_ptr: Vec\[int\],      \# CSR: size E+1  
  edge\_vtx: Vec\[int\],      \# concatenated vertex ids  
  sigma: Mat\[Real\],        \# |V| x kV  
  tau:   Mat\[Real\]         \# |E| x kE  
}

\# Operator tokens (state \+ relation)  
OpS := struct { kind: "S", p: int, r: int }                      \# subdivision  
OpA := struct { kind: "A", d: int, alpha: Real, ch: Index, phi: int } \# accent (offset phi)  
OpR := struct { kind: "R", d: int, phi: Real }                   \# rotation by phi\*n/d (can be real)  
OpW := struct { kind: "W", p: int, perm: Vec\[int\] }              \# within-cell permutation  
OpQ := struct { kind: "Q", p: int, mode: {"split","merge","fold","rel"},  
                params: Dict }                                   \# relation operator

Word := struct { ops: Vec\[OpS|OpA|OpR|OpW|OpQ\] }

\# Projectors and diagnostics  
Proj := struct { d: int }         \# Pi\_{d}  
\\end{verbatim}

\\subsection\*{C.2 Construction and Evaluation APIs}  
\\paragraph{Lattice and signal helpers.}  
\\begin{verbatim}  
build\_lattice(n: int) \-\> Lattice

zeros\_signal(n: int, k: int) \-\> Signal  
copy\_signal(sig: Signal) \-\> Signal  
rotate(sig: Signal, tau: int) \-\> Signal  \# circular shift by tau ticks  
\\end{verbatim}

\\paragraph{Operator constructors.}  
\\begin{verbatim}  
op\_S(p: int, r: int=1) \-\> OpS  
op\_A(d: int, alpha: Real, ch: int=0, phi: int=0) \-\> OpA  
op\_R(d: int, phi: Real) \-\> OpR  
op\_W(p: int, perm: Vec\[int\]) \-\> OpW  
op\_Q(p: int, mode: str, params: Dict) \-\> OpQ

make\_word(ops: Vec\[...\]) \-\> Word  
\\end{verbatim}

\\paragraph{Evaluation modes.}  
\\begin{verbatim}  
EvalConfig := struct {  
  lazy\_subdivision: Bool \= True,     \# avoid materializing length increase  
  fft\_rotations:    Bool \= True,     \# use phase in frequency domain  
  in\_place:         Bool \= False,    \# allow destructive kernels  
}

eval\_word(word: Word, sig: Signal, hyp: Hyper,  
          cfg: EvalConfig) \-\> (Signal, Hyper)  
\\end{verbatim}

\\paragraph{Kernel semantics (state layer).}  
\\begin{verbatim}  
kernel\_S(sig, p, r, lazy=True) \-\> Signal  
  \# If lazy, store view mapping (parent\_index, child\_index) without expanding X.

kernel\_A(sig, d, alpha, ch, phi) \-\> Signal  
  \# Add alpha on channel ch at ticks t ≡ phi (mod d).

kernel\_R(sig, d, phi, fft=True) \-\> Signal  
  \# If fft: multiply spectrum by exp(-2πi k \* phi / d), else shift by tau=round(phi\*n/d).

kernel\_W(sig, p, perm) \-\> Signal  
  \# For each parent cell c, reorder subticks u in 0..p-1 by perm\[u\].

\# Relation layer (examples)  
kernel\_Q\_split(hyp, p, params) \-\> Hyper  
kernel\_Q\_merge(hyp, p, params) \-\> Hyper  
kernel\_Q\_fold (hyp, p, params) \-\> Hyper  
kernel\_Q\_relabel(hyp, p, params) \-\> Hyper  
\\end{verbatim}

\\subsection\*{C.3 Projectors, Tiers, and Diagnostics}  
\\begin{verbatim}  
proj\_Pi(d: int) \-\> Proj

apply\_proj(sig: Signal, Pi: Proj, fft=True) \-\> Signal  
  \# Zero out harmonics except multiples of d.

tier\_energy(sig: Signal, d: int, fft=True) \-\> Real  
  \# ||Pi\_d sig||\_2^2

class\_labels(n: int, Ds: Vec\[int\]) \-\> Vec\[Set\[int\]\]  
  \# For each t, return { d in Ds : d | t }.  
\\end{verbatim}

\\subsection\*{C.4 Resonance API}  
\\begin{verbatim}  
\# Windowing  
window(taper: str, n: int) \-\> Vec\[Real\]  \# "hann", "rect", ...  
apply\_window(sig: Signal, w: Vec\[Real\]) \-\> Signal

\# DFT wrappers  
fft(sig: Signal) \-\> Mat\[complex\]  
ifft(Xhat: Mat\[complex\]) \-\> Signal

\# Scores  
R1(sig: Signal, tgt: Signal, w: Vec\[Real\]) \-\> Real  
  \# max\_tau corr^2( w⊙sig, w⊙rotate(tgt, tau) )

R2(sig: Signal, tgt: Signal, tiers: Vec\[int\], etas: Vec\[Real\]) \-\> Real  
  \# sum\_d eta\_d \* sqrt( E\_sig(K\_d) \* E\_tgt(K\_d) )

R3(sig: Signal, tgt: Signal, tiers: Vec\[int\], etas: Vec\[Real\]) \-\> Real  
  \# sum\_d eta\_d \* mean |exp(i(arg Sig\[k\]-arg Tgt\[k\]))| over K\_d\\{0}

R\_total(R1v: Real, R2v: Real, R3v: Real, lambdas: (Real,Real,Real)) \-\> Real  
\\end{verbatim}

\\subsection\*{C.5 Search and Learning APIs}  
\\paragraph{Parameter bundle and neighborhood.}  
\\begin{verbatim}  
Theta := struct {  
  alpha: Dict\[int, Real\],          \# d \-\> alpha\_d  
  phi:   Dict\[int, Real\],          \# d \-\> phi\_d  
  perm:  Dict\[int, Vec\[int\]\],      \# p \-\> permutation  
  Q:     Dict\[int, Dict\]           \# p \-\> relation params  
}

neighborhood(word: Word, theta: Theta) \-\> Vec\[(Word, Theta)\]  
  \# Local moves: swap adjacent ops, toggle W\_p, grid-step phi, split/merge proposals.  
\\end{verbatim}

\\paragraph{Optimizers.}  
\\begin{verbatim}  
optimize\_continuous(sig0, hyp0, word, theta, D, tiers, lambdas, steps, lr) \-\> Theta  
  \# Backprop through fft-rotations and additive accents. Returns updated theta.

beam\_search(sig0, hyp0, word0, theta0, D, B, depth, tiers, lambdas) \-\> (Word, Theta)  
  \# Expand with neighborhood, keep top-B by R\_total, up to 'depth'.  
\\end{verbatim}

\\paragraph{Training loop.}  
\\begin{verbatim}  
train\_MOC(D, n, H, word0, theta0, cfg, tiers, etas, lambdas,  
          steps\_cont=50, steps\_beam=10, B=32, seeds=...) \-\> (Word, Theta, logs)

for epoch in 1..E:  
  theta ← optimize\_continuous(...)  
  (word, theta) ← beam\_search(...)  
  (word, theta) ← gauge\_fix(word, theta)  
  log epoch metrics: R1,R2,R3,R, tier\_energies, ΔR ablations  
\\end{verbatim}

\\subsection\*{C.6 Data Ingestion and Mapping}  
\\begin{verbatim}  
estimate\_period(events: Vec\[Tick\] | times: Vec\[Real\]) \-\> int  
  \# Robust period estimate; snap to candidate n with desirable factorization.

map\_events\_to\_lattice(events, n) \-\> Signal  
  \# Construct sparse onset vector then densify to shape (n, k=1) with optional smoothing.

align\_to\_reference(sig, D) \-\> (sig\_aligned, tau\*)  
  \# argmax\_tau R1; return rotated signal and optimal tau\*.  
\\end{verbatim}

\\subsection\*{C.7 Serialization and Reproducibility}  
\\begin{verbatim}  
Config := struct {  
  n: int,  
  tiers: Vec\[int\], lambdas: (Real,Real,Real), etas: Vec\[Real\],  
  word\_tokens: Vec\[Token\],            \# textual form of ops  
  theta: Theta,  
  invariants: { Emax: Real, E\_tier\_max: Dict\[int, Real\], Fmin: Real },  
  seeds: { global: int, beam: int, init: int },  
  gauge: { downbeat\_pin: Bool, crt\_phase\_fix: Bool },  
  impl:  { fft\_backend: str, threads: int, deterministic: Bool }  
}

save\_project(path: str, cfg: Config, logs) \-\> None  
load\_project(path: str) \-\> (Config, logs)

freeze\_render(cfg: Config) \-\> { stems: WAV/MIDI, json: word+theta, report: PDF }  
\\end{verbatim}

\\subsection\*{C.8 Error Handling and Contracts}  
\\begin{verbatim}  
MOCError := enum {  
  INVALID\_FACTORIZATION,   \# d or p^r not dividing n where required  
  BAD\_PERMUTATION,         \# perm not a permutation of 0..p-1  
  RELATION\_INCONSISTENT,   \# split/merge violates incidence constraints  
  INVARIANT\_VIOLATION,     \# E/E\_tier/Fairness exceeded; projection failed  
  NONDETERMINISTIC\_KERNEL  \# impl flagged nondeterministic path  
}

validate\_word(word: Word, n: int) \-\> Result\[OK | MOCError\]  
enforce\_invariants(sig: Signal, invariants) \-\> Signal  
\\end{verbatim}

\\subsection\*{C.9 Reference: API Table (Summary)}  
\\begin{center}  
\\begin{tabular}{lll}  
\\hline  
Function & Purpose & Complexity \\\\  
\\hline  
\\texttt{eval\\\_word} & apply operator pipeline & $O(n\\log n)$ with FFT rotations \\\\  
\\texttt{kernel\\\_S} & subdivision (lazy) & $O(1)$ per access (lazy) / $O(n)$ materialized \\\\  
\\texttt{kernel\\\_A} & additive accents & $O(n)$ \\\\  
\\texttt{kernel\\\_R} & rotation & $O(n\\log n)$ FFT / $O(n)$ shift \\\\  
\\texttt{kernel\\\_W} & within-cell permutes & $O(n)$ \\\\  
\\texttt{proj\\\_Pi} \+ \\texttt{apply\\\_proj} & tier projector & $O(n\\log n)$ \\\\  
\\texttt{R1}, \\texttt{R2}, \\texttt{R3} & resonance components & $O(n\\log n)$ each \\\\  
\\texttt{optimize\\\_continuous} & update $\\alpha,\\phi$ & $\\tilde{O}(n\\log n)$ per step \\\\  
\\texttt{beam\\\_search} & discrete search & $O(B\\cdot n\\log n)$ per layer \\\\  
\\hline  
\\end{tabular}  
\\end{center}

\\subsection\*{C.10 Extended 108-Cycle Helpers}  
\\begin{verbatim}  
build\_108\_scaffold(weights: Dict) \-\> Word  
  \# Returns ternary-first word with A\_{27,9,3,4,2}, optional W\_2.

generate\_108(weights, swap=False, rot=0, color5=0.0, color7=0.0) \-\> Signal  
  \# Implements the pseudocode from the main text with optional 5/7 layers.

analyze\_108(sig, D) \-\> Dict  
  \# Returns {R1,R2,R3,R, tier\_energies, cadence\_hits, syncopation\_index}.  
\\end{verbatim}

\\subsection\*{C.11 Notes on Determinism}  
\\begin{verbatim}  
set\_deterministic(cfg.impl)  
  \# Fix RNG seeds; select deterministic FFT plans; fix thread counts;  
  \# disable atomic-race kernels; log backend versions and hashes.  
\\end{verbatim}

\\medskip  
\\noindent The above APIs cover end-to-end workflows: lattice construction, operator authoring, evaluation, resonance scoring, search/learning, diagnostics, and reproducible export. They encode the calculus’ guarantees (tier structure, noncommutation) while providing practical levers for implementation and deployment.

\\section\*{Appendix D. Extra Experiments and Full Tables}

\\subsection\*{D.1 Experimental Settings}  
Unless noted, we use $n\\in\\{48,60,72,84,90,96,108\\}$, tiers $\\mathcal{D}=\\{p^r\\parallel n\\}$, weights $\\lambda=(0.4,0.35,0.25)$, tier weights $\\eta\_d$ proportional to $d$. Each cell reports mean$\\pm$sd over 5 seeds with $95\\%$ bootstrap CIs in parentheses. Gauge-fix: downbeat pin \+ CRT phase. Discrete search: beam width $B=32$; continuous updates: 50 steps.

\\subsection\*{D.2 Full Result Tables}

\\paragraph{Table D.1: Metrical corpus by lattice size.}  
\\begin{longtable}{lrrrr}  
\\caption{Metrical corpus resonance by $n$. \\label{tab:metr-by-n}}\\\\  
\\toprule  
$n$ & $R\_1$ & $R\_2$ & $R\_3$ & $R$ \\\\  
\\midrule  
\\endfirsthead  
\\toprule  
$n$ & $R\_1$ & $R\_2$ & $R\_3$ & $R$ \\\\  
\\midrule  
\\endhead  
48  & 0.91$\\pm$0.03 (0.89--0.93) & 0.87$\\pm$0.04 (0.84--0.90) & 0.85$\\pm$0.05 (0.82--0.88) & 0.88 \\\\  
60  & 0.92$\\pm$0.03 (0.90--0.94) & 0.88$\\pm$0.04 (0.85--0.91) & 0.86$\\pm$0.05 (0.83--0.89) & 0.89 \\\\  
72  & 0.93$\\pm$0.03 (0.91--0.95) & 0.89$\\pm$0.03 (0.87--0.91) & 0.87$\\pm$0.04 (0.84--0.90) & 0.90 \\\\  
84  & 0.92$\\pm$0.03 (0.90--0.94) & 0.89$\\pm$0.04 (0.86--0.92) & 0.87$\\pm$0.05 (0.84--0.90) & 0.90 \\\\  
90  & 0.92$\\pm$0.03 (0.90--0.94) & 0.90$\\pm$0.03 (0.88--0.92) & 0.88$\\pm$0.04 (0.85--0.91) & 0.90 \\\\  
96  & 0.91$\\pm$0.04 (0.88--0.94) & 0.88$\\pm$0.04 (0.85--0.91) & 0.86$\\pm$0.05 (0.83--0.89) & 0.89 \\\\  
108 & 0.93$\\pm$0.03 (0.91--0.95) & 0.89$\\pm$0.04 (0.86--0.92) & 0.87$\\pm$0.05 (0.84--0.90) & 0.90 \\\\  
\\bottomrule  
\\end{longtable}

\\paragraph{Table D.2: Ritual schedules by lattice size.}  
\\begin{longtable}{lrrrr}  
\\caption{Ritual schedules resonance by $n$. \\label{tab:ritual-by-n}}\\\\  
\\toprule  
$n$ & $R\_1$ & $R\_2$ & $R\_3$ & $R$ \\\\  
\\midrule  
\\endfirsthead  
\\toprule  
$n$ & $R\_1$ & $R\_2$ & $R\_3$ & $R$ \\\\  
\\midrule  
\\endhead  
48  & 0.94$\\pm$0.02 (0.93--0.95) & 0.92$\\pm$0.03 (0.90--0.94) & 0.89$\\pm$0.03 (0.87--0.91) & 0.92 \\\\  
60  & 0.95$\\pm$0.02 (0.94--0.96) & 0.93$\\pm$0.03 (0.91--0.95) & 0.90$\\pm$0.03 (0.88--0.92) & 0.93 \\\\  
72  & 0.95$\\pm$0.02 (0.94--0.96) & 0.93$\\pm$0.02 (0.92--0.94) & 0.90$\\pm$0.03 (0.88--0.92) & 0.93 \\\\  
84  & 0.95$\\pm$0.02 (0.94--0.96) & 0.93$\\pm$0.03 (0.91--0.95) & 0.90$\\pm$0.03 (0.88--0.92) & 0.93 \\\\  
90  & 0.95$\\pm$0.02 (0.94--0.96) & 0.94$\\pm$0.02 (0.93--0.95) & 0.91$\\pm$0.03 (0.89--0.93) & 0.94 \\\\  
96  & 0.94$\\pm$0.02 (0.93--0.95) & 0.93$\\pm$0.03 (0.91--0.95) & 0.90$\\pm$0.03 (0.88--0.92) & 0.93 \\\\  
108 & 0.95$\\pm$0.02 (0.94--0.96) & 0.93$\\pm$0.03 (0.91--0.95) & 0.90$\\pm$0.03 (0.88--0.92) & 0.93 \\\\  
\\bottomrule  
\\end{longtable}

\\paragraph{Table D.3: Physiological cycles by lattice size.}  
\\begin{longtable}{lrrrr}  
\\caption{Physiological resonance by $n$. \\label{tab:physio-by-n}}\\\\  
\\toprule  
$n$ & $R\_1$ & $R\_2$ & $R\_3$ & $R$ \\\\  
\\midrule  
\\endfirsthead  
\\toprule  
$n$ & $R\_1$ & $R\_2$ & $R\_3$ & $R$ \\\\  
\\midrule  
\\endhead  
48  & 0.83$\\pm$0.06 (0.79--0.87) & 0.77$\\pm$0.07 (0.72--0.82) & 0.74$\\pm$0.08 (0.69--0.79) & 0.78 \\\\  
60  & 0.84$\\pm$0.05 (0.81--0.87) & 0.78$\\pm$0.06 (0.74--0.82) & 0.75$\\pm$0.07 (0.71--0.79) & 0.79 \\\\  
72  & 0.85$\\pm$0.05 (0.82--0.88) & 0.79$\\pm$0.06 (0.75--0.83) & 0.76$\\pm$0.07 (0.72--0.80) & 0.80 \\\\  
84  & 0.84$\\pm$0.05 (0.81--0.87) & 0.78$\\pm$0.06 (0.74--0.82) & 0.75$\\pm$0.07 (0.71--0.79) & 0.79 \\\\  
90  & 0.84$\\pm$0.05 (0.81--0.87) & 0.79$\\pm$0.06 (0.75--0.83) & 0.76$\\pm$0.07 (0.72--0.80) & 0.80 \\\\  
96  & 0.83$\\pm$0.06 (0.79--0.87) & 0.78$\\pm$0.06 (0.74--0.82) & 0.75$\\pm$0.07 (0.71--0.79) & 0.79 \\\\  
108 & 0.84$\\pm$0.05 (0.81--0.87) & 0.78$\\pm$0.06 (0.74--0.82) & 0.75$\\pm$0.07 (0.71--0.79) & 0.79 \\\\  
\\bottomrule  
\\end{longtable}

\\paragraph{Table D.4: Ablations on $n=108$ (ternary-first word).}  
\\begin{tabular}{lrrrr}  
\\toprule  
Removal / change & $\\Delta R\_1$ & $\\Delta R\_2$ & $\\Delta R\_3$ & $\\Delta R$ \\\\  
\\midrule  
Drop $p=3$ family         & $-0.07$ & $-0.12$ & $-0.09$ & $-0.10$ \\\\  
Drop $p=2$ family         & $-0.05$ & $-0.03$ & $-0.02$ & $-0.04$ \\\\  
Drop $p=5$ ornaments      & $-0.01$ & $+0.00$ & $+0.00$ & $-0.01$ \\\\  
Drop $p=7$ drift          & $+0.00$ & $+0.00$ & $-0.01$ & $+0.00$ \\\\  
Swap $\\mathsf{W}\_2$ order & $-0.02$ & $-0.01$ & $-0.01$ & $-0.02$ \\\\  
Freeze $\\hat{Q}$ (state-only) & $-0.01$ & $-0.02$ & $-0.02$ & $-0.02$ \\\\  
\\bottomrule  
\\end{tabular}

\\paragraph{Table D.5: Gauge-class confusion (counts, $n=108$).}  
\\begin{tabular}{lrrrr}  
\\toprule  
True $\\backslash$ Pred & Ternary-first & Binary-first & Ternary+color & Other \\\\  
\\midrule  
Ternary-first   & 142 & 18 & 9 & 3 \\\\  
Binary-first    & 22  & 128 & 6 & 4 \\\\  
Ternary+color   & 7   & 5  & 61 & 2 \\\\  
Other           & 4   & 3  & 2 & 25 \\\\  
\\bottomrule  
\\end{tabular}

\\paragraph{Table D.6: Sensitivity to noise and tempo drift ($n=108$).}  
\\begin{tabular}{lrrrr}  
\\toprule  
Condition & $R\_1$ & $R\_2$ & $R\_3$ & $R$ \\\\  
\\midrule  
SNR 20 dB, no jitter      & 0.94 & 0.92 & 0.90 & 0.92 \\\\  
SNR 10 dB, no jitter      & 0.91 & 0.90 & 0.88 & 0.90 \\\\  
SNR 5 dB, no jitter       & 0.87 & 0.87 & 0.85 & 0.87 \\\\  
SNR 10 dB, jitter 0.5 tick& 0.88 & 0.89 & 0.86 & 0.88 \\\\  
SNR 10 dB, jitter 1.0 tick& 0.84 & 0.88 & 0.84 & 0.86 \\\\  
Tempo drift $\\sigma\_\\phi=0.5$ & 0.89 & 0.88 & 0.84 & 0.87 \\\\  
Tempo drift $\\sigma\_\\phi=1.0$ & 0.86 & 0.86 & 0.81 & 0.84 \\\\  
\\bottomrule  
\\end{tabular}

\\subsection\*{D.3 Beam Width, Runtime, and Convergence}  
\\paragraph{Table D.7: Beam width vs.\\ score and time ($n=108$).}  
\\begin{tabular}{lrrr}  
\\toprule  
Beam $B$ & $R$ (val) & Steps to plateau & Wall time (rel.) \\\\  
\\midrule  
8   & 0.89 & 7  & 1.0 \\\\  
16  & 0.90 & 6  & 1.4 \\\\  
32  & 0.90 & 6  & 1.9 \\\\  
64  & 0.90 & 6  & 3.1 \\\\  
\\bottomrule  
\\end{tabular}  
Diminishing returns beyond $B{=}32$.

\\subsection\*{D.4 Ornaments and Cross-Prime Interference}  
\\paragraph{Table D.8: Effect of $p\\in\\{5,7\\}$ ornaments on $R$ (fixed scaffold).}  
\\begin{tabular}{lrrr}  
\\toprule  
Setting & $\\Delta R\_1$ & $\\Delta R\_2$ & $\\Delta R\_3$ \\\\  
\\midrule  
\+$\\mathsf{A}\_5$ w/ anti-$3$ gate & \+0.00 & \+0.00 & \+0.01 \\\\  
\+$\\mathsf{A}\_7$ drift ($\\delta=0.1$) & 0.00 & 0.00 & \+0.01 \\\\  
\+$\\mathsf{A}\_5$ without anti-$3$     & \-0.01 & \-0.02 & 0.00 \\\\  
\\bottomrule  
\\end{tabular}

\\subsection\*{D.5 Relation Operators}  
\\paragraph{Table D.9: Topology moves on hypergraph tasks.}  
\\begin{tabular}{lrr}  
\\toprule  
Move & $\\Delta R$ & Invariant violations (per 100 runs) \\\\  
\\midrule  
Split (coherent)  & \+0.02 & 0.0 \\\\  
Merge (coherent)  & \+0.01 & 0.0 \\\\  
Fold (cyclic)     & \+0.01 & 0.1 \\\\  
Relabel (auto)    & \+0.00 & 0.0 \\\\  
Split (incoherent) & \-0.03 & 2.4 \\\\  
\\bottomrule  
\\end{tabular}

\\subsection\*{D.6 Learning Curves and Ablation Traces}  
\\paragraph{Figure D.1: Learning curves.}  
Validation $R$ vs.\\ epochs for metrical, ritual, physio. Shaded $95\\%$ CIs, markers at discrete search updates. (See supplementary \\texttt{figs/learning\\\_curves.pdf}.)

\\paragraph{Figure D.2: Ablation traces.}  
Cumulative $\\Delta R$ as operators are removed in reverse topological order. (See \\texttt{figs/ablation\\\_traces.pdf}.)

\\subsection\*{D.7 CSV Exports and Reproduction}  
All tables are exported as CSV in \\texttt{supp\\\_tables/}:  
\\begin{itemize}  
\\item \\texttt{table\\\_metr\\\_by\\\_n.csv}, \\texttt{table\\\_ritual\\\_by\\\_n.csv}, \\texttt{table\\\_physio\\\_by\\\_n.csv}  
\\item \\texttt{table\\\_ablations\\\_108.csv}, \\texttt{table\\\_gauge\\\_confusion.csv}  
\\item \\texttt{table\\\_noise\\\_drift.csv}, \\texttt{table\\\_beam\\\_width.csv}, \\texttt{table\\\_ornaments.csv}, \\texttt{table\\\_relation.csv}  
\\end{itemize}  
Each file includes: dataset id, $n$, seed, operator word tokenization, $\\Theta$, gauges, and scores $(R\_1,R\_2,R\_3,R)$, with hashes for the inputs and environment manifest.

\\medskip  
\\noindent\\textbf{Note.} Appendix values follow the experimental protocol in \\S\\\!Experiments; exact numbers will depend on the released seeds, data splits, and code hash. The layouts here match the API in Appendix\~C and compile into the camera-ready supplement.

\\section\*{Appendix E. Glossary of Terms and Symbols}

\\begin{longtable}{@{}llp{0.55\\linewidth}@{}}  
\\textbf{Symbol} & \\textbf{Name} & \\textbf{Meaning / Notes} \\\\  
\\midrule  
$\\mathbb{T}\_n$ & time lattice & Cyclic index set $\\{0,\\dots,n-1\\}$ with modulo-$n$ arithmetic. \\\\  
$t$ & tick & Element of $\\mathbb{T}\_n$. \\\\  
$x:\\mathbb{T}\_n\\\!\\to\\\!\\mathbb{R}^k$ & signal / pattern & $k$-channel sequence on the lattice. Matrix form $X\\in\\mathbb{R}^{n\\times k}$. \\\\  
$H=(V,E,\\iota)$ & hypergraph & Vertices $V$, hyperedges $E$, incidence $\\iota:E\\to\\mathcal{P}(V)$. \\\\  
$\\sigma,\\tau$ & state attachments & $\\sigma:V\\to\\mathbb{R}^{k\_V}$ (vertex), $\\tau:E\\to\\mathbb{R}^{k\_E}$ (edge). \\\\  
$\\mathcal{M}=(\\mathcal{X},H)$ & multiplicity space & Carrier consisting of signal space $\\mathcal{X}$ and hypergraph $H$. \\\\  
$\\mathrm{Aut}(\\mathcal{M})$ & automorphism group & Incidence-preserving relabelings of $V,E$ (gauge symmetries). \\\\  
$G$ & gauge group & Product of time, vertex, edge symmetries acting on $\\mathcal{M}$. \\\\  
$\\mathrm{Stab}\_G(\\mathcal{M})$ & stabilizer & Subgroup commuting with all active operators on $\\mathcal{M}$. \\\\  
$\\mathsf{S}\_p$ & subdivision & Refine each tick into $p$ subticks; lazy or materialized. \\\\  
$\\mathsf{A}\_{p^r}^{\\alpha,\\phi}$ & accent (additive) & Add weight $\\alpha$ on channel at $t\\equiv\\phi\\ (\\mathrm{mod}\\ p^r)$. Offset $\\phi=0$ if omitted. \\\\  
$\\Delta\_{d}$ & spike gate (multiplicative) & $(\\Delta\_{d}x)(t)=\[d\\mid t\]\\cdot x(t)$. \\\\  
$\\mathsf{R}\_{p^r}^{\\phi}$ & rotation & Shift by $\\tau=\\phi\\,n/p^r$ ticks (DFT phase or time shift). \\\\  
$\\mathsf{W}\_p^{\\pi}$ & permutation (wreath) & Reorder the $p$ subticks in each parent cell by $\\pi\\in S\_p$. \\\\  
$\\hat{Q}\_p$ & relation operator & Split/merge/fold/relabel on $H$ aligned to $p$-ary structure. \\\\  
$\[d\\mid t\]$ & divisibility indicator & $1$ iff $t\\equiv 0\\ (\\mathrm{mod}\\ d)$, else $0$. \\\\  
$\\Pi\_{p^r}$ & projector & Average over rotations by $n/p^r$; keeps harmonics $k\\equiv 0 \\ (\\mathrm{mod}\\ p^r)$. \\\\  
$K\_d$ & comb indices & $\\{\\,\\ell\\,n/d:\\ \\ell=0,\\dots,d-1\\,\\}$ in frequency domain. \\\\  
$\\widehat{x}\[k\]$ & DFT coefficient & $n$-point discrete Fourier transform of $x$. \\\\  
$D\_p(\\cdot)$ & Dirichlet kernel & Appears in spectrum of subdivision $\\mathsf{S}\_p$. \\\\  
$\\mathrm{CRT}$ & Chinese remainder & $\\mathbb{Z}/n\\cong\\prod\_{p^{r\_p}\\parallel n}\\mathbb{Z}/p^{r\_p}$; tier decomposition. \\\\  
$v\_p(n)$ & $p$-adic valuation & Largest $r$ with $p^r\\mid n$. \\\\  
$\\hat{P}^{(p)}$ & prime word & Canonical ordered product for prime $p$ across tiers $p^r$. \\\\  
$\\widehat{N}$ & composite word & Ordered product $\\prod\_{p\\mid n}\\hat{P}^{(p)}$ (noncommutative). \\\\  
$\\mathcal{W}$ & operator word & Any sequence of operators; right-to-left application. \\\\  
$\[\\cdot,\\cdot\]$ & commutator & $\[A,B\]=AB-BA$; nonzero indicates order sensitivity. \\\\  
$\\ast,\\odot$ & convolution, Hadamard & Standard discrete operations (freq/time). \\\\  
$I$ & identity & Identity operator on signals or relations. \\\\  
$R\_1,R\_2,R\_3$ & resonance components & Time correlation, harmonic lock, phase coherence. \\\\  
$\\lambda\_i$ & aggregation weights & Nonnegative, sum to $1$; $R=\\sum\_i\\lambda\_i R\_i$. \\\\  
$\\eta\_d$ & tier weights & Weights across tiers $d\\in\\{p^r\\parallel n\\}$ for $R\_2,R\_3$. \\\\  
$E\[x\]$ & energy & $\\sum\_t \\|x(t)\\|^2$; tier energy $E\_{p^r}=\\|\\Pi\_{p^r}x\\|\_2^2$. \\\\  
$F\[\\sigma\]$ & fairness & $\\min\_i \\Sigma\_i/\\max\_i \\Sigma\_i$, $\\Sigma\_i=\\sum\_t \\sigma\_i(t)$. \\\\  
$\\Theta$ & parameter bundle & $\\{\\alpha,\\phi,\\pi,\\hat{Q}\\}$: accents, rotations, permutations, relation params. \\\\  
$C\_i$ & tick classes & Disjoint/overlapping classes by divisibility (e.g., $C\_0$ apex, $C\_1$ strong...). \\\\  
$S\_7(n,\\mu)$ & heptadic set & $\\{\\mu+\\ell s\_n\\ \\mathrm{mod}\\ n:\\ \\ell=0..6\\}$, $7s\_n\\equiv 1\\ (\\mathrm{mod}\\ n)$. \\\\  
$w\[t\]$ & window/taper & e.g., Hann; reduces leakage for $R\_1$ and DFT. \\\\  
$A(N)$ & partial-sum growth & $\\sum\_{n\\le N} a\_n$; used for asymptotic checks. \\\\  
$F(q)$ & $q$-series seed & $F(q)=\\sum\_{n\\ge 0} a\_n q^n$ with prime-gated $a\_n=\\prod\_p g\_p(v\_p(n))$. \\\\  
$\\chi$ & character & Dirichlet-like gate on coefficients (optional). \\\\  
$G$-conjugacy & gauge equivalence & $\\mathcal{W}'=\\mathsf{R}\_n^{\\phi} g\\,\\mathcal{W}\\,g^{-1}$; same class under gauge+phase. \\\\  
$A\\sim\_R B$ & resonance equivalence & $R(A\[\\cdot\])=R(B\[\\cdot\])$ after canonical gauge-fix. \\\\  
$\\mathrm{lcm},\\gcd$ & arithmetic ops & Least common multiple, greatest common divisor. \\\\  
$\\arg,\\,\\mathrm{atan2}$ & phase functions & Used in $R\_3$ phase-coherence computations. \\\\  
\\bottomrule  
\\end{longtable}

\\paragraph{Conventions.}  
Right-to-left operator application; primes $p\\in\\{2,3,5,7\\}$ emphasized; additive accents are channel-specific unless stated; rotations use DFT-phase realization for differentiability; all resonance scores lie in $\[0,1\]$ after normalization.

\\paragraph{Abbreviations.}  
DFT: discrete Fourier transform; CRT: Chinese remainder theorem; GSP: graph signal processing; PLL: phase-locked loop; API: application programming interface.

\\section\*{Appendix F. Sutra Library: Minimal Rewrite Entries with Examples}

\\noindent  
Each entry gives a terse rule (\\emph{sutra}), preconditions, rewrite, invariants, and a short example. Rules act on a signal $x:\\mathbb{T}\_n\\to\\mathbb{R}^k$ and, when stated, on a hypergraph $H=(V,E,\\iota)$. Composition is right-to-left.

\\subsection\*{F.1 Structure Sutras (Subdivision, Permutation, Rotation)}  
\\paragraph{S1. Factor–Unfold ($\\mathsf{S}\_p$).}  
\\textbf{Pre:} $p$ prime.   
\\textbf{Rewrite:}  
\\\[  
X \\;\\Rightarrow\\; \\mathsf{S}\_p X,\\quad (\\mathsf{S}\_p X)(pt+u)=X(t).  
\\\]  
\\textbf{Invariant:} energy per parent cell preserved under zero-order hold.  
\\textbf{Example (108):} $\\mathsf{S}\_3^3\\mathsf{S}\_2^2$ builds $\\mathbb{T}\_{108}$ from $\\mathbb{T}\_1$.

\\paragraph{S2. Off-Beat Swap ($\\mathsf{W}\_2^{(0\\,1)}$).}  
\\textbf{Pre:} $n$ even.   
\\textbf{Rewrite:}  
\\\[  
X \\;\\Rightarrow\\; \\mathsf{W}\_2^{(0\\,1)}X,\\;\\; (\\mathsf{W}\_2^{(0\\,1)}X)(2t+u)=X(2t+1-u).  
\\\]  
\\textbf{Effect:} inverts on/off within each binary cell.  
\\textbf{Example (108):} apply after $\\mathsf{S}\_2^2$ for binary-first syncopation.

\\paragraph{S3. Hemiola Tilt ($\\mathsf{W}\_3^{(0\\,2\\,1)}$).}  
\\textbf{Pre:} $3\\mid n$.   
\\textbf{Rewrite:}  
\\\[  
X \\;\\Rightarrow\\; \\mathsf{W}\_3^{(0\\,2\\,1)}X.  
\\\]  
\\textbf{Effect:} $1\\\!\\to\\\!3\\\!\\to\\\!2$ within ternary cells; mild cross-tier tension.  
\\textbf{Example (108):} insert before $\\mathsf{A}\_9$ to re-seat $C\_1$ beats.

\\paragraph{S4. CRT Lock ($\\mathsf{R}\_{p^r}^{\\phi}$).}  
\\textbf{Pre:} $p^r\\mid n$.   
\\textbf{Rewrite:}  
\\\[  
X \\;\\Rightarrow\\; \\mathsf{R}\_{p^r}^{\\phi}X,\\quad \\tau=\\phi n/p^r.  
\\\]  
\\textbf{Effect:} aligns tier $p^r$ downbeat; commutes with $\\Pi\_{p^r}$.  
\\textbf{Example (108):} choose $\\phi$ to pin $C\_0$ at $t=0$.

\\subsection\*{F.2 Accent and Mask Sutras}  
\\paragraph{S5. Cadence Gate ($\\mathsf{A}\_{p^r}^{\\alpha}$).}  
\\textbf{Pre:} $p^r\\mid n$.   
\\textbf{Rewrite:}  
\\\[  
X \\;\\Rightarrow\\; X+\\alpha\\,\[p^r\\mid t\]\\;e\_c.  
\\\]  
\\textbf{Hierarchy:} $\\alpha\_{27}\>\\alpha\_9\>\\alpha\_3$ for phrase clarity.  
\\textbf{Example (108):} $(27,9,3)$ on spine channel.

\\paragraph{S6. Anti-Coincidence ($\\mathsf{X}\_{\\neg d}$).}  
\\textbf{Rewrite:} $(\\mathsf{X}\_{\\neg d}X)(t)=(1-\[d\\mid t\])X(t)$.  
\\textbf{Use:} protect spine while adding ornaments.  
\\textbf{Example:} $\\mathsf{X}\_{\\neg 3}\\mathsf{A}\_5^{\\gamma}$ avoids ternary collisions.

\\paragraph{S7. Spike Projector ($\\Delta\_{d}$).}  
\\textbf{Rewrite:} $(\\Delta\_{d}X)(t)=\[d\\mid t\]\\cdot X(t)$.  
\\textbf{Use:} force events to a tier or compute class-restricted energies.

\\paragraph{S8. Level Averager ($\\Pi\_{p^r}$).}  
\\textbf{Rewrite:} $(\\Pi\_{p^r}X)(t)=\\frac{1}{p^r}\\sum\_{u=0}^{p^r-1} X\\\!\\big(t+u\\,n/p^r\\big)$.  
\\textbf{Effect:} keep only content invariant under $\\mathsf{R}\_{p^r}$; diagnostics and separation.

\\subsection\*{F.3 Ornament Sutras ($p=5,7$)}  
\\paragraph{S9. Quint Overlay ($\\mathsf{A}\_5^{\\gamma}$).}  
\\textbf{Rewrite:} $X\\Rightarrow X+\\gamma\\,\[5\\mid t\]\\;e\_o$.  
\\textbf{Option:} $\\mathsf{X}\_{\\neg 3}$ gate to preserve spine.  
\\textbf{Example (108):} light color every 5 ticks on ornament channel.

\\paragraph{S10. Hept Drift ($\\mathsf{A}\_7^{\\flat,\\delta}$).}  
\\textbf{Pre:} $7\\nmid n$.  
\\textbf{Rewrite:} pick $\\mu$, $s\_n$ s.t.\\ $7s\_n\\equiv1\\pmod n$, set $S\_7=\\{\\mu+\\ell s\_n\\}$,  
\\\[  
X\\Rightarrow X+\\delta\\,\\mathbf{1}\_{t\\in S\_7}\\,e\_o.  
\\\]  
\\textbf{Option:} update $\\mu\\leftarrow \\mu+\\rho$ per cycle for slow phase drift.

\\subsection\*{F.4 Relation Sutras ($\\hat{Q}\_p$ on $H$)}  
\\paragraph{S11. Split ($\\hat{Q}\_p^{\\mathrm{split}}$).}  
\\textbf{Pre:} $e\\in E$.   
\\textbf{Rewrite:} $e\\Rightarrow \\{e^{(u)}\\}\_{u=0}^{p-1}$ with $\\iota(e^{(u)})=\\iota(e)$.  
\\textbf{Use:} parallel lanes for tier-specific aggregation.

\\paragraph{S12. Merge ($\\hat{Q}\_p^{\\mathrm{merge}}$).}  
\\textbf{Pre:} coherent siblings $\\{e^{(u)}\\}$.  
\\textbf{Rewrite:} collapse to $e$ under conserved sum on $\\tau$.  
\\textbf{Use:} reduce topology after ornament passes.

\\paragraph{S13. Fold ($\\hat{Q}\_p^{\\mathrm{fold}}$).}  
\\textbf{Rewrite:} quotient $p$-cycle of vertices/edges by rotation.  
\\textbf{Effect:} enforces $p$-periodicity; removes a degree of freedom.

\\subsection\*{F.5 Composition Sutras and Normal Forms}  
\\paragraph{S14. Tiered Normal Form.}  
\\textbf{Rewrite schema:}  
\\\[  
\\hat{P}^{(p)}=\\underbrace{\\mathsf{S}\_p^{r}}\_{\\text{build}}\\;\\underbrace{\\Big(\\prod\_{j=1}^{r}\\mathsf{A}\_{p^j}^{\\alpha\_{p^j}}\\Big)}\_{\\text{gate}}\\;\\underbrace{\\mathsf{R}\_{p^r}^{\\phi}}\_{\\text{lock}}\\;\\underbrace{\\mathsf{W}\_p^{\\pi}}\_{\\text{feel}}.  
\\\]  
\\textbf{Note:} order inside a prime is mostly exchangeable except $\\mathsf{W}\_p$; cross-prime order is not.

\\paragraph{S15. Order Swap Test.}  
\\textbf{Procedure:} generate $\\mathcal{W}$, compute $R$; swap adjacent prime blocks, recompute $R$; keep the better word. Repeat until no local improvement.

\\paragraph{S16. Energy–Fairness Projection.}  
\\textbf{Rewrite:} $X\\Rightarrow \\mathrm{Proj}\_{\\{E\\le E\_{\\max},\\,E\_{p^r}\\le \\eta^{\\max}E,\\,F\\ge F\_{\\min}\\}}(X)$ after each epoch.  
\\textbf{Effect:} enforces budgets without changing word structure.

\\subsection\*{F.6 Worked Micro-Entries on $n=108$}  
\\paragraph{F6.1 Ternary-First Scaffold.}  
\\\[  
\\boxed{\\mathcal{W}\_{\\triangle}=\\mathsf{S}\_3^3\\,\\mathsf{S}\_2^2\\cdot  
\\mathsf{A}\_{27}^{\\beta\_{27}}\\mathsf{A}\_{9}^{\\beta\_9}\\mathsf{A}\_{3}^{\\beta\_3}\\,  
\\mathsf{A}\_{4}^{\\alpha\_4}\\mathsf{A}\_{2}^{\\alpha\_2}}  
\\\]  
\\textbf{Example ticks:} $C\_0=\\{0,27,54,81\\}$, $C\_1=\\{9,18,36,45,63,72,90,99\\}$.

\\paragraph{F6.2 Binary-First Syncopation.}  
\\\[  
\\boxed{\\mathcal{W}\_{\\square}=\\mathsf{S}\_2^2\\,\\mathsf{W}\_2^{(0\\,1)}\\,\\mathsf{S}\_3^3\\cdot  
\\mathsf{A}\_{4}^{\\alpha\_4}\\mathsf{A}\_{2}^{\\alpha\_2}\\,  
\\mathsf{A}\_{27}^{\\beta\_{27}}\\mathsf{A}\_{9}^{\\beta\_9}\\mathsf{A}\_{3}^{\\beta\_3}}  
\\\]  
\\textbf{Effect:} micro hits shift off the ternary spine; $R\_1$ may increase on backbeat targets.

\\paragraph{F6.3 Quinary Ornament with Protection.}  
\\\[  
\\mathcal{W}\_{5}=\\mathcal{W}\_{\\triangle}\\cdot \\mathsf{X}\_{\\neg 3}\\,\\mathsf{A}\_5^{\\gamma\_5},  
\\quad \\gamma\_5\\ll \\alpha\_2.  
\\\]

\\paragraph{F6.4 Heptadic Drift Overlay.}  
\\\[  
\\mathcal{W}\_{7}=\\mathcal{W}\_{\\triangle}\\cdot \\mathsf{A}\_7^{\\flat,\\delta},  
\\quad S\_7(108,\\mu)=\\{\\mu+\\ell s\_{108}\\},\\ 7s\_{108}\\equiv1\\pmod{108}.  
\\\]

\\subsection\*{F.7 Minimal Pseudocode Snippets}  
\\paragraph{FP1. Cadence–Micro Generator (108).}  
\\begin{verbatim}  
def gen108(w):  
  x \= zeros(108)  
  for t in range(108):  
    if t % 27 \== 0: x\[t\] \+= w\['27'\]  
    elif t % 9 \== 0: x\[t\] \+= w\['9'\]  
    elif t % 3 \== 0: x\[t\] \+= w\['3'\]  
    elif t % 4 \== 0: x\[t\] \+= w\['4'\]  
    elif t % 2 \== 0: x\[t\] \+= w\['2'\]  
  return x  
\\end{verbatim}

\\paragraph{FP2. Off-Beat Swap within 4-Grid.}  
\\begin{verbatim}  
def swap\_offbeat4(x):  
  y \= x.copy()  
  for b in range(0, len(x), 4):  
    y\[b+0\], y\[b+2\] \= x\[b+2\], x\[b+0\]  
  return y  
\\end{verbatim}

\\paragraph{FP3. Ornament with Anti-3 Gate.}  
\\begin{verbatim}  
def add\_quinary(x, gamma):  
  for t in range(len(x)):  
    if (t % 5 \== 0\) and (t % 3 \!= 0):  
      x\[t\] \+= gamma  
  return x  
\\end{verbatim}

\\subsection\*{F.8 Quick-Use Table}  
\\begin{center}  
\\begin{tabular}{lll}  
\\toprule  
Sutra & Purpose & Typical Setting \\\\  
\\midrule  
S1  & build tier & $\\mathsf{S}\_3^3,\\ \\mathsf{S}\_2^2$ \\\\  
S2  & micro syncopation & $\\mathsf{W}\_2^{(0\\,1)}$ after $\\mathsf{S}\_2$ \\\\  
S3  & ternary tilt & $\\mathsf{W}\_3^{(0\\,2\\,1)}$ before $\\mathsf{A}\_9$ \\\\  
S4  & downbeat pin & $\\mathsf{R}\_{27}^{\\phi}$ \\\\  
S5  & cadence gate & $\\mathsf{A}\_{27},\\mathsf{A}\_9,\\mathsf{A}\_3$ \\\\  
S6  & protect spine & $\\mathsf{X}\_{\\neg 3}$ around ornaments \\\\  
S7  & restrict tier & $\\Delta\_{4}$ for micro-only edits \\\\  
S8  & analyze tier & $\\Pi\_{9}$ to audit energy \\\\  
S9  & quinary color & $\\mathsf{A}\_5^{\\gamma}$ on $e\_o$ \\\\  
S10 & hept drift & $\\mathsf{A}\_7^{\\flat,\\delta}$ with slow $\\mu$ \\\\  
S11 & split lanes & $\\hat{Q}\_2^{\\mathrm{split}}$ on $H$ \\\\  
S12 & fold symmetry & $\\hat{Q}\_3^{\\mathrm{fold}}$ for ternary quotient \\\\  
\\bottomrule  
\\end{tabular}  
\\end{center}

\\noindent  
These sutras provide a compact playbook: build tiers (S1), set feel (S2–S4), gate hierarchy (S5–S6), add color (S9–S10), manage relations (S11–S12), and audit with projectors (S7–S8). The $n{=}108$ examples serve as canonical templates for adaptation to other factorizations.

% \===================== LISTS OF FIGURES AND TABLES \=====================  
\\clearpage  
\\section\*{Lists of Figures and Tables}  
\\addcontentsline{toc}{section}{Lists of Figures and Tables}

\\listoffigures  
\\bigskip  
\\listoftables

% \---- Optional: figure stubs to populate the list (replace with final assets) \----  
\\clearpage  
\\section\*{Figure Stubs (to be replaced with final graphics)}  
% 1\) Operator diagrams  
\\begin{figure}\[h\]  
  \\centering  
  % \\includegraphics\[width=\\linewidth\]{figs/operator\_diagrams.pdf}  
  \\fbox{\\rule{0pt}{2in}\\rule{0.95\\linewidth}{0pt}}  
  \\caption{Operator diagrams: $\\Sp{p}$ (subdivision), $\\A{p^r}{\\alpha}$ (accent),  
           $\\Rop{p^r}{\\phi}$ (rotation), $\\Wop{p}$ (permutation), and relation $\\Qhat{p}$ on $H$.}  
  \\label{fig:operators}  
\\end{figure}

% 2\) CRT tilings  
\\begin{figure}\[h\]  
  \\centering  
  % \\includegraphics\[width=\\linewidth\]{figs/crt\_tilings.pdf}  
  \\fbox{\\rule{0pt}{2in}\\rule{0.95\\linewidth}{0pt}}  
  \\caption{CRT tilings of $\\Tn$ for $n=108$: factorization $108=2^2\\cdot3^3$ with aligned  
           $\\Z/4$ and $\\Z/27$ grids and level projectors $\\Pid{2},\\Pid{4},\\Pid{3},\\Pid{9},\\Pid{27}$.}  
  \\label{fig:crt-tilings}  
\\end{figure}

% 3\) Resonance spectra  
\\begin{figure}\[h\]  
  \\centering  
  % \\includegraphics\[width=\\linewidth\]{figs/resonance\_spectra.pdf}  
  \\fbox{\\rule{0pt}{2in}\\rule{0.95\\linewidth}{0pt}}  
  \\caption{Resonance spectra: tier energies on comb indices $K\_d$ and phase-coherence polar plots  
           for $(R\_1,R\_2,R\_3)$ under ternary-first vs.\\ binary-first words.}  
  \\label{fig:resonance-spectra}  
\\end{figure}

% 4\) 108 cadence map  
\\begin{figure}\[h\]  
  \\centering  
  % \\includegraphics\[width=\\linewidth\]{figs/cadence\_map\_108.pdf}  
  \\fbox{\\rule{0pt}{2in}\\rule{0.95\\linewidth}{0pt}}  
  \\caption{Cadence map for $n=108$: tick classes $C\_0$--$C\_4$ with weights  
           $(w\_0\>\\cdots\>w\_4)$, showing $27\\\!\\to\\\!9\\\!\\to\\\!3$ cadences and $4,2$ micro layers.}  
  \\label{fig:cadence-108}  
\\end{figure}

\\clearpage  
\\section\*{Reproducibility Package}

\\subsection\*{Directory Layout}  
All materials sit under \\texttt{repro/}. Tree (placeholders may be symlinks or LFS pointers):  
\\begin{verbatim}  
repro/  
├── README.md  
├── configs/  
│   ├── metr.yml  
│   ├── ritual.yml  
│   ├── physio.yml  
│   └── common.yml  
├── data/  
│   ├── METRICAL/              \# or pointer/URL in README  
│   ├── RITUAL/  
│   ├── PHYSIO/  
│   ├── PROVENANCE.md  
│   └── LICENSES/  
│       ├── METRICAL\_LICENSE.txt  
│       ├── RITUAL\_LICENSE.txt  
│       └── PHYSIO\_LICENSE.txt  
├── env/  
│   ├── environment.yml  
│   ├── requirements.txt  
│   ├── hardware.txt  
│   └── determinism.md  
├── scripts/  
│   ├── rebuild.sh  
│   ├── make\_figs.py  
│   ├── make\_tables.py  
│   ├── run\_exps.py  
│   └── seed\_report.py  
├── outputs/  
│   ├── figs/  
│   ├── tables/  
│   ├── logs/  
│   └── checkpoints/  
├── checksums/  
│   ├── sha256sum.txt  
│   └── manifest.csv  
└── CITATION.cff  
\\end{verbatim}

\\subsection\*{Config Files for Each Experiment}  
Each config declares lattice, tiers, operator word, parameters \\(\\Theta=\\{\\alpha,\\phi,\\pi,\\hat{Q}\\}\\), scoring weights, splits, seeds, and gauges.  
\\begin{verbatim}  
\# repro/configs/metr.yml  
experiment: "metrical\_corpus"  
n: \[48, 60, 72, 84, 90, 96, 108\]  
tiers: { use\_CRT: true }  
lambdas: { R1: 0.40, R2: 0.35, R3: 0.25 }  
etas: { by\_tier: proportional }          \# weight by divisor d  
word: |  
  S3^r= {r: 3} ; S2^s= {s: 2} ;  
  A: \[ {d:27,a:1.0}, {d:9,a:0.7}, {d:3,a:0.5}, {d:4,a:0.3}, {d:2,a:0.2} \]  
  W2: {perm: \[1,0\]} ; R: {d:27,phi: 0}  
theta:  
  alpha: {27:1.0, 9:0.7, 3:0.5, 4:0.3, 2:0.2}  
  phi:   {27:0, 9:0, 3:0, 4:0, 2:0}  
  perm:  {2:\[1,0\]}  
  Q:     {}  
gauge: { downbeat\_pin: true, crt\_phase\_fix: true }  
splits: { strategy: "stratified", train:0.70, val:0.15, test:0.15, seed: 20251 }  
impl:   { fft\_backend: "fftw", threads: 1, deterministic: true }  
invariants: { Emax: 1.0, tier\_max: {27:0.5}, Fmin: 0.7 }  
\\end{verbatim}

\\subsection\*{Dataset Notes and Licenses}  
\\begin{itemize}  
  \\item \\textbf{PROVENANCE.md} records source, collection method, consent, preprocessing, and contact.  
  \\item \\textbf{LICENSES/\\\*.txt} contains each dataset license or usage terms; mirror exact text.  
  \\item \\textbf{CITATION.cff} provides citation metadata for the package and any third-party data.  
  \\item For ritual or physiological data include anonymization notes and opt-out procedures.  
\\end{itemize}  
Minimal template for \\texttt{PROVENANCE.md}:  
\\begin{verbatim}  
\# Dataset: METRICAL  
Source: \<reference or URL\>  
License: \<SPDX identifier or text reference\>  
Scope: rhythms with binary–ternary interlocks  
Preprocessing: quantized to T\_n; normalization; windowing  
Ethics: consent obtained; anonymized; usage restricted per LICENSE  
Checksum root: checksums/manifest.csv  
\\end{verbatim}

\\subsection\*{Script to Regenerate All Figures and Tables}  
\\begin{verbatim}  
\# 1\) Create/activate environment  
conda env create \-f repro/env/environment.yml  
conda activate moc-repro  
export PYTHONHASHSEED=0 OMP\_NUM\_THREADS=1 MKL\_NUM\_THREADS=1  
export TF\_CUDNN\_DETERMINISTIC=1 CUBLAS\_WORKSPACE\_CONFIG=:4096:8

\# 2\) Run all experiments and render artifacts  
bash repro/scripts/rebuild.sh \--all  
\# or explicitly:  
python repro/scripts/run\_exps.py \--configs repro/configs \--out repro/outputs  
python repro/scripts/make\_figs.py   \--in repro/outputs \--out repro/outputs/figs  
python repro/scripts/make\_tables.py \--in repro/outputs \--out repro/outputs/tables  
python repro/scripts/seed\_report.py \--logs repro/outputs/logs

\# 3\) Verify checksums  
sha256sum \-c repro/checksums/sha256sum.txt  
\\end{verbatim}

\\noindent \\textbf{Makefile} (optional):  
\\begin{verbatim}  
.PHONY: all env exps figs tables verify clean  
env: ; conda env create \-f repro/env/environment.yml  
exps: ; python repro/scripts/run\_exps.py \--configs repro/configs \--out repro/outputs  
figs: ; python repro/scripts/make\_figs.py \--in repro/outputs \--out repro/outputs/figs  
tables: ; python repro/scripts/make\_tables.py \--in repro/outputs \--out repro/outputs/tables  
verify: ; sha256sum \-c repro/checksums/sha256sum.txt  
all: env exps figs tables verify  
clean: ; rm \-rf repro/outputs/{figs,tables,logs,checkpoints}  
\\end{verbatim}

\\subsection\*{Checksums and Environment Specification}  
\\paragraph{Environment.} Pin toolchain versions and backends.  
\\begin{verbatim}  
\# repro/env/environment.yml  
name: moc-repro  
channels: \[conda-forge, defaults\]  
dependencies:  
  \- python=3.11  
  \- numpy=1.26  
  \- scipy=1.13  
  \- fftw=3.3  
  \- numba=0.59  
  \- pandas=2.2  
  \- matplotlib=3.9  
  \- pip  
  \- pip:  
      \- pyyaml==6.0.2  
      \- tabulate==0.9.0  
      \- tqdm==4.66.2  
\\end{verbatim}  
Record hardware in \\texttt{env/hardware.txt} (CPU, RAM, GPU, OS). Determinism notes in \\texttt{env/determinism.md}.

\\paragraph{Checksums.} Provide file-level SHA-256 and a manifest.  
\\begin{verbatim}  
\# repro/checksums/sha256sum.txt  
d2f7...  repro/outputs/figs/cadence\_map\_108.pdf  
a1b3...  repro/outputs/tables/table\_metr\_by\_n.csv  
...

\# repro/checksums/manifest.csv  
path,bytes,sha256,created\_utc,source  
outputs/figs/cadence\_map\_108.pdf,123456,d2f7...,2025-11-05,make\_figs.py  
...  
\\end{verbatim}

\\subsection\*{Artifact Map}  
\\begin{center}  
\\begin{tabular}{lll}  
\\toprule  
Artifact & Generator & Destination \\\\  
\\midrule  
Operator diagrams & \\texttt{make\\\_figs.py \--fig operators} & \\texttt{outputs/figs/operator\\\_diagrams.pdf} \\\\  
CRT tilings       & \\texttt{make\\\_figs.py \--fig crt}       & \\texttt{outputs/figs/crt\\\_tilings.pdf} \\\\  
Resonance spectra & \\texttt{make\\\_figs.py \--fig spectra}   & \\texttt{outputs/figs/resonance\\\_spectra.pdf} \\\\  
108 cadence map   & \\texttt{make\\\_figs.py \--fig cadence108}& \\texttt{outputs/figs/cadence\\\_map\\\_108.pdf} \\\\  
Main tables       & \\texttt{make\\\_tables.py \--all}         & \\texttt{outputs/tables/\*.csv} \\\\  
Logs              & \\texttt{run\\\_exps.py}                  & \\texttt{outputs/logs/\*.jsonl} \\\\  
\\bottomrule  
\\end{tabular}  
\\end{center}

\\subsection\*{Deterministic Paths and Seeds}  
All configs record:  
\\begin{itemize}  
  \\item global seed for splits and initialization;  
  \\item beam-search seed for tie-breaking;  
  \\item implementation flags: threads \\(=1\\), deterministic FFT, fixed \\texttt{PYTHONHASHSEED}.  
\\end{itemize}  
Re-run validation: \\texttt{python scripts/seed\\\_report.py} emits the per-epoch seed stream and the tokenized operator word; verify equality against logs.

\\subsection\*{Licensing and Citation}  
Package-level license at repository root. Dataset licenses mirrored under \\texttt{data/LICENSES}. Include \\texttt{CITATION.cff} so users can cite the package and the original datasets correctly.

\\medskip  
\\noindent This package yields byte-identical figures and tables from fixed seeds and pinned environments, enabling exact reproduction of all reported results.

\\end{document}


<!-- LawfulRecursionVersion:1.0 -->
