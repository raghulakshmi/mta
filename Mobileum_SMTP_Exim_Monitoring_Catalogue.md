### 1. SMTP / Exim Overview

This should be the first screen after selecting `MTA1` or `MTA2`.

| Metric | What it tells us |
|---|---|
| Exim service status | Running / stopped / failed |
| SMTP listener status | Port 25 actually listening |
| MTA hostname | `mta1.mobileum.com` / `mta2.mobileum.com` |
| Exim version | Running package/version |
| Uptime | Exim/service uptime |
| Current SMTP connections | Connections open now |
| Connection rate | Connections/sec or/min |
| Messages accepted | Current interval |
| Messages rejected | Current interval |
| Messages completed | Successfully processed |
| Messages deferred | Delivery not completed |
| Queue depth | Messages currently waiting |
| Oldest queued message | Age of oldest item |
| Proofpoint pending | Messages awaiting PP leg |
| Barracuda pending | Messages awaiting BA leg |
| Dual-delivery completed | Both legs completed |
| Unaccounted messages | Accepted but not identifiable as completed/pending |
| SMTP health | Overall derived status |

The most important PoC KPI remains:

```text
Accepted Messages
       ↓
Proofpoint Delivery
       +
Barracuda Delivery
       ↓
UNACCOUNTED = 0
```

---

### 2. SMTP Connections

This should show what is happening at the actual SMTP listener.

Monitor:

- Active TCP connections to port 25
- New connections/minute
- Peak concurrent connections
- Connections by source IP
- Unique source IPs
- Connections per source IP
- Connection duration
- Connections closed normally
- Connections dropped
- Connections reset
- Connections timing out
- SMTP sessions without a message
- Sessions reaching `MAIL FROM`
- Sessions reaching `RCPT TO`
- Sessions reaching `DATA`
- Sessions successfully completing DATA
- Sessions terminated before DATA
- Commands/session
- Connection rejection rate

This gives us visibility into attacks as well as legitimate mail volume.

Example:

```text
SMTP CONNECTIONS

Active                     18
Connections / sec          7.4
Peak                        41
Unique Source IPs          93

Completed sessions       8,421
Dropped                    112
Timed out                   17
Rejected                    66
```

This is especially important against the customer's stated traffic profile—roughly 8 messages/sec average with substantially higher peaks—because we need to distinguish expected load from abnormal connection growth.

---

### 3. SMTP Protocol Statistics

This goes deeper than connection counts.

Track commands such as:

```text
EHLO / HELO
MAIL FROM
RCPT TO
DATA
RSET
NOOP
QUIT
STARTTLS
AUTH
```

For this broker, AUTH ideally should not normally be part of Internet-facing mail reception.

Useful statistics:

| Metric | Purpose |
|---|---|
| EHLO count | SMTP handshakes |
| HELO count | Legacy clients |
| MAIL FROM count | Envelope senders |
| RCPT TO count | Recipient attempts |
| DATA count | Messages submitted |
| RSET count | Aborted/restarted SMTP transactions |
| STARTTLS count | TLS negotiations |
| QUIT count | Cleanly terminated sessions |
| Protocol errors | Malformed SMTP behaviour |
| Unknown commands | Scanner/attack indication |

---

### 4. Message Acceptance

We should monitor the point where Exim actually takes responsibility for a message.

Metrics:

```text
Accepted messages
Accepted recipients
Accepted bytes
Average message size
Maximum message size
Messages/min
Messages/sec
Peak messages/sec
```

Also break them down by:

```text
Source IP
Sender domain
Envelope sender
Recipient domain
Recipient
```

For the PoC we can additionally verify that acceptance is only for the configured Mobileum PoC recipients/domain.

---

### 5. SMTP Rejections

This deserves its own dashboard section because it is both operational and security telemetry.

Categorize rejection reasons:

```text
Invalid recipient
Relay denied
Unknown domain
Malformed HELO/EHLO
Invalid MAIL FROM
Invalid RCPT TO
Too many recipients
Message too large
Connection limit
Rate limit
TLS failure
ACL denial
DNS/RDNS failure
Protocol violation
Temporary rejection
Permanent rejection
```

Then expose:

```text
Total rejected
4xx temporary rejections
5xx permanent rejections
Top rejection reason
Top rejected source IP
Top invalid recipient
Top sender domain
```

This will also help detect **directory harvesting**.

---

### 6. Exim Queue

This should be one of the most detailed sections.

At minimum:

```text
Current queue depth
Queue growth rate
Oldest message
Average queue age
Median queue age
Messages >5 min
Messages >15 min
Messages >30 min
Messages >1 hour
Messages >4 hours
Messages >12 hours
Messages >24 hours
Frozen messages
Deferred messages
Retrying messages
```

Also show queue size:

```text
Number of messages
Total bytes
Average message size
Largest queued message
```

And ideally bucket it:

