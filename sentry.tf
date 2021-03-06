locals {
  sentry_git_hash = try(
    var.sentry.commit_hash,
    "a7c5a32e36282f513e6dd5f9461f50114cb0597d"
  )
}

resource "aws_security_group" "sentry" {
  count                  = var.sentry != null ? 1 : 0
  vpc_id                 = aws_vpc.vpc.id
  name                   = "P/v1/${var.provose_config.name}/sentry"
  description            = "Provose security group owned by module ${var.provose_config.name}, configuring ports for our Sentry installation."
  revoke_rules_on_delete = true
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Provose = var.provose_config.name
  }
}

resource "aws_instance" "sentry" {
  count                  = var.sentry != null ? 1 : 0
  ami                    = data.aws_ami.amazon_linux_2_ecs_gpu_hvm_ebs.id
  subnet_id              = aws_subnet.vpc[0].id
  instance_type          = var.sentry.instance_type
  vpc_security_group_ids = [aws_security_group.sentry[0].id]
  key_name               = try(var.sentry.key_name, null)
  root_block_device {
    volume_size = max(
      try(var.sentry.root_volume_size_gb, 0),
      local.minimum_aws_ami_root_volume_size_gb
    )
  }
  user_data = <<USER_DATA
#!/bin/bash
yum update -y
amazon-linux-extras install docker
systemctl start docker.service
usermod -a -G docker ec2-user
chkconfig docker on

yum install -y python3-pip wget unzip
python3 -m pip install docker-compose
# For some reason, /usr/local/bin/docker-compose is not in $PATH?
ln -sv /usr/local/bin/docker-compose /usr/bin/docker-compose
mkdir -p /sentry
cd /sentry
wget https://github.com/getsentry/onpremise/archive/${local.sentry_git_hash}.zip
unzip ${local.sentry_git_hash}.zip
rm -f ${local.sentry_git_hash}.zip
cd onpremise-${local.sentry_git_hash}
# We can't pin an installation of a specific container version
# until the following issue is solved:
# https://github.com/getsentry/onpremise/issues/412

# Start the database with a ten second head start
# so Sentry doesn't crash when trying to connect.
docker-compose up -d postgres
sleep 10

# Run the installer, but don't interactively create a user.
yes n | ./install.sh

# Run the database migrations.
docker-compose run web sentry upgrade --noinput

# Create a user noninteractively.
docker-compose run web sentry createuser --email '${var.sentry.superuser.email}' --password '${var.sentry.superuser.password}' --superuser --no-input
chown -R ec2-user /sentry
cat > /etc/systemd/system/sentry.service <<-TEMPLATE
[Unit]
Description="Starts Sentry on-premise and associated services"
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/sentry/onpremise-${local.sentry_git_hash}
ExecStart=/usr/local/bin/docker-compose -f /sentry/onpremise-${local.sentry_git_hash}/docker-compose.yml up
Restart=on-failure

[Install]
WantedBy=multi-user.target
TEMPLATE
# Start the service
systemctl start sentry

USER_DATA

  tags = {
    Name    = "${var.provose_config.name}-sentry"
    Provose = var.provose_config.name
  }
}

resource "aws_lb_target_group_attachment" "sentry" {
  count            = var.sentry != null ? 1 : 0
  target_group_arn = aws_lb_target_group.sentry[0].arn
  target_id        = aws_instance.sentry[count.index].id
}

# Terraform has an issue where it cannot replace load balancer target groups
# with another load balancer target group having the same name.
# So whenever we change a field that forces us to create a new group, we
# generate a new random name.
resource "random_id" "sentry" {
  count       = var.sentry != null ? 1 : 0
  byte_length = 20
  keepers = {
    vpc_id = aws_vpc.vpc.id
  }
}

resource "aws_lb_target_group" "sentry" {
  count    = var.sentry != null ? 1 : 0
  name     = "tg-${replace(random_id.sentry[0].b64_url, "_", "-")}"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener_rule" "sentry" {
  count        = var.sentry != null ? 1 : 0
  listener_arn = aws_lb_listener.vpc_http_https__port_443[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sentry[0].arn
  }

  condition {
    host_header {
      values = ["sentry.${local.internal_fqdn}"]
    }
  }
}

resource "aws_route53_record" "sentry" {
  count   = var.sentry != null ? 1 : 0
  zone_id = aws_route53_zone.internal_dns.id
  name    = "sentry.${var.provose_config.internal_subdomain}"
  type    = "A"
  alias {
    name                   = aws_lb.vpc_http_https[0].dns_name
    zone_id                = aws_lb.vpc_http_https[0].zone_id
    evaluate_target_health = false
  }
}

# == Output ==

output "sentry" {
  value = {
    aws_security_group = {
      sentry = aws_security_group.sentry
    }
    aws_instance = {
      sentry = aws_instance.sentry
    }
    aws_lb_target_group_attachment = {
      sentry = aws_lb_target_group_attachment.sentry
    }
    aws_lb_target_group = {
      sentry = aws_lb_target_group.sentry
    }
    aws_lb_listener_rule = {
      sentry = aws_lb_listener_rule.sentry
    }
    aws_route53_record = {
      sentry = aws_route53_record.sentry
    }
  }
}
