#!/usr/bin/env bash

export REGISTRY_IP=1.2.3.4

export AGENT_01_IP=1.2.3.4
export AGENT_02_IP=1.2.3.4
export AGENT_03_IP=1.2.3.4

export GAME_01_IP=1.2.3.4
export GAME_02_IP=1.2.3.4

export SNOWFLAKE_IP=1.2.3.4
export ARCHIVER_IP=1.2.3.4

export MONGODB_URL=mongodb://172.17.42.1/mydb
export REDIS_URL=172.17.42.1:6379
export REDIS_PW=123456

export NSQ_LOOKUPD0_IP=${AGENT_01_IP}
export NSQ_LOOKUPD1_IP=${AGENT_02_IP}

ETH0_IP=$(ip -4 -o addr | grep eth0 | awk '{print $4}' | cut -f1 -d'/')
DOCKER0_IP=$(ip -4 -o addr | grep docker0 | awk '{print $4}' | cut -f1 -d'/')

echo ETH0_IP: $ETH0_IP
echo DOCKER0_IP: $DOCKER0_IP

case $ETH0_IP in
	$AGENT_01_IP)
        SERVICE_ID="agent1"
        ;;
	$AGENT_02_IP)
        SERVICE_ID="agent2"
        ;;
	$AGENT_03_IP)
        SERVICE_ID="agent3"
        ;;
	$GAME_01_IP)
        SERVICE_ID="game1"
        ;;
	$GAME_02_IP)
        SERVICE_ID="game2"
        ;;
	$SNOWFLAKE_IP)
        SERVICE_ID="snowflake"
        ;;
	*)
        ;;
esac

echo SERVICE_ID: $SERVICE_ID

# snowflake
if [[ $ETH0_IP == $SNOWFLAKE_IP ]]; then
    echo "starting snowflake on ${ETH0_IP}"
    docker pull ${REGISTRY_IP}:5000/snowflake
    docker rm -f snowflake >/dev/null 2>&1
    docker run -d --name snowflake -p 50003:50003 \
        -e SERVICE_ID=${SERVICE_ID} \
        -e ETCD_HOST=http://${DOCKER0_IP}:2379 \
        -e NSQD_HOST=http://${DOCKER0_IP}:4151 \
        ${REGISTRY_IP}:5000/snowflake
fi

# archiver
if [[ $ETH0_IP == $ARCHIVER_IP ]]; then
    echo "starting archiver on ${ETH0_IP}"
    docker pull ${REGISTRY_IP}:5000/archiver
    docker rm -f redologs >/dev/null 2>&1
    docker rm -f archiver >/dev/null 2>&1
    docker create -v /data --name redologs ${REGISTRY_IP}:5000/archiver /bin/true
    docker run -d --name archiver --volumes-from redologs \
        -e 'NSQLOOKUPD_HOST=http://${NSQ_LOOKUPD0_IP}:4161;http://${NSQ_LOOKUPD1_IP}:4161' \
        -e NSQD_HOST=http://${DOCKER0_IP}:4151 \
        ${REGISTRY_IP}:5000/archiver /go/bin/archiver
fi

# game
if [[ $ETH0_IP == $GAME_01_IP || $ETH0_IP == $GAME_02_IP ]]; then
    echo "starting ${SERVICE_IP} on ${ETH0_IP}"
    docker pull ${REGISTRY_IP}:5000/game
    docker rm -f game >/dev/null 2>&1
    docker run -d --name game -p 51000:51000 \
        -e SERVICE_ID=${SERVICE_ID} \
        -e ETCD_HOST=http://${DOCKER0_IP}:2379 \
        -e NSQD_HOST=http://${DOCKER0_IP}:4151 \
        -e MONGODB_URL=${MONGODB_URL} \
        -e REDIS_URL=${REDIS_URL} \
        -e REDIS_PW=${REDIS_PW} \
        ${REGISTRY_IP}:5000/game
fi

# agent
if [[ $ETH0_IP == $AGENT_01_IP || $ETH0_IP == $AGENT_02_IP || $ETH0_IP == $AGENT_03_IP ]]; then
    echo "starting ${SERVICE_ID} on ${ETH0_IP}"
    docker pull ${REGISTRY_IP}:5000/agent
    docker rm -f agent >/dev/null 2>&1
    docker run -d --name agent -p 8888:8888 -p 6060:6060 \
        -e SERVICE_ID=${SERVICE_ID} \
        -e ETCD_HOST=http://${DOCKER0_IP}:2379 \
        -e NSQD_HOST=http://${DOCKER0_IP}:4151 \
        -e MONGODB_URL=${MONGODB_URL} \
        ${REGISTRY_IP}:5000/agent
fi
