# cloudwatch events

# IAM Role for Lifecycle Hook to send messages to SQS

resource "aws_iam_role" "lifecycle_hook" {
  name = format("%s-lifecycle-hook", var.name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-lifecycle-hook", var.name)
    },
  )
}

resource "aws_iam_role_policy" "lifecycle_hook_sqs" {
  name = "sqs-send-message"
  role = aws_iam_role.lifecycle_hook.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.nth.arn
      }
    ]
  })
}

# EC2 Instance State-change Notification (shutting-down)

resource "aws_cloudwatch_event_rule" "nth_shutting_down" {
  name        = format("%s-shutting-down", local.sqs_nth)
  description = "EC2 Instance State-change Notification"

  event_pattern = jsonencode(
    {
      "source" : [
        "aws.ec2"
      ]
      "detail-type" : [
        "EC2 Instance State-change Notification"
      ]
      "detail" : {
        "state" : ["shutting-down"]
      }
    }
  )

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-shutting-down", local.sqs_nth)
    },
  )
}

resource "aws_cloudwatch_event_target" "nth_shutting_down" {
  target_id = format("%s-shutting-down", local.sqs_nth)
  rule      = aws_cloudwatch_event_rule.nth_shutting_down.name
  arn       = aws_sqs_queue.nth.arn
}

# AWS Health Event

resource "aws_cloudwatch_event_rule" "nth_scheduled" {
  name        = format("%s-scheduled-change", local.sqs_nth)
  description = "AWS Health Event"

  event_pattern = jsonencode(
    {
      "source" : [
        "aws.health"
      ]
      "detail-type" : [
        "AWS Health Event"
      ]
      "detail" : {
        "service" : ["EC2"]
        "eventTypeCategory" : ["scheduledChange"]
      }
    }
  )

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-scheduled-change", local.sqs_nth)
    },
  )
}

resource "aws_cloudwatch_event_target" "nth_scheduled" {
  target_id = format("%s-scheduled-change", local.sqs_nth)
  rule      = aws_cloudwatch_event_rule.nth_scheduled.name
  arn       = aws_sqs_queue.nth.arn
}

# EC2 Spot Instance Interruption Warning (spot-itn)

resource "aws_cloudwatch_event_rule" "nth_spot_itn" {
  name        = format("%s-spot-interruption", local.sqs_nth)
  description = "EC2 Spot Instance Interruption Warning"

  event_pattern = jsonencode(
    {
      "source" : [
        "aws.ec2"
      ]
      "detail-type" : [
        "EC2 Spot Instance Interruption Warning"
      ]
      "detail" : {
        "instance-action" : ["terminate"]
      }
    }
  )

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-spot-interruption", local.sqs_nth)
    },
  )
}

resource "aws_cloudwatch_event_target" "nth_spot_itn" {
  target_id = format("%s-spot-interruption", local.sqs_nth)
  rule      = aws_cloudwatch_event_rule.nth_spot_itn.name
  arn       = aws_sqs_queue.nth.arn
}

# EC2 Instance Rebalance Recommendation (rebalance)

resource "aws_cloudwatch_event_rule" "nth_rebalance" {
  name        = format("%s-rebalance", local.sqs_nth)
  description = "EC2 Instance Rebalance Recommendation"

  event_pattern = jsonencode(
    {
      "source" : [
        "aws.ec2"
      ]
      "detail-type" : [
        "EC2 Instance Rebalance Recommendation"
      ]
    }
  )

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-rebalance", local.sqs_nth)
    },
  )
}

resource "aws_cloudwatch_event_target" "nth_rebalance" {
  target_id = format("%s-rebalance", local.sqs_nth)
  rule      = aws_cloudwatch_event_rule.nth_rebalance.name
  arn       = aws_sqs_queue.nth.arn
}
