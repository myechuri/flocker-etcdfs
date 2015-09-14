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

```
vagrant@node1:~$ sudo bash
root@node1:~# ls /var/lib/flocker
current_configuration.v1.json
root@node1:~# cat /var/lib/flocker/current_configuration.v1.json 
{"nodes": [], "$__class__$": "Deployment"}root@node1:~# 
root@node1:~# docker run --rm --volume-driver=flocker -v my:/data busybox sh -c "echo hello > /data/state.txt"
root@node1:~# docker run --rm --volume-driver=flocker -v my:/data busybox sh -c "cat /data/state.txt"
hello
root@node1:~# cat /var/lib/flocker/current_configuration.v1.json 
{"nodes": [{"applications": [], "manifestations": {"values": [["8bcde111-d4ca-4ede-b244-bb551af11092", {"$__class__$": "Manifestation", "primary": true, "dataset": {"deleted": false, "dataset_id": "8bcde111-d4ca-4ede-b244-bb551af11092", "$__class__$": "Dataset", "maximum_size": 107374182400, "metadata": {"values": [["name", "my"]], "$__class__$": "PMap"}}}]], "$__class__$": "PMap"}, "uuid": {"hex": "8a92f64e-f6ab-46b8-bc83-50f1ac75bc0f", "$__class__$": "UUID"}, "$__class__$": "Node"}], "$__class__$": "Deployment"}
```

Verify that ``etcdctl`` reports Flocker Control Agent state seen from ``etcd-fs``.

```
root@node1:~# /var/lib/etcd-v2.1.3-linux-amd64/etcdctl get current_configuration.v1.json
{"nodes": [{"applications": [], "manifestations": {"values": [["8bcde111-d4ca-4ede-b244-bb551af11092", {"$__class__$": "Manifestation", "primary": true, "dataset": {"deleted": false, "dataset_id": "8bcde111-d4ca-4ede-b244-bb551af11092", "$__class__$": "Dataset", "maximum_size": 107374182400, "metadata": {"values": [["name", "my"]], "$__class__$": "PMap"}}}]], "$__class__$": "PMap"}, "uuid": {"hex": "8a92f64e-f6ab-46b8-bc83-50f1ac75bc0f", "$__class__$": "UUID"}, "$__class__$": "Node"}], "$__class__$": "Deployment"}
root@node1:~# 
```
