#!/bin/bash

# For Milvus 0.6.0 CPU-version and GPU-version 
# Docker version 19.03.5

# How to use
# $ ./install_milvus.sh [$INSTALL_PATH] [$IMAGE_TAG (optional)]

if [ $# -eq 1 ];then
	dir_location=$1
	milvus_tag=0.6.0-cpu-d120719-2b40dd
elif [ $# -eq 2 ];then
	dir_location=$1
	milvus_tag=$2
else
	echo "Error: please use $ ./install_milvus.sh [\$INSTALL_PATH] [\$IMAGE_TAG (optional)] to run."
	exit -1
fi

if [ -d ${dir_location} ];then
	echo "Error: The specified location already exists, please try again."
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

milvus_image_id=$(docker images | grep "$milvus_tag" \
 |awk '{printf "%s\n",$3}')
echo "milvus_image_id:" $milvus_image_id

MILVUS_CNT=$(docker ps | grep $milvus_tag | wc -l)

if [ $MILVUS_CNT -ne 0 ];then
	echo "An instance of Milvus is already running..."
	exit 0
fi

mkdir -p ${dir_location}/db
mkdir -p ${dir_location}/conf
mkdir -p ${dir_location}/logs

DOWNLOAD_CNT_LOG=0
DOWNLOAD_CNT_CONF=0

while [ ! -f ${dir_location}/conf/log_config.conf ];do
    sleep 2
    # CPU/GPU  version config file
    wget -P ${dir_location}/conf https://raw.githubusercontent.com/milvus-io/docs/0.6.0/assets/config/log_config.conf

    if [ $DOWNLOAD_CNT_LOG -ge 30 ];then
        echo "Cannot connect to GitHub to get the config files. Please check your network connection."
        exit -1
    fi
    DOWNLOAD_CNT_LOG=$[$DOWNLOAD_CNT_LOG + 1]
done

while [ ! -f ${dir_location}/conf/server_config.yaml ];do
    sleep 2

    if [[ $milvus_tag == *"cpu"* ]]; then
        # CPU version config file
        wget -P ${dir_location}/conf https://raw.githubusercontent.com/milvus-io/docs/0.6.0/assets/server_config.yaml
    else
        # GPU version config file
        wget -P ${dir_location}/conf https://raw.githubusercontent.com/milvus-io/docs/0.6.0/assets/config/server_config.yaml
    fi

    if [ $DOWNLOAD_CNT_CONF -ge 30 ];then
        echo "Cannot connect to GitHub to get the config files. Please check your network connection."
        exit -1
    fi
    DOWNLOAD_CNT_CONF=$[$DOWNLOAD_CNT_CONF + 1]
done

# Use this command if the image is CPU-only Milvus
if [[ $milvus_tag == *"cpu"* ]]; then
    docker run -d --name milvus_cpu \
    -p 19530:19530 \
    -p 8080:8080 \
    -v ${dir_location}/db:/var/lib/milvus/db \
    -v ${dir_location}/conf:/var/lib/milvus/conf \
    -v ${dir_location}/logs:/var/lib/milvus/logs \
    milvusdb/milvus:$milvus_tag
    
# Use this command if the image is GPU-supported Milvus
else
    docker run -d --name milvus_gpu --gpus all \
    -p 19530:19530 \
    -p 8080:8080 \
    -v ${dir_location}/db:/var/lib/milvus/db \
    -v ${dir_location}/conf:/var/lib/milvus/conf \
    -v ${dir_location}/logs:/var/lib/milvus/logs \
    milvusdb/milvus:$milvus_tag
fi

    
milvus_container_id=$(docker ps |grep ${milvus_tag} |awk '{printf "%s\n",$1}')
echo "Milvus container ID: " ${milvus_container_id}

IS_RUN=$(docker ps | grep ${milvus_container_id} | wc -l)
TRY_CNT=0
while [ $IS_RUN -eq 0 ];do
	sleep 1
	IS_RUN=$(docker ps | grep ${milvus_container_id} | wc -l)
	if [ $TRY_CNT -ge 60 ];then
		echo "Error: Failed to start Milvus. Please check the logs."
        docker logs ${milvus_container_id} | awk '{printf "\n" $0}'
        echo "Milvus docker logs:" ${logs}
		exit -1
	fi
	TRY_CNT=$[$TRY_CNT + 1]
done

echo "State: Successfully started Milvus!"

docker logs ${milvus_container_id} | awk '{printf "\n" $0}'
