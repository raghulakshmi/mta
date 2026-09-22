# Mobileum Dashboard Recovery

**Purpose:** Quick recovery procedure for the Mobileum MTA Monitoring dashboard when MTA status dots become stale/missing, `/api/health` shows stale data, or the backend returns HTTP 500.

**Applies to:** Jumpbox deployment under:

```text
/opt/mobileum-mta-dashboard
```

Services:

```text
mobileum-mta-collector
mobileum-mta-dashboard
```

> These recovery actions affect only the monitoring services on the Jumpbox. They do **not** restart Exim and do **not** affect mail flow or the MTA queues.

---

## Recovery Set 1 — Dashboard Shows STALE / Missing Green Dots

### 1. Check dashboard health

```bash
curl -s http://127.0.0.1:8089/api/health \
  | python3 -m json.tool
```

Healthy output should show values such as:

```text
"status": "UP"
"display_status": "UP"
"host_reachable": true
"exim_service": "active"
"listener": 1
"sample_age_seconds": < 45
```

If you see:

```text
"display_status": "STALE"
```

or:

```text
"last_error": "[Errno 24] Too many open files"
```

continue below.

---

### 2. Check collector logs

```bash
sudo journalctl \
  -u mobileum-mta-collector \
  --since "10 minutes ago" \
  --no-pager
```

Look for errors such as:

```text
Too many open files
unable to open database file
```

---

### 3. Restart only the collector

```bash
sudo systemctl restart mobileum-mta-collector
```

Verify:

```bash
systemctl is-active mobileum-mta-collector
```

Expected:

```text
active
```

Wait for approximately two collection cycles:

```bash
sleep 30
```

Then check health again:

```bash
curl -s http://127.0.0.1:8089/api/health \
  | python3 -m json.tool
```

If fresh `UP` status returns, refresh the browser. The green dots should return automatically.

---

## Recovery Set 2 — `/api/health` Returns HTTP 500

### 1. Confirm the HTTP status

```bash
curl -i http://127.0.0.1:8089/api/health
```

If the response is:

```text
HTTP/1.1 500 Internal Server Error
```

check the dashboard service log:

```bash
sudo journalctl \
  -u mobileum-mta-dashboard \
  --since "10 minutes ago" \
  --no-pager
```

Common error observed:

```text
sqlite3.OperationalError: unable to open database file
```

---

### 2. Restart the dashboard backend

```bash
sudo systemctl restart mobileum-mta-dashboard
```

Wait briefly:

```bash
sleep 5
```

Verify:

```bash
systemctl is-active mobileum-mta-dashboard
```

Expected:

```text
active
```

Then test:

```bash
curl -i http://127.0.0.1:8089/api/health
```

Expected:

```text
HTTP/1.1 200 OK
```

Finally:

```bash
curl -s http://127.0.0.1:8089/api/health \
  | python3 -m json.tool
```

---

## Combined Quick Recovery

Use this when the dashboard is stale and you want the shortest safe recovery sequence:

```bash
curl -s http://127.0.0.1:8089/api/health \
  | python3 -m json.tool

sudo journalctl \
  -u mobileum-mta-collector \
  --since "10 minutes ago" \
  --no-pager

sudo systemctl restart mobileum-mta-collector

sleep 30

curl -s http://127.0.0.1:8089/api/health \
  | python3 -m json.tool
```

If `/api/health` still returns HTTP 500:

```bash
sudo systemctl restart mobileum-mta-dashboard

sleep 5

curl -i http://127.0.0.1:8089/api/health
```

---

## Optional Diagnostic Capture Before Restart

If time permits, capture collector file-descriptor usage before restarting. This is useful for diagnosing recurrence of the `Too many open files` condition.

```bash
CPID=$(systemctl show -p MainPID --value mobileum-mta-collector)

echo "Collector PID: $CPID"

sudo ls /proc/$CPID/fd | wc -l

sudo grep -i 'open files' /proc/$CPID/limits

sudo systemctl show mobileum-mta-collector -p LimitNOFILE
```

To inspect recent descriptors:

```bash
sudo ls -l /proc/$CPID/fd | tail -30
```

---

## Final Verification

Verify both monitoring services:

```bash
systemctl is-active mobileum-mta-collector
systemctl is-active mobileum-mta-dashboard
```

Expected:

```text
active
active
```

Then verify dashboard health:

```bash
curl -s http://127.0.0.1:8089/api/health \
  | python3 -m json.tool
```

Healthy MTA example:

```text
"status": "UP"
"display_status": "UP"
"host_reachable": true
"exim_service": "active"
"listener": 1
"sample_age_seconds": < 45
```

---

## Important Notes

- Restarting `mobileum-mta-collector` does **not** restart Exim.
- Restarting `mobileum-mta-dashboard` does **not** restart Exim.
- These actions do **not** alter the MTA mail queue.
- Do not restart Nginx unless HTTPS access itself is failing.
- Do not restart MTA1 or MTA2 for a dashboard-only problem.
- A remaining frozen queue item on MTA2 may be expected during safe-hold testing.
