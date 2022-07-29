ansible-playbook -i inventory.yaml create-user.yaml -e "username=daniar"
ansible-playbook -i inventory.yaml create-loop.yaml -e "username=daniar"
ansible-playbook -i inventory.yaml install-kubernetes-kubeadm.yaml -e "username=daniar"
ansible-playbook -i inventory.yaml quickstart-minio-kubernetes.yaml -e "username=daniar"