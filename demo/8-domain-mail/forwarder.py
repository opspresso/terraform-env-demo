"""Forward one SES recipient to a fixed mailbox without relaying arbitrary mail."""

import json
import os
from email import policy
from email.parser import BytesParser
from email.utils import formataddr, getaddresses

MARKER = "opspresso-admin-mail"
# These headers describe the original transport/signature, not our new message.
TRANSPORT_HEADERS = {
    "from", "sender", "to", "cc", "bcc", "return-path", "received",
    "received-spf", "authentication-results", "dkim-signature", "domainkey-signature",
    "arc-seal", "arc-message-signature", "arc-authentication-results",
    "message-id", "resent-from", "resent-sender", "resent-to", "resent-cc",
    "resent-bcc", "resent-message-id", "resent-date", "x-ses-spam-verdict",
    "x-ses-virus-verdict", "x-ses-receipt", "x-ses-dkim-signature",
    "x-ses-source-arn", "x-ses-from-arn", "x-ses-return-path-arn",
    "x-ses-configuration-set", "x-ses-message-tags",
}


def build_message(raw, sender, destination):
    message = BytesParser(policy=policy.SMTP).parsebytes(raw)
    if message.get("X-Opspresso-Forwarded") == MARKER:
        return None
    original_from = getaddresses(message.get_all("From", []))
    reply_to = getaddresses(message.get_all("Reply-To", [])) or original_from
    if not original_from or not all(address and "@" in address for _, address in original_from):
        raise ValueError("Incoming message has no usable From address")
    if not reply_to or not all(address and "@" in address for _, address in reply_to):
        raise ValueError("Incoming message has no usable reply address")

    for name in set(message.keys()):
        if name.lower() in TRANSPORT_HEADERS or name.lower() in {"reply-to", "x-opspresso-forwarded"}:
            del message[name]
    # SES must authenticate our domain. Reply-To retains the original reply target.
    label = original_from[0][0] or original_from[0][1]
    message["From"] = formataddr((f"{label} via Opspresso", sender))
    message["To"] = destination
    message["Reply-To"] = ", ".join(formataddr(pair) for pair in reply_to)
    message["X-Opspresso-Forwarded"] = MARKER
    return message.as_bytes()


def clients():
    import boto3

    return boto3.client("s3"), boto3.client("sesv2")


def process_record(record, s3, ses, *, bucket, prefix, sender, destination):
    if record.get("eventSource") != "aws:ses":
        raise ValueError("Only SES receipt events are accepted")
    receipt = record["ses"]["receipt"]
    if sender.lower() not in [value.lower() for value in receipt["recipients"]]:
        raise ValueError("Event does not include the configured envelope recipient")
    message_id = record["ses"]["mail"]["messageId"]
    if not message_id or "/" in message_id or ".." in message_id:
        raise ValueError("Invalid SES message ID")
    key = prefix + message_id
    tags = {item["Key"]: item["Value"] for item in s3.get_object_tagging(Bucket=bucket, Key=key)["TagSet"]}
    if tags.get("delivery") in {"forwarded", "quarantined", "loop"}:
        return {"message_id": message_id, "status": "already_processed"}

    if any(receipt.get(verdict, {}).get("status") == "FAIL" for verdict in ("spamVerdict", "virusVerdict")):
        status = "quarantined"
    else:
        raw = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
        forwarded = build_message(raw, sender, destination)
        if forwarded is None:
            status = "loop"
        else:
            ses.send_email(
                FromEmailAddress=sender,
                Destination={"ToAddresses": [destination]},
                Content={"Raw": {"Data": forwarded}},
            )
            status = "forwarded"
    s3.put_object_tagging(Bucket=bucket, Key=key, Tagging={"TagSet": [{"Key": "delivery", "Value": status}]})
    return {"message_id": message_id, "status": status}


def handler(event, context):
    s3, ses = clients()
    results = [process_record(
        record, s3, ses,
        bucket=os.environ["MAIL_BUCKET"],
        prefix=os.environ["MAIL_PREFIX"],
        sender=os.environ["MAIL_ADDRESS"],
        destination=os.environ["FORWARD_TO"],
    ) for record in event["Records"]]
    # Never log the event, headers, body, destination, or exception request payloads.
    for result in results:
        print(json.dumps(result))
    return results
