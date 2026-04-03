variable "name" {
  type        = string
  description = "Name prefix for backup resources"
}

variable "bucket_name" {
  type        = string
  description = "Backup bucket name"
}

variable "prefix" {
  type        = string
  description = "Prefix for stored backups"
}