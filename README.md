## Flocker etcd-fs integration

Use etcd-fs to HA-protect Flocker control service.

# Step 1: Spin up 2 node cluster

```
$ vagrant up
```

# Step 2: Verify etcd is up on node1

```
$ vagrant ssh node1
vagrant@node1:~$ /var/lib/etcd-v2.1.3-linux-amd64/etcdctl set mykey "this is awesome"
this is awesome
vagrant@node1:~$ /var/lib/etcd-v2.1.3-linux-amd64/etcdctl get mykey
this is awesome
vagrant@node1:~$ /var/lib/etcd-v2.1.3-linux-amd64/etcdctl cluster-health
member ce2a822cea30bfca is healthy: got healthy result from http://localhost:2379
cluster is healthy
```

# Check correctness of etcd-fs

Find the latest Flocker config file ``*current_configuration.v1.json.new`` in ``/var/lib/flocker``.

```bash
root@node1:/var/lib/flocker# cat /var/lib/flocker/R5nD5XzzUpoYqvHxcurrent_configuration.v1.json.new
{"nodes": [], "$__class__$": "Deployment"}
```

Verify that ``etcdctl`` gets the same content reported above:
```bash
root@node1:/var/lib/flocker# /var/lib/etcd-v2.1.3-linux-amd64/etcdctl get /R5nD5XzzUpoYqvHxcurrent_configuration.v1.json.new
{"nodes": [], "$__class__$": "Deployment"}
root@node1:/var/lib/flocker#
```
