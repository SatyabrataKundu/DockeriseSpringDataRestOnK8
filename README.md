################spring-boot-postgres-on-k8s######################

This demo deploys a simple Spring Boot web application that connects to Postgres onto a Kubernetes cluster. 


####################### Prerequisites ###########################

Through MiniKube Kunernetes cluster of computers that are connected to work as a single unit. 
1. 	Install Minikube in Windows 10 has a dependency of VM(virtualbox or hyperv). 
	minikube start --vm-driver=virtualbox
	or
	minikube start --vm-driver=hyperv
2. Install Minikube in VM/EC2/GCE environment

KUBEADM is tool to bootstap the cluster in VM/EC2/GCE 
3.	```
	apt-get update && apt-get install -y apt-transport-https curl
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
	cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
	deb https://apt.kubernetes.io/ kubernetes-xenial main
	EOF
	apt-get update
	apt-get install -y kubelet kubeadm kubectl
	apt-mark hold kubelet kubeadm kubectl

	kubeadm config images pull

	swapoff -a
	
	sysctl net.bridge.bridge-nf-call-iptables=1

	kubeadm init --apiserver-advertise-address=<IP> --pod-network-cidr=10.244.0.0/16


#Example:
	```
	kubeadm join 10.44.206.53:6443 --token 1h3dye.o8vmp4r0detm5nqq \
    	--discovery-token-ca-cert-hash sha256:6cc98e14359e6f9ae4d38b960319e39ef5f2534a2a0e3ccd54226d191620325a

	
#To run kubectl commands  need to export the kube config
	```
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config

	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml

4. Through Docker Desktop cluster can be created through kubernetes installation 
	
#################################################################
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

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
--------------------------------------------------------------------
###DEV-ENVIRONMET-STARTS
###Set-up Enviroment Variable in VS-code
   ```
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk1.8.0_45")
###check Environment variable in VS code
   ```
$ENV:JAVA_HOME
$ENV:PATH
###RUN the maven packing
   ```
./mvnw -DskipTests package
or
maven clean install -DskipTests

###Docker-hub Account login
   ```
docker login

####Docker image Building
   ```
docker build -t satyabratakundu/spring-boot-postgres-on-k8s:v1 .

####Push image in Docker hub account
   ```
docker push satyabratakundu/spring-boot-postgres-on-k8s:v1




###K8-CLUSTER-ENVIRONMET-STARTS
###Access images from Docker-hub required login
   ```
docker login

###Inpest the configuration for Docker-hub login
   ```
vi /root/.docker/config.json

###Pull image in Docker hub account
   ```
docker pull satyabratakundu/spring-boot-postgres-on-k8s:v1


###Check images in Host VM of K8 master
   ```
docker images

####Create required yml files in specific directory
   ```
cd /opt/training-files/

###Prepare Postgres.yml file
   ```
vi postgres.yml

###PASTE the below contents
   ```
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: default
data:
  postgres_user: postgres
  postgres_password: postgres
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-storage
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: postgres
spec:
  template:
    metadata:
      labels:
        app: postgres
    spec:
      volumes:
        - name: postgres-storage
      containers:
        - image: postgres
          name: postgres
          env:
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: postgres-config
                  key: postgres_user
            - name: POSTGRES_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: postgres-config
                  key: postgres_password
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          ports:
            - containerPort: 5432
              name: postgres
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  type: ClusterIP
  ports:
    - port: 5432
  selector:
    app: postgres

###Prepare spring-boot-app.yml file
   ```
vi spring-boot-app.yml

###PASTE the below contents
   ```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: spring-boot-postgres-sample
  namespace: default
spec:
  replicas: 1
  template:
    metadata:
      name: spring-boot-postgres-sample
      labels:
        app: spring-boot-postgres-sample
    spec:
      containers:
      - name: spring-boot-postgres-sample
        env:
          - name: POSTGRES_USER
            valueFrom:
              configMapKeyRef:
                name: postgres-config
                key: postgres_user
          - name: POSTGRES_PASSWORD
            valueFrom:
              configMapKeyRef:
                name: postgres-config
                key: postgres_password
          - name: POSTGRES_HOST
            valueFrom:
              configMapKeyRef:
                name: hostname-config
                key: postgres_host
        image: satyabratakundu/spring-boot-postgres-on-k8s:v1

###Deploy postgres with a persistent volume
   ```
kubectl create -f postgres.yml

###Create a config map with the hostname of Postgres
   ```
kubectl create configmap hostname-config --from-literal=postgres_host=$(kubectl get svc postgres -o jsonpath="{.spec.clusterIP}")

###Deploy the spring-boot-app
   ```
kubectl create -f spring-boot-app.yml

###Create an NodePort to access it from hostip:Nodeport
   ```
kubectl expose deployment spring-boot-postgres-sample --type=NodePort --port=8080

###Get the External IP address of Service
###App accessible at http://<External IP Address>:8080
   ```
kubectl get svc spring-boot-postgres-sample

###Run Kubectl commands to verify
   ```
kubectl get pods
kubectl get pods
kubectl get svc
kubectl get cm
kubectl get deployment

###Scale your application
   ```
kubectl scale deployment spring-boot-postgres-sample --replicas=3

###Run Kubectl commands to verify
   ```
kubectl get pods

###Edit Deploymet to change any config
   ```
kubectl edit deployment spring-boot-postgres-sample

###Clean-UP
   ```
kubectl get deployment
kubectl delete deployment postgres
kubectl delete deployment spring-boot-postgres-sample
kubectl get svc
kubectl delete svc postgres spring-boot-postgres-sample
kubectl get cm
kubectl delete cm postgres-config
kubectl get pvc
kubectl delete  pvc postgres-pv-claim  
