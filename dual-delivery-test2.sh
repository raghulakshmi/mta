cat > ~/mta/dual-delivery-test.sh <<'EOF'
#!/bin/bash

set -e

FQDN=$(hostname -f)
HOST=$(hostname -s)
BATCH="${HOST}-DUAL-$(date -u +%Y%m%dT%H%M%SZ)"
MAILDATE="$(LC_ALL=C date -R)"

echo
echo "=================================================="
echo " Mobileum Dual Delivery Test"
echo "=================================================="
echo "Host  : $FQDN"
echo "Batch : $BATCH"
echo
echo "Expected:"
echo "  Proofpoint -> proofpoint_copy"
echo "  Barracuda  -> barracuda_production"
echo

for i in $(seq -w 1 10); do

    MID="${BATCH}-${i}@${FQDN}"

    echo "Sending message $i/10 : <$MID>"

    sudo /usr/sbin/exim4 \
      -C /etc/exim4/exim4.conf \
      -odf \
      -f commissioning@example.org \
      Venkatesh.AK@mobileum.com <<MAIL
From: Mobileum MTA Commissioning <commissioning@example.org>
To: Venkatesh.AK@mobileum.com
Subject: Mobileum Dual Delivery Validation ${i}/10
Message-ID: <${MID}>
Date: ${MAILDATE}

Mobileum dual-delivery commissioning validation.

Origin MTA: ${FQDN}
Batch: ${BATCH}
Test message: ${i} of 10

Expected downstream delivery:
- Proofpoint
- Barracuda
MAIL

done

echo
echo "=================================================="
echo " Batch complete"
echo " $BATCH"
echo "=================================================="
EOF
