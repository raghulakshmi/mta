for MTA in mta1 mta2; do
  echo "================================================="
  echo " Sending 10 test messages through $MTA"
  echo "================================================="

  for N in $(seq -w 1 10); do

    TS=$(date +%Y%m%d%H%M%S)
    TESTID="MOBILEUM-${MTA}-${TS}-${N}"

    echo "Sending $TESTID"

    ssh "$MTA" "sudo /usr/sbin/exim4 -odf \
      -f Venkatesh.AK@mobileum.com \
      Venkatesh.AK@mobileum.com" <<EOF
From: Venkatesh.AK@mobileum.com
To: Venkatesh.AK@mobileum.com
Subject: MOBILEUM MTA TEST ${MTA} ${N} ${TESTID}
Message-ID: <${TESTID}@${MTA}.mobileum.com>
X-Mobileum-MTA-Test: ${TESTID}
X-Mobileum-Origin-MTA: ${MTA}
Date: $(date -R)

Mobileum production MTA delivery validation.

Source MTA : ${MTA}
Test No    : ${N}
Test ID    : ${TESTID}

Expected delivery paths:

1. Proofpoint - unseen copy
2. Barracuda  - production delivery

This is a controlled pre-production test.
EOF

    sleep 2
  done
done
