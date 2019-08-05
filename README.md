# spring-boot-postgres-on-k8s

This demo deploys a simple Spring Boot web application that connects to Postgres onto a Kubernetes cluster. 


##################################### Prerequisites #################################

################################ VM related setting #################################
./HJCPPortal.sh

curl -sSL https://get.docker.com/ | sh

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2"
}
EOF

The contents of /etc/resolv.conf

nameserver 10.77.224.100
nameserver 10.77.224.101
search persistent.co.in
nameserver 10.44.226.223



cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2",
  "insecure-registry":"ip:port"
}
EOF


####Install Docker-Compose########
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

systemctl daemon-relaod && systemctl restart docker
#####################################################################################

- Kubernetes cluster with kubectl installed and configured to use your cluster
- docker cli installed, you must be signed into your Docker Hub account

1. apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

2. kubeadm config images pull

3. swapoff -a

4. sysctl net.bridge.bridge-nf-call-iptables=1

5. kubeadm init --apiserver-advertise-address=<IP> --pod-network-cidr=10.244.0.0/16

eg:
kubeadm join 10.44.206.53:6443 --token 1h3dye.o8vmp4r0detm5nqq \
    --discovery-token-ca-cert-hash sha256:6cc98e14359e6f9ae4d38b960319e39ef5f2534a2a0e3ccd54226d191620325a
kubeadm join 10.44.206.52:6443 --token gzr7cs.aql8dw5ncl4wa6z9 \
    --discovery-token-ca-cert-hash sha256:30b65e3fa7b222254cac133547046f0c1492c1d6aad6c3e3e98f1c29c959a4f8

6. to run kubectl commands 
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

7. kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml

8. systemctl daemon-reload
systemctl restart kubelet

###################################################################################################

## Deploy Spring Boot app and Postgres on Kubernetes
1. Deploy postgres with a persistent volume claim
   ```
   kubectl create -f specs/postgres.yml
   ```

1. Create a config map with the hostname of Postgres
   ```
   kubectl create configmap hostname-config --from-literal=postgres_host=$(kubectl get svc postgres -o jsonpath="{.spec.clusterIP}")
   ```

1. Build the Spring Boot app

   ```
   ./mvnw -DskipTests package
   ```

1. Build a Docker image and push the image to Docker Hub
   ```
   docker build -t <your Docker Hub account>/spring-boot-postgres-on-k8s:v1 .
   docker push <your Docker Hub account>/spring-boot-postgres-on-k8s:v1
   ```

1. Replace `<your Docker Hub account>` with your account name in `specs/spring-boot-app.yml`, then deploy the app
   ```
   kubectl create -f specs/spring-boot-app.yml
   ```

1. Create an external load balancer for your app
   ```
   kubectl expose deployment spring-boot-postgres-sample --type=LoadBalancer --port=8080
   ```

1. Get the External IP address of Service, then the app will be accessible at `http://<External IP Address>:8080`
   ```
   kubectl get svc spring-boot-postgres-sample
   ```
   > **Note:** It may take a few minutes for the load balancer to be created

1. Scale your application
   ```
   kubectl scale deployment spring-boot-postgres-sample --replicas=3
   ```

## Updating your application
1. Update the image that the containers in your deployment are using
   ```
   kubectl set image deployment/spring-boot-postgres-sample spring-boot-postgres-sample=<your Docker Hub account>/spring-boot-postgres-on-k8s:v2
   ```

## Deleting the Resources
1. Delete the Spring Boot app deployment
   ```
   kubectl delete -f specs/spring-boot-app.yml
   ```

1. Delete the service for the app
   ```
   kubectl delete svc spring-boot-postgres-sample
   ```

1. Delete the hostname config map
   ```
   kubectl delete cm hostname-config
   ```

1. Delete Postgres
   ```
   kubectl delete -f specs/postgres.yml
   ```
