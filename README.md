# 🚀 Kubernetes Services Architecture & Deployment on AWS with kOps

Ce projet présente le déploiement d'une application conteneurisée sur un cluster **Kubernetes provisionné avec kOps sur AWS**.

L'objectif est de comprendre et de mettre en pratique les principaux mécanismes d'exposition des applications Kubernetes :

* **ClusterIP**
* **NodePort**
* **LoadBalancer**

Le projet permet également de pratiquer la création d'un cluster Kubernetes sur AWS, la gestion des ressources avec `kubectl` et l'intégration avec les services AWS.

---

# 📐 Architecture du projet

Le cluster Kubernetes est provisionné sur **AWS EC2** à l'aide de **kOps**.

Le stockage de l'état du cluster est configuré dans **Amazon S3**.

```text
                         AWS Cloud
                             │
                    ┌────────┴────────┐
                    │      kOps       │
                    │ Cluster Manager │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    Kubernetes   │
                    │     Cluster     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
          Master Node     Worker Node 1   Worker Node 2
                             │              │
                             └──────┬───────┘
                                    │
                              Kubernetes
                                Services
                                    │
               ┌────────────────────┼────────────────────┐
               │                    │                    │
               ▼                    ▼                    ▼
           ClusterIP             NodePort           LoadBalancer
               │                    │                    │
               ▼                    ▼                    ▼
          Internal App         Worker Node IP       AWS ELB
```

---

# ☁️ Infrastructure AWS

Le projet utilise principalement :

```text
AWS
│
├── EC2
│   ├── Kubernetes Control Plane
│   ├── Worker Node 1
│   └── Worker Node 2
│
├── S3
│   └── kOps State Store
│
├── Elastic Load Balancing
│   └── LoadBalancer Service
│
└── Route 53
    └── DNS (optionnel)
```

---

# 🔄 Les trois types de Services

## 1. ClusterIP

`ClusterIP` est le type de Service Kubernetes utilisé par défaut.

Il fournit une adresse IP virtuelle accessible **à l'intérieur du cluster**.

```text
Pod A
  │
  ▼
ClusterIP Service
  │
  ▼
Pod B
```

Il est particulièrement adapté aux communications internes entre composants :

```text
Frontend → Backend
Backend → Database
Service A → Service B
```

Exemple :

```yaml
apiVersion: v1
kind: Service

metadata:
  name: web-app-service

spec:
  type: ClusterIP

  selector:
    app: web-app

  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

Vérification :

```bash
kubectl get svc
```

---

# 2. NodePort

`NodePort` expose un Service sur un port de chaque nœud Kubernetes.

Exemple :

```text
http://<NODE-IP>:30080
```

Architecture :

```text
Internet
   │
   │ :30080
   ▼
Worker Node 1
   │
   ▼
NodePort Service
   │
   ▼
Pod
```

Exemple :

```yaml
apiVersion: v1
kind: Service

metadata:
  name: web-app-nodeport

spec:
  type: NodePort

  selector:
    app: web-app

  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
```

Vérification :

```bash
kubectl get svc
```

Puis :

```bash
kubectl get nodes -o wide
```

L'application peut ensuite être testée avec l'adresse IP d'un nœud :

```text
http://<NODE-IP>:30080
```

---

# 3. LoadBalancer

Le type `LoadBalancer` permet d'exposer un Service vers l'extérieur.

Dans l'environnement AWS utilisé par ce projet, Kubernetes peut demander au fournisseur cloud de provisionner un **AWS Load Balancer**.

Architecture :

```text
                 Internet
                     │
                     ▼
              AWS Load Balancer
                     │
             ┌───────┴───────┐
             │               │
             ▼               ▼
         Worker 1         Worker 2
             │               │
             └───────┬───────┘
                     │
                     ▼
               Kubernetes
                  Service
                     │
              ┌──────┴──────┐
              ▼             ▼
             Pod           Pod
```

Exemple :

```yaml
apiVersion: v1
kind: Service

