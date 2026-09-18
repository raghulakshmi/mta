# Mobileum Exim MTA Operations Command Sheet

Applies to `mta1.mobileum.com` and `mta2.mobileum.com` on Ubuntu 24.04 with Exim 4.97 (`exim4-daemon-heavy`) and persistent spool `/var/spool/exim4` on the dedicated 500 GB EBS.

> Use `sudo` for Exim queue/message inspection because the spool and TLS paths are intentionally restricted.

## 1. Quick health check

```bash
hostname -f
systemctl status exim4 --no-pager
systemctl is-enabled exim4
systemctl is-active exim4
/usr/sbin/exim4 -bV | head -20
sudo ss -lntp | grep ':25'
```

Check the active configuration:

```bash
sudo exim4 -bV | grep -i 'Configuration file'
sudo exim4 -bP primary_hostname
sudo exim4 -bP spool_directory
sudo exim4 -bP local_interfaces
sudo exim4 -bP queue_only
sudo exim4 -bP split_spool_directory
```

## 2. EBS / spool health

```bash
findmnt /var/spool/exim4
df -hT /var/spool/exim4
df -i /var/spool/exim4
findmnt -no UUID /var/spool/exim4
```

Ownership:

```bash
sudo ls -ldn   /var/spool/exim4   /var/spool/exim4/input   /var/spool/exim4/msglog   /var/spool/exim4/db
```

DR metadata:

```bash
sudo cat /var/spool/exim4/.mobileum-exim-spool.env
sudo cat /etc/mobileum-mta/spool-ebs.conf
sudo findmnt --verify --verbose
```

## 3. Queue overview

Show queue:

```bash
sudo exim4 -bp
```

Count messages:

```bash
sudo exim4 -bpc
```

Queue summary:

```bash
sudo exim4 -bp | /usr/sbin/exiqsumm
```

Example Exim queue ID:

```text
1x7Ux3-000000000rS-2RyL
```

Do not confuse the Exim queue ID with the email's RFC `Message-ID:` header.

## 4. Inspect one queued message

```bash
sudo exim4 -Mvh <EXIM-ID>   # headers
sudo exim4 -Mvb <EXIM-ID>   # body
sudo exim4 -Mvl <EXIM-ID>   # per-message log
```

Example:

```bash
sudo exim4 -Mvh 1x7Ux3-000000000rS-2RyL
sudo exim4 -Mvb 1x7Ux3-000000000rS-2RyL
sudo exim4 -Mvl 1x7Ux3-000000000rS-2RyL
```

## 5. Locate physical spool files

```bash
sudo find /var/spool/exim4 -type f -name '*<EXIM-ID>*'
```

With split spooling enabled, files may be under subdirectories below `input/` and `msglog/`.

Never manually edit or delete spool files.

## 6. Search queue

By sender:

```bash
sudo exiqgrep -f 'sender@example.com'
sudo exiqgrep -i -f 'sender@example.com'
```

By recipient:

```bash
sudo exiqgrep -r 'Venkatesh.AK@mobileum.com'
sudo exiqgrep -i -r 'Venkatesh.AK@mobileum.com'
```

Frozen messages:

```bash
sudo exiqgrep -z
sudo exiqgrep -z -i
```

Non-frozen:

```bash
sudo exiqgrep -x
```

Older than 1 hour:

```bash
sudo exiqgrep -o 3600
sudo exiqgrep -o 3600 -i
```

## 7. Trace by RFC Message-ID header

Current logs:

```bash
sudo grep -R -F '<message-id@example.com>' /var/log/exim4/
```

Compressed rotated logs:

```bash
sudo zgrep -F '<message-id@example.com>' /var/log/exim4/*.gz 2>/dev/null
```

Queued headers:

```bash
sudo grep -R -F '<message-id@example.com>' /var/spool/exim4/input/ 2>/dev/null
```

## 8. Trace by Exim queue ID in logs

```bash
sudo grep -F '<EXIM-ID>' /var/log/exim4/mainlog
sudo zgrep -F '<EXIM-ID>' /var/log/exim4/mainlog.*.gz 2>/dev/null
```

Useful Exim log markers:

```text
<=  message received
=>  successful delivery
->  additional successful delivery
==  delivery deferred
**  delivery failed
Completed  processing completed
```

## 9. Search logs by sender/recipient

```bash
sudo grep -F 'sender@example.com' /var/log/exim4/mainlog
sudo grep -F 'Venkatesh.AK@mobileum.com' /var/log/exim4/mainlog
sudo zgrep -F 'Venkatesh.AK@mobileum.com' /var/log/exim4/mainlog.*.gz 2>/dev/null
```

## 10. Freeze / thaw

