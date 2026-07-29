---
title: SIEM & Security Data Lake Architecture
tags:
  - siem
  - security-data-lake
  - log-aggregation
  - wazuh
  - elastic
  - splunk
created: "2026-07-16"
updated: "2026-07-16"
status: pending
---

## Daftar Isi

1. [Kenapa SIEM & Security Data Lake?](#1-kenapa-siem--security-data-lake)
2. [Arsitektur Security Data Lake](#2-arsitektur-security-data-lake)
3. [Log Collection & Ingestion](#3-log-collection--ingestion)
4. [Storage & Schema Design](#4-storage--schema-design)
5. [Detection & Correlation](#5-detection--correlation)
6. [Threat Hunting](#6-threat-hunting)
7. [SIEM Comparison: Open Source vs Enterprise](#7-siem-comparison-open-source-vs-enterprise)
8. [Deployment Blueprint: Wazuh + ELK](#8-deployment-blueprint-wazuh--elk)
9. [Playbook Integration](#9-playbook-integration)

---

## 1. Kenapa SIEM & Security Data Lake?

Vault saat ini punya komponen keamanan per-layer:

- **WAF:** jarsWAF, Cloudflare ([[waf-reverse-proxy-deepdive]])
- **Endpoint:** eBPF, Suricata, detection playbook ([[endpoint-detection-playbook]])
- **Response:** IR framework ([[incident-response-framework]])
- **Threat intel:** Threat directory ([[comprehensive-threat-directory]])

**Missing pillar:** Bagaimana semua data keamanan ini dikumpulkan, disimpan, dan dikorelasikan di satu tempat?

```
┌────────────────────────────────────────────────────┐
│  Security Data Lake / SIEM                          │
│                                                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ WAF logs │ │ Endpoint │ │ Network (Suricata)│  │
│  │ Cloudflare│ │ (eBPF)  │ │ IDS/IPS          │  │
│  └──────────┘ └──────────┘ └──────────────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Syslog   │ │ Cloud    │ │ Threat Intel     │  │
│  │ Auth     │ │ Audit    │ │ Feeds            │  │
│  └──────────┘ └──────────┘ └──────────────────┘  │
└────────────────────────────────────────────────────┘
```

**Kenapa penting:**

- **Korelasi:** Serangan biasanya terlihat di multiple source — tanpa SIEM, koneksi gak ketahuan
- **Search:** Investigasi butuh query cepat (IP, timestamp, user) di petabytes data
- **Retention:** Compliance (GDPR, PCI-DSS) butuh log retention 1-7 tahun
- **Threat hunting:** Cari IOCs yang gak terdeteksi rule-based detection
- **Forensik:** Timeline lengkap buat incident response

---

## 2. Arsitektur Security Data Lake

### 2.1 High-Level Architecture

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Sources   │  │   Sources   │  │   Sources   │
│ WAF / LB    │  │ Endpoints   │  │ Cloud Audit │
│ Cloudflare  │  │ eBPF/Falco  │  │ AWS CTS/S3  │
│ Nginx       │  │ Sysmon      │  │ GCP Audit   │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       ▼                ▼                ▼
┌──────────────────────────────────────────────────┐
│               Log Ingestion Layer                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐             │
│  │ Logstash│ │Fluentd  ││Vector   │             │
│  │ (ELK)   │ │         │ │(Datadog)│             │
│  └────┬────┘ └────┬────┘ └────┬────┘             │
│       │           │           │                  │
│       └─────┬─────┴─────┬─────┘                  │
│             ▼           ▼                        │
│      ┌──────────┐  ┌──────────┐                  │
│      │  Kafka   │  │  Rabbit  │  ← buffer layer  │
│      │  (queue) │  │  (MQ)    │                  │
│      └────┬─────┘  └──────────┘                  │
└───────────┼──────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────┐
│               Storage Layer                        │
│                                                    │
│  ┌──────────────────────────────────────────┐     │
│  │  Hot Storage (SSD) — 7-30 hari           │     │
│  │  Elasticsearch / OpenSearch              │     │
│  │  Index per day: wazuh-alerts-2026.07.16  │     │
│  └──────────────────────────────────────────┘     │
│                                                    │
│  ┌──────────────────────────────────────────┐     │
│  │  Warm Storage (HDD) — 1-6 bulan          │     │
│  │  Elasticsearch (frozen/attribute)         │     │
│  └──────────────────────────────────────────┘     │
│                                                    │
│  ┌──────────────────────────────────────────┐     │
│  │  Cold Storage (S3/Object) — 1-7 tahun    │     │
│  │  Parquet / JSONL / AVRO                   │     │
│  │  Athena / Trino / Spark untuk query       │     │
│  └──────────────────────────────────────────┘     │
└────────────────────┬─────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────┐
│               Analysis Layer                       │
│                                                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Detection│ │  Search  │ │  ML-based         │  │
│  │ Rules    │ │ (Kibana) │ │  Anomaly Detect   │  │
│  │ Wazuh /  │ │          │ │  (Elastic ML)     │  │
│  │ Sigma    │ │          │ │                   │  │
│  └──────────┘ └──────────┘ └──────────────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │Threat    │ │ Reporting│ │  Automation       │  │
│  │ Hunting  │ │ Compliance│ │  (Shuffle/SOAR)  │  │
│  └──────────┘ └──────────┘ └──────────────────┘  │
└──────────────────────────────────────────────────┘
```

### 2.2 Storage Tier Strategy

| Tier     | Storage        | Retention | Query Speed | Cost | Use Case                             |
| -------- | -------------- | --------- | ----------- | ---- | ------------------------------------ |
| **Hot**  | NVMe SSD       | 7-30 hari | <1 detik    | $$$  | Alerting, dashboards, active hunting |
| **Warm** | SATA SSD / HDD | 1-6 bulan | 1-10 detik  | $$   | Historical search, investigation     |
| **Cold** | S3 / Object    | 1-7 tahun | 10-60 detik | $    | Compliance, forensic retrieval       |

---

## 3. Log Collection & Ingestion

### 3.1 Source Integration

```python
# Contoh: kirim log Cloudflare WAF ke SIEM
# Cloudflare → Logpush → S3 → SIEM

# Atau langsung via syslog:
# /etc/rsyslog.d/cloudflare.conf
template(name="cfwaf" type="string" string="%msg%\n")

if $programname == "cloudflare-waf" then {
    action(type="omfwd"
           target="192.168.1.100" port="514"
           protocol="tcp"
           template="cfwaf")
}
```

### 3.2 Log Normalization

Log dari source berbeda harus di-normalisasi ke schema yang konsisten:

```javascript
// Logstash filter — normalisasi Cloudflare WAF
filter {
    if [source] == "cloudflare-waf" {
        mutate {
            rename => {
                "ClientIP" => "source.ip"
                "ClientRequestPath" => "url.path"
                "WAFRuleID" => "rule.id"
                "WAFAction" => "action"
            }
            convert => { "source.port" => "integer" }
        }

        date {
            match => ["EdgeStartTimestamp", "ISO8601"]
            target => "@timestamp"
        }
    }
}
```

**ECS (Elastic Common Schema):** Standar untuk uniformity:

```yaml
# Wajib normalize ke ECS:
source.ip: 192.168.1.100
source.port: 443
destination.ip: 10.0.0.5
destination.port: 8080
event.action: blocked
event.category: network
event.type: connection
rule.id: 959100
rule.description: SQL Injection Detected
tags: ["cloudflare", "waf"]
```

### 3.3 Log Sources Yang Wajib Ada

| Source                  | Data                                       | Tools                            |
| ----------------------- | ------------------------------------------ | -------------------------------- |
| **WAF / Reverse Proxy** | HTTP request, blocked attacks, rate limits | Cloudflare, Nginx, jarsWAF       |
| **Network IDS/IPS**     | Packet-level threat detection              | Suricata, Zeek, Snort            |
| **Endpoint**            | Process, file, network events              | eBPF, Falco, Wazuh agent, Sysmon |
| **System auth**         | SSH, sudo, user login                      | `auth.log`, `secure`             |
| **Cloud audit**         | API calls, IAM changes, S3 access          | AWS CloudTrail, GCP Audit Log    |
| **DNS**                 | Query logs, tunneling detection            | BIND, Unbound, Pi-hole           |
| **Container**           | K8s audit, pod events, container runtime   | Falco, K8s Audit Log             |
| **Threat intel**        | IOC feeds, known bad IPs                   | MISP, AlienVault OTX, CrowdSec   |

---

## 4. Storage & Schema Design

### 4.1 Elasticsearch Index Strategy

```yaml
# Index template untuk security logs
PUT _index_template/security-logs
{
  "index_patterns": ["wazuh-alerts-*", "suricata-*", "cloudflare-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "refresh_interval": "30s",
      "translog.durability": "async",

      # Hot-warm-cold lifecycle
      "index.routing.allocation.require.data": "hot",
      "index.lifecycle.name": "security-lifecycle"
    },
    "mappings": {
      "dynamic": false,  # prevent mapping explosion
      "properties": {
        "@timestamp": { "type": "date" },
        "source.ip": { "type": "ip" },
        "destination.ip": { "type": "ip" },
        "event.action": { "type": "keyword" },
        "rule.id": { "type": "keyword" },
        "message": { "type": "text", "index": true }
      }
    }
  }
}
```

### 4.2 ILM (Index Lifecycle Management)

```json
PUT _ilm/policy/security-lifecycle
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_size": "50GB",
            "max_age": "1d"
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "allocate": {
            "require": { "data": "warm" }
          },
          "force_merge": { "max_num_segments": 1 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "allocate": {
            "require": { "data": "cold" }
          },
          "freeze": {}
        }
      },
      "delete": {
        "min_age": "365d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### 4.3 Schema untuk Security Data Lake (Parquet)

```python
# PySpark — transform JSON logs ke Parquet untuk cold storage
from pyspark.sql.types import *

schema = StructType([
    StructField("timestamp", TimestampType(), True),
    StructField("source_ip", StringType(), True),
    StructField("dest_ip", StringType(), True),
    StructField("event_type", StringType(), True),  # connection, auth, file, etc
    StructField("action", StringType(), True),       # allow, block, alert
    StructField("rule_id", StringType(), True),
    StructField("raw_log", StringType(), True),      # original log for forensic
    StructField("tags", ArrayType(StringType()), True),
])

# Partition by date + source
df.write \
    .partitionBy("year", "month", "event_type") \
    .mode("append") \
    .parquet("s3a://security-data-lake/logs/")
```

### 4.4 Data Sizing Estimate

| Source              | Daily Volume  | 30 Days     | 1 Year      |
| ------------------- | ------------- | ----------- | ----------- |
| WAF (1M req/day)    | ~1 GB         | 30 GB       | 365 GB      |
| Suricata IDS        | ~2 GB         | 60 GB       | 730 GB      |
| Endpoint (20 hosts) | ~500 MB       | 15 GB       | 185 GB      |
| System auth log     | ~100 MB       | 3 GB        | 37 GB       |
| Cloud audit         | ~200 MB       | 6 GB        | 73 GB       |
| DNS queries         | ~200 MB       | 6 GB        | 73 GB       |
| **Total estimate**  | **~4 GB/day** | **~120 GB** | **~1.5 TB** |

---

## 5. Detection & Correlation

### 5.1 Sigma Rules — Universal Detection Format

Sigma = YARA untuk log. Platform-agnostic rule language buat SIEM.

```yaml
# sigma_rule.yml
title: Suspicious PowerShell Execution via EventLog
id: 08f8b3c4-3f2d-4a5e-9b1c-7d8e9f0a1b2c
status: experimental
description: Detects suspicious PowerShell execution patterns

logsource:
  category: process_creation
  product: windows

detection:
  selection:
    Image|endswith: '\powershell.exe'
    CommandLine|contains:
      - "-enc"
      - "-e "
      - "DownloadString"
      - "IEX"
      - "Invoke-Expression"
  condition: selection

falsepositives:
  - Legitimate administrative scripts

level: high
```

**Konversi Sigma ke berbagai SIEM:**

```bash
# Sigma → Wazuh/Elastic query
sigma convert -t es-qs -r sigma/rules/windows/powershell_suspicious.yml
# Output: (Image.keyword:*\\powershell.exe AND CommandLine.keyword:(*-enc* OR *-e * OR *DownloadString*))

# Sigma → Splunk
sigma convert -t splunk -r sigma/rules/windows/powershell_suspicious.yml
```

### 5.2 Wazuh Rules — FIM & Intrusion Detection

```xml
<!-- Wazuh rule — detect port scan via Suricata -->
<rule id="100012" level="10">
  <decoded_as>suricata</decoded_as>
  <field name="alert_category">Port Scan</field>
  <field name="srcip" type="ip-match">!$WHITELIST|10.0.0.0/8</field>
  <options>no_full_log</options>
  <description>Suricata: Port Scan detected from $(srcip)</description>
  <group>suricata,recon,port_scan,</group>
</rule>
```

### 5.3 Correlation Rules

```python
# Pseudocode — multi-source correlation
class CorrelationEngine:
    """
    Detect multi-stage attack dengan correlating signals dari
    multiple source dalam timeline.
    """

    def correlate_timeline(self, ip: str, window: timedelta = timedelta(hours=1)):
        events = self.search_all_sources(f"source.ip:{ip} OR dest.ip:{ip}")

        stages = []
        for event in sorted(events, key=lambda e: e.timestamp):
            # Stage mapping
            if event.type == "port_scan":
                stages.append(("RECON", event.timestamp))
            elif event.type == "waf_block":
                stages.append(("EXPLOIT_ATTEMPT", event.timestamp))
            elif event.type == "auth_failure" and event.count > 5:
                stages.append(("BRUTE_FORCE", event.timestamp))
            elif event.type == "process_creation" and "nc.exe" in event.command:
                stages.append(("C2_CONNECT", event.timestamp))

        # Jika ada 3+ stages → high confidence incident
        if len(stages) >= 3:
            alert(f"Multi-stage attack: {stages}")
            return Incident(
                severity="high",
                ip=ip,
                timeline=stages,
                recommendation=self.get_playbook(stages)
            )
```

### 5.4 Elastic Security — Prebuilt Detection Rules

```yaml
# Beberapa prebuilt rules yang penting:
- "Direct Outbound DNS Traffic" # C2 detection
- "Suspicious Process Creation" # malware execution
- "External IPs from Internal Network" # data exfil
- "Unusual SMB Traffic" # lateral movement
- "Windows Event Log Cleared" # covering tracks
- "Multiple Failed Auth Attempts" # brute force
- "WAF Blocked Requests Spike" # web attack wave
```

---

## 6. Threat Hunting

### 6.1 Hunting Loop Framework

```
1. Hypothesis: "Mungkin ada attacker yang pake DNS tunneling"
2. Data needed: DNS query logs (Unbound/BIND logs)
3. Query: Cari queries dengan entropy tinggi, TTL tidak biasa, TXT records panjang
4. Analyze: Apakah ada IP dengan pola query mencurigakan?
5. Act: Block IP, update detection rules, document findings
```

### 6.2 Hunting Query — Kibana / OpenSearch

```json
// ELK Query — DNS tunneling detection
GET dns-logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "range": { "query_length": { "gt": 50 } } },
        { "regexp": { "query": ".*[a-z0-9]{30,}\\..*" } }
      ],
      "filter": [
        { "term": { "response_code": "NOERROR" } }
      ]
    }
  },
  "aggs": {
    "by_source": {
      "terms": { "field": "source.ip", "size": 10 }
    }
  }
}
```

### 6.3 Prebuilt Hunting Queries

| Hypothesis               | Query Pattern                                                 | Source               |
| ------------------------ | ------------------------------------------------------------- | -------------------- |
| **Data exfil via DNS**   | Query dengan entropy > 4.0 + TXT records panjang              | DNS logs             |
| **Lateral movement**     | New service creation + network connection dari host yang sama | Endpoint logs        |
| **Credential dumping**   | lsass.exe process access dari non-system process              | Sysmon / eBPF        |
| **Persistence via cron** | Crontab modification dari non-root user                       | auth.log + cron logs |
| **Port scanning**        | 100+ connections ke port beda dari satu IP dalam 1 menit      | Suricata/Zeek        |

---

## 7. SIEM Comparison: Open Source vs Enterprise

### Feature Comparison

| Feature                      | Wazuh (OSS)       | ELK Security        | Splunk ES       | S1/Sentinel             |
| ---------------------------- | ----------------- | ------------------- | --------------- | ----------------------- |
| **Log ingestion**            | ✅ Agent + Syslog | ✅ Beats + Syslog   | ✅ UF + Syslog  | ✅ Agent                |
| **FIM**                      | ✅ Built-in       | ✅ Filebeat FIM     | ⚠️ Add-on       | ✅                      |
| **Vulnerability detection**  | ✅                | ❌                  | ⚠️ Add-on       | ✅ (S1)                 |
| **Correlation rules**        | ✅ XML-based      | ✅ EQL + rules      | ✅ SPL          | ✅ Native               |
| **SOAR / Automation**        | ❌ (API only)     | ⚠️ (Elastic Cases)  | ✅ (Playbooks)  | ✅                      |
| **Threat intel integration** | ✅                | ✅                  | ✅              | ✅ Native               |
| **UEBA / ML**                | ❌                | ✅ (Elastic ML)     | ✅              | ✅                      |
| **Agent OS support**         | Win, Linux, Mac   | Win, Linux, Mac     | Win, Linux, Mac | Win, Linux, Mac, mobile |
| **Pricing**                  | **Free**          | Free (basic) / Paid | $$$$            | $$$$$                   |
| **Self-hosted effort**       | Medium            | Medium              | High            | Cloud only              |

### Recommendation

| Scenario              | Rekomendasi                             | Budget            |
| --------------------- | --------------------------------------- | ----------------- |
| **Homelab / Indie**   | Wazuh + OpenSearch                      | $0 (self-hosted)  |
| **Small-medium org**  | ELK Security (free tier) + Wazuh agents | ~$500/month infra |
| **Medium enterprise** | Elastic Security (Platinum)             | ~$10k/month       |
| **Large enterprise**  | Splunk ES / Sentinel                    | ~$50k+/month      |

---

## 8. Deployment Blueprint: Wazuh + ELK

### 8.1 Architecture — Single Node (Homelab)

```yaml
# docker-compose.yml — Wazuh + OpenSearch
version: "3.8"
services:
  # OpenSearch (Elasticsearch fork)
  opensearch:
    image: opensearchproject/opensearch:2.14
    environment:
      - node.name=os-node
      - cluster.initial_master_nodes=os-node
      - discovery.type=single-node
      - plugins.security.ssl.http.enabled=false
      - OPENSEARCH_JAVA_OPTS=-Xms4g -Xmx4g
    volumes:
      - data-opensearch:/usr/share/opensearch/data
    ports:
      - "9200:9200"

  # Wazuh Indexer + Manager
  wazuh-manager:
    image: wazuh/wazuh-manager:4.9
    ports:
      - "1514:1514" # Agent registration
      - "1515:1515" # Agent communication
      - "55000:55000" # API
    volumes:
      - data-wazuh:/var/ossec/data

  # OpenSearch Dashboards (Kibana fork)
  dashboard:
    image: opensearchproject/opensearch-dashboards:2.14
    ports:
      - "5601:5601"
    depends_on:
      - opensearch

  # Filebeat — ship Wazuh alerts to OpenSearch
  filebeat:
    image: elastic/filebeat:8.14
    volumes:
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml

  # CrowdSec — threat intel
  crowdsec:
    image: crowdsecurity/crowdsec:latest
    volumes:
      - data-crowdsec:/var/lib/crowdsec/data
    environment:
      - COLLECTIONS=crowdsecurity/linux crowdsecurity/nginx

volumes:
  data-opensearch:
  data-wazuh:
  data-crowdsec:
```

### 8.2 Wazuh Agent Deployment

```bash
# Linux agent
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
apt install wazuh-agent
/var/ossec/bin/manage_agents -n  # auto-registration

# Konfigurasi /var/ossec/etc/ossec.conf
<agent_config>
  <client>
    <server>
      <address>192.168.1.100</address>
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
    <config-profile>linux</config-profile>
  </client>

  <!-- File Integrity Monitoring -->
  <syscheck>
    <directories check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <frequency>3600</frequency>
  </syscheck>

  <!-- Active Response -->
  <active-response>
    <command>host-deny</command>
    <location>local</location>
    <rules_id>100012</rules_id>  <!-- Port scan rule -->
  </active-response>
</agent_config>
```

### 8.3 Integrasi CrowdSec — Threat Intel Feeds

```yaml
# CrowdSec → SIEM integration
# CrowdSec detect attack → send blocklist ke WAF/iptables → SIEM ingest log

# Output crowdsec ke SIEM
crowdsec:
  acquisitions:
    - source: file
      filename: /var/log/nginx/*.log
      labels:
        type: nginx

  cscli:
    # Sync decisions ke SIEM via API
    - cmd: cscli decisions list -o json
      trigger: on_ban

  outputs:
    - type: syslog
      target: 192.168.1.100:514 # SIEM syslog
      format: json
```

### 8.4 Alert Routing — PagerDuty / Telegram

```python
# Wazuh integration script — alert ke Telegram
import requests
import json
import sys

TELEGRAM_TOKEN = "YOUR_BOT_TOKEN"
CHAT_ID = "YOUR_CHAT_ID"

def send_alert(alert_json):
    alert = json.loads(alert_json)

    message = f"""🚨 Wazuh Alert: Level {alert['rule']['level']}
📋 Rule: {alert['rule']['description']}
🖥️ Agent: {alert['agent']['name']}
🔍 Details: {alert.get('full_log', 'N/A')}
⏰ {alert['timestamp']}"""

    requests.post(
        f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage",
        json={"chat_id": CHAT_ID, "text": message, "parse_mode": "HTML"}
    )

if __name__ == "__main__":
    send_alert(sys.stdin.read())
```

---

## 9. Playbook Integration

### 9.1 SIEM → Incident Response Workflow

```
SURICATA ALERT: Port scan detected (Level 7)
  ↓
WAZUH CORRELATION: Combined with 5 auth failures from same IP
  ↓
ELASTIC RULE: "Reconnaissance + Brute Force" — triggered
  ↓
AUTOMATION (Shuffle/SOAR):
  1. Extract IP dari alert
  2. Check IP di threat intel databases (MISP, VirusTotal)
  3. If malicious → block via iptables / CrowdSec
  4. Create incident in IR tracker
  5. Notify SOC via Telegram
  ↓
RESPONSE TEAM: Investigasi dan update playbook
```

### 9.2 SOAR — Shuffle (Open Source)

```yaml
# Shuffle workflow — auto-block IP pipeline
name: Auto-Block Malicious IP
triggers:
  - type: webhook
    id: wazuh-alert

steps:
  - name: Parse Alert
    action: shuffle-tools:extract-json
    parameters:
      source: ${trigger.body}
      field: source_ip

  - name: Check Threat Intel
    action: http:get
    parameters:
      url: "https://www.virustotal.com/api/v3/ip_addresses/${parsed_ip}"
      headers:
        x-apikey: ${env.VT_API_KEY}
    on_error:
      - action: skip
        reason: "Rate limited — proceed with caution"

  - name: Decision
    action: shuffle-tools:condition
    parameters:
      condition: ${threat_intel.malicious} == true

  - name: Block via iptables
    action: ssh:command
    parameters:
      host: "gateway.local"
      command: "iptables -A INPUT -s ${parsed_ip} -j DROP"
    condition: ${decision} == true

  - name: Notify
    action: telegram:send-message
    parameters:
      message: "🚫 Blocked IP ${parsed_ip} (malicious: ${threat_intel.malicious})"
```

### 9.3 Dashboard SIEM — Visualisasi

```json
// Kibana/OpenSearch dashboard — Security Overview
{
  "panels": [
    { "title": "Events Over Time", "type": "line", "metrics": ["count"] },
    { "title": "Top Source IPs", "type": "table", "metrics": ["top_values"] },
    { "title": "Alert Severity", "type": "pie", "split": "rule.level" },
    { "title": "MITRE ATT&CK Tactics", "type": "heatmap" },
    { "title": "Active Agents", "type": "metric", "value": "agent_count" },
    { "title": "Blocked Threats Today", "type": "metric", "value": "blocked_count" }
  ]
}
```

---

## Referensi

- [[incident-response-framework]] — IR fase-fase & mapping SOP
- [[waf-reverse-proxy-deepdive]] — WAF arsitektur untuk source log
- [[endpoint-detection-playbook]] — Detection dari sisi endpoint
- [[blueteam-detection-matrix]] — C2 detection matrix
- [[comprehensive-threat-directory]] — Threat intel directory
- [[ids-ips-waf-nsm-comparison]] — Perbandingan sensor network
- [[ebpf-kernel-security]] — eBPF untuk endpoint monitoring
- [Wazuh Documentation](https://documentation.wazuh.com)
- [OpenSearch Security](https://opensearch.org/docs/latest/security/)
- [Sigma Rules Repository](https://github.com/SigmaHQ/sigma)
- [Shuffle SOAR](https://shuffler.io)
- [Elastic Security](https://www.elastic.co/security)
- [CrowdSec](https://crowdsec.net)

---

_Dibuat: 16 Juli 2026 — Panduan membangun SIEM & Security Data Lake dari Wazuh + ELK._
