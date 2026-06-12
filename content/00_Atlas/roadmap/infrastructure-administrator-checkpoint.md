# Infrastructure Administrator Roadmap

> **Prinsip utama**: 1 jam per hari, konsisten > marathon sesekali.  
> Checklist ini bukan tutorial — ini **proof of progress**. Jangan lanjut ke fase berikutnya sebelum checkpoint-nya bisa kamu jelaskan sendiri tanpa buka Google.

---

## Status Tracker

| Phase | Topic               | Status         |
| ----- | ------------------- | -------------- |
| 0     | Pre-existing Skills | ✅ Done        |
| 1     | Ansible Foundation  | 🔲 In Progress |
| 2     | Playbook Core       | 🔲 Not Started |
| 3     | Roles               | 🔲 Not Started |
| 4     | Real Power          | 🔲 Not Started |
| 5     | Real Project        | 🔲 Not Started |

---

## Phase 0 — What You Already Have

_Credit where it's due. These are real skills, not beginner level._

- [x] Linux administration (Rocky Linux + Ubuntu/Metasploitable)
- [x] Docker — deployed WAF, reverse proxy, monitoring stack
- [x] Nginx Proxy Manager + Cloudflare Tunnel
- [x] Basic network architecture (bridged, NAT, Tailscale)
- [x] Security monitoring mindset (auditd, CrowdSec, Suricata)

**You are not starting from zero.**

---

## Phase 1 — Ansible Foundation

_Target: 2 weeks | 1hr/day = ~14 sessions | 4-5hr day = 2-3 sessions_

### Setup

- [ ] Install Ansible on Rocky Linux as control node
- [ ] Configure SSH key-based auth from control → managed nodes
- [ ] Create first static inventory file (`/etc/ansible/hosts`)

### First Contact

- [ ] Run `ansible all -m ping` — all nodes respond
- [ ] Run ad-hoc command: install a package without SSH-ing manually
- [ ] Understand the difference: ad-hoc vs playbook

### First Playbook

- [ ] Write a playbook that creates a user on a remote host
- [ ] Write a playbook that installs and starts a service
- [ ] Understand `hosts`, `tasks`, `become`, `name` fields

### ✅ Phase 1 Checkpoint

> _Can you rebuild a basic server config (user + package + service) with one command?_  
> If yes → proceed. If no → repeat the playbook section.

---

## Phase 2 — Playbook Core

_Target: 2 weeks | Focus: making playbooks smart, not just sequential_

### Variables

- [ ] Define variables inside playbook (`vars:`)
- [ ] Use `group_vars/` and `host_vars/` directories
- [ ] Understand variable precedence (which one wins when two conflict)

### Logic

- [ ] Use `when:` for conditional tasks
- [ ] Use `loop:` to repeat tasks over a list
- [ ] Use `register:` to capture task output and act on it

### Handlers

- [ ] Understand what a handler is (runs only when notified)
- [ ] Write a handler that restarts Nginx only when config changes
- [ ] Understand why this matters vs just always restarting

### Tags

- [ ] Add tags to tasks
- [ ] Run only tagged tasks with `--tags`
- [ ] Skip specific tasks with `--skip-tags`

### ✅ Phase 2 Checkpoint

> _Write a playbook that:_  
> _- Installs Docker on Rocky Linux_  
> _- Only restarts Docker daemon if config changed_  
> _- Skips installation if Docker already exists_  
> If you can write that without copy-paste → proceed.

---

## Phase 3 — Roles

_Target: 2 weeks | Focus: reusable, structured automation_

### Role Structure

- [ ] Understand the folder structure: `tasks/`, `handlers/`, `vars/`, `defaults/`, `templates/`, `files/`
- [ ] Convert your Phase 2 playbook into a role
- [ ] Understand difference between `vars/` (fixed) and `defaults/` (overridable)

### Building Roles

- [ ] Write a `base_setup` role: user, SSH hardening, firewall basics
- [ ] Write a `docker_setup` role: install Docker + Compose
- [ ] Write a `monitoring` role: deploy Grafana + Prometheus via Docker

### Community Roles

