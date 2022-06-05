docker build -t dokcer-compose-loongarch64 .
docker run --rm -v "$(pwd)"/dist:/dist dokcer-compose-loongarch64
ls -al "$(pwd)"/dist
