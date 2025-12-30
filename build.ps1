# Build PowerShell script converted from build.sh
# -- Build Apache Spark Standalone Cluster Docker Images

# Variables
$BUILD_DATE = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
$SPARK_VERSION = "3.4.1"
$HADOOP_VERSION = "3"
$DELTA_SPARK_VERSION = "2.4.0"
$DELTALAKE_VERSION = "0.10.0"
$JUPYTERLAB_VERSION = "4.0.2"
$PANDAS_VERSION = "2.3.3"
$DELTA_PACKAGE_VERSION = "delta-core_2.12:2.4.0"
$SPARK_VERSION_MAJOR = $SPARK_VERSION.Substring(0,1)
$SPARK_XML_PACKAGE_VERSION = "spark-xml_2.12:0.16.0"
$SPARKSQL_MAGIC_VERSION = "0.0.3"
$KAFKA_PYTHON_VERSION = "2.0.2"

# Note: `$SCALA_VERSION` is referenced by the Docker builds in the original script
# but not defined in that file. Leaving it undefined here will expand to an empty string.

function cleanContainers {
    Write-Host "Cleaning containers..."

    # stop & remove jupyterlab containers
    $ids = docker ps -a --filter "name=jupyterlab" --format "{{.ID}}" 2>$null
    if ($ids) { $ids | ForEach-Object { docker stop $_ -ErrorAction SilentlyContinue; docker rm $_ -ErrorAction SilentlyContinue } }

    # stop & remove all spark-worker containers (may be multiple)
    $ids = docker ps -a --filter "name=spark-worker" --format "{{.ID}}" 2>$null
    if ($ids) { $ids | ForEach-Object { docker stop $_ -ErrorAction SilentlyContinue; docker rm $_ -ErrorAction SilentlyContinue } }

    # stop & remove spark-master
    $ids = docker ps -a --filter "name=spark-master" --format "{{.ID}}" 2>$null
    if ($ids) { $ids | ForEach-Object { docker stop $_ -ErrorAction SilentlyContinue; docker rm $_ -ErrorAction SilentlyContinue } }

    # stop & remove spark-base
    $ids = docker ps -a --filter "name=spark-base" --format "{{.ID}}" 2>$null
    if ($ids) { $ids | ForEach-Object { docker stop $_ -ErrorAction SilentlyContinue; docker rm $_ -ErrorAction SilentlyContinue } }

    # stop & remove base
    $ids = docker ps -a --filter "name=base" --format "{{.ID}}" 2>$null
    if ($ids) { $ids | ForEach-Object { docker stop $_ -ErrorAction SilentlyContinue; docker rm $_ -ErrorAction SilentlyContinue } }
}

function cleanImages {
    Write-Host "Cleaning images..."

    $id = docker images jupyterlab --format "{{.ID}}" 2>$null | Select-Object -First 1
    if ($id) { docker rmi -f $id -ErrorAction SilentlyContinue }

    $id = docker images spark-worker --format "{{.ID}}" 2>$null | Select-Object -First 1
    if ($id) { docker rmi -f $id -ErrorAction SilentlyContinue }

    $id = docker images spark-master --format "{{.ID}}" 2>$null | Select-Object -First 1
    if ($id) { docker rmi -f $id -ErrorAction SilentlyContinue }

    $id = docker images spark-base --format "{{.ID}}" 2>$null | Select-Object -First 1
    if ($id) { docker rmi -f $id -ErrorAction SilentlyContinue }

    $id = docker images base --format "{{.ID}}" 2>$null | Select-Object -First 1
    if ($id) { docker rmi -f $id -ErrorAction SilentlyContinue }
}

function cleanVolume {
    Write-Host "Removing Docker volume 'distributed-file-system' if exists..."
    docker volume rm "distributed-file-system" 2>$null | Out-Null
}

function buildImages {
    Write-Host "Building images..."

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

# Main
cleanContainers
cleanImages
cleanVolume
buildImages
