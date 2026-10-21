"""Create a restricted SMTP key and save it locally without printing secrets."""

import argparse
import base64
import hashlib
import hmac
import json
import os
from pathlib import Path
import subprocess


def smtp_password(secret, region):
    key = ("AWS4" + secret).encode()
    for value in ("11111111", region, "ses", "aws4_request", "SendRawEmail"):
        key = hmac.new(key, value.encode(), hashlib.sha256).digest()
    return base64.b64encode(b"\x04" + key).decode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", required=True)
    parser.add_argument("--region", default="ap-northeast-2")
    parser.add_argument("--output", type=Path, default=Path.home() / ".config/opspresso-mail/smtp.json")
    args = parser.parse_args()
    user = "opspresso-admin-mail-smtp"

    def aws(*command):
        result = subprocess.run(["aws", "--profile", args.profile, "--region", args.region,
                                 *command, "--output", "json"], capture_output=True, text=True, check=True)
        return json.loads(result.stdout or "{}")

    if aws("sts", "get-caller-identity")["Account"] != "396608815058":
        raise SystemExit("Unexpected AWS account")
    if aws("iam", "list-access-keys", "--user-name", user)["AccessKeyMetadata"]:
        raise SystemExit("SMTP user already has a key; inspect or rotate it explicitly")
    args.output.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    # Reserve a private file before creating a key, and never overwrite credentials.
    fd = os.open(args.output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    access_key = None
    try:
        with os.fdopen(fd, "w") as output:
            access_key = aws("iam", "create-access-key", "--user-name", user)["AccessKey"]
            json.dump({
                "host": f"email-smtp.{args.region}.amazonaws.com",
                "port": 587,
                "security": "STARTTLS",
                "username": access_key["AccessKeyId"],
                "password": smtp_password(access_key["SecretAccessKey"], args.region),
                "from": "admin@opspresso.com",
            }, output, indent=2)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
    except BaseException:
        if access_key is not None:
            aws("iam", "delete-access-key", "--user-name", user, "--access-key-id", access_key["AccessKeyId"])
        args.output.unlink(missing_ok=True)
        raise
    print(f"Saved SMTP credentials to {args.output} (mode 0600)")


if __name__ == "__main__":
    main()