metadata:
  name: web-app-lb-service

spec:
  type: LoadBalancer

  selector:
    app: web-app

  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

Déploiement :

```bash
kubectl apply -f service.yaml
```

Vérification :

```bash
kubectl get svc web-app-lb-service
```

Une adresse externe peut apparaître dans la colonne `EXTERNAL-IP`.

---

# 🆚 Comparaison des Services Kubernetes

| Type         | Accessibilité       | Utilisation principale                 |
| ------------ | ------------------- | -------------------------------------- |
| ClusterIP    | Interne au cluster  | Communication entre services           |
| NodePort     | IP des nœuds + port | Exposition simple / tests              |
| LoadBalancer | Externe             | Exposition publique via cloud provider |

Architecture simplifiée :

```text
ClusterIP
    │
    └── Internal Traffic

NodePort
    │
    └── Node IP + Port

LoadBalancer
    │
    └── External Load Balancer
```

---

# 🚀 Provisionnement du cluster avec kOps

Le script :

```text
kops.sh
```

automatise les principales étapes de création de l'environnement Kubernetes.

Rendre le script exécutable :

```bash
chmod +x kops.sh
```

Puis :

```bash
./kops.sh
```

Selon sa configuration, le script peut notamment préparer :

* AWS CLI
* S3 State Store
* IAM
* SSH keys
* kOps
* Kubernetes Cluster
* EC2 instances

---

# ☸️ Vérification du cluster

Une fois le cluster créé :

```bash
kubectl get nodes
```

Exemple :

```text
NAME                         STATUS   ROLES
ip-10-0-0-10...              Ready    control-plane
ip-10-0-1-20...              Ready    <none>
ip-10-0-2-30...              Ready    <none>
```

Vérifier les Pods :

```bash
kubectl get pods -A
```

Vérifier les Services :

```bash
kubectl get svc -A
```

---

# 📦 Déploiement de l'application

## Deployment

Le Deployment crée et maintient les Pods de l'application.

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: web-app-deployment

spec:
  replicas: 2

  selector:
    matchLabels:
      app: web-app

  template:
    metadata:
      labels:
        app: web-app

    spec:
      containers:

        - name: web-app

          image: nginx:latest

          ports:
            - containerPort: 80