Freeze:

```bash
sudo exim4 -Mf <EXIM-ID>
```

Thaw:

```bash
sudo exim4 -Mt <EXIM-ID>
```

Show frozen queue:

```bash
sudo exiqgrep -z
```

Do not thaw messages while SAFE-HOLD commissioning mode is intentionally enabled unless delivery routing has been validated.

## 11. Remove a message

```bash
sudo exim4 -Mrm <EXIM-ID>
```

Then verify:

```bash
sudo exim4 -bp
```

`-Mrm` permanently removes the queued message.

## 12. Queue delivery / retry

Attempt delivery of one message:

```bash
sudo exim4 -M <EXIM-ID>
```

Run queue:

```bash
sudo exim4 -q
```

Verbose queue run:

```bash
sudo exim4 -q -v
```

Do not force delivery while SAFE-HOLD/freeze controls are intentionally enabled.

## 13. Retry databases

```bash
sudo ls -lh /var/spool/exim4/db
sudo exim_dumpdb /var/spool/exim4 retry
sudo exim_dumpdb /var/spool/exim4 wait-remote_smtp
```

Do not manually delete retry database files during normal operations.

## 14. Recipient allow-list

```bash
sudo cat /etc/exim4/mobileum-recipients
sudo ls -l /etc/exim4/mobileum-recipients
```

Known local-part:

```bash
sudo exim4 -be '${lookup{Venkatesh.AK}lsearch{/etc/exim4/mobileum-recipients}{FOUND}{NOTFOUND}}'
```

Unknown local-part:

```bash
sudo exim4 -be '${lookup{does.not.exist}lsearch{/etc/exim4/mobileum-recipients}{FOUND}{NOTFOUND}}'
```

## 15. Offline ACL testing

```bash
sudo exim4 -bh 203.0.113.10
```

Open-relay test:

```text
EHLO attacker.example
MAIL FROM:<attacker@example.org>
RCPT TO:<victim@gmail.com>
```

Expected: `Relay not permitted`.

Invalid Mobileum recipient:

```text
RSET
MAIL FROM:<sender@example.org>
RCPT TO:<does.not.exist@mobileum.com>
```

Expected: `Unknown recipient`.

Valid Mobileum recipient:

```text
RSET
MAIL FROM:<sender@example.org>
RCPT TO:<Venkatesh.AK@mobileum.com>
```

Expected: recipient accepted.

## 16. SMTP listener / EHLO capabilities

```bash
sudo ss -lntp | grep ':25'
```

Commissioning mode should listen only on loopback.

```bash
printf 'EHLO test.mobileum.com\r\nQUIT\r\n' | nc -w 5 127.0.0.1 25
```

Look for `250-STARTTLS`.

## 17. STARTTLS test

```bash
openssl s_client   -starttls smtp   -connect 127.0.0.1:25   -servername "$(hostname -f)"   -brief </dev/null
```

Full certificate:

```bash
openssl s_client   -starttls smtp   -connect 127.0.0.1:25   -servername "$(hostname -f)"   -showcerts </dev/null
```

Inspect local certificate:

```bash
sudo openssl x509   -in /etc/exim4/tls/server.crt   -noout   -subject   -issuer   -dates   -ext subjectAltName
```

Check Exim can read certificate and key:

```bash
sudo -u Debian-exim test -r /etc/exim4/tls/server.crt && echo "CERT readable"
sudo -u Debian-exim test -r /etc/exim4/tls/server.key && echo "KEY readable"
```

Check certificate/key pair:

```bash
sudo openssl x509   -in /etc/exim4/tls/server.crt   -pubkey -noout | sha256sum

sudo openssl pkey   -in /etc/exim4/tls/server.key   -pubout | sha256sum
```

The hashes must match.

## 18. Remote STARTTLS test

Barracuda example:

```bash
printf 'EHLO '"$(hostname -f)"'\r\nQUIT\r\n' | nc -w 10 d100265b.ess.barracudanetworks.com 25
```

TLS handshake:

```bash
openssl s_client   -starttls smtp   -connect d100265b.ess.barracudanetworks.com:25   -servername d100265b.ess.barracudanetworks.com   -brief </dev/null
```

## 19. VRFY / EXPN

```bash
printf 'EHLO test.mobileum.com\r\nVRFY Venkatesh.AK@mobileum.com\r\nQUIT\r\n' | nc -w 5 127.0.0.1 25
```

```bash
printf 'EHLO test.mobileum.com\r\nEXPN Venkatesh.AK@mobileum.com\r\nQUIT\r\n' | nc -w 5 127.0.0.1 25
```

These should be rejected by the configured ACLs.

## 20. Service operations

