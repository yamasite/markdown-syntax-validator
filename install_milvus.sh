#!/bin/bash

if [ $# -eq 1 ];then
	dir_location=$1
	milvus_tag=0.6.0-cpu-d120719-2b40dd
elif [ $# -eq 2 ];then
	dir_location=$1
	megawise_tag=$2
else
	echo "Error: please use install_milvus.sh [path(required)] [milvus_tag(optional)] to run."
	exit -1
fi

if [ -d ${dir_location} ];then
	echo "Error: file /home/$USER/milvus already exists, please try again."
  	exit 0
fi

echo "milvus_tag :" $milvus_tag
mkdir -p ${dir_location}/

docker pull milvusdb/milvus:$milvus_tag

cd ${dir_location}
dir_location=$(pwd)

if [ -d ${dir_location} ];then
    echo "Milvus will be installed in : ${dir_location}."
else
    echo "Error: can't create ${dir_location}, please check out the permission."
    exit -1
fi

milvus_image_id=$(docker images |grep "milvusdb/milvus" | grep "$megawise_tag" \
 |awk '{printf "%s\n",$3}')
echo "milvus_image_id:" $milvus_image_id

MILVUS_CNT=$(docker ps | grep $milvus_image_id | wc -l)

if [ $MILVUS_CNT -ne 0 ];then
	echo "An instance of Milvus is already running..."
	exit 0
fi

mkdir -p ${dir_location}/db
mkdir -p ${dir_location}/conf
mkdir -p ${dir_location}/logs

mkdir -p /home/$USER/milvus/conf
wget https://raw.githubusercontent.com/milvus-io/docs/0.6.0/assets/server_config.yaml
wget https://raw.githubusercontent.com/milvus-io/docs/0.6.0/assets/config/log_config.conf

docker run -d --name milvus_cpu \
    -e "TZ=Asia/Shanghai" -p 19530:19530 \
    -p 8080:8080 \
    -v /home/$USER/milvus/db:/var/lib/milvus/db \
    -v /home/$USER/milvus/conf:/var/lib/milvus/conf \
    -v /home/$USER/milvus/logs:/var/lib/milvus/logs milvusdb/milvus:cpu-latest
