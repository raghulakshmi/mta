for i in $(seq 1 10); do
  sudo /usr/sbin/exim4 \
    -C /etc/exim4/exim4.conf \
    -odf \
    -f commissioning@example.org \
    Venkatesh.AK@mobileum.com <<EOF
From: Mobileum MTA Commissioning <commissioning@example.org>
To: Venkatesh.AK@mobileum.com
Subject: Mobileum Dual Delivery Test $i/10
Message-ID: <mta1-dual-$(date +%s)-$i@mta1.mobileum.com>
Date: $(LC_ALL=C date -R)

Mobileum dual-delivery test message $i of 10.

Expected:
- Proofpoint copy
- Barracuda production delivery
EOF
done
