# The catalog stays on GitHub Pages. Move only its public DNS identity; existing
# application records and unrelated opspresso.com names are not adopted here.
resource "aws_route53_record" "models_catalog" {
  zone_id = data.aws_route53_zone.k3s_agrt.zone_id
  name    = "models.agrt.dev"
  type    = "CNAME"
  ttl     = 300
  records = ["opspresso.github.io"]

  lifecycle {
    create_before_destroy = true
  }
}

# The existing catalog CNAME is not owned by another state in this backend.
# Its replacement creates models.agrt.dev before removing models.opspresso.com.
import {
  to = aws_route53_record.models_catalog
  id = "Z09927883VHDFS344CJ61_models.opspresso.com_CNAME"
}
