#!/usr/bin/env bash

export AGENT_01_IP=1.2.3.4
export AGENT_02_IP=1.2.3.4
export AGENT_03_IP=1.2.3.4
export MONITOR_IP=1.2.3.4

export ETCD0_IP=${AGENT_01_IP}
export ETCD1_IP=${AGENT_02_IP}
export ETCD2_IP=${AGENT_03_IP}
export ETCD_BROWSER_IP=${MONITOR_IP}

export NSQ_ADMIN_IP=${MONITOR_IP}
export NSQ_LOOKUPD0_IP=${AGENT_01_IP}
export NSQ_LOOKUPD1_IP=${AGENT_02_IP}

export STATSD_IP=${MONITOR_IP}

ETH0_IP=$(ip -4 -o addr | grep eth0 | awk '{print $4}' | cut -f1 -d'/')
DOCKER0_IP=$(ip -4 -o addr | grep docker0 | awk '{print $4}' | cut -f1 -d'/')

echo ETH0_IP: $ETH0_IP
echo DOCKER0_IP: $DOCKER0_IP

# 3 node etcd cluster
case $ETH0_IP in
	$ETCD0_IP)
        ETCD_NAME="etcd0"
        ;;
	$ETCD1_IP)
        ETCD_NAME="etcd1"
        ;;
	$ETCD2_IP)
        ETCD_NAME="etcd2"
        ;;
	*)
        ETCD_NAME="etcd-proxy"
        ;;
esac

if [[ $ETCD_NAME == "etcd0" || $ETCD_NAME == "etcd1" || $ETCD_NAME == "etcd2" ]]; then
    echo "starting ${ETCD_NAME} on ${ETH0_IP}"
    docker rm -f etcd >/dev/null 2>&1
    docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 4001:4001 -p 2380:2380 -p 2379:2379 \
        --name etcd quay.io/coreos/etcd:v2.2.2 \
        --name ${ETCD_NAME} \
        --advertise-client-urls http://${ETH0_IP}:2379,http://${ETH0_IP}:4001 \
        --listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
        --initial-advertise-peer-urls http://${ETH0_IP}:2380 \
        --listen-peer-urls http://0.0.0.0:2380 \
        --initial-cluster-token etcd-cluster-1 \
        --initial-cluster etcd0=http://${ETCD0_IP}:2380,etcd1=http://${ETCD1_IP}:2380,etcd2=http://${ETCD2_IP}:2380 \
        --initial-cluster-state new
else
    echo "starting etcd-proxy on ${ETH0_IP}"
    docker rm -f etcd-proxy >/dev/null 2>&1
    docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 2379:2379 \
        --name etcd-proxy quay.io/coreos/etcd:v2.2.2 \
        --proxy=on \
        --listen-client-urls http://0.0.0.0:2379 \
        --initial-cluster etcd0=http://${ETCD0_IP}:2380,etcd1=http://${ETCD1_IP}:2380,etcd2=http://${ETCD2_IP}:2380
fi

# etcd-browser
if [[ $ETH0_IP == $ETCD_BROWSER_IP ]]; then
    echo "starting etcd-browser on ${ETH0_IP}"
    docker rm -f etcd-browser >/dev/null 2>&1
    docker run -d --name etcd-browser -p 0.0.0.0:8000:8000 \
        --env ETCD_HOST=${DOCKER0_IP} \
        --env ETCD_PORT=2379 \
        --env AUTH_USER=admin \
        --env AUTH_PASS=admin \
        buddho/etcd-browser
fi

# 1 x nsqadmin, 2 x nsqlookupd, n x nsqd cluster
#
# nsqlookupd
if [[ $ETH0_IP == $NSQ_LOOKUPD0_IP || $ETH0_IP == $NSQ_LOOKUPD1_IP ]]; then
    echo "starting nsqlookupd on ${ETH0_IP}"
    docker rm -f nsqlookupd >/dev/null 2>&1
    docker run -d --name nsqlookupd -p 4160:4160 -p 4161:4161 \
        nsqio/nsq:v0.3.6 /nsqlookupd \
        --broadcast-address=${ETH0_IP}
fi

# nsqadmin
if [[ $ETH0_IP == $NSQ_ADMIN_IP ]]; then
    echo "starting nsqadmin on ${ETH0_IP}"
    docker rm -f nsqadmin >/dev/null 2>&1
    docker run -d --name nsqadmin -p 4171:4171 \
        nsqio/nsq:v0.3.6 /nsqadmin \
        --lookupd-http-address=${NSQ_LOOKUPD0_IP}:4161 \
        --lookupd-http-address=${NSQ_LOOKUPD1_IP}:4161
fi

# nsqd
echo "starting nsqd on ${ETH0_IP}"
docker rm -f nsqd >/dev/null 2>&1
docker run -d --name nsqd -p 4150:4150 -p 4151:4151 \
    nsqio/nsq:v0.3.6 /nsqd \
    --broadcast-address=${ETH0_IP} \
    --lookupd-tcp-address=${NSQ_LOOKUPD0_IP}:4160 \
    --lookupd-tcp-address=${NSQ_LOOKUPD1_IP}:4160

# kamon-grafana-dashboard
if [[ $ETH0_IP == $STATSD_IP ]]; then
    echo "starting kamon-grafana-dashboard on ${ETH0_IP}"
    docker rm -f statsd >/dev/null 2>&1
    docker run -d -p 80:80 -p 81:81 -p 8125:8125/udp -p 8126:8126 \
        --name statsd kamon/grafana_graphite
fi

# registrator
docker rm -f registrator >/dev/null 2>&1
docker run -d --name=registrator \
    --net=host \
    --volume=/var/run/docker.sock:/tmp/docker.sock \
    gliderlabs/registrator:latest \
    -ip ${ETH0_IP} \
    etcd://${DOCKER0_IP}:2379/backends
