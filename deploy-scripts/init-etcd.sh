#!/usr/bin/env bash

docker exec etcd /etcdctl -C http://127.0.0.1:2379 set /seqs/snowflake-uuid 0
docker exec etcd /etcdctl -C http://127.0.0.1:2379 set /seqs/userid 0

# upload numbers
