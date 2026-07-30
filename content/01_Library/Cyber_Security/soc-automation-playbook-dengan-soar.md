---
title: "SOC Automation & SOAR Playbook — Incident Orchestration, Shuffle, Wazuh-TheHive, Automated Containment"
tags:
  - cyber-security
  - soc
  - soar
  - automation
  - incident-response
  - library
aliases:
  - "SOAR Implementation Guide"
  - "SOC Automation Pipeline"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> SOC Automation adalah praktik mengorkestrasi alur kerja keamanan secara otomatis — dari alert SIEM hingga remediasi — tanpa intervensi manual. SOAR (Security Orchestration, Automation, and Response) adalah platform yang menjembatani deteksi (SIEM/EDR) dengan aksi (firewall, endpoint, ticketing). Catatan ini mencakup arsitektur SOAR, perbandingan platform open-source (Shuffle, Wazuh+TheHive, Splunk SOAR), playbook automation dalam YAML, incident enrichment pipeline, serta teknik automated containment.

**Domain Terkait:** [[siem-security-data-lake-architecture]] (sumber alert) → [[incident-response-framework]] (playbook dasar) → [[threat-hunting-methodology]] (deteksi proaktif) → [[blueteam-detection-matrix]] (detection coverage) → [[endpoint-detection-playbook]] (remediasi endpoint)

---

## Daftar Isi

