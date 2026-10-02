Launch Amazon Linux 2023 , t2.micro

Attach a IAM ROLE TE=EC2, Permisions = admin

vi .bashrc

export PATH=$PATH:/usr/local/bin/
:wq!

source .bashrc

ssh-keygen

cp /root/.ssh/id_rsa.pub mykey.pub

chmod 777 my-keypair.pub

vi kops.sh

#!/bin/bash

# 1. Téléchargement et installation des outils
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
wget https://github.com/kubernetes/kops/releases/download/v1.32.0/kops-linux-amd64
chmod +x kops-linux-amd64 kubectl
mv kubectl /usr/local/bin/kubectl
mv kops-linux-amd64 /usr/local/bin/kops

# 2. Création du Bucket S3 (correction us-east-1)
aws s3api create-bucket --bucket djibril-kops-testbkt143333.k8s.local --region us-east-1
aws s3api put-bucket-versioning --bucket djibril-kops-testbkt143333.k8s.local --region us-east-1 --versioning-configuration Status=Enabled

# 3. Variable d'état kOps
export KOPS_STATE_STORE=s3://djibril-kops-testbkt143333.k8s.local

# 4. Création du cluster avec la clé mykey.pub générée
kops create cluster \
  --name=djibril.k8s.local \
  --zones=us-east-1a,us-east-1b \
  --control-plane-count=1 \
  --control-plane-size=t3.medium \
  --node-count=2 \
  --node-size=t3.small \
  --node-volume-size=20 \
  --control-plane-volume-size=20 \
  --ssh-public-key=mykey.pub \
  --image=ami-0fef201115eefe936 \
  --networking=calico \
  --topology=public

# 5. Déploiement des ressources sur AWS
kops update cluster --name djibril.k8s.local --yes --admin


wq!

sh kops.sh

export KOPS_STATE_STORE=s3://djibril-kops-testbkt143333.k8s.local

kops validate cluster --wait 10m


-- kops get cluster

-- kubectl get nodes/no

-- kubectl get nodes -o wide

Suggestions:
 * list clusters with: kops get cluster
 * edit this cluster with: kops edit cluster djibril.k8s.local
 * edit your node instance group: kops edit ig --name=djibril.k8s.local nodes-us-east-1a
 * edit your control-plane instance group: kops edit ig --name=djibril.k8s.local control-plane-us-east-1a


kops delete cluster --name djibril.k8s.local --yes



