import io
import unittest
from email import policy
from email.message import EmailMessage
from email.parser import BytesParser
from unittest.mock import Mock

from forwarder import MARKER, build_message, process_record

SENDER = "admin@example.com"
DESTINATION = "owner@example.net"


def message():
    mail = EmailMessage()
    mail["From"] = "Customer <customer@example.org>"
    mail["To"] = SENDER
    mail["Cc"] = "private-copy@example.org"
    mail["Bcc"] = "hidden@example.org"
    mail["Subject"] = "첨부 파일 확인"
    mail["DKIM-Signature"] = "original-signature"
    mail["Authentication-Results"] = "untrusted.example; dkim=pass"
    mail["X-SES-CONFIGURATION-SET"] = "untrusted-set"
    mail.set_content("안녕하세요. 첨부 파일을 확인해 주세요.")
    mail.add_alternative("<p>안녕하세요.</p>", subtype="html")
    mail.add_attachment(b"\x00\xff\x01", maintype="application", subtype="octet-stream", filename="test.bin")
    return mail


def record(**verdicts):
    return {"eventSource": "aws:ses", "ses": {
        "mail": {"messageId": "test-message-1"},
        "receipt": {"recipients": [SENDER], "spamVerdict": {"status": "PASS"},
                    "virusVerdict": {"status": "PASS"}, **verdicts},
    }}


class ForwarderTests(unittest.TestCase):
    def test_multipart_unicode_and_attachment_survive_header_rewrite(self):
        forwarded = BytesParser(policy=policy.default).parsebytes(build_message(message().as_bytes(), SENDER, DESTINATION))
        self.assertEqual(forwarded["From"].addresses[0].addr_spec, SENDER)
        self.assertEqual(forwarded["Reply-To"].addresses[0].addr_spec, "customer@example.org")
        self.assertEqual(forwarded["To"], DESTINATION)
        self.assertEqual(forwarded["Subject"], "첨부 파일 확인")
        self.assertIn("첨부 파일", forwarded.get_body(preferencelist=("plain",)).get_content())
        self.assertEqual(list(forwarded.iter_attachments())[0].get_payload(decode=True), b"\x00\xff\x01")
        for name in ("Cc", "Bcc", "DKIM-Signature", "Authentication-Results", "X-SES-CONFIGURATION-SET"):
            self.assertIsNone(forwarded[name])

    def test_preserves_explicit_reply_to(self):
        mail = message()
        mail["Reply-To"] = "Support <support@example.org>"
        forwarded = BytesParser(policy=policy.default).parsebytes(build_message(mail.as_bytes(), SENDER, DESTINATION))
        self.assertEqual(forwarded["Reply-To"].addresses[0].addr_spec, "support@example.org")

    def test_loop_is_not_forwarded(self):
        mail = message()
        mail["X-Opspresso-Forwarded"] = MARKER
        self.assertIsNone(build_message(mail.as_bytes(), SENDER, DESTINATION))

    def setUp(self):
        self.s3, self.ses = Mock(), Mock()
        self.s3.get_object_tagging.return_value = {"TagSet": []}
        self.s3.get_object.return_value = {"Body": io.BytesIO(message().as_bytes())}

    def process(self, event):
        return process_record(event, self.s3, self.ses, bucket="test-bucket", prefix="incoming/", sender=SENDER, destination=DESTINATION)

    def test_forward_uses_only_fixed_destination(self):
        result = self.process(record())
        self.assertEqual(result["status"], "forwarded")
        self.assertEqual(self.ses.send_email.call_args.kwargs["Destination"], {"ToAddresses": [DESTINATION]})
        self.s3.put_object_tagging.assert_called_once()

    def test_spam_and_virus_are_stored_without_forwarding(self):
        for verdict in ("spamVerdict", "virusVerdict"):
            with self.subTest(verdict=verdict):
                self.assertEqual(self.process(record(**{verdict: {"status": "FAIL"}}))["status"], "quarantined")
        self.ses.send_email.assert_not_called()
        self.s3.get_object.assert_not_called()

    def test_send_failure_is_retried_not_marked_success(self):
        self.ses.send_email.side_effect = RuntimeError("SES unavailable")
        with self.assertRaisesRegex(RuntimeError, "SES unavailable"):
            self.process(record())
        self.s3.put_object_tagging.assert_not_called()

    def test_completed_delivery_is_not_repeated(self):
        self.s3.get_object_tagging.return_value = {"TagSet": [{"Key": "delivery", "Value": "forwarded"}]}
        self.assertEqual(self.process(record())["status"], "already_processed")
        self.ses.send_email.assert_not_called()

    def test_envelope_recipient_not_to_header_controls_acceptance(self):
        event = record()
        event["ses"]["receipt"]["recipients"] = ["other@example.com"]
        with self.assertRaisesRegex(ValueError, "envelope recipient"):
            self.process(event)
        self.s3.get_object.assert_not_called()
        self.ses.send_email.assert_not_called()


if __name__ == "__main__":
    unittest.main()
