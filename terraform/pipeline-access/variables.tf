variable "aws_region" {
  description = "The AWS region used by the aws provider for the pipeline access resources"
  type        = string
  default     = "us-east-1"
}

variable "github_subject_prefix" {
  description = "The OIDC subject prefix of the GitHub repository that is allowed to assume the pipeline roles, including the immutable owner and repository IDs"
  type        = string
  default     = "repo:dragana1986@187338634/techmax-web-platform@1428824283"
}
