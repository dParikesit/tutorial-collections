# TOC:

- Automated setup using ansible
- Manual setup
  - Preparation [Login as "cc"]
  - Setup zsh [Login on "daniar"]
  - Create loop devices
  - Deploy kubernetes using kubeadm
  - Quickstart minio
- Use the API

## Automated setup using ansible

Steps:

- Make sure you can login as cc
- Edit ip address in inventory.yaml into your chameleoun cloud's IP
- (Optional) You can change username you want in "command.sh". Make sure you change all username in it. The default username is "daniar"
- Run the following
  ```
  cd ansible-playbook
  chmod +x command.sh
  ./command.sh
  ```
- Wait until it finishes

## Manual setup

### 00. Preparation [Login as "cc"]
- Use cc user!!
    ```
    ssh cc@192.5.86.200
    ```
- Setup disk

    ```
    # check if there is already mounted disk
    df -H
        # /dev/sda1       251G  2.8G  248G   2% /
        # should be enough
    ```

- Setup user daniar
    ```
    sudo adduser daniar
    sudo usermod -aG wheel daniar
    sudo su
    cp -r /home/cc/.ssh /home/daniar
    chmod 700  /home/daniar/.ssh
    chmod 644  /home/daniar/.ssh/authorized_keys
    chown daniar  /home/daniar/.ssh
    chown daniar  /home/daniar/.ssh/authorized_keys
    echo "daniar ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users
    exit
    exit
    ```

### 0. Setup zsh [Login on "daniar"]

ssh 192.5.86.200
```
sudo su
yum update -y
yum install zsh -y
chsh -s /bin/zsh root

# Break the Copy here ====

exit
sudo chsh -s /bin/zsh daniar
which zsh
echo $SHELL

sudo yum install wget git vim zsh -y

# Break the Copy here ====

printf 'Y' | sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

/bin/cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
sudo sed -i 's|home/daniar:/bin/bash|home/daniar:/bin/zsh|g' /etc/passwd
sudo sed -i 's|ZSH_THEME="robbyrussell"|ZSH_THEME="risto"|g' ~/.zshrc
zsh
exit
exit
```

### 1. Create loop devices [[AFTER EACH REBOOT]]

    # https://www.thegeekdiary.com/how-to-create-virtual-block-device-loop-device-filesystem-in-linux/

    # If there is only 1 physical storage, you must create loop devices!

        # linux support block device called the loop device, which maps a normal file onto a virtual block device

    # Create a file (25 GB each)

        mkdir -p /mnt/extra/loop-files/
        cd /mnt/extra/loop-files/
        dd if=/dev/zero of=loopbackfile1.img bs=100M count=250
        dd if=/dev/zero of=loopbackfile2.img bs=100M count=250
        dd if=/dev/zero of=loopbackfile3.img bs=100M count=250
        dd if=/dev/zero of=loopbackfile4.img bs=100M count=250
        dd if=/dev/zero of=loopbackfile5.img bs=100M count=250

        # check size
        # du -sh loopbackfile1.img

            # 1048576000 bytes (1.0 GB) copied, 0.723784 s, 1.4 GB/s
            # 1001M loopbackfile1.img

    # Create the loop device

        cd /mnt/extra/loop-files/
        sudo losetup -fP loopbackfile1.img
        sudo losetup -fP loopbackfile2.img
        sudo losetup -fP loopbackfile3.img
        sudo losetup -fP loopbackfile4.img
        sudo losetup -fP loopbackfile5.img

    # print loop devices

        losetup -a
            # /dev/loop0: []: (/mnt/extra/loop-files/loopbackfile1.img)
            # /dev/loop1: []: (/mnt/extra/loop-files/loopbackfile2.img)
            # /dev/loop2: []: (/mnt/extra/loop-files/loopbackfile3.img)

    # Format devices into filesystems

        printf "y" | sudo mkfs.ext4 /mnt/extra/loop-files/loopbackfile1.img
        printf "y" | sudo mkfs.ext4 /mnt/extra/loop-files/loopbackfile2.img
        printf "y" | sudo mkfs.ext4 /mnt/extra/loop-files/loopbackfile3.img
        printf "y" | sudo mkfs.ext4 /mnt/extra/loop-files/loopbackfile4.img
        printf "y" | sudo mkfs.ext4 /mnt/extra/loop-files/loopbackfile5.img

    # mount loop devices

        mkdir -p /mnt/extra/loop-devs/loop0
        mkdir -p /mnt/extra/loop-devs/loop1
        mkdir -p /mnt/extra/loop-devs/loop2
        mkdir -p /mnt/extra/loop-devs/loop3
        mkdir -p /mnt/extra/loop-devs/loop4
        cd /mnt/extra/loop-devs/
        sudo mount -o loop /dev/loop0 /mnt/extra/loop-devs/loop0
        sudo mount -o loop /dev/loop1 /mnt/extra/loop-devs/loop1
        sudo mount -o loop /dev/loop2 /mnt/extra/loop-devs/loop2
        sudo mount -o loop /dev/loop3 /mnt/extra/loop-devs/loop3
        sudo mount -o loop /dev/loop4 /mnt/extra/loop-devs/loop4
        lsblk -f
        df -h

        # remove loop devs [No-NEED]
            # sudo umount /mnt/extra/loop-devs/loop0
            # sudo umount /mnt/extra/loop-devs/loop1
            # sudo umount /mnt/extra/loop-devs/loop2
            # sudo umount /mnt/extra/loop-devs/loop3
            # sudo umount /mnt/extra/loop-devs/loop4
            # sudo losetup -d /dev/loop0
            # sudo losetup -d /dev/loop1
            # sudo losetup -d /dev/loop2
            # sudo losetup -d /dev/loop3
            # sudo losetup -d /dev/loop4
            # rm -rf /mnt/extra/loop-files/*.img

        # check using "lsblk"
            # we will use "loop5" "loop6" "loop7" for Motr
            # "loop8" for log

