locals {
  path_build_docker   = "${path.module}"
  path_build_mvn      = "${path.module}/java"

  path_source         = "${path.module}/java/src/main/java"
  path_source_zip     = "${path.module}/java/target/deps.zip"
  path_output_jar     = "${path.module}/java/target/generic-1.0.0.jar"
}

resource "null_resource" "local_mvn_build" {
  count = var.mvn_build_method == "mvn" ? 1 : 0
  provisioner "local-exec" {
    working_dir = local.path_build_mvn
    command     = "mvn package"
  }

  triggers = {
    rerun_every_time = uuid()
  }
}

resource "null_resource" "docker_mvn_build" {
  count = var.mvn_build_method == "docker-mvn" ? 1 : 0
  provisioner "local-exec" {
    working_dir = local.path_build_docker
    command     = "/bin/bash build.sh"
  }

  triggers = {
    rerun_every_time = uuid()
  }
}

data "archive_file" "java_source_zip" {
  type        = "zip"
  source_dir  = local.path_source
  output_path = local.path_source_zip

  depends_on = [
    null_resource.local_mvn_build,
    null_resource.docker_mvn_build
  ]
}

resource "aws_lambda_layer_version" "java_layer" {
  layer_name          = "${var.generic}_layer"
  filename            = local.path_source_zip
  source_code_hash    = data.archive_file.java_source_zip.output_base64sha256
  compatible_runtimes = ["java11"]
}
