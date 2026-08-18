# variable

variable "region" {
  description = "생성될 리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "embedding_model" {
  description = "Knowledge Base 가 임베딩에 쓰는 Bedrock 모델. 인덱스의 dimension 과 짝이 맞아야 합니다."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "embedding_dimension" {
  description = "벡터 인덱스의 차원. 위 모델이 내는 차원과 같아야 합니다."
  type        = number
  default     = 1024
}

variable "idc_host_ip" {
  description = "IDC alpha 호스트의 공인 IP. `alpha.agentdure.com` 이 여기를 가리킵니다."
  type        = string
  default     = "115.68.216.99"
}