```text
AGE            COUNT

0–5 min          37
5–15 min          4
15–30 min         1
30–60 min         0
1–4 hours         0
>4 hours          0
```

That graph will make backlog immediately obvious.

---

### 7. Queue Growth / Drain Rate

Queue depth alone isn't enough.

We should calculate:

```text
Messages accepted/min
Messages delivered/min
Messages entering queue/min
Messages leaving queue/min
Net queue growth/min
Estimated drain time
```

For example:

```text
Accepted       490/min
Delivered      487/min
Queue change    +3/min
```

versus:

```text
Accepted       490/min
Delivered       50/min
Queue change  +440/min
```

The second condition tells us the MTA is heading toward trouble even before disk alarms occur.

---

### 8. Proofpoint Delivery Leg

Because of your `unseen` router, this must be monitored independently.

Show:

```text
Attempted
Delivered
Deferred
Failed
Pending
Retrying
Delivery rate
Average delivery latency
P95 delivery latency
P99 delivery latency
SMTP response codes
TLS used
TLS protocol
Remote endpoint
Last successful delivery
Last failed delivery
```

And preferably:

```text
Proofpoint

Delivered       18,472
Deferred             3
Failed               0
Pending              3

Success          99.98%
Last success     17:43:21
TLS              TLSv1.3
```

---

### 9. Barracuda Delivery Leg

Exactly the same treatment:

```text
Attempted
Delivered
Deferred
Failed
Pending
Retrying
Delivery rate
Latency
SMTP responses
TLS
Last success
Last failure
```

This separation is critical. Overall Exim health could be green while **one transport has stopped delivering**.

---

### 10. Dual-Delivery Integrity

I consider this the **most important custom dashboard for this PoC**.

For every accepted Exim Message-ID, determine:

```text
Accepted by Exim       YES
        │
        ├── Proofpoint delivery       YES/NO
        │
        └── Barracuda delivery        YES/NO
```

Then classify:

```text
BOTH DELIVERED
PROOFPOINT ONLY
BARRACUDA ONLY
BOTH PENDING
ONE PENDING
BOTH FAILED
UNACCOUNTED
```

Dashboard:

```text
DUAL DELIVERY INTEGRITY

Accepted                     42,183
Both delivered               42,172
Waiting both                      4
Waiting Proofpoint                3
Waiting Barracuda                 4
Proofpoint-only completed         0
Barracuda-only completed          0
Unaccounted                       0
```

That gives Mobileum visible proof that the broker duplication logic is functioning.

---

### 11. Message Trace

This should be interactive.

Search using:

```text
Exim Message-ID
Sender
Recipient
Source IP
Time range
```

Then display:

```text
17:42:04  Connection from 203.x.x.x
17:42:04  EHLO
17:42:05  MAIL FROM:<sender@example.com>
17:42:05  RCPT TO:<user@mobileum.net>
17:42:05  DATA
17:42:06  ACCEPTED
           Message-ID: 1xABC2-000XYZ

17:42:07  Proofpoint delivery started
17:42:08  Proofpoint 250 OK

17:42:07  Barracuda delivery started
17:42:09  Barracuda 250 OK

RESULT: BOTH DELIVERED
```

This becomes extremely useful during customer demonstrations.

---

### 12. SMTP Response Codes

Aggregate upstream and downstream SMTP status:

```text
2xx success
4xx temporary failure
5xx permanent failure
```

More specifically:

```text
220
221
250
354
421
450
451
452
454
500
501
503
550
551
552
553
554
```

And break them down separately:

```text
Inbound SMTP responses
Proofpoint responses
Barracuda responses
```

A sudden rise in `421`, `451`, `452` is often more useful than waiting for queue size to become critical.

---

### 13. Delivery Deferrals

Detailed reasons should be extracted.

Examples:

```text
Connection refused
Connection timed out
Connection reset
No route to host
Host unreachable
DNS lookup failed
SMTP 421
SMTP 450
SMTP 451
SMTP 452
TLS negotiation failed
Remote host closed connection
```

Then:

```text
Deferred by Proofpoint
Deferred by Barracuda
Top defer reason
Top remote endpoint
Duration of ongoing defer condition
```

---

### 14. Retry Statistics

Because Exim independently retries each transport, monitor:

```text
Retry attempts
Messages awaiting retry
Next retry
Retry successes
Repeated failures
Retry age
```

For each delivery leg independently.

This aligns very well with our Exim design because a Proofpoint failure must **not interfere with the Barracuda copy**, and vice versa.

---

### 15. Frozen Messages

Very important for Exim:

```text
Frozen count
Oldest frozen
Newest frozen
Reason frozen
Frozen bytes
```

And provide Message-ID details.

A dashboard warning should be triggered even if there are only a few frozen messages.

---

### 16. TLS Monitoring

Inbound:

```text
SMTP sessions
STARTTLS offered
STARTTLS attempted
TLS established
TLS failures
TLS protocol versions
TLS cipher
Non-TLS sessions
Certificate expiry
```

