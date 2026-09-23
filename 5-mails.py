python3 - <<'PY'
import smtplib
import email.utils
import time
from email.message import EmailMessage

SMTP_HOST = "172.31.28.75"
SMTP_PORT = 25

sender = "commissioning@example.org"

recipients = [
    "Shreenivas.K@mobileum.com",
    "Koushik.R@mobileum.com",
    "Venkatesh.AK@mobileum.com",
]

for i in range(1, 6):
    msg = EmailMessage()

    msg["From"] = f"Mobileum MTA Commissioning <{sender}>"
    msg["To"] = ", ".join(recipients)
    msg["Subject"] = f"Mobileum MTA2 External SMTP Test {i}/5"
    msg["Date"] = email.utils.formatdate(localtime=True)
    msg["Message-ID"] = (
        f"<mta2-external-{int(time.time())}-{i}@jumpbox.mobileum.com>"
    )

    msg.set_content(f"""Mobileum MTA2 external SMTP test message {i} of 5.

Source      : Jumpbox
Target MTA  : mta2.mobileum.com
Recipients  : Shreenivas.K@mobileum.com
              Koushik.R@mobileum.com
              Venkatesh.AK@mobileum.com

Expected:
- Proofpoint unseen copy
- Barracuda production delivery
""")

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=20) as smtp:
        smtp.set_debuglevel(1)
        smtp.ehlo()
        smtp.send_message(msg)

    print(f"\nSUCCESS: Test message {i}/5 accepted by MTA2\n")
    time.sleep(1)

PY