```

Appliquer :

```bash
kubectl apply -f deployment.yaml
```

Vérifier :

```bash
kubectl get deployment
```

Puis :

```bash
kubectl get pods -o wide
```

---

# 🌐 Déploiement du Service LoadBalancer

Créer :

```text
service.yaml
```

Puis :

```bash
kubectl apply -f service.yaml
```

Vérifier :

```bash
kubectl get svc
```

Exemple :

```text
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP
web-app-lb-service LoadBalancer   10.100.10.20    <AWS-LB>
```

---

# 🧪 Tests

## Test ClusterIP

Depuis un Pod du cluster :

```bash
curl http://web-app-service
```

Le nom du Service est résolu grâce au DNS interne de Kubernetes.

---

## Test NodePort

Récupérer les IP des nœuds :

```bash
kubectl get nodes -o wide
```

Puis tester :

```text
http://<NODE-IP>:<NODE-PORT>
```

Exemple :

```text
http://<NODE1-IP>:30080
```

et :

```text
http://<NODE2-IP>:30080
```

---

## Test LoadBalancer

Récupérer l'adresse externe :

```bash
kubectl get svc web-app-lb-service
```

Puis accéder à :

```text
http://<LOAD-BALANCER-DNS>
```

---

# 🔍 Commandes Kubernetes utiles

### Pods

```bash
kubectl get pods
kubectl get pods -o wide
```

### Deployments

```bash
kubectl get deployments
kubectl describe deployment web-app-deployment
```

### Services

```bash
kubectl get svc
kubectl describe svc web-app-lb-service
```

### Nodes

```bash
kubectl get nodes
kubectl get nodes -o wide
```

### Logs

```bash
kubectl logs <POD-NAME>
```

### Description d'une ressource

```bash
kubectl describe pod <POD-NAME>
```

---

# 📁 Structure du projet

```text
Kubernetes-Service-Project/
│
├── kops.sh
│
├── Kubernetes_Services_Guide_kOps_AWS.docx
│
├── deployment.yaml
│
├── service.yaml
│
├── ClusterIP.png
│
├── App-on-Node1.png
│
├── App-on-Node2.png
│
└── App-access-using-LB.png
```

---

# 📸 Proof of Concept

## 1. ClusterIP

La capture présente l'utilisation du Service `ClusterIP` pour la communication interne.

```text
ClusterIP.png
```

---

## 2. NodePort — Worker Node 1

L'application est accessible via l'adresse IP du premier nœud :

```text
App-on-Node1.png
```

---

## 3. NodePort — Worker Node 2

L'application est également accessible via le second nœud :

```text
App-on-Node2.png
```

---

## 4. LoadBalancer — AWS

L'application est exposée via un Load Balancer provisionné sur AWS :

```text
App-access-using-LB.png
```

---

# 🧠 Concepts Kubernetes démontrés

Ce projet permet de pratiquer :

### Kubernetes

* Pods
* Deployments
* Replica management
* Services
* Service discovery
* Kubernetes networking
* Node scheduling

### Services

* ClusterIP
* NodePort
* LoadBalancer

### AWS

* EC2
* S3
* IAM
* Elastic Load Balancing
* Route 53

### kOps

* Kubernetes cluster provisioning
* AWS infrastructure management
* State Store
* Cluster lifecycle management

### Linux

* SSH
* Shell scripting
* AWS CLI
* Kubernetes CLI

---

# 🔐 Sécurité réseau

Les règles réseau AWS doivent être configurées pour permettre uniquement les flux nécessaires.

Exemples :

```text
SSH
22

HTTP
80

HTTPS
443

Kubernetes API
6443

NodePort
30000-32767
```

Les règles exactes dépendent de l'architecture et doivent être limitées aux sources nécessaires plutôt que d'ouvrir largement les ports.

---

# 📈 Architecture actuelle

```text
                     AWS
                      │
              ┌───────┴───────┐
              │      kOps     │
              └───────┬───────┘
                      │
               Kubernetes
                  Cluster
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
       Master      Worker 1    Worker 2
                      │           │
                      └─────┬─────┘
                            │
                       Kubernetes
                         Services
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ▼              ▼              ▼
         ClusterIP       NodePort      LoadBalancer
             │              │              │
             ▼              ▼              ▼
         Internal       Node Access     AWS LB
```

---

# 🔮 Évolution vers une architecture Cloud Native

Ce projet constitue une base pour aller vers une architecture Kubernetes plus complète.

Évolution possible :

```text
                         AWS
                          │
                    Load Balancer
                          │
                          ▼
                      Ingress
                          │
                    Kubernetes
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
       Frontend        Backend          API
          │               │               │
          └───────────────┼───────────────┘
                          │
                    Observability
                     │          │
                 Prometheus   Grafana
                          │
                       Argo CD
                          │
                        GitHub
```

Une prochaine évolution naturelle est l'intégration de :

* **Ingress Nginx**
* **Helm**
* **Argo CD**
* **Prometheus**
* **Grafana**
* **AWS EKS**
* **Terraform**
* **GitOps**

---

# 📤 Publication sur GitHub

Initialiser le repository :

```bash
git init
```

Configurer la branche principale :

```bash
git branch -M main
```

Ajouter les fichiers :

```bash
git add .
```

Créer le commit :

```bash
git commit -m "feat: add Kubernetes kOps services project"
```

Configurer le repository distant :

```bash
git remote add origin https://github.com/boubacardjibrilla/Kubernetes-Service-Project.git
```

Publier :

```bash
git push -u origin main
```

---

# 👨‍💻 Author

**Boubacar Djibrilla**

Software Engineering | AWS | DevOps | Cloud

GitHub: `boubacardjibrilla`
