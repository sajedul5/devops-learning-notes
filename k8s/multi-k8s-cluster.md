# Kubernetes High Availability (HA) Cluster Setup Guide (RHEL Compatible)

This guide describes how to deploy a **High Availability (HA)** Kubernetes cluster using **kubeadm**, **HAProxy**, and **Keepalived** on **RHEL-compatible Linux distributions** (e.g., RHEL 9, AlmaLinux, Rocky Linux).

---

## Cluster Overview

The setup includes:
- **3 Master Nodes** for high availability of the control plane  
- **3 Worker Nodes** for workloads  
- **1 Virtual IP (VIP)** managed by Keepalived for API Server failover  
- **HAProxy** load balancing traffic to master nodes

---

## Node Hostname List and IP


###### Node Hostname List and IP ######

    10.0.0.1   k8s-master-01.example.com
    10.0.0.2   k8s-master-02.example.com
    10.0.0.3   k8s-master-03.example.com
    10.0.1.1   k8s-worker-01.example.com
    10.0.1.2   k8s-worker-02.example.com
    10.0.1.3   k8s-worker-03.example.com
    ........ add + more .................

## 1.System Preparation (All Nodes)


# Set hostname (example)
hostnamectl set-hostname k8s-master-01.example.com

# Add all node host entries
    cat <<EOF >> /etc/hosts
    10.0.0.1   k8s-master-01.example.com
    10.0.0.2   k8s-master-02.example.com
    10.0.0.3   k8s-master-03.example.com
    10.0.1.1   k8s-worker-01.example.com
    10.0.1.2   k8s-worker-02.example.com
    10.0.1.3   k8s-worker-03.example.com
    10.0.0.100 vip.example.com
    EOF

# Disable SELinux and swap
    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    swapoff -a
    sed -i '/swap/d' /etc/fstab

# Load required kernel modules
    cat <<EOF | tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF

    modprobe overlay
    modprobe br_netfilter

# Apply sysctl params
    cat <<EOF | tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF

    sysctl --system

## 2. Install Container Runtime (containerd)

# Install dependencies
    sudo dnf install -y yum-utils device-mapper-persistent-data lvm2

# Add Docker repo
   sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install containerd
    sudo dnf install -y containerd.io

# Configure containerd
    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml

# Use systemd cgroups
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

    sudo systemctl enable --now containerd

# 3. Install Kubernetes Components

    cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
    enabled=1
    gpgcheck=1
    gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
    EOF

    dnf install -y kubelet kubeadm kubectl
    systemctl enable kubelet

# 4. HAProxy and Keepalived Setup

    All master nodes run both HAProxy and Keepalived to achieve load-balanced and fault-tolerant control-plane access.
# Install Packages

    sudo dnf install -y haproxy keepalived

# HAProxy Configuration (All Masters)

```bash
sudo vi /etc/haproxy/haproxy.cfg
frontend kubernetes
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-master-01 10.0.0.1:6443 check fall 3 rise 2
    server k8s-master-02 10.0.0.2:6443 check fall 3 rise 2
    server k8s-master-03 10.0.0.3:6443 check fall 3 rise 2
```
# Enable and start HAProxy

    sudo systemctl enable --now haproxy


# Keepalived Configuration

    sudo vi /etc/keepalived/keepalived.conf on each master node:

```
Master 01

vrrp_instance VI_1 {
    state MASTER
    interface ens160
    virtual_router_id 51
    priority 101
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 42pass
    }
    virtual_ipaddress {
        10.0.0.100/24
    }
}
```

```
Master 02

vrrp_instance VI_1 {
    state BACKUP
    interface ens160
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 42pass
    }
    virtual_ipaddress {
        10.0.0.100/24
    }
}

```
```
Master 03

vrrp_instance VI_1 {
    state BACKUP
    interface ens160
    virtual_router_id 51
    priority 99
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 42pass
    }
    virtual_ipaddress {
        10.0.0.100/24
    }
}
```

# Start both services
    sudo systemctl enable --now haproxy keepalived
    ip addr show | grep 10.0.0.100

# 5. Initialize Control Plane (Master 01)

```
kubeadm init \
  --control-plane-endpoint "vip.example.com:6443" \
  --upload-certs \
  --kubernetes-version v1.31.0 \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=10.0.0.1
```
    Save the kubeadm join and certificate-key output for later use.
# 6. Configure kubectl Access (Master 01)

    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
# 7. Deploy Pod Network (Flannel)

    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

    Wait for the pods to be ready
    kubectl get pods -n kube-system

# 8. Join Other Control Plane Nodes (Master 02 & 03)

```
Run this command on both k8s-master-02 and k8s-master-03 (use your actual token and cert-key):
kubeadm join vip.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <cert-key>
```
# 9. Join Worker Nodes
```
Run this on all worker nodes:
kubeadm join vip.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

# 10. Verify Cluster Status
```
Check cluster nodes:

kubectl get nodes -o wide

Check control-plane health:

kubectl get endpoints kube-scheduler -n kube-system
kubectl get endpoints kube-controller-manager -n kube-system
```