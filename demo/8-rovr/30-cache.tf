# 샌드박스가 공유하는 패키지·런타임 캐시입니다. 다시 내려받을 수 있는 데이터라 백업하지 않습니다.
resource "aws_efs_file_system" "sandbox_cache" {
  creation_token   = "rovr-sandbox-cache"
  encrypted        = true
  performance_mode = "generalPurpose"
  # Bursting은 읽기·쓰기 GB당 요금이 없습니다. 크레딧이 떨어지면 저장 용량에 비례한 기준 처리량으로 내려갑니다.
  throughput_mode = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "rovr-sandbox-cache"
  }
}

resource "aws_efs_backup_policy" "sandbox_cache" {
  file_system_id = aws_efs_file_system.sandbox_cache.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_security_group" "sandbox_cache" {
  name        = "rovr-sandbox-cache"
  description = "NFS from EKS nodes to the rovr sandbox cache"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "rovr-sandbox-cache"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nfs_from_nodes" {
  security_group_id = aws_security_group.sandbox_cache.id

  description                  = "EKS nodes to EFS 2049/tcp"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = data.terraform_remote_state.eks.outputs.workspace_security_group_id
}

# 샌드박스 노드가 뜰 수 있는 모든 private subnet에 mount target을 둡니다.
resource "aws_efs_mount_target" "sandbox_cache" {
  for_each = { for index, id in data.terraform_remote_state.vpc.outputs.private_subnets : tostring(index) => id }

  file_system_id  = aws_efs_file_system.sandbox_cache.id
  subnet_id       = each.value
  security_groups = [aws_security_group.sandbox_cache.id]
}

# 샌드박스 uid 1000으로 고정합니다. rovr가 uid를 바꾸면 이 값도 함께 바꿉니다.
resource "aws_efs_access_point" "sandbox_cache" {
  file_system_id = aws_efs_file_system.sandbox_cache.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/cache"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }

  tags = {
    Name = "rovr-sandbox-cache"
  }
}