### 2. Deploy kubernetes using kubeadm
- Update package manager
```
sudo yum update
```

- Install CRI-O
```
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/devel:kubic:libcontainers:stable.repo
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:1.24.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.24/CentOS_7/devel:kubic:libcontainers:stable:cri-o:1.24.repo
sudo yum install cri-o -y 
```

- Disable swap
```
swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

- Configure ufw config
```
cat <<EOF | sudo tee /etc/ufw/sysctl.conf
net/bridge/bridge-nf-call-ip6tables = 1
net/bridge/bridge-nf-call-iptables = 1
net/bridge/bridge-nf-call-arptables = 1
net/ipv4/ip_forward = 1
EOF
```

- Enable modprobe bridge and br_netfilter
```
sudo modprobe bridge
sudo modprobe br_netfilter
```

- Modify sysctl config
```
sudo sysctl -w net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1 >> /etc/sysctl.conf
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1 >> /etc/sysctl.conf
sudo sysctl -w net.bridge.bridge-nf-call-arptables=1 >> /etc/sysctl.conf
```

- Reload ufw and sysctl config
```
sudo ufw reload
sudo sysctl --system
```

- Add kubernetes repo
```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
```

- Set SELinux in permissive mode
```
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum repolist -y
```

- Install kubernetes
```
sudo yum install -y kubelet-1.24.0 kubeadm-1.24.0 kubectl-1.24.0 --disableexcludes=kubernetes
```

- Enable CRI-O and kubelet
```
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl enable kubelet --now
```

- Initialize control-plane
```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

- Add kubectl alias
```
mkdir -p /home/{{username}}/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/{{username}}/.kube/config
sudo chown {{username}} /home/{{username}}/.kube/config

# Logout then login again to load config
```

- Apply Calico for networking
```
kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
kubectl create -f https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml
```

- Untaint master nodes to run minio in master node
```
kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-
```

### 3. Quickstart minio
- Download custom minio-dev.yaml to the machine
```
# This minio-dev.yaml is customized to use 4 of the loop devices created
cd ~
wget [TODO]
```

- Create MinIO pods
```
kubectl apply -f minio-dev.yaml
```

## Use the API
- Open one terminal
```
kubectl port-forward pod/minio -n minio-dev 9000 9090
```

- Open other terminal
```
# You can run s3bench in this terminal
# The api endpoint is 127.0.0.1:9000
# Access key is 'minioadmin'
# Access secret is 'minioadmin'
```