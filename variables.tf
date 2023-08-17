variable "mvn_build_method" {
  description = "The method for building the Java JAR; use either 'mvn' or 'docker-mvn'."
  type        = string
  default     = "docker-mvn"
}
