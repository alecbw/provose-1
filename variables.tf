variable "containers" {
  type        = any
  default     = {}
  description = "Sets up containers on Elastic Container Service. This abstracts over ECS clusters, services, task definitions, and tasks."
}

variable "ebs_volumes" {
  type        = any
  default     = {}
  description = "Creates Elastic Block Storage volumes that are independent of an AWS EC2 instance, but can be bound to one."
}

variable "ec2_instances" {
  type        = any
  default     = {}
  description = "Sets up bare AWS EC2 instances."
}

variable "elastic_file_systems" {
  type        = any
  default     = {}
  description = "Sets up AWS Elastic File Systems (EFS), which are Network File System (NFS) instances managed by Amazon."
}

variable "elasticsearch_clusters" {
  type        = any
  default     = {}
  description = "Sets up Elasticsearch clusters with Kibana using Amazon's managed offering for Elasticsearch."
}

variable "images" {
  type        = any
  default     = {}
  description = "Sets up images on AWS's Elastic Container Registry."
}

variable "jumphost" {
  type        = map
  default     = null
  description = "Creates a jumphost"
}

variable "mysql_clusters" {
  type        = any
  default     = {}
  description = "Sets up AWS Aurora MySQL clusters."
}

variable "openvpn" {
  type        = any
  default     = null
  description = "Sets up an AWS EC2 Client VPN, which is a managed OpenVPN server. This also creates the Public Key Infrastructure (PKI) and creates OpenVPN client files."
}

variable "overrides" {
  type        = any
  default     = {}
  description = "Manual overrides for compatibility."
}

variable "postgresql_clusters" {
  type        = any
  default     = {}
  description = "Sets up AWS Aurora PostgreSQL clusters."
}

variable "provose_config" {
  type        = any
  description = "Required field. This sets up the core configuration of Provose."
}

variable "redis_clusters" {
  type        = any
  default     = {}
  description = "Sets up AWS ElastiCache Redis clusters."
}

variable "redisinsight" {
  type        = map
  default     = null
  description = "Sets up an AWS EC2 instance with RedisInsight."
}

variable "s3_buckets" {
  type        = any
  default     = {}
  description = "Sets up AWS S3 buckets."
}

variable "secrets" {
  type        = map
  default     = {}
  description = "This is a mapping of secrets to values. The secrets are stored in AWS Secrets Manager."
}

variable "sentry" {
  type        = any
  default     = null
  description = "Sets up an AWS EC2 instance running Sentry in a Docker container. This installation of Sentry is appropriate for development usage, but will not scale to production usage."
}

variable "statsd_graphite_grafana" {
  type        = any
  default     = null
  description = "This sets up Statsd, Graphite, and Grafana in Docker containers on a single AWS EC2 instance."
}