- [[#1. Mengapa SOC Automation Diperlukan]]
- [[#2. Arsitektur SOAR — Event Pipeline]]
- [[#3. Perbandingan Platform SOAR]]
- [[#4. Shuffle — Open-Source SOAR]]
- [[#5. Wazuh + TheHive — Detection-to-Case Pipeline]]
- [[#6. Playbook Automation — YAML Format]]
- [[#7. Automated Containment Techniques]]
- [[#8. Incident Enrichment Pipeline]]
- [[#9. MCP vs Webhook vs API-Native Orchestration]]
- [[#10. Deploy & Operasional]]
- [[#11. Metrik & Dashboard]]
- [[#12. Referensi]]

---

## 1. Mengapa SOC Automation Diperlukan

SOC modern menghadapi tiga masalah utama:

| Masalah                         | Tanpa SOAR                           | Dengan SOAR                                 |
| ------------------------------- | ------------------------------------ | ------------------------------------------- |
| **Volume alert**                | 10.000+ alert/hari → analyst fatigue | Filtering, dedup, prioritization otomatis   |
| **Mean-Time-to-Respond (MTTR)** | 30-120 menit per alert               | 30 detik - 5 menit                          |
| **Analyst shortage**            | Junior handle triage, senior burnout | Automated tier-1, analyst fokus investigasi |
| **Consistency**                 | Setiap analyst beda prosedur         | Playbook enforce standarisasi               |

**Rumus MTTR improvement:**

$$ \text{MTTR}_{manual} = \sum_{i=1}^{n} (t_{detect} + t_{triage} + t_{enrich} + t_{contain} + t_{remediate})_i $$

$$ \text{MTTR}_{SOAR} = max(t_{detect}, t_{auto-enrich}, t_{auto-contain}) + t_{review} $$

Dengan SOAR, waktu triage, enrichment, dan containment bisa turun dari **ribuan detik ke satuan detik**.

---

## 2. Arsitektur SOAR — Event Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  SIEM    │───▶│  SOAR    │───▶│ Case     │───▶│ Remediate│
│ Wazuh    │    │ Shuffle  │    │ TheHive  │    │ Firewall │
│ Splunk   │    │          │    │          │    │ EDR      │
│ ELK      │    │          │    │          │    │ DNS      │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                     │
                     ▼
              ┌──────────────┐
              │ Enrichment   │
              │ VirusTotal   │
              │ AbuseIPDB    │
              │ Shodan       │
              │ WHOIS        │
              └──────────────┘
```

**Layers:**

1. **Detection Layer** — SIEM/EDR kirim alert via webhook, syslog, atau API
2. **Orchestration Layer** — SOAR filter alert, jalankan playbook, trigger enrichment
3. **Case Management Layer** — Buat ticket dengan semua evidence terstruktur
4. **Remediation Layer** — Execute action: block IP, isolate host, reset credential
5. **Enrichment Layer** — API calls ke threat intel untuk konteks tambahan

---

## 3. Perbandingan Platform SOAR

| Fitur         | Shuffle       | Wazuh+TheHive     | Splunk SOAR   | Palo Alto XSOAR   |
| ------------- | ------------- | ----------------- | ------------- | ----------------- |
| **OS**        | Open Source   | Open Source       | Commercial    | Commercial        |
| **Lisensi**   | Apache 2.0    | AGPL v3           | Per-seat      | Per-seat          |
| **Playbook**  | YAML + UI     | Python + template | Python (Apps) | Python (Playbook) |
| **Integrasi** | 200+ apps     | 50+ via Hive      | 300+ apps     | 600+ apps         |
| **AI/ML**     | Gemini API    | -                 | SOAR AI       | Cortex ML         |
| **Deploy**    | Docker/Podman | Docker/Podman     | Cloud/On-prem | On-prem/Cloud     |
| **UI Modern** | ✅ Ya         | ⚠️ Functional     | ✅ Ya         | ✅ Ya             |

**Rekomendasi:**

- **Shuffle** — untuk tim dengan budget $0, mau fleksibilitas maksimal
- **Wazuh+TheHive** — sudah punya Wazuh, perlu case management
- **Splunk SOAR** — enterprise, sudah pakai Splunk SIEM

---

## 4. Shuffle — Open-Source SOAR

Shuffle adalah SOAR open-source berbasis workflow YAML. Bisa di-deploy via Docker/Podman dengan resource minimal.

### Deploy dengan Podman

```yaml
# docker-compose.yml → podman-compose
version: "3.8"
services:
  shuffle:
    image: ghcr.io/frikky/shuffle:latest
    ports:
      - "3001:3001"
    environment:
      - SHUFFLE_DB_TYPE=sqlite
      - SHUFFLE_ORG_ID=your-org
    volumes:
      - ./shuffle-data:/etc/shuffle
    restart: unless-stopped
```

### Playbook Sederhana — Block IP via Cloudflare

```yaml
# playbook-block-ip.yaml
name: "Block Malicious IP"
trigger:
  type: webhook
  endpoint: /block-ip

steps:
  - id: parse_alert
    type: jsonpath
    input: $TRIGGER
    config:
      source_ip: $.alert.source_ip
      severity: $.alert.severity

  - id: enrich_ip
    type: http
    url: "https://www.virustotal.com/api/v3/ip_addresses/{{steps.parse_alert.source_ip}}"
    headers:
      x-apikey: $VT_API_KEY
    output: $ENRICHMENT

  - id: decision
    type: condition
    input:
      field: "{{steps.enrich_ip.data.attributes.last_analysis_stats.malicious}}"
      condition: "> 5"
    branches:
      true: block_ip
      false: log_only

  - id: block_ip
    type: http
    url: "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/firewall/access_rules/rules"
    method: POST
    headers:
      Authorization: "Bearer $CF_API_TOKEN"
    body:
      mode: block
      configuration:
        target: ip
        value: "{{steps.parse_alert.source_ip}}"
```

### Integrasi Webhook SIEM

```bash
# Di Wazuh → ossec.conf tambahkan integration
<integration>
  <name>shuffle</name>
  <hook_url>http://shuffle:3001/api/v1/webhook/block-ip</hook_url>
  <alert_format>json</alert_format>
</integration>
```

---

## 5. Wazuh + TheHive — Detection-to-Case Pipeline

Wazuh sebagai SIEM/EDR mengirim alert ke TheHive sebagai case management. Pipeline ini gratis, mature, dan banyak dipakai.

### TheHive Deploy

```yaml
version: "3.8"
services:
  thehive:
    image: thehiveproject/thehive:latest
    ports:
      - "9000:9000"
    environment:
      - JAVA_OPTS=-Xms2G -Xmx4G
    volumes:
      - thehive-data:/opt/thp/data
    depends_on:
      - cassandra
      - elasticsearch
```

### Wazuh → TheHive Integration

```xml
<!-- /var/ossec/etc/ossec.conf -->
<integration>
  <name>thehive</name>
  <hook_url>http://thehive:9000/api/alert</hook_url>
  <alert_format>json</alert_format>
  <rule_id>5710,5712,5715</rule_id>
</integration>
```

### Automated Case Creation

Flow: Wazuh detect → alert JSON → TheHive create alert → analyst triage → escalate to case.

```python
# thehive-create-case.py — Webhook receiver
from flask import Flask, request
import requests

app = Flask(__name__)

THEHIVE_URL = "http://thehive:9000"
THEHIVE_KEY = "your-api-key"

@app.route("/webhook/wazuh", methods=["POST"])
def handle_alert():
    alert = request.json

    # Buat alert di TheHive
    payload = {
        "title": f"Wazuh Alert: {alert['rule']['description']}",
        "description": alert.get("full_log", ""),
        "severity": alert["rule"]["level"],
        "tags": ["wazuh", alert["rule"]["groups"][0]],
        "source": "wazuh",
        "sourceRef": alert["id"],
        "artifacts": [
            {"dataType": "ip", "data": alert["data"]["src_ip"]},
            {"dataType": "hostname", "data": alert["agent"]["name"]},
        ]
    }

    resp = requests.post(
        f"{THEHIVE_URL}/api/alert",
        headers={"Authorization": f"Bearer {THEHIVE_KEY}"},
        json=payload
    )
    return resp.text
```

---

## 6. Playbook Automation — YAML Format

Playbook adalah inti SOAR. Format YAML memungkinkan version control dan review.

### Struktur Playbook

```yaml
name: string
description: string
trigger: # Event source
  type: webhook|schedule|api
  config: {}
steps: [] # Daftar aksi berurutan
variables: {} # Konstanta / env vars
error_handling: # Apa yang terjadi jika step gagal
  default: fail|skip|retry
```

### Step Types

| Type        | Fungsi        | Contoh                          |
| ----------- | ------------- | ------------------------------- |
| `http`      | HTTP request  | API call ke firewall, VT, Slack |
| `condition` | Branching     | If malicious > 5 → block        |
| `jsonpath`  | Extract field | Parse nested JSON               |
| `python`    | Custom script | Compute hash, decode base64     |
| `email`     | Kirim email   | Notifikasi ke analyst           |
| `ssh`       | SSH command   | Execute command di server       |

---

## 7. Automated Containment Techniques

### Firewall Block — iptables/nftables

```bash
# Webhook receiver via python
@app.route("/contain/block-ip")
def block_ip():
    ip = request.args.get("ip")
    subprocess.run([
        "ssh", "admin@firewall",
        f"nft add rule inet filter input ip saddr {ip} drop"
    ])
```

### Cloudflare WAF Block

```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/firewall/access_rules/rules" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mode":"block","configuration":{"target":"ip","value":"1.2.3.4"},"notes":"SOAR automation"}'
```

### EDR Isolate (Wazuh Active Response)

```xml
<!-- ossec.conf -->
<active-response>
  <command>host-deny</command>
  <location>local</location>
  <level>10</level>
  <rules_group>authentication</rules_group>
  <timeout>3600</timeout>
</active-response>
```

### Containment Decision Matrix

| Indicator                     | Confidence | Action                      |
| ----------------------------- | ---------- | --------------------------- |
| IP known malicious (VT > 5)   | High       | Block at firewall + notify  |
| Beaconing to C2               | High       | Isolate endpoint + block IP |
| Suspicious login from new geo | Medium     | MFA challenge + log         |
| Port scan from internal IP    | Low        | Log + investigate           |

---

## 8. Incident Enrichment Pipeline

Setiap alert harus di-enrich sebelum ditindaklanjuti.

```yaml
# enrichment-playbook.yaml
steps:
  - id: get_ip
    jsonpath:
      input: $ALERT
      path: $.source_ip

  - id: vt_lookup
    type: http
    url: "https://www.virustotal.com/api/v3/ip_addresses/{{get_ip.value}}"

  - id: abuseipdb
    type: http
    url: "https://api.abuseipdb.com/api/v2/check?ipAddress={{get_ip.value}}"

  - id: shodan
    type: http
    url: "https://api.shodan.io/shodan/host/{{get_ip.value}}?key=$SHODAN_KEY"

  - id: whois
    type: http
    url: "https://whois.api/{{get_ip.value}}"

  - id: merge_enrichment
    type: python
    script: |
      result = {
        "ip": steps.get_ip.value,
        "vt_malicious": steps.vt_lookup.data.attributes.last_analysis_stats.malicious,
        "abuse_confidence": steps.abuseipdb.data.abuseConfidenceScore,
        "shodan_ports": steps.shodan.data.ports,
        "whois_org": steps.whois.data.org
      }
      # Decision logic
      if result["vt_malicious"] > 5 or result["abuse_confidence"] > 50:
        trigger("block_ip", {"ip": result["ip"]})
```

---

## 9. MCP vs Webhook vs API-Native Orchestration

Tiga pendekatan untuk menghubungkan SOAR dengan tools lain:

| Approach                         | Latency   | Complexity | Use Case                        |
| -------------------------------- | --------- | ---------- | ------------------------------- |
| **Webhook**                      | 100-500ms | Rendah     | Fire & forget, notifikasi Slack |
| **API-Native**                   | 50-200ms  | Sedang     | Query threat intel, block IP    |
| **MCP** (Model Context Protocol) | 200ms-2s  | Tinggi     | Orchestration dengan LLM agent  |

MCP memungkinkan SOAR berintegrasi dengan LLM agent untuk decision making:

```
SIEM Alert → SOAR playbook → MCP call → LLM analisis konteks → SOAR eksekusi
```

Ini sangat powerful untuk alert ambiguity tinggi (contoh: "Login dari IP asing — apakah ini threat atau user legit?").

---

## 10. Deploy & Operasional

### Minimum Resource

| Platform            | CPU    | RAM  | Storage |
| ------------------- | ------ | ---- | ------- |
| Shuffle             | 2 vCPU | 4 GB | 20 GB   |
| TheHive + Cassandra | 4 vCPU | 8 GB | 50 GB   |
| Wazuh (server)      | 4 vCPU | 8 GB | 100 GB  |

### Runbook Checklist

- [ ] Deploy SOAR (Shuffle atau TheHive)
- [ ] Konfigurasi webhook SIEM → SOAR
- [ ] Buat 3 playbook pertama: block-ip, isolate-host, notify-slack
- [ ] Tes enrichment pipeline (VT, AbuseIPDB)
- [ ] Uji automated containment di staging
- [ ] Monitor false positive rate
- [ ] Backup playbook ke git

---

## 11. Metrik & Dashboard

| Metrik                | Target              | Cara Ukur          |
| --------------------- | ------------------- | ------------------ |
| Alert-to-case time    | < 5 menit           | SOAR logs          |
| Playbook success rate | > 95%               | Step completion    |
| False positive rate   | < 10%               | Analyst feedback   |
| MTTR                  | < 15 menit critical | Case resolved time |

---

## 12. Referensi

- **Shuffle Documentation:** https://shuffler.io/docs
- **TheHive Project:** https://thehive-project.org/
- **Wazuh Integration Guide:** https://documentation.wazuh.com/current/user-manual/integrations.html
- **Wazuh Active Response:** https://documentation.wazuh.com/current/user-manual/capabilities/active-response.html
- **Cloudflare API Firewall Rules:** https://developers.cloudflare.com/api/operations/firewall-rules

**Cross-link vault:**

- [[siem-security-data-lake-architecture]] — sumber alert utama
- [[incident-response-framework]] — SOP yang diotomatisasi
- [[threat-hunting-methodology]] — threat intel enrichment
- [[blueteam-detection-matrix]] — detection coverage mapping
- [[endpoint-detection-playbook]] — remediasi endpoint
- [[waf-reverse-proxy-deepdive]] — WAF integration
