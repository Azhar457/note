---
title: "Embodied AI & Robotics — RT-2, PaLM-E, VLA, Sim-to-Real"
tags:
  - embodied-ai
  - robotics
  - vla-models
  - sim-to-real
  - rt-2
  - palm-e
  - robotic-foundation-models
aliases:
  - Embodied AI Deep Dive
  - Vision-Language-Action Models
  - Robotic Foundation Models
  - Sim-to-Real Transfer
created: 2026-07-14
updated: 2026-07-14
status: evergreen
cssclasses:
  - wide-table
---

# 🏭 EMBODIED AI & ROBOTICS — Ketika AI Mendapatkan Tubuh

**VLA Models (RT-2 · PaLM-E) · Sim-to-Real · Robotic Foundation Models · Open Challenges**

> [!abstract] Filosofi Fundamental
> Sebuah LLM bisa menulis esai tentang cara membuat kopi, tapi tidak bisa mengangkat cangkir. Embodied AI adalah jembatan antara **kognisi digital** dan **aksi fisik**. Dokumen ini membedah revolusi VLA (Vision-Language-Action) — model yang menggabungkan penglihatan, bahasa, dan gerakan dalam satu arsitektur — dari RT-2 Google DeepMind hingga π0 (Physical Intelligence). Dibahas juga Sim-to-Real transfer, robotic foundation models, dan mengapa robotik adalah "final frontier" AI.

---

## Daftar Isi

