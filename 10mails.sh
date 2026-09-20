HOST=$(hostname -s)
FQDN=$(hostname -f)
BATCH="${HOST}-BARRACUDA-$(date -u +%Y%m%dT%H%M%SZ)"
MAILDATE="$(LC_ALL=C date -R)"

for i in $(seq -w 1 10); do

  MID="${BATCH}-${i}@${FQDN}"

  sudo /usr/sbin/exim4 \
    -odq \
    -f commissioning@example.org \
    Venkatesh.AK@mobileum.com <<EOF
From: Mobileum MTA Commissioning <commissioning@example.org>
To: Venkatesh.AK@mobileum.com
Subject: Mobileum Barracuda Delivery Validation
Message-ID: <${MID}>
Date: ${MAILDATE}

Mobileum pre-go-live Barracuda delivery validation.

Origin MTA: ${FQDN}
Batch: ${BATCH}
Test message: ${i} of 10

Expected destination:
Barracuda production

Check Point is disabled.
Proofpoint is disabled.
EOF

done
