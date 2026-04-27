# Build Apache Spark Standalone Cluster Docker Images (PowerShell Version)

# ----------------------------------------------------------------------------------------------------------------------
# -- Variables ---------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

$BUILD_DATE = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
$SPARK_VERSION = "3.4.1"
$HADOOP_VERSION = "3"
$DELTA_SPARK_VERSION = "2.4.0"
$DELTALAKE_VERSION = "0.10.0"
$JUPYTERLAB_VERSION = "4.0.2"
$PANDAS_VERSION = "2.0.1"
$DELTA_PACKAGE_VERSION = "delta-core_2.12:2.4.0"
$SPARK_VERSION_MAJOR = $SPARK_VERSION.Substring(0,1)
$SPARK_XML_PACKAGE_VERSION = "spark-xml_2.12:0.16.0"
$SPARKSQL_MAGIC_VERSION = "0.0.3"
$KAFKA_PYTHON_VERSION = "2.0.2"
$SCALA_VERSION = "2.12" # Add this variable since it's referenced in buildImages

# ----------------------------------------------------------------------------------------------------------------------
# -- Functions----------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

function Remove-Containers {
  $containers = docker ps -a --format "{{.ID}} {{.Names}}"
  foreach ($name in @('jupyterlab', 'spark-worker', 'spark-master', 'spark-base', 'base')) {
    $ids = $containers | Where-Object { $_ -match $name } | ForEach-Object { $_.Split()[0] }
    foreach ($id in $ids) {
      docker stop $id | Out-Null
      docker rm $id | Out-Null
    }
  }
}

function Remove-Images {
  foreach ($name in @('jupyterlab', 'spark-worker', 'spark-master', 'spark-base', 'base')) {
    $images = docker images --format "{{.ID}} {{.Repository}}" | Where-Object { $_ -match $name }
    foreach ($img in $images) {
      $imgId = $img.Split()[0]
      docker rmi -f $imgId | Out-Null
    }
  }
}

function Remove-Volume {
  docker volume rm "distributed-file-system" | Out-Null
}

function Build-Images {
  docker build `
    --build-arg build_date="$BUILD_DATE" `
    --build-arg scala_version="$SCALA_VERSION" `
    --build-arg delta_spark_version="$DELTA_SPARK_VERSION" `
    --build-arg deltalake_version="$DELTALAKE_VERSION" `
    --build-arg pandas_version="$PANDAS_VERSION" `
    -f docker/base/Dockerfile `
    -t base:latest .

  docker build `
    --build-arg build_date="$BUILD_DATE" `
    --build-arg scala_version="$SCALA_VERSION" `
    --build-arg delta_spark_version="$DELTA_SPARK_VERSION" `
    --build-arg deltalake_version="$DELTALAKE_VERSION" `
    --build-arg pandas_version="$PANDAS_VERSION" `
    --build-arg spark_version="$SPARK_VERSION" `
    --build-arg hadoop_version="$HADOOP_VERSION" `
    --build-arg delta_package_version="$DELTA_PACKAGE_VERSION" `
    --build-arg spark_xml_package_version="$SPARK_XML_PACKAGE_VERSION" `
    -f docker/spark-base/Dockerfile `
    -t "spark-base:$SPARK_VERSION" .

  docker build `
    --build-arg build_date="$BUILD_DATE" `
    --build-arg spark_version="$SPARK_VERSION" `
    -f docker/spark-master/Dockerfile `
    -t "spark-master:$SPARK_VERSION" .

  docker build `
    --build-arg build_date="$BUILD_DATE" `
    --build-arg spark_version="$SPARK_VERSION" `
    -f docker/spark-worker/Dockerfile `
    -t "spark-worker:$SPARK_VERSION" .

  docker build `
    --build-arg build_date="$BUILD_DATE" `
    --build-arg scala_version="$SCALA_VERSION" `
    --build-arg delta_spark_version="$DELTA_SPARK_VERSION" `
    --build-arg deltalake_version="$DELTALAKE_VERSION" `
    --build-arg pandas_version="$PANDAS_VERSION" `
    --build-arg spark_version="$SPARK_VERSION" `
    --build-arg jupyterlab_version="$JUPYTERLAB_VERSION" `
    --build-arg sparksql_magic_version="$SPARKSQL_MAGIC_VERSION" `
    --build-arg kafka_python_version="$KAFKA_PYTHON_VERSION" `
    -f docker/jupyterlab/Dockerfile `
    -t "jupyterlab:$JUPYTERLAB_VERSION-spark-$SPARK_VERSION" .
}

# ----------------------------------------------------------------------------------------------------------------------
# -- Main --------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

Remove-Containers
Remove-Images
Remove-Volume
Build-Images