- [[#First Principles — Mengapa Embodiment Penting]]
- [[#VLA — Vision-Language-Action Models]]
- [[#RT-2 — Robotic Transformer 2 (Google DeepMind)]]
- [[#PaLM-E — Embodied Reasoning at Scale]]
- [[#Sim-to-Real Transfer]]
- [[#Robotic Foundation Models — Ekosistem]]
- [[#Toolchain Robotik — dari Simulasi ke Deploy]]
- [[#Implementasi — Step by Step]]
- [[#Open Challenges & Frontier]]
- [[#Catatan Terkait]]

---

## First Principles — Mengapa Embodiment Penting

### Apa itu Embodied AI?

Embodied AI ≠ "robot with ChatGPT." Embodied AI adalah agen yang:

1. **Menerima input sensorik** dari dunia fisik (kamera, tactile, proprioception)
2. **Mengambil keputusan** berdasarkan input + tujuan
3. **Bertindak** di dunia fisik melalui aktuator (lengan, kaki, gripper)
4. **Menerima feedback** dari lingkungan (berhasil/gagal, collision, force)

### Mengapa Ini Sulit?

```
Masalah fundamental: Simbol Grounding Problem
┌────────────────────────────────────────────────────────┐
│ LLM: "Cangkir ada di atas meja"                        │
│   → Ini hanya simbol — model tidak pernah mengalami    │
│     berat, tekstur, atau keseimbangan cangkir.         │
│                                                        │
│ Embodied AI: "Ambil cangkir itu"                       │
│   → Harus: deteksi → pose estimation → trajectory      │
│     planning → force control → grasp → verify          │
│   → Satu kegagalan di salah satu langkah = gagal total │
└────────────────────────────────────────────────────────┘
```

### Embodiment Spectrum

```
Level 0: Text Only (LLM) — Tidak ada embodiment
Level 1: Vision Only — Melihat tapi tidak bisa bertindak
Level 2: Vision + Language (VLM) — Melihat + memahami
Level 3: Vision + Language + Action (VLA) — Melihat + memahami + bertindak ⭐
Level 4: VLA + Memory — Belajar dari pengalaman fisik
Level 5: VLA + Curiosity — Eksplorasi aktif, belajar skill baru
```

---

## VLA — Vision-Language-Action Models

### Arsitektur VLA

```
┌────────────────────────────────────────────────────────────┐
│                      VISUAL ENCODER                         │
│  (ViT / SigLIP / DINOv2) — extract visual features         │
│  Input: image(s) → Output: visual tokens           │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│                      LANGUAGE MODEL                         │
│  (PaLM / Llama / GPT) — reasoning + planning               │
│  Input: visual tokens + text instruction                   │
│  Output: reasoning tokens + action tokens                  │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│                      ACTION HEAD                            │
│  Decode action tokens → continuous/low-level control       │
│  Output: end-effector pose, joint angles, gripper          │
└────────────────────────────────────────────────────────────┘
```

### Diskritisasi Aksi — RT-2 Approach

**Masalah:** Robot action space kontinu (pose 6-DoF + gripper). Language model output diskrit (tokens).

**Solusi RT-2:** Diskritisasi continuous action ke bins.

```
Action space:
  x: [-0.5, 0.5] → 256 bins → token
  y: [-0.5, 0.5] → 256 bins → token
  z: [-0.2, 0.5] → 128 bins → token
  roll: [-π, π] → 64 bins → token
  pitch: [-π, π] → 64 bins → token
  yaw: [-π, π] → 64 bins → token
  gripper: [0, 1] → 2 bins → token

Total action tokens per timestep: 7 tokens
Action vocabulary: ~1,000 tokens dari total 256K model vocabulary
```

**Keuntungan:** Action tokens bisa diproses seperti language tokens — autoregressive generation.
**Kerugian:** Resolusi terbatas oleh jumlah bins. Halus的运动 diperlukan post-processing.

---

## RT-2 — Robotic Transformer 2 (Google DeepMind)

### Filosofi

RT-2 membawa **internet-scale knowledge** ke robotik. Model VLM yang di-fine-tune dengan data robotic.

```
Web-scale pre-training (PaLI-X / PaLM-E)
  ├── Milyaran gambar + teks dari internet
  ├── Tahu konsep: "cangkir", "meja", "ambilkan"
  └── Tahu relasi: "cangkir di atas meja"
          │
          ▼
Robotic fine-tuning
  ├── Ribuan episode robotic demonstration
  ├── Mapping: "ambilkan cangkir" → action tokens
  └── Generalisasi ke object/scene baru
```

### Detail Arsitektur

| Komponen           | Detail                                           |
| ------------------ | ------------------------------------------------ |
| **Base Model**     | PaLI-X (55B) atau PaLM-E (562B)                  |
| **Visual Encoder** | ViT-22B + SigLIP                                 |
| **Training**       | Co-Fine-Tuning: web data + robotic data simultan |
| **Action Rep**     | 8 bins per dimensi → token                       |
| **Sequence**       | 6 timestep history → predict next action         |
| **Inference**      | Autoregressive: 7 action tokens per step         |

### CoT + RT-2

**Chain-of-Thought sebelum action:**

```
Input: "Ambil apel merah di sebelah cangkir"
Model generates:
  Thought: "Ada apel merah dan cangkir putih di atas meja.
            Apel merah di sebelah kiri cangkir.
            Saya perlu menjangkau apel merah."
  Action: [0.32, -0.15, 0.45, 0.1, -0.3, 0.5, 0.8]
```

**Hasil:** CoT meningkatkan success rate dari 62% → 78% pada task unseen.

### Evaluasi RT-2

| Task                      | RT-2 (No CoT) | RT-2 (CoT) | Baseline (Gato) |
| ------------------------- | ------------- | ---------- | --------------- |
| **Pick & Place** (seen)   | 87%           | 91%        | 72%             |
| **Pick & Place** (unseen) | 62%           | 78%        | 35%             |
| **Multi-step** (3 steps)  | 42%           | 58%        | 18%             |
| **Distractor rejection**  | 68%           | 81%        | 41%             |

---

## PaLM-E — Embodied Reasoning at Scale

### Inovasi PaLM-E

PaLM-E mengintegrasikan **continuous sensor data langsung ke dalam language model** sebagai _embodied tokens_.

```
┌─────────────────────────────────────────────────────────────┐
│                       INPUT STREAM                           │
│                                                              │
│  Text: "Ambil kotak merah dari laci atas"                  │
│  Image(s): 3 camera views                                    │
│  State: joint_positions [0.1, -0.3, 0.5, ...]              │
│  Neural 3D: scene representation vector                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                      ENCODERS                                │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐    │
│  │  Text    │  │  Visual  │  │  State   │  │   Neural   │    │
│  │  Encoder │  │  Encoder │  │  Encoder │  │   3D       │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬──────┘    │
│       │             │             │              │           │
│       ▼             ▼             ▼              ▼           │
│  tokens         visual tokens   state tokens   3d tokens     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                PaLM (562B) Decoder-Only                │  │
│  │  [Text tokens] [Visual tokens] [State tokens] [3D]     │  │
│  │  → Reasoning → Planning → Action tokens                │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Kemampuan Unik PaLM-E

| Kemampuan                 | Deskripsi                        | Contoh                                              |
| ------------------------- | -------------------------------- | --------------------------------------------------- |
| **Active Perception**     | Gerak untuk melihat lebih baik   | "Saya tidak bisa melihat kotak, putar kamera 45°"   |
| **Failure Recovery**      | Deteksi + koreksi kegagalan      | "Gagal grasp — coba lagi dengan posisi 2cm ke kiri" |
| **Multi-modal Reasoning** | Gabung visual + state + language | "Objek terlalu berat untuk suction gripper"         |
| **Task Planning**         | Breakdown task kompleks          | "Ambil kotak → buka laci → letakkan → tutup laci"   |
| **Language Grounding**    | Hubungkan simbol ke fisik        | "Kiri" = koordinat relatif -0.3m dari current pose  |

---

## Sim-to-Real Transfer

### Reality Gap

Simulator tidak pernah sempurna. Perbedaan antara simulasi dan realitas = **reality gap**.

| Aspek        | Simulator                        | Dunia Nyata                 |
| ------------ | -------------------------------- | --------------------------- |
| **Fisika**   | Approximate (PBD, spring-damper) | Real physics                |
| **Sensor**   | Perfect, no noise                | Noise, latency, dropout     |
| **Aktuator** | Instant, precise                 | Delay, backlash, friction   |
| **Object**   | Perfect mesh, uniform            | Deformasi, variasi, texture |
| **Lighting** | Controlled                       | Unpredictable               |
| **Latency**  | Deterministic                    | Stochastic                  |

### Domain Randomization (DR)

**Strategi paling efektif** untuk menjembatani reality gap.

**Prinsip:** Variasi parameter simulasi secara acak → policy belajar menjadi **robust** terhadap variasi.

```python
# Contoh domain randomization untuk robot arm
def randomize_scene():
    # 1. Visual randomization
    lighting = {
        "direction": uniform(0, 360),
        "intensity": uniform(500, 2000),  # lux
        "color_temp": uniform(3000, 7000),  # Kelvin
    }
    table_texture = random.choice(TEXTURES)  # wood, metal, plastic
    object_color = random_color()  # RGB random

    # 2. Physics randomization
    physics = {
        "friction": uniform(0.2, 1.5),       # Coefficient
        "mass_scale": uniform(0.5, 2.0),       # Object mass multiplier
        "gravity": uniform(8.0, 10.0),         # m/s²
        "joint_damping": uniform(0.01, 0.1),   # Motor damping
        "control_latency": uniform(0, 0.05),   # Detik
    }

    # 3. Camera randomization
    camera = {
        "position_noise": uniform(-0.02, 0.02),  # meter
        "fov_noise": uniform(-2, 2),              # degrees
        "motion_blur": uniform(0, 0.5),           # intensity
    }

    return {"lighting": lighting, "physics": physics, "camera": camera}
```

### Domain Adaptation

**Pendekatan alternatif:** Align feature distribution antara domain simulasi dan real.

```
                   Sim Data → Feature Extractor → Sim Features
                                                    │
                                              Domain Adversarial
                                              Loss (GAN-based)
                                                    │
                   Real Data → Feature Extractor → Real Features
                                                    │
                                              Task Policy
                                              (shared untuk kedua domain)
```

### System Identification

**Tune simulator agar match real world dynamics:**

```python
def sys_id(real_trajectory, initial_params):
    """Cari parameter simulator yang paling match dengan real data"""

    def sim_loss(params):
        # Run simulator with params
        sim_traj = run_sim(params, real_trajectory.actions)
        # MSE between sim and real states
        return np.mean((sim_traj.states - real_trajectory.states) ** 2)

    # Bayesian optimization untuk mencari parameter optimal
    best_params = bayesian_optimize(
        sim_loss,
        param_space={
            "friction": (0.1, 2.0),
            "mass": (0.1, 5.0),
            "damping": (0.001, 0.5),
        },
        n_iterations=100,
    )
    return best_params
```

### Sim-to-Real Success Stories

| Project           | Task                     | Sim           | Real Success | Teknik                          |
| ----------------- | ------------------------ | ------------- | ------------ | ------------------------------- |
| **OpenAI Dactyl** | Rubik's cube             | MuJoCo        | 100%         | DR + LSTM + asymm. actor-critic |
| **Drone Racing**  | Gate traversal           | FlightGoggles | 95%          | DR + GAN domain adaptation      |
| **ANYmal**        | Rough terrain locomotion | RaiSim        | 90%          | DR + teacher-student            |
| **RLBench**       | Multi-task manipulation  | CoppeliaSim   | 45-75%       | Per-task (masih rendah)         |

---

## Robotic Foundation Models — Ekosistem

### Perbandingan Model

| Model            | Org                   | Tahun | Arsitektur                   | Data                    | Action Space | Open Source? |
| ---------------- | --------------------- | ----- | ---------------------------- | ----------------------- | ------------ | ------------ |
| **RT-2**         | Google DeepMind       | 2023  | PaLI-X → action              | Web data + ~10K demo    | ❌           |
| **RT-X**         | Open X-Embodiment     | 2023  | RT-2 arch + multi-embodiment | 1M+ episode, 22 robots  | ✅           |
| **PaLM-E**       | Google                | 2023  | PaLM + embodied tokens       | Internet + robotic      | ❌           |
| **Octo**         | UC Berkeley           | 2023  | Transformer-based            | Open X-Embodiment       | ✅           |
| **π0 (Pi-Zero)** | Physical Intelligence | 2024  | Flow matching + VLM          | Multi-robot, multi-task | ❌           |
| **MOO**          | MIT                   | 2024  | Object-centric VLA           | Proprietary             | ❌           |
| **GraspGPT**     | Microsoft             | 2024  | LLM-based grasp planning     | Internet                | ❌           |

### Open X-Embodiment Dataset

**Dataset terbesar dan paling beragam untuk robotic learning:**

| Metrik              | Nilai                                            |
| ------------------- | ------------------------------------------------ |
| **Total episodes**  | 1,000,000+                                       |
| **Robot platforms** | 22 (Franka, Kuka, UR5, Sawyer, Spot, etc.)       |
| **Tasks**           | 527 (pick, place, push, open, close, pour, etc.) |
| **Environments**    | 60+ labs worldwide                               |
| **Annotations**     | Language instructions, task IDs, success/failure |

**Format RT-X (unified):**

```python
{
    "episode_id": "franka_00142",
    "robot": "franka_panda",
    "steps": [
        {
            "observation": {
                "image_0": np.array (480, 640, 3),
                "image_1": np.array (480, 640, 3),
                "joint_positions": [0.1, -0.3, 0.5, ...],
                "gripper_position": 0.04,
            },
            "action": {
                "world_vector": [0.23, -0.12, 0.05],
                "rotation_delta": [0.01, -0.03, 0.02],
                "gripper_open": 0.0,
            },
            "language_instruction": "pick up the red apple",
            "reward": 0.0 if step < len-1 else 1.0,
        },
    ]
}
```

---

## Toolchain Robotik — dari Simulasi ke Deploy

### Simulators

| Simulator              | Fisika       | Visual       | Robot Support  | RL Support | GPU |
| ---------------------- | ------------ | ------------ | -------------- | ---------- | --- |
| **MuJoCo**             | ✅ Excellent | ❌ Basic     | ✅ Broad       | ✅ Native  | ❌  |
| **Isaac Sim (NVIDIA)** | ✅ Excellent | ✅ Photoreal | ✅ Broad       | ✅ Native  | ✅  |
| **PyBullet**           | ⚠️ OK        | ⚠️ Basic     | ✅ Broad       | ⚠️ DIY     | ❌  |
| **Habitat (Meta)**     | ❌ N/A       | ✅ Excellent | ❌ Navigation  | ✅         | ✅  |
| **CoppeliaSim**        | ✅ Good      | ⚠️ OK        | ✅ Broad       | ⚠️ API     | ⚠️  |
| **SAPIEN**             | ⚠️ OK        | ✅ Good      | ✅ Maniulation | ✅         | ✅  |

### Robot Middleware

```
┌─────────────────────────────────────────────────────────┐
│                    ROS 2 (Humble)                         │
│                                                           │
│  rclpy/rclcpp — Node-based distributed architecture      │
│  Topics — pub/sub communication (camera, joint state)    │
│  Actions — goal-based (move_arm, grasp)                  │
│  Services — request/reply (get_pose, detect_object)      │
│  TF2 — coordinate transform tree                         │
│  Gazebo — simulation bridge              │
└─────────────────────────────────────────────────────────┘
```

### Reinforcement Learning Stack

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  SB3     │   │  Gymnasium│  │  Sim     │   │  Policy  │
│  (SAC)   │──►│  Env      │──►│  (MuJoCo)│──►│  Deploy  │
│  PPO     │   │  Wrapper  │   │  Isaac   │   │  → Real  │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
```

---

## Implementasi — Step by Step

### Langkah 1: Setup Simulasi dengan MuJoCo + Gym

```python
import mujoco
import gymnasium as gym
import numpy as np

# Load robot model (Franka Panda example)
model = mujoco.MjModel.from_xml_path("franka_panda.xml")
data = mujoco.MjData(model)

class RobotEnv(gym.Env):
    def __init__(self, model_path, render_mode=None):
        self.model = mujoco.MjModel.from_xml_path(model_path)
        self.data = mujoco.MjData(self.model)

        # Action space: 7 joint velocities + gripper
        self.action_space = gym.spaces.Box(
            low=np.array([-1.0]*7 + [0.0]),
            high=np.array([1.0]*7 + [1.0]),
            dtype=np.float32,
        )

        # Observation: joint positions, end-effector pose, gripper
        self.observation_space = gym.spaces.Dict({
            "joint_pos": gym.spaces.Box(-3.14, 3.14, (7,)),
            "ee_pose": gym.spaces.Box(-2.0, 2.0, (7,)),  # xyz + quat
            "gripper": gym.spaces.Box(0.0, 0.08, (1,)),
            "image": gym.spaces.Box(0, 255, (224, 224, 3), dtype=np.uint8),
        })

        # Rendering
        self.renderer = mujoco.Renderer(self.model)

    def step(self, action):
        # Apply action
        self.data.ctrl[:7] = action[:7]  # Joint velocities
        self.data.ctrl[7] = action[7]    # Gripper

        # Physics step
        mujoco.mj_step(self.model, self.data)

        # Get observation
        obs = self._get_obs()

        # Reward: distance to goal
        reward = -np.linalg.norm(obs["ee_pose"][:3] - self.goal_pos)

        # Done: close enough or timeout
        done = reward > -0.02  # < 2cm from goal

        return obs, reward, done, False, {}

    def _get_obs(self):
        # Extract joint positions
        joint_pos = self.data.qpos[:7].copy()

        # End-effector pose from FK
        ee_id = self.model.body("end_effector").id
        ee_pose = np.concatenate([
            self.data.xpos[ee_id],
            self.data.xquat[ee_id],
        ])

        # Render image
        self.renderer.update_scene(self.data, camera="front")
        image = self.renderer.render().copy()

        return {
            "joint_pos": joint_pos,
            "ee_pose": ee_pose,
            "gripper": np.array([self.data.qpos[7]]),
            "image": image,
        }
```

### Langkah 2: Train Policy dengan SAC

```python
from stable_baselines3 import SAC
from stable_baselines3.common.vec_env import DummyVecEnv

# Domain randomization wrapper
class DomainRandomizationWrapper(gym.Wrapper):
    def reset(self, **kwargs):
        # Randomize physics
        self.model.opt.gravity[2] = np.random.uniform(-10.0, -8.0)

        # Randomize object pose
        obj_id = self.model.body("object").id
        self.model.body_pos[obj_id][:2] = np.random.uniform(-0.2, 0.2, 2)

        # Randomize goal
        self.goal_pos = np.random.uniform([0.2, -0.3, 0.0], [0.5, 0.3, 0.3])

        return self.env.reset(**kwargs)

# Create env
env = DummyVecEnv([lambda: DomainRandomizationWrapper(RobotEnv("robot.xml"))])

# Train SAC
model = SAC(
    "MultiInputPolicy",
    env,
    learning_rate=3e-4,
    buffer_size=1_000_000,
    batch_size=256,
    tau=0.005,
    gamma=0.99,
    ent_coef="auto",
    verbose=1,
)

model.learn(total_timesteps=5_000_000)
model.save("robot_policy_sac")
```

### Langkah 3: Sim-to-Real — Deploy Policy

```python
# Deployment script — muat policy dan jalankan di robot real
import rospy
from sensor_msgs.msg import JointState
from geometry_msgs.msg import PoseStamped

class SimToRealDeploy:
    def __init__(self, policy_path):
        self.policy = SAC.load(policy_path)

        # ROS subscribers
        rospy.Subscriber("/joint_states", JointState, self.joint_callback)
        rospy.Subscriber("/cartesian_pose", PoseStamped, self.pose_callback)

        # Publishers
        self.arm_pub = rospy.Publisher("/arm_controller/command", JointState, queue_size=10)
        self.gripper_pub = rospy.Publisher("/gripper_controller/command", JointState, queue_size=10)

        self.current_obs = None
        self.rate = rospy.Rate(50)  # 50 Hz

    def joint_callback(self, msg):
        # Update joint state
        pass

    def pose_callback(self, msg):
        # Update end-effector pose
        pass

    def run(self):
        while not rospy.is_shutdown():
            if self.current_obs is None:
                continue

            # Policy inference — no exploration
            action, _ = self.policy.predict(self.current_obs, deterministic=True)

            # Clip action untuk safety
            action = np.clip(action, -0.5, 0.5)

            # Publish
            self.publish_action(action)
            self.rate.sleep()
```

---

## Open Challenges & Frontier

### 1. Data Scarcity

| Domain    | Data Scale           | Biaya      |
| --------- | -------------------- | ---------- |
| **Text**  | Trillions of tokens  | ~$0.1M     |
| **Image** | Billions of images   | ~$1M       |
| **Robot** | Millions of episodes | **$100M+** |

**Mengapa robot data sangat mahal?**

- Setiap episode = setup ulang robot secara fisik (manusia ~30 detik)
- 1M episode = ~8,300 jam manusia
- Robot rusak, battery habis, object jatuh
- Tidak bisa "scale up" dengan compute saja

**Solusi potensial:**

- **Sim-to-Real** (tapi masih gap)
- **Human video** as training data (IL from YouTube)
- **Self-supervised exploration** (curiosity-driven)
- **Data augmentation** via 3D reconstruction

### 2. Generalization

| Dimensi         | Current SOTA       | Target           |
| --------------- | ------------------ | ---------------- |
| **Object**      | 10-50 objects      | 10,000+          |
| **Scene**       | 1-3 scenes         | Any tabletop     |
| **Lighting**    | Lab conditions     | Any              |
| **Distractors** | 0-2 objects        | Clutter          |
| **Tasks**       | Pick & Place, Open | Any manipulation |

### 3. Safety

```
Physical Safety:
├── Force limiting — jangan sampai robot melukai manusia
├── Emergency stop — hardware + software
├── Collision detection — filtered contact detection
└── Safe RL — constraint dalam policy optimization (Lagrangian, shielding)

System Safety:
├── Distribution shift detection — policy di luar training distribution → stop
├── Fallback policy — jika primary policy tidak yakin
├── Human-in-the-loop — untuk high-risk decisions
└── Formal verification — bukti bahwa policy tidak akan masuk unsafe state
```

### 4. Computation

Inferensi VLA model (562B params) di embedded hardware? **Belum feasible.**

| Hardware         | PaLM-E (562B) | RT-2 (55B)      | Octo (1.2B) |
| ---------------- | ------------- | --------------- | ----------- |
| **A100 (80GB)**  | ~5 detik/step | ~0.5 detik/step | ~10ms/step  |
| **Jetson Orin**  | ❌            | ❌              | ~100ms/step |
| **Raspberry Pi** | ❌            | ❌              | ❌          |

**Arah riset:** Model kecil (sub-5B), quantization, distillation, temporal action aggregation.

---

## Catatan Terkait

- **[[agentic-ai-mcp-architecture-deepdive]]** — Agentic AI (cognitive loop untuk robot)
- **[[desain-sistem-otonom]]** — Autonomous system design (arsitektur robot)
- **[[embedded-systems]]** — Embedded systems (hardware robot)
- **[[cognitive-architecture-engineering]]** — Cognitive architecture (robot cognition)
- **[[computer-vision-deepdive]]** — Computer vision (perception untuk robot)
- **[[reinforcement-learning-deepdive]]** — Reinforcement learning (otak robot)

---

> [!tip] Prinsip Praktis
> Embodied AI adalah bidang di mana **simulasi tidak pernah cukup**. Setiap model VLA hari ini bekerja di lab dengan lighting terkontrol, object terbatas, dan tanpa disturbance. Reality gap bukanlah bug — ini adalah tantangan fundamental dari fisika. Aturan praktis: (1) Domain randomization adalah pertahanan terbaik Anda, (2) Jangan pernah deploy policy yang hanya di-train di simulasi — validasi di real minimal 10% dari total data, (3) Model kecil + temporal smoothing sering outperform model besar + single-step prediction di dunia nyata karena latency dan noise. Dan yang terpenting: **safety dulu.** Robot yang salah grasp bisa merusak — atau melukai.
