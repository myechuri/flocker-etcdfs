## Flocker etcd-fs integration

Use etcd-fs to HA-protect Flocker control service.

# Step 1: Spin up 2 node cluster

```
$ vagrant up
```

# Step 2: Verify etcd is up on node1

```
$ vagrant ssh node1
vagrant@node1:~$ /var/lib/etcd/etcd-v2.1.3-linux-amd64/etcdctl set mykey "this is awesome"
this is awesome
vagrant@node1:~$ /var/lib/etcd/etcd-v2.1.3-linux-amd64/etcdctl get mykey
this is awesome
```

