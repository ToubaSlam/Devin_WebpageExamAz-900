# Runbook: How to Respond to a Monitoring Alert

**Audience:** On-call engineer.  
**Goal:** Diagnose and resolve production incidents systematically, minimising downtime.

---

## Severity levels

| Severity | Response time | Example alerts |
|---|---|---|
| **Critical** | Immediate | `ApiDown`, `HighErrorRate` (> 5%) |
| **Warning** | Within 30 min | `HighResponseLatency` (p95 > 1 s) |

---

## Step 1 — Acknowledge the alert

Note the alert name, time fired, and affected service. Acknowledge in PagerDuty/Slack to stop escalation.

## Step 2 — Check the Grafana dashboard

Open `http://<VM_PUBLIC_IP>:3000` → **Flask API Dashboard**.

| Panel | What to look for |
|---|---|
| Error Rate | Spike above 5%? When did it start? |
| Request Rate | Drop to zero = API down |
| p95 Latency | Sudden increase = slow dependency or resource exhaustion |
| Request Count by Status | Which status codes are spiking? |

## Step 3 — SSH into the VM

```bash
ssh azureuser@<VM_PUBLIC_IP>
```

### Check container status

```bash
cd /opt/portfolio
docker compose -f docker-compose.prod.yml ps
```

Expected: all services `Up (healthy)`. If any show `Exit` or `unhealthy` → Step 4.

### Check resource usage

```bash
docker stats --no-stream
docker inspect devops-api | grep -i oomkilled
```

## Step 4 — Read the logs

```bash
docker compose -f docker-compose.prod.yml logs --tail=100 api
docker compose -f docker-compose.prod.yml logs -f api      # follow live
```

| Log pattern | Likely cause |
|---|---|
| `Worker failed to boot` | Bad code in latest deploy |
| `Cannot allocate memory` | OOM — increase VM size or reduce workers |
| `ConnectionRefusedError` | Downstream dependency unreachable |

## Step 5 — Quick fixes

### Restart a crashed container

```bash
docker compose -f docker-compose.prod.yml restart api
sleep 15
curl -sf http://localhost:5000/health
```

### Rollback to previous image

```bash
docker inspect devops-api | grep Image   # see current image
nano /opt/portfolio/.env                 # change IMAGE_TAG to last good SHA
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
curl -sf http://localhost:5000/health && echo "OK"
```

### Full stack restart

```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

## Step 6 — Post-incident

1. Confirm recovery on Grafana (error rate 0%, latency normal).
2. Write a blameless post-mortem: timeline, root cause, impact, action items.
3. Open a GitHub issue tagged `incident` with the post-mortem.
4. Update alert thresholds in `monitoring/prometheus/alert_rules.yml` if needed.

---

## Useful commands cheat sheet

```bash
# All container logs
docker compose -f docker-compose.prod.yml logs -f

# Which image is running
docker inspect devops-api --format '{{.Config.Image}}'

# Force-recreate one service
docker compose -f docker-compose.prod.yml up -d --force-recreate api

# Disk and memory
df -h && free -h

# Reload Prometheus config without restart
curl -X POST http://localhost:9090/-/reload
```
