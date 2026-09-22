#!/bin/bash

set -e

FQDN=$(hostname -f)
BATCH="$(hostname -s)-DUAL-$(date -u +%Y%m%dT%H%M%SZ)"
MAILDATE="$(LC_ALL=C date -R)"

echo "Batch: $BATCH"
echo "Sending 10 dual-delivery commissioning messages..."

for i in $(seq -w 1 10); do

    MID="${BATCH}-${i}@${FQDN}"

    echo "Sending test $i/10 - Message-ID <$MID>"

    sudo /usr/sbin/exim4 \
      -C /etc/exim4/exim4.conf.mobileum-safehold \
      -odf \
      -f commissioning@example.org \
      Venkatesh.AK@mobileum.com <<EOF
From: Mobileum MTA Commissioning <commissioning@example.org>
To: Venkatesh.AK@mobileum.com
Subject: Mobileum Dual Delivery Validation ${i}/10
Message-ID: <${MID}>
Date: ${MAILDATE}

Mobileum dual-delivery commissioning validation.

Origin MTA: ${FQDN}
Batch: ${BATCH}
Test message: ${i} of 10

Expected delivery legs:
1. Proofpoint
2. Barracuda

This is a controlled commissioning test.
EOF

done

echo
echo "Batch complete: $BATCH"
