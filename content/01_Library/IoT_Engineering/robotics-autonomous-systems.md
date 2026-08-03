---
tags: [robotics, autonomous-systems, ros, slam, path-planning, drone, swarm-robotics, manipulation, inverse-kinematics, mpc]
aliases: [RAS, Robotics Deep Dive, Autonomous Systems]
status: complete
created: 2026-07-31
updated: 2026-07-31
cssclasses: [wide-table, math-render]
---

> [!abstract] Robotics & Autonomous Systems
> Robotika adalah integrasi mekanika, elektronika, dan software untuk menciptakan agen fisik yang bisa berinteraksi dengan dunia nyata. Dari manipulator industri yang presisi 0.01mm sampai drone otonom yang navigate 3D space, robotics adalah domain engineering yang memerlukan pemahaman mendalam kinematics, dynamics, perception, dan control. Catatan ini mencakup ROS2 architecture, SLAM, path planning, drone autonomy, swarm coordination, dan manipulation — dengan formula, algoritma, dan implementasi.

---

## Daftar Isi
1. [[#1. ROS2 Architecture & Navigation Stack]]
2. [[#2. SLAM — Simultaneous Localization and Mapping]]
3. [[#3. Path Planning & Motion Control]]
4. [[#4. Drone Autonomy — PX4, ArduPilot]]
5. [[#5. Swarm Robotics & Multi-Agent Coordination]]
6. [[#6. Manipulation & Grasping]]
7. [[#7. Sensor Fusion & State Estimation]]
8. [[#8. References]]

---

## 1. ROS2 Architecture & Navigation Stack

### 1.1 ROS2 vs ROS1

| Feature | ROS1 | ROS2 |
|:--------|:----:|:----:|
| Middleware | Custom TCPROS/UDPROS | DDS (Data Distribution Service) |
| Real-time | No | Yes (DDS + ROS2 real-time executor) |
| Security | None | SROS2 (encryption, authentication) |
| Build system | catkin | colcon (ament) |
| Node lifecycle | Simple | Managed (active, inactive, shutdown) |
| Multi-robot | Difficult | Native (DDS discovery) |

### 1.2 DDS — Data Distribution Service

**Publish-Subscribe model:**
```
Topic: typed data channel (e.g., sensor_msgs/Image)
Publisher: node yang publish data ke topic
Subscriber: node yang subscribe ke topic
QoS: reliability, durability, deadline, lifespan
```

**QoS Policies:**
```
Reliability:
  BEST_EFFORT: UDP-like, fast, may drop
  RELIABLE: TCP-like, guaranteed delivery

Durability:
  VOLATILE: only new subscribers get future data
  TRANSIENT_LOCAL: new subscribers get last N samples
  TRANSIENT: persistent (requires DDS persistence service)

Deadline: max interval between samples
Lifespan: max age of sample before ignored
```

### 1.3 Navigation Stack (Nav2)

**Architecture:**
```
Input: goal pose (x, y, θ)
Output: velocity commands (v, ω)

Components:
  1. Map Server: static map (occupancy grid)
  2. AMCL: probabilistic localization
  3. Planner: global path (A*, Dijkstra, Theta*)
  4. Controller: local path (DWA, TEB, MPPI)
  5. Recovery: behavior trees (spin, backup, clear costmap)
  6. BT Navigator: behavior tree execution
```

**Behavior Tree (BT):**
```
<root>
  <Sequence>
    <ComputePathToPose goal="{goal}" path="{path}"/>
    <FollowPath path="{path}" controller_id="FollowPath"/>
    <Spin spin_dist="1.57"/>
  </Sequence>
</root>
```

---

## 2. SLAM — Simultaneous Localization and Mapping

### 2.1 Problem Formulation

**State:**
```
x_t = [robot_pose_t, map_t]

Robot pose: (x, y, θ) untuk 2D; (x, y, z, qx, qy, qz, qw) untuk 3D
Map: occupancy grid, point cloud, atau feature landmarks
```

**Observation model:**
```
z_t = h(x_t) + v_t

h: sensor model (lidar ray casting, camera projection)
v_t: observation noise (Gaussian, typically)
```

**Motion model:**
```
x_t = f(x_{t-1}, u_t) + w_t

f: odometry/kinematics model
u_t: control input (v, ω) atau (Δx, Δy, Δθ)
w_t: process noise
```

### 2.2 Extended Kalman Filter (EKF) SLAM

**Prediction:**
```
x̂_t|t-1 = f(x̂_t-1|t-1, u_t)
P_t|t-1 = F_t · P_t-1|t-1 · F_t^T + Q_t

F_t = ∂f/∂x (Jacobian)
Q_t = process noise covariance
```

**Update:**
```
K_t = P_t|t-1 · H_t^T · (H_t · P_t|t-1 · H_t^T + R_t)^-1
x̂_t|t = x̂_t|t-1 + K_t · (z_t - h(x̂_t|t-1))
P_t|t = (I - K_t · H_t) · P_t|t-1

H_t = ∂h/∂x (Jacobian)
R_t = observation noise covariance
```

**Complexity:**
```
EKF-SLAM: O(n²) per update, n = jumlah landmarks
Untuk n=100: manageable
Untuk n=10,000: too slow
```

### 2.3 Graph-Based SLAM

**Pose graph:**
```
Nodes: robot poses x_i (i=1..N)
Edges: constraints z_ij (odometry atau loop closure)

Error function:
  e_ij(x_i, x_j) = z_ij - h(x_i, x_j)

Objective:
  minimize Σ ||e_ij||²_Ωij

  Ωij = information matrix (inverse covariance)
```

**Optimization:**
```
Gauss-Newton:
  H · Δx = -b
  x_new = x + Δx

H = Σ J_ij^T · Ωij · J_ij   (Hessian approximation)
b = Σ J_ij^T · Ωij · e_ij   (gradient)
J_ij = ∂e_ij/∂x             (Jacobian)

Sparse structure: H is sparse (local connections only)
Solver: sparse Cholesky (e.g., CHOLMOD) atau iterative (PCG)
```

**G2O / GTSAM / Ceres:**
```
G2O: general graph optimization
GTSAM: factor graphs with Bayes tree
Ceres: non-linear least squares (Google)
```

### 2.4 LiDAR SLAM — LOAM, LIO-SAM

**LOAM (LiDAR Odometry and Mapping):**
```
Two parallel threads:
  1. Odometry (high frequency, coarse):
     - Point-to-plane ICP (Iterative Closest Point)
     - Feature extraction: edge features + planar features
     - Match ke local map (k-d tree)

  2. Mapping (low frequency, fine):
     - Point-to-plane ICP ke global map
     - Map update: add new points, remove old
```

**Point-to-plane ICP:**
```
Given: source point cloud P, target point cloud Q
Find: transformation T = [R|t] minimizing

E(T) = Σ ( (R·p_i + t - q_j) · n_j )²

n_j: normal vector di q_j
j = nearest neighbor dari p_i di Q
```

**LIO-SAM (LiDAR-Inertial Odometry):**
```
Fusion: LiDAR + IMU (tightly coupled)
IMU preintegration: delta rotation, velocity, position
Factor graph: IMU factors + LiDAR factors + GPS factors (optional)
Loop closure: scan-to-map matching + pose graph optimization
```

---

## 3. Path Planning & Motion Control

### 3.1 Configuration Space (C-space)

**Definition:**
```
C-space = semua kemungkinan pose robot

2D mobile robot: C = R² × S¹ (x, y, θ)
3D mobile robot: C = R³ × SO(3) (x, y, z, roll, pitch, yaw)
6-DOF arm: C = R^joint_count (θ1, θ2, ..., θn)
```

**Obstacle mapping:**
```
C-obstacle = { q ∈ C | robot(q) ∩ obstacle ≠ ∅ }
C-free = C \ C-obstacle
```

### 3.2 Sampling-Based Planning

**RRT (Rapidly-exploring Random Tree):**
```
Algorithm:
  1. Initialize tree T dengan start node q_start
  2. For i = 1 to N:
     a. Sample random node q_rand di C-free
     b. Find nearest node q_near di T
     c. Extend dari q_near ke q_rand dengan step size Δq
     d. If collision-free: add q_new ke T
  3. If q_new dekat goal: return path
```

**RRT* (optimal RRT):**
```
Additional steps:
  - Rewire: untuk setiap node baru, cek apakah bisa improve cost ke neighbors
  - Asymptotic optimality: converges ke optimal path saat N → ∞

Cost improvement:
  if cost(q_new) + dist(q_new, q_neighbor) < cost(q_neighbor):
    rewire parent(q_neighbor) = q_new
```

**PRM (Probabilistic Roadmap):**
```
Preprocessing (offline):
  1. Sample N nodes di C-free
  2. Connect each node ke k nearest neighbors (if collision-free)
  3. Store graph

Query (online):
  1. Connect start dan goal ke graph
  2. A* search pada graph
```

### 3.3 Grid-Based Planning

**A* Algorithm:**
```
f(n) = g(n) + h(n)

g(n): cost dari start ke node n (known)
h(n): heuristic estimate dari n ke goal

Admissible heuristic: h(n) ≤ h*(n) (true cost)
Consistent heuristic: h(n) ≤ c(n,n') + h(n')

If admissible: A* finds optimal path
If consistent: A* never reopens nodes
```

**Heuristics for 2D grid:**
```
Manhattan: h = |x1-x2| + |y1-y2|  (4-connected)
Euclidean: h = √((x1-x2)² + (y1-y2)²)  (8-connected)
Diagonal: h = max(|Δx|, |Δy|) + (√2-1)·min(|Δx|, |Δy|)
```

**D* Lite (Dynamic A*):**
```
For dynamic environments (obstacles berubah):
  - Reuse previous search results
  - Only update affected nodes
  - Much faster than replanning from scratch
```

### 3.4 Model Predictive Control (MPC)

**Optimization problem:**
```
minimize Σ [ ||x_k - x_ref||²_Q + ||u_k||²_R ] + ||x_N - x_ref||²_P
subject to:
  x_{k+1} = A·x_k + B·u_k  (dynamics)
  x_k ∈ X (state constraints)
  u_k ∈ U (input constraints)

Q: state cost matrix (posisi, orientasi)
R: input cost matrix (velocity, angular velocity)
P: terminal cost (Lyapunov stability)
N: prediction horizon
```

**MPC for mobile robot:**
```
State: x = [x, y, θ, v, ω]^T
Input: u = [a, α]^T (linear acceleration, angular acceleration)

Kinematics (unicycle):
  ẋ = v·cos(θ)
  ẏ = v·sin(θ)
  θ̇ = ω

Discretized (Euler, Δt):
  x_{k+1} = x_k + v_k·cos(θ_k)·Δt
  y_{k+1} = y_k + v_k·sin(θ_k)·Δt
  θ_{k+1} = θ_k + ω_k·Δt
  v_{k+1} = v_k + a_k·Δt
  ω_{k+1} = ω_k + α_k·Δt
```

**Implementation:**
```
At each timestep:
  1. Measure current state x_0
  2. Solve QP (Quadratic Program) untuk horizon N
  3. Apply first control input u_0*
  4. Shift horizon, repeat
```

---

## 4. Drone Autonomy — PX4, ArduPilot

### 4.1 Flight Dynamics

**6-DOF equations (simplified):**
```
Position: ṗ = R(θ)·v
Velocity: v̇ = -ω × v + g·R^T·e_z + (1/m)·F_thrust

Orientation: q̇ = 0.5·q ⊗ [0, ω]^T
Angular velocity: ω̇ = J^-1 · (τ - ω × J·ω)

F_thrust = Σ F_i  (total thrust dari 4 rotors)
τ = [τ_roll, τ_pitch, τ_yaw]^T  (torque dari differential thrust)
```

**Rotor thrust model:**
```
F_i = k_F · ω_i²
τ_i = k_τ · ω_i²

k_F: thrust coefficient (depends on propeller)
k_τ: torque coefficient
ω_i: rotor angular velocity (rad/s)
```

### 4.2 PX4 Control Architecture

**Cascaded control:**
```
Outer loop (slow, 50Hz): Position control
  Input: position setpoint (x, y, z)
  Output: velocity setpoint (vx, vy, vz)
  Controller: PID

Middle loop (medium, 250Hz): Velocity control
  Input: velocity setpoint
  Output: acceleration/thrust setpoint
  Controller: PID

Inner loop (fast, 1000Hz): Attitude control
  Input: attitude setpoint (quaternion)
  Output: body rates (p, q, r)
  Controller: PID

Innermost loop (fastest, 1000Hz): Rate control
  Input: body rate setpoint
  Output: motor commands
  Controller: PID
```

### 4.3 Trajectory Planning

**Minimum snap trajectory:**
```
For quadrotor: differentially flat system
Flat outputs: x(t), y(t), z(t), ψ(t)

Minimum snap: minimize integral of snap (4th derivative of position)
  J = ∫ ||r^(4)(t)||² dt

Piecewise polynomial (7th order):
  r(t) = Σ c_i · t^i, i=0..7

Constraints:
  - Position waypoints
  - Velocity continuity
  - Acceleration continuity
  - Jerk continuity
  - Snap continuity
```

**Time allocation:**
```
Given waypoints [p0, p1, ..., pn]
Allocate time [t0, t1, ..., tn] untuk setiap segment

Heuristic: t_i = distance(p_i, p_{i+1}) / v_max
Optimization: adjust t_i untuk minimize total snap
```

### 4.4 SLAM for Drones — VINS-Mono, ORB-SLAM3

**Visual-Inertial Odometry (VIO):**
```
Input: IMU (200Hz) + Monocular camera (30Hz)
Output: 6-DOF pose + 3D landmarks

Fusion: tightly coupled
  - IMU preintegration: predict state
  - Visual reprojection: correct state

Bundle Adjustment:
  minimize Σ ||p_i - π(T·P_j)||²

  p_i: observed 2D feature
  P_j: 3D landmark position
  T: camera pose
  π: projection function
```

**ORB-SLAM3:**
```
Features: ORB (Oriented FAST and Rotated BRIEF)
Tracking: frame-to-frame + frame-to-map
Local mapping: keyframe insertion, culling, BA
Loop closure: DBoW2 bag-of-words, Sim(3) pose graph
Multi-map: merge maps, pure visual-inertial
```

---

## 5. Swarm Robotics & Multi-Agent Coordination

### 5.1 Swarm Intelligence Principles

**Three key principles (Bonabeau et al.):**
```
1. Self-organization: global pattern dari local interactions
2. Decentralized control: no single point of failure
3. Emergent behavior: complex behavior dari simple rules
```

### 5.2 Consensus Algorithms

**Average consensus:**
```
x_i(k+1) = x_i(k) + ε · Σ (x_j(k) - x_i(k))
            j∈N(i)

x_i: state agent i (e.g., position estimate)
N(i): neighbors of agent i
ε: step size (0 < ε < 1/Δ_max)
Δ_max: maximum degree in graph

Convergence: x_i → (1/N) · Σ x_j(0) saat k → ∞
```

**Convergence rate:**
```
Rate = -ln(λ₂)
λ₂: second smallest eigenvalue of Laplacian (Fiedler value)

λ₂ > 0: connected graph
λ₂ besar: fast convergence
λ₂ kecil: slow convergence
```

### 5.3 Formation Control

**Virtual structure:**
```
Define formation sebagai rigid body virtual
Each robot tracks virtual point:
  p_i^desired = p_virtual + R_virtual · r_i_offset

r_i_offset: offset robot i dalam frame virtual
```

**Behavior-based (Reynolds boids):**
```
Three rules:
  1. Separation: avoid collision
     v_sep = -Σ (p_i - p_j) / ||p_i - p_j||²

  2. Alignment: match velocity
     v_ali = (1/|N|) · Σ v_j

  3. Cohesion: move to center
     v_coh = (1/|N|) · Σ p_j - p_i

Total: v = c1·v_sep + c2·v_ali + c3·v_coh
```

### 5.4 Task Allocation — Hungarian Algorithm

**Assignment problem:**
```
N robots, M tasks (N ≥ M)
Cost matrix C[N×M]: C[i,j] = cost robot i do task j

Objective: minimize Σ C[i, a(i)]
Subject to: a(i) unique assignment
```

**Hungarian algorithm complexity:**
```
O(n³) untuk n×n matrix
O(n²·m) untuk rectangular
```

---

## 6. Manipulation & Grasping

### 6.1 Forward Kinematics

**Denavit-Hartenberg (DH) parameters:**
```
For each joint i:
  a_i: link length
  α_i: link twist
  d_i: link offset
  θ_i: joint angle

Transformation matrix:
  T_i = Rot(z,θ_i) · Trans(z,d_i) · Trans(x,a_i) · Rot(x,α_i)

End-effector pose:
  T_0^n = T_0^1 · T_1^2 · ... · T_{n-1}^n
```

### 6.2 Inverse Kinematics

**Analytical (closed-form):**
```
Available untuk: 6-DOF industrial arms (PUMA, KUKA, ABB)
Multiple solutions: up to 8 untuk 6-DOF spherical wrist
```

**Numerical (Jacobian-based):**
```
Jacobian: J = ∂x/∂θ  (6×n matrix)

Δθ = J⁺ · Δx

J⁺: pseudoinverse (Moore-Penrose)
Δx: desired end-effector displacement

Iterative:
  θ_{k+1} = θ_k + α · J⁺(θ_k) · (x_desired - x_current)
```

**Singularity:**
```
det(J·J^T) = 0 → singular configuration

Types:
  - Wrist singularity: joint 4 dan 6 aligned
  - Elbow singularity: arm fully extended
  - Shoulder singularity: wrist center on axis 1
```

### 6.3 Grasping — Force Closure

**Grasp matrix:**
```
G = [G_1, G_2, ..., G_k]

G_i: grasp matrix untuk contact i
k: number of contacts

Force closure condition:
  rank(G) = 6 (full rank for 3D)
  ∃ contact forces such that any external wrench can be resisted
```

**Friction cone:**
```
Coulomb friction: ||f_t|| ≤ μ·||f_n||

μ: friction coefficient
f_t: tangential force
f_n: normal force

Friction cone angle: α = arctan(μ)
```

---

## 7. Sensor Fusion & State Estimation

### 7.1 Kalman Filter

**Linear system:**
```
x_k = A·x_{k-1} + B·u_k + w_k
z_k = H·x_k + v_k

w_k ~ N(0, Q)
v_k ~ N(0, R)
```

**Prediction:**
```
x̂_k|k-1 = A·x̂_{k-1|k-1} + B·u_k
P_k|k-1 = A·P_{k-1|k-1}·A^T + Q
```

**Update:**
```
K_k = P_k|k-1·H^T · (H·P_k|k-1·H^T + R)^-1
x̂_k|k = x̂_k|k-1 + K_k·(z_k - H·x̂_k|k-1)
P_k|k = (I - K_k·H)·P_k|k-1
```

### 7.2 Extended Kalman Filter (EKF)

**Non-linear system:**
```
x_k = f(x_{k-1}, u_k) + w_k
z_k = h(x_k) + v_k
```

**Linearization:**
```
F_k = ∂f/∂x (evaluated at x̂_{k-1|k-1})
H_k = ∂h/∂x (evaluated at x̂_k|k-1)
```

### 7.3 Unscented Kalman Filter (UKF)

**Sigma points:**
```
2n+1 sigma points untuk n-dimensional state

χ₀ = x̂
χ_i = x̂ + √(n+λ)·P_i   untuk i=1..n
χ_i = x̂ - √(n+λ)·P_i   untuk i=n+1..2n

λ = α²(n+κ) - n
α: spread parameter (0.001-1)
κ: secondary scaling (0 atau 3-n)
```

**Advantage:**
```
EKF: first-order approximation (Jacobian)
UKF: second-order approximation (sigma points)
UKF lebih akurat untuk highly non-linear systems
```

---

## 8. References

1. Siciliano, B., & Khatib, O. (Eds.). (2016). *Springer Handbook of Robotics* (2nd ed.). Springer. — Comprehensive robotics reference.

2. Thrun, S., Burgard, W., & Fox, D. (2005). *Probabilistic Robotics*. MIT Press. — SLAM, localization, Kalman filters.

3. LaValle, S. M. (2006). *Planning Algorithms*. Cambridge University Press. — Motion planning, RRT, PRM.

4. Mellinger, D., & Kumar, V. (2011). "Minimum Snap Trajectory Generation and Control for Quadrotors." *ICRA 2011*. — Drone trajectory planning.

5. Reynolds, C. W. (1987). "Flocks, Herds and Schools: A Distributed Behavioral Model." *ACM SIGGRAPH*. — Boids algorithm.

6. Mur-Artal, R., & Tardós, J. D. (2017). "ORB-SLAM2: An Open-Source SLAM System for Monocular, Stereo, and RGB-D Cameras." *IEEE T-RO*, 33(5), 1255-1262. — Visual SLAM.

7. Qin, T., Li, P., & Shen, S. (2018). "VINS-Mono: A Robust and Versatile Monocular Visual-Inertial State Estimator." *IEEE T-RO*, 34(4), 1004-1020. — Visual-inertial odometry.

8. Mehta, D. (2023). *PX4 Autopilot User Guide*. PX4 Development Team. — Drone control architecture.

## Koneksi ke Vault

| Catatan | Koneksi |
|:--------|:--------|
| [[embedded-systems]] | Robotics = embedded systems + control + perception |
| [[computer-vision]] | Visual SLAM, object detection untuk manipulation |
| [[swarm-ai-imam-robandi]] | Swarm intelligence principles |
| [[math-and-algorithms]] | Kinematics, graph theory, optimization |
| [[ai-comm-protocol-deepdive]] | ROS2 DDS = distributed communication protocol |