```bash
sudo systemctl status exim4 --no-pager
sudo systemctl stop exim4
sudo systemctl start exim4
sudo systemctl restart exim4
sudo systemctl reload exim4
sudo systemctl mask exim4
sudo systemctl unmask exim4

systemctl is-enabled exim4
systemctl is-active exim4
```

## 21. Validate configuration before restart

```bash
sudo exim4 -bV
sudo exim4 -bP primary_hostname
sudo exim4 -bP spool_directory
sudo exim4 -bP local_interfaces
sudo exim4 -bP queue_only
sudo exim4 -bP split_spool_directory
```

Candidate configuration:

```bash
sudo exim4 -C /etc/exim4/exim4.conf.mobileum-safehold -bV
sudo exim4 -C /etc/exim4/exim4.conf.mobileum-safehold -bP primary_hostname
```

## 22. Logs

```bash
sudo tail -f /var/log/exim4/mainlog
sudo tail -100 /var/log/exim4/mainlog
sudo tail -100 /var/log/exim4/paniclog
sudo tail -100 /var/log/exim4/rejectlog
```

Watch all:

```bash
sudo tail -F   /var/log/exim4/mainlog   /var/log/exim4/rejectlog   /var/log/exim4/paniclog
```

## 23. Follow one message live

Terminal 1:

```bash
sudo tail -F /var/log/exim4/mainlog
```

Once the Exim ID appears:

```bash
sudo grep -F '<EXIM-ID>' /var/log/exim4/mainlog
sudo exim4 -Mvh <EXIM-ID>
sudo exim4 -Mvb <EXIM-ID>
sudo exim4 -Mvl <EXIM-ID>
```

## 24. Process checks

```bash
ps -ef | grep '[e]xim'
pgrep -a exim4
sudo ss -lntp | grep exim
```

## 25. Capacity monitoring

```bash
df -h /var/spool/exim4
df -i /var/spool/exim4
sudo du -sh /var/spool/exim4
sudo exim4 -bpc
sudo exiqgrep -z -i | wc -l
```

## 26. Safe maintenance workflow

Before changes:

```bash
sudo exim4 -bp
sudo cp -a /etc/exim4 /root/exim4-backup-$(date +%Y%m%d-%H%M%S)
```

Validate candidate:

```bash
sudo exim4 -C /path/to/candidate.conf -bV
```

After activation:

```bash
sudo exim4 -bV
sudo systemctl restart exim4
sudo systemctl status exim4 --no-pager
sudo tail -F /var/log/exim4/mainlog /var/log/exim4/paniclog
```

## 27. Destructive / high-impact commands

Use these with extra care:

```bash
sudo exim4 -Mrm <EXIM-ID>   # permanently remove message
sudo exim4 -Mt <EXIM-ID>    # thaw frozen message
sudo exim4 -M <EXIM-ID>     # attempt delivery
sudo exim4 -q                # run queue
```

Never manually delete files under `/var/spool/exim4/input`, `/var/spool/exim4/msglog`, or `/var/spool/exim4/db`.

## 28. Quick message-trace template

Known Exim ID:

```bash
ID='1x7Ux3-000000000rS-2RyL'

sudo grep -F "$ID" /var/log/exim4/mainlog
sudo exim4 -Mvh "$ID"
sudo exim4 -Mvb "$ID"
sudo exim4 -Mvl "$ID"
sudo find /var/spool/exim4 -type f -name "*$ID*"
```

Known recipient:

```bash
RCPT='Venkatesh.AK@mobileum.com'

sudo exiqgrep -r "$RCPT"
sudo grep -F "$RCPT" /var/log/exim4/mainlog
```

Known sender:

```bash
SENDER='sender@example.com'

sudo exiqgrep -f "$SENDER"
sudo grep -F "$SENDER" /var/log/exim4/mainlog
```

## 29. Current Mobileum reference

```text
Production domain       : mobileum.com
Test recipient          : Venkatesh.AK@mobileum.com
Recipient lookup file   : /etc/exim4/mobileum-recipients
Spool path              : /var/spool/exim4
MTA1                     : mta1.mobileum.com
MTA2                     : mta2.mobileum.com
Exim account             : Debian-exim
Current UID/GID          : 111:113
Exim package             : exim4-daemon-heavy 4.97-4ubuntu4.7
```

MTA1 spool:

```text
EBS Volume : vol-0e4f320c25c79b61a
UUID       : 9822922b-80fa-4b85-ba8f-d318ce6c3451
```

MTA2 spool:

```text
EBS Volume : vol-0acdb94c4fdbe6c49
UUID       : d3b34896-ff47-4639-a099-80816d31a46b
```
