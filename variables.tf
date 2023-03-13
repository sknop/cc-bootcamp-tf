variable "confluent_cloud_api_key" {
  type = string
}
variable "confluent_cloud_api_secret" {
  type = string
}
variable "customer_aws_account" {
  type = string    
  default = "829250931565"
}
variable "region" {
  description = "The AWS Region of the existing VPC"
  type = string
  default = "ap-south-1"
}
variable "customer_vpc_id" {
  description = "The VPC ID to private link to Confluent Cloud"
  type = string
  default = "vpc-0db46f0dfba87b815"
}
