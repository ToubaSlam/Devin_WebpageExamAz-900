variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project_name"        { type = string }
variable "environment"         { type = string }
variable "subnet_id"           { type = string }
variable "public_ip_id"        { type = string }
variable "vm_size"             { type = string }
variable "admin_username"      { type = string }
variable "ssh_public_key"      { type = string; sensitive = true }
variable "acr_login_server"    { type = string }
variable "tags"                { type = map(string) }
