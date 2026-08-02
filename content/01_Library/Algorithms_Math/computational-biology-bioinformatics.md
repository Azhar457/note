---
tags:
  [
    bioinformatics,
    computational-biology,
    genomics,
    proteomics,
    molecular-dynamics,
    crispr,
    phylogenetics,
    drug-discovery,
    alpha-fold,
    nextflow,
  ]
aliases: [CBB, Bioinformatics Deep Dive, CompBio]
status: complete
created: 2026-07-31
updated: 2026-07-31
cssclasses: [wide-table, math-render]
---

> [!abstract] Computational Biology & Bioinformatics
> Kehidupan adalah informasi yang diekspresikan melalui kimia. DNA adalah storage medium dengan density 455 exabyte per gram. Protein adalah molecular machine dengan struktur 3D yang menentukan fungsi. Computational biology adalah disiplin yang menerjemahkan data biologis menjadi insight melalui algoritma, statistik, dan simulasi. Catatan ini mencakup genomics, proteomics, molecular dynamics, CRISPR design, phylogenetics, dan bioinformatics pipeline — dengan formula, kompleksitas, dan implementasi.

---

## Daftar Isi

1. [[#1. Genomics — Sequence Alignment, Assembly, Variant Calling]]
2. [[#2. Proteomics — Mass Spectrometry, Protein Identification]]
3. [[#3. Molecular Dynamics & Drug Discovery]]
4. [[#4. CRISPR — Guide RNA Design & Off-Target Prediction]]
5. [[#5. Phylogenetics & Evolutionary Modeling]]
6. [[#6. Bioinformatics Pipeline — Nextflow, Snakemake]]
7. [[#7. AlphaFold & Structural Prediction]]
8. [[#8. References]]

---

## 1. Genomics — Sequence Alignment, Assembly, Variant Calling

### 1.1 DNA sebagai Information Storage

**Density storage DNA:**

```
1 base = 2 bits (A=00, T=01, C=10, G=11)
1 base pair = 2 bits
Human genome: 3.2 × 10^9 bp
Information content: 6.4 × 10^9 bits = 800 MB
Physical volume: ~6 picograms
Density: 800MB / 6pg ≈ 133 exabytes/gram

Theoretical max (synthetic): 455 exabytes/gram
```

### 1.2 Sequence Alignment — Smith-Waterman & Needleman-Wunsch

**Needleman-Wunsch (global alignment):**

```
F(i,j) = max {
    F(i-1,j-1) + s(xi,yj),   (match/mismatch)
    F(i-1,j) + d,              (deletion)
    F(i,j-1) + d,              (insertion)
    0                          (not in NW — ini Smith-Waterman)
}

s(x,y) = match_score if x==y else mismatch_penalty
d = gap_penalty (typically -2 to -10)
```

**Smith-Waterman (local alignment):**

```
F(i,j) = max {
    F(i-1,j-1) + s(xi,yj),
    F(i-1,j) + d,
    F(i,j-1) + d,
    0                          ← key difference: local alignment
}
```

**Kompleksitas:**

```
Time: O(m·n) untuk 2 sequence length m dan n
Space: O(m·n) untuk full matrix
Space optimized: O(min(m,n)) dengan Hirschberg algorithm
```

**Contoh numerik:**

```
Seq A: "GATTACA" (m=7)
Seq B: "GCATGCU" (n=7)
Match=+1, Mismatch=-1, Gap=-2

Matrix 8×8:
      G  C  A  T  G  C  U
   0 -2 -4 -6 -8 -10 -12 -14
G -2  1 -1 -3 -5  -7  -9 -11
A -4 -1  0 -2 -4  -6  -8 -10
T -6 -3 -2 -1 -3  -5  -7  -9
T -8 -5 -4 -3 -2  -4  -6  -8
A -10 -7 -6 -5 -4  -3  -5  -7
C -12 -9 -8 -7 -6  -5  -4  -6
A -14 -11 -10 -9 -8  -7  -6  -5

Optimal alignment (traceback):
G A T T A C A
G C A T _ G C U
Score: -5 (not great — contoh sederhana)
```

### 1.3 BLAST — Heuristic Alignment

BLAST (Basic Local Alignment Search Tool) menggunakan **heuristic** untuk mempercepat pencarian:

**Algoritma:**

```
1. Seed: cari short word matches (default: 11 bp untuk DNA)
2. Extend: extend seed di kedua arah dengan scoring
3. Evaluate: HSP (High-Scoring Segment Pair) dengan E-value threshold
```

**E-value (Expect value):**

```
E = K · m · n · e^(-λS)

K, λ: Karlin-Altschul parameters (depends on scoring matrix)
m: query length
n: database size
S: alignment score

Interpretasi:
E < 0.001: highly significant
E < 0.01: significant
E < 1: possibly significant
E > 10: not significant
```

**Speedup vs Smith-Waterman:**

```
SW: O(m·n) per query-database pair
BLAST: O(m·log(n)) heuristic
Speedup: 50-100× untuk database besar
Sensitivity: ~95% of true homologs (trade-off)
```

### 1.4 De Novo Assembly — De Bruijn Graph

**De Bruijn Graph:**

```
Nodes: (k-1)-mers
Edges: k-mers (overlap k-1)

Contoh: k=3
Reads: "ATG", "TGC", "GCA", "CAT"
Nodes: "AT", "TG", "GC", "CA"
Edges: AT→TG ("ATG"), TG→GC ("TGC"), GC→CA ("GCA"), CA→AT ("CAT")
Graph: AT ↔ TG ↔ GC ↔ CA ↔ AT (cycle)
```

**Genome assembly complexity:**

```
Human genome: 3.2 Gbp
Read length (Illumina): 150 bp
Coverage: 30×
Total reads: (3.2G × 30) / 150 = 640 million reads

De Bruijn graph (k=31):
Nodes: ~3.2G (unique 30-mers)
Edges: ~3.2G
Memory: 50-100 GB RAM
Time: 1-3 hari (depends on hardware)
```

### 1.5 Variant Calling — SNP & Indel

**Bayesian variant calling:**

```
P(variant | data) = P(data | variant) · P(variant) / P(data)

P(data | variant): likelihood dari observed reads
P(variant): prior probability (typically 0.001 for SNP)
```

**Phred-scaled quality score:**

```
Q = -10 · log10(P(error))

Q=10: P(error)=0.1 (90% confidence)
Q=20: P(error)=0.01 (99% confidence)
Q=30: P(error)=0.001 (99.9% confidence)
```

**Variant allele frequency (VAF):**

```
VAF = alt_reads / (ref_reads + alt_reads)

Heterozygous SNP: VAF ≈ 0.5
Homozygous alt: VAF ≈ 1.0
Homozygous ref: VAF ≈ 0.0
Subclonal (tumor): VAF < 0.5
```

---

## 2. Proteomics — Mass Spectrometry, Protein Identification

### 2.1 Mass Spectrometry Basics

**Prinsip:**

```
1. Ionisasi protein/peptide (ESI atau MALDI)
2. Akselerasi di electric field
3. Defleksi di magnetic field
4. Detection berdasarkan m/z (mass-to-charge ratio)
```

**Resolusi MS:**

```
R = m / Δm

Low-res: R < 10,000 (ion trap, quadrupole)
High-res: R > 30,000 (Orbitrap, TOF)
Ultra-high-res: R > 100,000 (Orbitrap Elite)
```

### 2.2 Peptide Mass Fingerprinting (PMF)

**Protein digestion:**

```
Trypsin cleavage: C-terminal dari K atau R (kecuali diikuti P)

Protein: 500 amino acids
Expected peptides: ~40-50 (average length 10-15 aa)
```

**Matching:**

```
Observed masses: [M1, M2, M3, ...]
Theoretical masses: database dari known proteins

Score = Σ match(M_obs, M_theo, tolerance)

tolerance: ±0.1 Da (low-res) atau ±5 ppm (high-res)
```

**MOWSE score:**

```
Score = -10 · log10(P(random match))

Score > 67: significant (p < 0.05)
Score > 100: highly significant (p < 0.00001)
```

### 2.3 Tandem MS (MS/MS) — De Novo Sequencing

**Fragmentasi peptide:**

```
Collision-induced dissociation (CID):
  Peptide + N2 → fragment ions

Ion types:
  b-ion: N-terminal fragment (retains charge)
  y-ion: C-terminal fragment (retains charge)

Sequence reconstruction:
  mass(y_n) - mass(y_{n-1}) = mass(amino acid)
```

**De novo algorithm:**

```
1. Identify y-ion series (dominant di CID)
2. Calculate mass differences
3. Map ke amino acid masses
4. Reconstruct sequence

Ambiguity: I/L isobaric (same mass 113.08), Q/K (128.06)
```

---

## 3. Molecular Dynamics & Drug Discovery

### 3.1 Force Fields

**Potential energy function:**

```
U = U_bond + U_angle + U_dihedral + U_nonbonded

U_bond = Σ kb (r - r0)²                    (harmonic bond)
U_angle = Σ kθ (θ - θ0)²                   (harmonic angle)
U_dihedral = Σ kφ [1 + cos(nφ - δ)]        (periodic torsion)
U_nonbonded = Σ 4ε[(σ/r)^12 - (σ/r)^6] + Σ qi·qj/(4πε0·r)  (LJ + Coulomb)
```

**Parameter count:**

```
AMBER ff14SB: ~10,000 parameters
CHARMM36m: ~15,000 parameters
OPLS-AA: ~8,000 parameters
```

### 3.2 Integration — Verlet Algorithm

**Velocity Verlet:**

```
r(t+Δt) = r(t) + v(t)·Δt + 0.5·a(t)·Δt²
v(t+Δt) = v(t) + 0.5·[a(t) + a(t+Δt)]·Δt
```

**Timestep constraint:**

```
Δt < 2/ω_max

ω_max: highest frequency vibration (O-H bond: ~3,500 cm⁻¹)
Δt_max ≈ 1 fs (10⁻¹⁵ s)

Untuk simulation 1 μs:
  Steps = 10⁻⁶ / 10⁻¹⁵ = 10⁹ steps
  Time: ~1-7 hari (depends on system size & hardware)
```

### 3.3 Free Energy Perturbation (FEP)

**ΔG calculation:**

```
ΔG = -kT · ln⟨exp(-ΔU/kT)⟩

ΔU: energy difference between states
k: Boltzmann constant
T: temperature
⟨⟩: ensemble average
```

**Alchemical transformation:**

```
State A (ligand bound) → State B (ligand unbound)
λ parameter: 0 → 1
U(λ) = (1-λ)·U_A + λ·U_B

ΔG_bind = ∫₀¹ ⟨∂U/∂λ⟩ dλ
```

**Accuracy:**

```
FEP: ±1-2 kcal/mol (experimental accuracy: ±0.5-1 kcal/mol)
MM-PBSA/GBSA: ±2-3 kcal/mol (faster, less accurate)
```

### 3.4 Docking — Scoring Functions

**Scoring function components:**

```
ΔG_bind = ΔG_vdw + ΔG_elec + ΔG_hbond + ΔG_desolv + ΔG_torsion

Empirical scoring (ChemScore, X-Score):
  ΔG = c0 + c1·H_bond + c2·vdW + c3·desolv + c4·rot_bonds

Knowledge-based (PMF, DrugScore):
  ΔG = -kT · Σ ln[P_observed(r) / P_reference(r)]
```

**Virtual screening enrichment:**

```
EF = (Hits_sampled / N_sampled) / (Hits_total / N_total)

EF > 10: excellent
EF 5-10: good
EF < 5: poor
```

---

## 4. CRISPR — Guide RNA Design & Off-Target Prediction

### 4.1 CRISPR-Cas9 Mechanism

**Components:**

```
Cas9 protein: RNA-guided endonuclease
gRNA (guide RNA): 20 nt spacer + scaffold
  - Spacer: complementary ke target DNA
  - PAM: NGG (Protospacer Adjacent Motif, downstream target)
```

**Cleavage:**

```
gRNA binds target DNA (Watson-Crick pairing)
Cas9 HNH domain cleaves complementary strand
Cas9 RuvC domain cleaves non-complementary strand
Result: blunt-ended DSB (Double-Strand Break) 3 bp upstream PAM
```

### 4.2 On-Target Efficiency Prediction

**Deep learning models:**

```
Input: gRNA sequence (20 nt) + flanking context
Output: predicted cutting efficiency (0-1)

Models:
  - DeepCRISPR: CNN + LSTM
  - CRISPRon: transformer-based
  - Azimuth: gradient-boosted regression
```

**Feature importance:**

```
1. GC content (40-60% optimal)
2. Secondary structure (free energy of gRNA)
3. Chromatin accessibility (DNase-seq)
4. Position-specific nucleotide preferences
```

### 4.3 Off-Target Prediction

**Seed region:**

```
PAM-proximal 10-12 nt: most critical for specificity
Mismatch di seed: >10× reduction in cleavage
Mismatch di distal: <2× reduction
```

**CFD (Cutting Frequency Determination) score:**

```
CFD = Π weight(mismatch_position, mismatch_type)

weight matrix (determined empirically):
  Position 1 (PAM-distal): weight ≈ 0.9 per mismatch
  Position 20 (PAM-proximal): weight ≈ 0.1 per mismatch

CFD < 0.2: low off-target risk
CFD > 0.5: high off-target risk
```

**Off-target search space:**

```
Human genome: 3.2 × 10⁹ bp
Possible off-targets dengan ≤3 mismatches:
  C(20,0) + C(20,1)·3 + C(20,2)·3² + C(20,3)·3³
  = 1 + 60 + 1,710 + 32,760 ≈ 34,531 per gRNA

Untuk 20,000 genes × 5 gRNAs/gene = 100,000 gRNAs:
  Total checks: 100,000 × 34,531 ≈ 3.45 × 10⁹

Algorithm: suffix array / FM-index → O(n) lookup
```

### 4.4 Base Editing & Prime Editing

**Base editing (CBE/ABE):**

```
Cas9 nickase (D10A mutation) + deaminase
CBE: C→T conversion (cytosine deaminase)
ABE: A→G conversion (adenine deaminase)

Editing window: PAM-proximal 4-8 nt
Efficiency: 20-60% (depends on context)
```

**Prime editing:**

```
Cas9 H840A nickase + M-MLV reverse transcriptase
pegRNA: primer binding site (PBS) + RT template

Mechanism:
  1. Cas9 nicks target strand
  2. PBS anneals ke nicked strand
  3. RT synthesizes new DNA dari template
  4. Result: precise edit tanpa DSB

Efficiency: 10-50% (depends on edit size)
Edit size: up to 44 bp insertions, 80 bp deletions
```

---

## 5. Phylogenetics & Evolutionary Modeling

### 5.1 Distance Matrix Methods

**UPGMA (Unweighted Pair Group Method with Arithmetic Mean):**

```
Input: distance matrix D (n×n)
Output: rooted phylogenetic tree

Algorithm:
  1. Find minimum D[i,j]
  2. Cluster i and j into new node u
  3. D[u,k] = (D[i,k] + D[j,k]) / 2
  4. Repeat until single cluster

Assumption: molecular clock (constant rate)
```

**Neighbor Joining (NJ):**

```
Correction untuk molecular clock violation:
  Q(i,j) = (n-2)·D(i,j) - ΣD(i,k) - ΣD(j,k)

  Find minimum Q(i,j)
  Branch lengths: vi = D(i,j)/2 + (ΣD(i,k)-ΣD(j,k))/(2(n-2))
```

### 5.2 Maximum Likelihood

**Likelihood function:**

```
L(T,θ | D) = P(D | T, θ)

T: tree topology
θ: branch lengths + substitution model parameters
D: sequence alignment
```

**Substitution models:**

```
JC69: equal base frequencies, equal rates
K80: equal base frequencies, transition≠transversion
HKY85: unequal base frequencies, transition≠transversion
GTR: general time-reversible (most flexible)
+Γ: gamma-distributed rate variation across sites
+I: invariant sites
```

**Model selection (AIC):**

```
AIC = 2k - 2ln(L)
BIC = k·ln(n) - 2ln(L)

k: number of parameters
n: sample size
L: maximum likelihood

Model terbaik: minimum AIC/BIC
```

### 5.3 Bayesian Inference — MCMC

**MrBayes / BEAST:**

```
Posterior: P(T,θ | D) ∝ P(D | T,θ) · P(T) · P(θ)

Sampling: MCMC (Markov Chain Monte Carlo)
  - Proposal: random modification of tree
  - Acceptance: Metropolis-Hastings criterion

Burn-in: discard first N samples (convergence)
Convergence diagnostic: PSRF (Potential Scale Reduction Factor) < 1.01
```

---

## 6. Bioinformatics Pipeline — Nextflow, Snakemake

### 6.1 Workflow Management

**Nextflow — Dataflow paradigm:**

```
process align {
    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.bam")

    script:
    "bwa mem ref.fa $reads | samtools sort -o ${sample_id}.bam"
}

workflow {
    Channel.fromFilePairs("reads/*_{1,2}.fastq")
        | align
        | view
}
```

**Snakemake — Makefile-style:**

```python
rule bwa_align:
    input:
        reads=["reads/{sample}_1.fastq", "reads/{sample}_2.fastq"],
        ref="ref.fa"
    output:
        "aligned/{sample}.bam"
    shell:
        "bwa mem {input.ref} {input.reads} | samtools sort -o {output}"
```

### 6.2 Resource Management

**Containerization:**

```
Docker/Singularity: reproducible environment
Biocontainers: 10,000+ bioinformatics tools containerized

Conda/Bioconda: 9,000+ packages
```

**Cloud scaling:**

```
Nextflow + AWS Batch / Google Life Sciences / Azure Batch
Auto-scaling: 1 → 1000 instances on demand
Cost: $0.01-0.10 per CPU-hour

Human genome pipeline (30× WGS):
  Time: 4-8 jam
  Cost: $20-50 (cloud)
  Cost on-prem: $5-10 (electricity + amortization)
```

---

## 7. AlphaFold & Structural Prediction

### 7.1 Protein Structure Hierarchy

```
Primary: amino acid sequence
Secondary: α-helix, β-sheet, coil (local)
Tertiary: 3D fold (global)
Quaternary: multi-subunit assembly
```

### 7.2 AlphaFold2 Architecture

**Evoformer:**

```
Input: MSA (Multiple Sequence Alignment) + template structures
MSA representation: (s, r, c) — s sequences, r residues, c channels
Pair representation: (r, r, c) — residue-residue distances

Evoformer blocks: 48 layers
  - MSA attention: row-wise & column-wise
  - Triangular update: pair representation update
  - Outer product mean: MSA → pair
```

**Structure Module:**

```
Input: pair representation
Output: 3D coordinates (N, Cα, C, Cβ per residue)

Invariant point attention (IPA):
  - Attention in 3D space
  - Rotation & translation invariant

Iterations: 8 refinement cycles
```

### 7.3 Accuracy Metrics

**GDT_TS (Global Distance Test):**

```
GDT_TS = (GDT_P1 + GDT_P2 + GDT_P4 + GDT_P8) / 4

GDT_Pn: percentage of residues within n Å dari native

CASP14 results (AlphaFold2):
  Median GDT_TS: 92.4 (excellent: >90)
  Previous best (2018): ~60-70
```

**pLDDT (predicted Local Distance Difference Test):**

```
0-50: very low confidence (unstructured)
50-70: low confidence (loop regions)
70-90: confident (secondary structure)
90-100: very high confidence (core domain)
```

**RMSD (Root Mean Square Deviation):**

```
RMSD = √(Σ||ri - ri'||² / N)

RMSD < 2 Å: near-native
RMSD 2-4 Å: good
RMSD 4-6 Å: acceptable
RMSD > 6 Å: poor
```

---

## 8. References

1. Durbin, R., Eddy, S. R., Krogh, A., & Mitchison, G. (1998). _Biological Sequence Analysis: Probabilistic Models of Proteins and Nucleic Acids_. Cambridge University Press. — foundational alignment & HMM.

2. Altschul, S. F., et al. (1990). "Basic Local Alignment Search Tool." _Journal of Molecular Biology_, 215(3), 403-410. — BLAST algorithm.

3. Jumper, J., et al. (2021). "Highly Accurate Protein Structure Prediction with AlphaFold." _Nature_, 596(7873), 583-589. — AlphaFold2.

4. Doench, J. G., et al. (2016). "Optimized sgRNA Design to Maximize Activity and Minimize Off-Target Effects of CRISPR-Cas9." _Nature Biotechnology_, 34(2), 184-191. — CRISPR on-target/off-target.

5. Karplus, M., & McCammon, J. A. (2002). "Molecular Dynamics Simulations of Biomolecules." _Nature Structural Biology_, 9(9), 646-652. — MD fundamentals.

6. Felsenstein, J. (2004). _Inferring Phylogenies_. Sinauer Associates. — Phylogenetics bible.

7. Di Tommaso, P., et al. (2017). "Nextflow Enables Reproducible Computational Workflows." _Nature Biotechnology_, 35(4), 316-319. — Nextflow framework.

8. Anaconda, Inc. (2024). _Bioconda: A Distribution of Bioinformatics Software_. — Bioinformatics packaging.

## Koneksi ke Vault

| Catatan                                  | Koneksi                                             |
| :--------------------------------------- | :-------------------------------------------------- |
| [[advanced-ai-algorithms-breakthroughs]] | AlphaFold = breakthrough AI algorithm               |
| [[hierarchy-ai-levels]]                  | AI Level 5-6 (narrow superhuman) di protein folding |
| [[math-and-algorithms]]                  | Alignment, graph theory, dynamic programming        |
| [[research-methodology]]                 | Bioinformatics pipeline = experimental design       |
| [[cloud-infrastructure]]                 | Nextflow + cloud = scalable bioinformatics          |