- [ ] Use `ansible-galaxy role install` to pull a community role
- [ ] Understand how to read a role's README before using it
- [ ] Know when to use community roles vs write your own

### ✅ Phase 3 Checkpoint

> _Single command rebuilds your Docker stack on a fresh Rocky Linux VM._  
> Fresh VM → fully running stack: target under 10 minutes.

---

## Phase 4 — Real Power

_Target: 2 weeks | Focus: production-grade practices_

### Templates

- [ ] Write a Jinja2 template for Nginx config (`.conf.j2`)
- [ ] Use variables inside templates to make configs dynamic
- [ ] Deploy config from template — understand how it differs from static file copy

### Secrets Management

- [ ] Encrypt a secret with `ansible-vault encrypt_string`
- [ ] Use vault in a playbook — run it with `--ask-vault-pass`
- [ ] Store vault password in a file (understand the security tradeoff)

### Error Handling

- [ ] Use `block:` / `rescue:` / `always:` structure
- [ ] Use `ignore_errors:` carefully (know when NOT to use it)
- [ ] Use `failed_when:` to define your own failure condition

### Dynamic Inventory

- [ ] Understand why static inventory breaks at scale
- [ ] Write a simple Python/bash script that outputs JSON inventory
- [ ] (Optional) Use an inventory plugin for Docker or cloud

### ✅ Phase 4 Checkpoint

> _Your playbooks:_  
> _- Use templates for all config files_  
> _- Have zero plaintext passwords_  
> _- Handle failure without crashing the entire run_

---

## Phase 5 — Real Project

_Target: 2 weeks | This is the proof of everything_

### The Goal

Automate your **entire homelab rebuild** — from fresh Rocky Linux install to fully running production stack — with one command.

### What the Playbook Must Cover

- [ ] Base system setup (user, SSH keys, firewall, timezone)
- [ ] Docker + Docker Compose installation
- [ ] SafeLine WAF deployment via Docker
- [ ] CrowdSec + nftables bouncer
- [ ] Nginx Proxy Manager
- [ ] Grafana + Prometheus monitoring
- [ ] Cloudflare Tunnel connection

### Documentation (Do Not Skip)

- [ ] Write a `README.md` for your playbook repo
- [ ] Document every role: what it does, what variables it uses
- [ ] Post a breakdown on your digital garden — explain what you built

### ✅ Final Checkpoint

> _Time it. Fresh VM → full stack running._  
> _Target: under 15 minutes._  
> _Can you explain every role to someone who's never used Ansible?_  
> If yes — Phase 5 complete. You have a real, demonstrable DevOps skill.

---

## Daily Session Template

### 1-Hour Session (21:00–22:00)

```
00:00–10:00  Review yesterday's note — what did you actually build?
10:00–45:00  Hands-on only. Terminal open. Not tutorial-watching.
45:00–60:00  Write one note: what you built, what broke, how you fixed it.
```

### 4-5 Hour Session

```
Hour 1     : Review + plan which items to finish today
Hour 2-3   : Build — complete one full section of the current phase
Hour 3-4   : Break it intentionally — modify something, see what fails
Hour 4-5   : Fix it, document it, write the checkpoint explanation
```

**Rule**: If your terminal isn't open, you're not doing DevOps.

---

## Am I On Track? (Honest Self-Check)

Ask yourself these after each phase:

1. Can I explain what I built without opening Google?
2. If I deleted everything and started over, could I do it faster?
3. Did I write at least one note about what broke and why?

If all three are yes — you're on track.  
If not — that phase isn't done yet.

---

## On Relevance (The "Will This Matter in 2030?" Question)

Ansible as a tool may evolve. Infrastructure automation as a **concept** is permanent.

Someone who deeply understands Ansible can learn Terraform, Pulumi, or whatever comes next — in weeks, not months. The mental model transfers. Tool syntax doesn't define the skill.

> Learn it deep. One thing at a time. The compound effect of daily 1-hour sessions over 6 months is real.

---

_Last updated: June 2026_  
_Part of [[00_Atlas/roadmap/]] — Infrastructure Administrator path_
