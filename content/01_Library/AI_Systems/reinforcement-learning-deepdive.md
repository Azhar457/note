---
title: "Reinforcement Learning Deep-Dive"
tags:
  - reinforcement-learning
  - rl
  - ppo
  - dqn
  - decision-making
aliases:
  - "reinforcement-learning-deepdive"
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> RL adalah cabang ML yang fokus pada sequential decision making.

## Framework

```
Agent -> action -> Environment -> state + reward
  ^                                      |
  +--------------------------------------+
```

## Key Algorithms

| Algorithm | Type            | Key Feature                        |
| --------- | --------------- | ---------------------------------- |
| DQN       | Value-based     | Experience replay + target network |
| PPO       | Policy gradient | Clipped surrogate objective        |
| SAC       | Actor-critic    | Maximum entropy, continuous action |
| TD3       | Actor-critic    | Twin critics, target smoothing     |
| AlphaZero | Self-play       | MCTS + neural network              |

## Applications

- Robotics: manipulation, locomotion, grasping
- Game AI: AlphaGo, Dota 2
- Security: adversarial RL for penetration testing
