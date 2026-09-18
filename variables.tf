variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used to name/tag all resources"
  type        = string
  default     = "tf-assignment"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Only 2 public subnets are created (minimum EKS needs, across 2 AZs).
# No NAT Gateway / private subnets -> keeps cost near-zero.
variable "availability_zones" {
  description = "AZs to spread the 2 public subnets across"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the 2 public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "tf-assignment-eks"
}

variable "eks_node_instance_type" {
  description = "Instance type for the single EKS worker node"
  type        = string
  default     = "t3.medium" # smallest type AWS supports well for EKS-optimized AMI
}

variable "ec2_instance_type" {
  description = "Instance type for the standalone EC2 instance (behind the NLB)"
  type        = string
  default     = "t2.micro" # free-tier eligible
}

variable "key_name" {
  description = "Existing EC2 KeyPair name for SSH access (leave blank to skip SSH access)"
  type        = string
  default     = ""
}

variable "my_ip_cidr" {
  description = "Your IP in CIDR form, allowed to SSH into the EC2 instance (e.g. 1.2.3.4/32). Defaults to closed."
  type        = string
  default     = "127.0.0.1/32"
}
