# DEPRECATED ----- Liman MYS Docker Image

This project is not tested yet but looks like works fine just for now.
It utilizes Liman MYS services in Docker container and persists the data.

Included example Docker compose files for high availability containers.


### How to run?
```
git clone https://github.com/limanmys/webssh
docker build -t limanmys/webssh:latest .

git clone https://github.com/limanmys/docker-version
docker build -t limanmys/core:latest .
DB_PASS=<your_password_here> docker-compose up -d

Wait for container to get in running state and get administrator pw if you have not any;
docker exec -it liman-core limanctl administrator
```

### Kubernetes

We use Helm as deploy tool for kubernetes.

Example deploying steps for minikube

```
git clone https://github.com/limanmys/docker-version
docker build -t limanmys/core:next .
minikube image load limanmys/core:next
```

Edit values.yaml and enter your secret here

```
helm install liman --namespace limanmys --create-namespace ./helm
```

wait and access from browser; for minikube use `minikube tunnel`


#### for upgrading kube image

```
helm upgrade liman --namespace limanmys .
```
