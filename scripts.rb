def add_vagrant_group()
    $script = <<SCRIPT
usermod -a -G docker vagrant
SCRIPT
end

def create_zfs_pool()
    $script = <<SCRIPT
mkdir -p /var/opt/flocker
truncate --size 10G /var/opt/flocker/pool-vdev
zpool create flocker /var/opt/flocker/pool-vdev
SCRIPT
    return $script
end

def install_ssh_keys()
    $script = <<SCRIPT
cp /vagrant/bakedcerts/insecure_private_key /root/.ssh/id_rsa
cp /vagrant/bakedcerts/insecure_public_key /root/.ssh/id_rsa.pub
cat /vagrant/bakedcerts/insecure_public_key >> /root/.ssh/authorized_keys
chmod 0600 /root/.ssh/id_rsa /root/.ssh/id_rsa.pub
SCRIPT
    return $script
end

def copy_control_certs()
    $script = <<SCRIPT
mkdir -p /etc/flocker
cp /vagrant/bakedcerts/control.crt /etc/flocker/control-service.crt
cp /vagrant/bakedcerts/control.key /etc/flocker/control-service.key
SCRIPT
    return $script
end

def copy_agent_certs(hostname)
    $script = <<SCRIPT
mkdir -p /etc/flocker
cp /vagrant/bakedcerts/cluster.crt /etc/flocker/cluster.crt
cp /vagrant/bakedcerts/#{hostname}.crt /etc/flocker/node.crt
cp /vagrant/bakedcerts/#{hostname}.key /etc/flocker/node.key
cp /vagrant/bakedcerts/plugin.crt /etc/flocker/plugin.crt
cp /vagrant/bakedcerts/plugin.key /etc/flocker/plugin.key
SCRIPT
    return $script
end

def setup_etcd()
    $script = <<SCRIPT
# Setup etcd
# Default client port: 2379, default server-server port: 2380
cd /var/lib
curl -L  https://github.com/coreos/etcd/releases/download/v2.1.3/etcd-v2.1.3-linux-amd64.tar.gz -o etcd-v2.1.3-linux-amd64.tar.gz
tar xzvf etcd-v2.1.3-linux-amd64.tar.gz
cd /var/lib/etcd-v2.1.3-linux-amd64
./etcd &

# Get golang - prereq for building etcd-fs
# Get latest version of go - need 1.3 or higher for etcd-fs build.
# apt-get -y install golang
GO_VERSION=1.5
wget http://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz
tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
export PATH=/usr/local/go/bin:$PATH

# Get etcd-fs
cd /var/lib
git clone https://github.com/xetorthio/etcd-fs.git

# Go get go-etcd, go-fuse - prereqs for etcd-fs
cd /var/lib/etcd-fs
export GOPATH=/var/lib/etcd-fs
go get github.com/coreos/go-etcd/etcd
go get github.com/hanwen/go-fuse/fuse

# Build etcd-fs
make build

# Start etcd-fs
/var/lib/etcd-fs/etcdfs /var/lib/flocker http://localhost:4001 &
SCRIPT
    return $script
end

def flocker_control_config()
    $script = <<SCRIPT
cat <<EOF > /etc/init/flocker-control.override
start on runlevel [2345]
stop on runlevel [016]
EOF
echo 'flocker-control-api       4523/tcp                        # Flocker Control API port' >> /etc/services
echo 'flocker-control-agent     4524/tcp                        # Flocker Control Agent port' >> /etc/services
service flocker-control restart
ufw allow flocker-control-api
ufw allow flocker-control-agent
SCRIPT
    return $script
end

def flocker_agent_config(control_ip)
    $script = <<SCRIPT
mkdir -p /etc/flocker
cat <<EOF > /etc/flocker/agent.yml
"version": 1
"control-service":
   "hostname": "#{control_ip}"
   "port": 4524
"dataset":
   "backend": "zfs"
   "pool": "flocker"
EOF
service flocker-container-agent restart
service flocker-dataset-agent restart
SCRIPT
    return $script
end

def flocker_plugin_config(control_ip, node_ip)
    $script = <<SCRIPT
cat <<EOF > /etc/init/flocker-docker-plugin.conf
# flocker-plugin - flocker-docker-plugin job file

description "Flocker Plugin service"
author "ClusterHQ <support@clusterhq.com>"

respawn
env FLOCKER_CONTROL_SERVICE_BASE_URL=https://#{control_ip}:4523/v1
env MY_NETWORK_IDENTITY=#{node_ip}
exec /usr/local/bin/flocker-docker-plugin
EOF
service flocker-docker-plugin restart
SCRIPT
    return $script
end