Outbound separately:

```text
Proofpoint TLS
Barracuda TLS
```

Including:

```text
TLS version
Cipher
Certificate validation state
TLS failures
Last successful TLS session
```

This is particularly useful because we already verified STARTTLS behaviour on the Barracuda-side path during the design work.

---

### 17. SMTP Security / Abuse

This fits nicely beside your V8 OS security monitoring.

Monitor:

```text
Connection floods
High connection rate/IP
High RCPT rate/IP
Invalid recipients
Recipient enumeration
Relay attempts
Unknown domains
Malformed SMTP
Repeated protocol errors
TLS handshake attacks
Connection timeouts
Commands before HELO/EHLO
Abnormally long sessions
Oversized messages
Too many recipients/message
```

Top tables:

```text
Top source IPs
Top rejected IPs
Top relay attempts
Top invalid recipients
Top malformed clients
```

---

### 18. Open-Relay Health

I would actually make this a permanent status tile:

```text
RELAY PROTECTION
      ✓ SAFE
```

The collector can validate configuration rather than actually attempting uncontrolled external relay constantly.

Monitor:

```text
Allowed recipient domains
Relay ACL state
Accepted external domains
Unexpected routing events
```

Any message accepted for an unauthorized domain should produce a **critical event**.

---

### 19. DNS / Routing

Useful Exim diagnostics:

```text
DNS resolution health
Remote host lookup failures
Proofpoint endpoint resolution
Barracuda endpoint resolution
MX resolution failures
Routing failures
Router selected
Transport selected
```

For our broker, we particularly want to verify messages are using the configured manual routes and **never unexpectedly falling through to Internet MX routing**.

---

### 20. Exim Processes / Runtime

Monitor:

```text
Main Exim daemon PID
Running Exim processes
Active SMTP processes
Queue runner processes
Current queue run
Queue runner duration
Stuck Exim processes
Process count
```

`exiwhat` is useful here because it can tell us what individual Exim processes are currently doing.

---

### 21. SMTP Performance

Track:

```text
Connection setup latency
SMTP transaction latency
Acceptance latency
Queue wait time
Proofpoint delivery latency
Barracuda delivery latency
End-to-end latency
```

Show:

```text
Average
P50
P95
P99
Maximum
```

That becomes especially valuable under the customer's peak SMTP load.

---

### 22. Message Volume Trends

Graphs for:

```text
Connections/sec
Messages/sec
Recipients/sec
Accepted/min
Rejected/min
Delivered/min
Deferred/min
Queue depth
Queue age
Proofpoint delivery
Barracuda delivery
```

Across:

```text
15 minutes
1 hour
4 hours
12 hours
24 hours
7 days
```

This is where our central Jumpbox becomes valuable, because unlike V8's current local-journal-only implementation, we can retain historical statistics.

---

## How I would arrange this in V9

I would **not put all of this into one enormous SMTP page**. V8 already has four OS/security tabs. I'd extend the navigation roughly like this:

```text
SERVER: [ MTA1 ▼ ]      TIME: [ Last 4 Hours ▼ ]


OS / SECURITY
─────────────────────────────────────────────
SSH Access | Failed Logins | Sudo Activity | System Audit


SMTP / EXIM
─────────────────────────────────────────────
SMTP Overview | Connections | Queue | Delivery | Security | Message Trace
```

`Delivery` would contain the Proofpoint/Barracuda comparison and dual-delivery integrity.

Then the top-level server selector controls **everything**:

```text
[ MTA1 ▼ ]

MTA1
MTA2
```

Eventually I'd add:

```text
ALL MTAs
MTA1
MTA2
```

but `ALL MTAs` would mainly be an overview. Detailed Message Trace, SSH, audit, queue analysis etc. should still be tied to an individual MTA.

The **first SMTP screen** could therefore look something like:

```text
 MTA: MTA1 ▼                    Last update: 17:48:03

 ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
 │ EXIM       │ │ SMTP CONN  │ │ QUEUE      │ │ OLDEST     │
 │ ● RUNNING  │ │     23     │ │     37     │ │    42s     │
 └────────────┘ └────────────┘ └────────────┘ └────────────┘

 ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
 │ ACCEPTED   │ │ REJECTED   │ │ DEFERRED   │ │ FROZEN     │
 │   42,183   │ │      73    │ │       7    │ │       0    │
 └────────────┘ └────────────┘ └────────────┘ └────────────┘


                 DUAL DELIVERY

              PROOFPOINT          BARRACUDA
 Delivered       42,172             42,172
 Deferred             3                  4
 Failed               0                  0
 TLS                  ✓                  ✓

              UNACCOUNTED: 0 ✓
```

That gives us a clean separation: **V8 continues to cover host/security activity; V9 adds full Exim/SMTP operational observability** without Grafana or Prometheus.
