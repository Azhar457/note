---
tags: [computational-neuroscience, brain-computer-interface, bci, neural-signal-processing, fmri, eeg, ecog, neuralink, neuroprosthetics, hodgkin-huxley]
aliases: [CNBCI, Neuroscience Deep Dive, BCI Systems]
status: complete
created: 2026-07-31
updated: 2026-07-31
cssclasses: [wide-table, math-render]
---

> [!abstract] Computational Neuroscience & Brain-Computer Interface
> Otak adalah komputer biologis yang paling canggih — 86 miliar neuron, 100 triliun sinapsis, mengonsumsi 20W daya. Computational neuroscience mencoba memahami otak melalui model matematis dan simulasi. Brain-Computer Interface (BCI) mencoba membaca dan menulis informasi dari/ke otak. Catatan ini mencakup neural signal processing, brain imaging analysis, computational neuron models, BCI hardware stack, dan neuroprosthetics — dengan formula, algoritma, dan implementasi.

---

## Daftar Isi
1. [[#1. Neural Signal Processing — Spike Sorting, LFP, ECoG]]
2. [[#2. Brain Imaging Analysis — fMRI, DTI, MEG]]
3. [[#3. Computational Models of Neuron]]
4. [[#4. BCI Hardware Stack — OpenBCI, Neuralink, Utah Array]]
5. [[#5. Neurofeedback & Neuroprosthetics]]
6. [[#6. Signal Decoding & Machine Learning]]
7. [[#7. Ethics & Safety Considerations]]
8. [[#8. References]]

---

## 1. Neural Signal Processing — Spike Sorting, LFP, ECoG

### 1.1 Signal Types & Frequency Bands

| Signal | Frequency | Amplitude | Spatial Resolution | Invasive? |
|:-------|:---------:|:---------:|:------------------:|:---------:|
| EEG | 0.5-100 Hz | 10-100 μV | ~1-10 cm | No |
| ECoG | 0.5-200 Hz | 10-5000 μV | ~1-5 mm | Semi |
| LFP | 1-300 Hz | 50-5000 μV | ~50-350 μm | Yes |
| Spike | 300-3000 Hz | 50-500 μV | ~10-50 μm | Yes |
| MEG | 1-100 Hz | 10-1000 fT | ~5-10 mm | No |

### 1.2 Spike Sorting

**Waveform extraction:**
```
1. Bandpass filter: 300-3000 Hz
2. Threshold detection: V > 4·σ_noise
3. Extract waveform window: ±1-2 ms around peak
4. Align to peak or principal component
```

**Threshold formula:**
```
σ_noise = median(|V|) / 0.6745  (robust estimator)

Threshold = 4·σ_noise ≈ 4·RMS_noise

P(false positive | 4σ) ≈ 0.003% (Gaussian assumption)
```

**Clustering algorithms:**
```
1. PCA dimensionality reduction:
   - Extract first 2-3 principal components
   - Variance explained: typically 70-90%

2. Clustering:
   - K-means (fast, but need k)
   - Gaussian Mixture Model (probabilistic)
   - Template matching (matched filter)
   - MountainSort / Kilosort (state-of-the-art)
```

**Kilosort algorithm:**
```
1. Whitening: decorrelate channels
2. Template learning: learn spike templates via gradient descent
3. Matching pursuit: assign spikes ke templates
4. Drift correction: track electrode movement over time
```

### 1.3 Local Field Potential (LFP)

**Origin:**
```
LFP = weighted sum of synaptic currents from local population
Spatial reach: ~250-500 μm (depends on tissue conductivity)
```

**Frequency bands:**
```
Delta: 0.5-4 Hz   (deep sleep, unconsciousness)
Theta: 4-8 Hz     (hippocampus, memory encoding)
Alpha: 8-13 Hz    (visual cortex, eyes closed)
Beta: 13-30 Hz    (motor cortex, active thinking)
Gamma: 30-100 Hz  (feature binding, attention)
High gamma: 80-150 Hz (multi-unit activity proxy)
```

**Power spectral density:**
```
PSD(f) = |FFT(signal)|² / (fs·N)

fs: sampling frequency
N: number of samples
```

### 1.4 ECoG (Electrocorticography)

**Grid electrodes:**
```
Standard grid: 8×8 electrodes, 1 cm spacing
High-density: 8×8 electrodes, 3 mm spacing

Advantage over EEG:
  - Higher spatial resolution (no skull/scalp attenuation)
  - Higher frequency content (up to 200 Hz, even 500 Hz gamma)
  - Higher SNR (10-100× better than EEG)
```

---

## 2. Brain Imaging Analysis — fMRI, DTI, MEG

### 2.1 fMRI — BOLD Signal

**BOLD (Blood-Oxygen-Level-Dependent) contrast:**
```
BOLD signal ∝ Δ[HbR] (deoxyhemoglobin concentration)

Neural activity → increased blood flow → increased oxyhemoglobin
→ decreased deoxyhemoglobin → increased T2* signal

Hemodynamic response function (HRF):
  h(t) = (t/τ1)^n1 · exp(-t/τ1) - A·(t/τ2)^n2 · exp(-t/τ2)

  τ1 ≈ 6s, τ2 ≈ 16s, n1 ≈ 6, n2 ≈ 1, A ≈ 0.35
  Peak: ~5-6s after neural activity
  Duration: ~12-15s
```

**GLM (General Linear Model):**
```
Y = X·β + ε

Y: voxel time series (T×1)
X: design matrix (T×N regressors)
  - Task regressors (convolved with HRF)
  - Nuisance regressors (motion, drift, physiological)
β: parameter estimates (N×1)
ε: residual noise

β = (X^T·X)^-1 · X^T · Y

t-statistic: t = β / SE(β)
```

**Multiple comparisons:**
```
Voxels: 64×64×30 = 122,880 (typical)
Family-wise error rate (FWER): P(at least 1 false positive)

Bonferroni: threshold = α / N = 0.05 / 122,880 ≈ 4×10^-7
FDR (False Discovery Rate): control expected proportion of false positives
Cluster correction: threshold clusters by size
```

### 2.2 DTI — Diffusion Tensor Imaging

**Diffusion tensor:**
```
D = [Dxx Dxy Dxz
     Dxy Dyy Dyz
     Dxz Dyz Dzz]

Eigenvalues: λ1 ≥ λ2 ≥ λ3
Eigenvectors: principal diffusion directions
```

**Scalar metrics:**
```
MD (Mean Diffusivity) = (λ1 + λ2 + λ3) / 3
FA (Fractional Anisotropy) = √(3/2) · √[(λ1-MD)²+(λ2-MD)²+(λ3-MD)²] / √(λ1²+λ2²+λ3²)

FA = 0: isotropic (CSF, gray matter)
FA ≈ 1: highly anisotropic (white matter tracts)
```

**Tractography:**
```
Deterministic:
  - Streamline propagation along principal eigenvector
  - Stop when FA < threshold (0.2) or angle > threshold (45°)

Probabilistic:
  - Sample diffusion direction dari tensor distribution
  - Repeat 1000× per seed
  - Build connectivity probability map
```

### 2.3 MEG — Magnetoencephalography

**Principle:**
```
Neural currents generate magnetic fields
SQUID (Superconducting Quantum Interference Device) detects fields

Signal: 10-1000 fT (femtotesla)
Earth magnetic field: 50,000 nT = 50,000,000,000 fT
→ Need shielded room (mu-metal)
```

**Source localization:**
```
Forward problem: given source J, calculate field B at sensors
  B = G · J
  G: lead field matrix (depends on head geometry)

Inverse problem: given B, estimate J
  J = G⁺ · B  (minimum norm estimate)

  G⁺: pseudoinverse or regularized inverse
  Regularization: Tikhonov (L2) atau L1 (sparse)
```

---

## 3. Computational Models of Neuron

### 3.1 Hodgkin-Huxley Model (1952)

**Membrane current:**
```
C_m · dV/dt = -g_Na·m³·h·(V-E_Na) - g_K·n⁴·(V-E_K) - g_L·(V-E_L) + I_ext

C_m: membrane capacitance (~1 μF/cm²)
g_Na, g_K, g_L: maximal conductances
E_Na, E_K, E_L: reversal potentials
m, h, n: gating variables (0-1)
I_ext: external current
```

**Gating variables:**
```
dx/dt = α_x(V)·(1-x) - β_x(V)·x

α_m(V) = 0.1·(V+40) / (1 - exp(-(V+40)/10))
β_m(V) = 4·exp(-(V+65)/18)

α_h(V) = 0.07·exp(-(V+65)/20)
β_h(V) = 1 / (1 + exp(-(V+35)/10))

α_n(V) = 0.01·(V+55) / (1 - exp(-(V+55)/10))
β_n(V) = 0.125·exp(-(V+65)/80)
```

**Action potential threshold:**
```
V_threshold ≈ -55 mV
Peak: +40 mV
Repolarization: -70 mV (resting)
Duration: ~1-2 ms
```

### 3.2 Izhikevich Model (2003)

**Simplified 2D model:**
```
dv/dt = 0.04·v² + 5·v + 140 - u + I
du/dt = a·(b·v - u)

if v ≥ 30 mV:
  v = c
  u = u + d

v: membrane potential
u: recovery variable
a, b, c, d: parameters (determine neuron type)
```

**Parameter sets:**
```
Regular spiking (RS):    a=0.02, b=0.2, c=-65, d=8
Intrinsically bursting (IB): a=0.02, b=0.2, c=-55, d=4
Chattering (CH):         a=0.02, b=0.2, c=-50, d=2
Fast spiking (FS):       a=0.1,  b=0.2, c=-65, d=2
Low-threshold spiking (LTS): a=0.02, b=0.25, c=-65, d=2
Thalamo-cortical (TC):   a=0.02, b=0.25, c=-65, d=0.05
Resonator (RZ):          a=0.1,  b=0.26, c=-65, d=2
```

**Advantage:**
```
Hodgkin-Huxley: 4 ODEs, computationally expensive
Izhikevich: 2 ODEs, 1000× faster
Can reproduce 20+ neuron firing patterns
```

### 3.3 Leaky Integrate-and-Fire (LIF)

**Simplest model:**
```
τ_m · dV/dt = -(V - V_rest) + R·I(t)

if V ≥ V_threshold:
  emit spike
  V = V_reset

τ_m = R·C_m: membrane time constant (~10-20 ms)
```

**Firing rate (steady-state):**
```
ν = [τ_m · ln((V_rest - V_reset + R·I)/(V_rest - V_threshold + R·I))]^-1

Untuk I > I_threshold:
  ν ≈ (R·I - ΔV) / (τ_m · ΔV)  (linear approximation)
```

---

## 4. BCI Hardware Stack — OpenBCI, Neuralink, Utah Array

### 4.1 Electrode Types

| Type | Material | Impedance | Lifespan | Resolution |
|:-----|:---------|:---------:|:--------:|:----------:|
| Surface EEG | Ag/AgCl | 5-20 kΩ | Reusable | 1-10 cm |
| ECoG grid | Platinum | 1-5 kΩ | Permanent implant | 1-5 mm |
| Utah array | Silicon | 50-500 kΩ | 1-5 years | ~100 μm |
| Neuropixels | CMOS | <100 kΩ | Single use | ~20 μm |
| Neuralink | Polymer | <50 kΩ | >10 years (target) | ~12 μm |

### 4.2 Utah Array

**Specification:**
```
10×10 electrode grid
Electrode length: 1.0-1.5 mm
Electrode spacing: 400 μm
Total: 96 electrodes (4 corner electrodes are reference)
Material: doped silicon, insulated with Parylene
```

**Signal quality over time:**
```
Month 0: SNR = 10-15 dB
Month 6: SNR = 5-10 dB
Month 12: SNR = 3-5 dB
Month 24+: SNR < 3 dB (many channels lost)

Degradation cause: glial scarring, electrode drift
```

### 4.3 Neuralink N1

**Specification:**
```
Threads: 64 threads
Electrodes per thread: 16
Total electrodes: 1024
Electrode size: 12 μm diameter
Thread thickness: 4-6 μm
Insertion: robotic sewing machine
Wireless: Bluetooth Low Energy
Battery: inductive charging
```

**Bandwidth:**
```
1024 channels × 20 kHz sampling × 10 bits = 204.8 Mbps raw
On-chip compression: 200× reduction
Wireless throughput: ~1-5 Mbps
```

### 4.4 OpenBCI

**Cyton board:**
```
Channels: 8 EEG
Sampling: 250 Hz
Resolution: 24-bit ADC
Wireless: RF dongle (2.4 GHz)
Cost: $500-1000

Ganglion board:
  Channels: 4 EEG
  Cost: $200
```

---

## 5. Neurofeedback & Neuroprosthetics

### 5.1 Neurofeedback

**Protocol:**
```
1. Record real-time EEG/ECoG
2. Extract feature (e.g., alpha power at C3/C4)
3. Compare to target (e.g., increase alpha by 20%)
4. Provide feedback (visual, auditory, haptic)
5. User learns to modulate brain state
```

**Applications:**
```
ADHD: increase SMR (12-15 Hz), decrease theta (4-8 Hz)
Anxiety: increase alpha, decrease high beta
Depression: asymmetry training (F3/F4 alpha)
Peak performance: increase gamma (40 Hz)
```

**Efficacy:**
```
Meta-analysis (Arns et al., 2014):
  ADHD: effect size d = 0.6 (medium-large)
  Anxiety: d = 0.5 (medium)
  Epilepsy: d = 0.8 (large)
```

### 5.2 Motor Neuroprosthetics

**Brain-controlled cursor:**
```
Training:
  1. User imagines moving hand left/right/up/down
  2. Record motor cortex ECoG/spikes
  3. Decode intended direction dari neural activity
  4. Cursor moves sesuai decoded direction

Decoder:
  - Kalman filter: x_t = A·x_{t-1} + K·(z_t - H·x_t)
  - x: cursor position/velocity
  - z: neural firing rates
```

**Braingate clinical trial:**
```
Participant: tetraplegic
Implant: 96-channel Utah array (M1)
Performance: 
  - Typing: 90 chars/min (2021, decoded dari attempted handwriting)
  - Robot arm control: pick and place
  - Cursor control: 90% accuracy
```

### 5.3 Sensory Neuroprosthetics

**Cochlear implant:**
```
Microphone → Sound processor → Transmitter → Electrode array (cochlea)

Electrodes: 12-22 channels
Frequency mapping: basal = high freq, apical = low freq

Speech understanding:
  - Quiet: 70-90%
  - Noise: 40-60%
```

**Retinal implant:**
```
Argus II (Second Sight):
  - 60 electrodes (6×10 grid)
  - Implanted on retina
  - Glasses-mounted camera
  - Visual acuity: ~20/1260 (legal blindness = 20/200)
```

---

## 6. Signal Decoding & Machine Learning

### 6.1 Feature Extraction

**Time-domain:**
```
Mean, variance, skewness, kurtosis
Zero-crossing rate
Waveform length
```

**Frequency-domain:**
```
Power spectral density (Welch method)
Band power: delta, theta, alpha, beta, gamma
Spectral entropy
```

**Time-frequency:**
```
Short-time Fourier Transform (STFT)
Wavelet transform (Morlet wavelet)
Common Spatial Patterns (CSP) — for EEG
```

### 6.2 Common Spatial Patterns (CSP)

**For 2-class motor imagery:**
```
Goal: find spatial filters w that maximize variance for class 1
      and minimize variance for class 2

Optimization:
  maximize: w^T · Σ1 · w / w^T · Σ2 · w

  Σ1, Σ2: covariance matrices untuk class 1 dan 2

Solution: generalized eigenvalue problem
  Σ1 · w = λ · Σ2 · w
```

**Performance:**
```
CSP + LDA: 70-85% accuracy (2-class motor imagery, healthy subjects)
CSP + LDA: 50-70% accuracy (patients, limited training data)
```

### 6.3 Deep Learning for Decoding

**CNN for EEG:**
```
Input: (channels, time) = (64, 1000) untuk 4s @ 250Hz
Architecture:
  Conv2D(1, 64, kernel=(1, 50))  → temporal filtering
  Conv2D(64, 64, kernel=(64, 1)) → spatial filtering (CSP-like)
  BatchNorm + ReLU
  MaxPool(1, 3)
  Conv2D(64, 128, kernel=(1, 10))
  Global Average Pool
  FC(128, num_classes)
  Softmax
```

**RNN/LSTM for sequential decoding:**
```
Input: time series of neural features
LSTM layers: capture temporal dynamics
Output: sequence of decoded states

Advantage: model temporal dependencies
Disadvantage: need more data, slower training
```

**Transfer learning:**
```
Pre-train pada large dataset (e.g., BCI Competition IV)
Fine-tune pada subject-specific data

Improvement: +5-15% accuracy dengan limited subject data
```

---

## 7. Ethics & Safety Considerations

### 7.1 Safety Thresholds

**Neural tissue heating:**
```
FDA limit: <1°C temperature increase
Neuralink: <0.1°C (validated via simulation)

Power dissipation: P = I²·R
For 1024 channels @ 1 μA: P ≈ 1-10 μW (negligible)
```

**Infection risk:**
```
Utah array: 5-10% infection rate over 5 years
Neuralink: target <1% (hermetic packaging)
```

### 7.2 Privacy & Security

**Neural data sensitivity:**
```
EEG/ECoG bisa reveal:
  - Motor intent (before action)
  - Emotional state
  - Cognitive load
  - Attention focus
  - Potentially: thoughts, preferences

Encryption: AES-256 untuk wireless transmission
Access control: multi-factor authentication
```

---

## 8. References

1. Dayan, P., & Abbott, L. F. (2001). *Theoretical Neuroscience: Computational and Mathematical Modeling of Neural Systems*. MIT Press. — Foundational computational neuroscience.

2. Rieke, F., Warland, D., de Ruyter van Steveninck, R., & Bialek, W. (1997). *Spikes: Exploring the Neural Code*. MIT Press. — Neural coding theory.

3. Niedermeyer, E., & da Silva, F. L. (Eds.). (2005). *Electroencephalography: Basic Principles, Clinical Applications, and Related Fields* (5th ed.). Lippincott Williams & Wilkins. — EEG bible.

4. Wolpaw, J. R., & Wolpaw, E. W. (Eds.). (2012). *Brain-Computer Interfaces: Principles and Practice*. Oxford University Press. — BCI comprehensive text.

5. Hochberg, L. R., et al. (2012). "Reach and Grasp by People with Tetraplegia Using a Neurally Controlled Robotic Arm." *Nature*, 485(7398), 372-375. — Braingate clinical results.

6. Izhikevich, E. M. (2003). "Simple Model of Spiking Neurons." *IEEE Transactions on Neural Networks*, 14(6), 1569-1572. — Izhikevich model.

7. Jun, J. J., et al. (2017). "Fully Integrated Silicon Probes for High-Density Recording of Neural Activity." *Nature*, 551(7679), 232-236. — Neuropixels.

8. Musk, E., & Neuralink. (2019). "An Integrated Brain-Machine Interface Platform with Thousands of Channels." *Journal of Medical Internet Research*. — Neuralink N1.

## Koneksi ke Vault

| Catatan | Koneksi |
|:--------|:--------|
| [[advanced-ai-algorithms-breakthroughs]] | Neural decoding = deep learning application |
| [[hierarchy-ai-levels]] | BCI = human-AI symbiosis (Level 8-9) |
| [[math-and-algorithms]] | Signal processing, linear algebra, optimization |
| [[research-methodology]] | Clinical trials, experimental design |
| [[cryptography-biometrics]] | Neural/BCI authentication (EEG passthought) |
