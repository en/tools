部署脚本

- 修改deploy-env.sh里面的ip和ssh连接参数

- 修改infra-setup.sh以下变量, 均使用私有ip
`ETCD0_IP`
`ETCD1_IP`
`ETCD2_IP`
`ETCD_BROWSER_IP`

`NSQ_ADMIN_IP`
`NSQ_LOOKUPD0_IP`
`NSQ_LOOKUPD1_IP`

`STATSD_IP`

没有特殊指定的结点将安装etcd-proxy, nsqd, registrator

- 首先
```bash
source deploy-env.sh
```

之后可以用下面的命令在远程机器上执行命令
```bash
$agent_01_do docker ps -a
```

顺序建议
etcd0, etcd1, etcd2 <= etcd集群完成
nsqlookupd0, nsqlookupd1 <= nsq集群完成
nsqadmin, etcd-browser, statsd <= 监控工具

- 然后
```bash
$agent_01_do < infra-setup.sh
$agent_02_do < infra-setup.sh
$agent_03_do < infra-setup.sh
$monitor_do < infra-setup.sh
```

- 打开etcd-browser, nsqadmin查看集群是否正常工作, 或命令
```bash
$agent_01_do docker exec etcd /etcdctl -C http://127.0.0.1:2379 member list
```
