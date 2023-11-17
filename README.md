# Baykanurov_microservices
Baykanurov microservices repository

## Docker-2
### Что было сделано:
1. Установка Docker (уже был Docker Desktop, работаю на WSL2)
2. Выполнено знакомство с основными командами Docker
3. Результат команды `docker images` был сохранен в `docker-monolith/docker-1.log`
4. Yandex Cloud CLI был установлен раннее
5. Установка Docker machine v0.16.2
```shell
sudo curl -o /usr/local/bin/docker-machine -L https://github.com/docker/machine/releases/download/v0.16.2/docker-machine-`uname -s`-`uname -m` && \
sudo chmod +x /usr/local/bin/docker-machine
```
6. Создан инстанс
```shell
yc compute instance create \
  --name docker-host \
  --zone ru-central1-a \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2004-lts,size=15 --preemptible --cores=2 \
  --ssh-key ~/.ssh/id_ed25519.pub
```
7. Инициализировано окружение Docker
```shell
docker-machine --debug create \
  --driver generic \
  --generic-ip-address=51.250.92.127 \
  --generic-ssh-user yc-user \
  --generic-ssh-key ~/.ssh/id_ed25519 \
  docker-host
```
8. Активируем окружение Docker
```shell
eval $(docker-machine env docker-host)
```
9. Собраз образ reddit:latest
10. Отправлен образ в Docker hub
```shell
docker push baykanurov/otus-reddit:1.0
```
11. Проверить образ можно командой
```shell
docker pull baykanurov/otus-reddit:1.0
```

## Docker-3
### Что было сделано:
1. Написал Dockerfile и собрал образ для каждого из сервисов приложения:
- **post-py**
- **comment**
- **ui**
```shell
docker build -t baykanurov/post:1.0 ./post-py
docker build -t baykanurov/comment:1.0 ./comment
docker build -t baykanurov/ui:1.0 ./ui
```
2. Запустил и проверил, что всё работает
```shell
docker network create reddit
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:4.4
docker run -d --network=reddit --network-alias=post baykanurov/post:1.0
docker run -d --network=reddit --network-alias=comment baykanurov/comment:1.0
docker run -d --network=reddit -p 9292:9292 baykanurov/ui:1.0
```
3. С какими проблемами столкнулся:
- Образ `mongo:latest` не работал с той кодовой базой которая была в приложении, поэтому я опустил версию до 4.4
- Сервис post-py не собирался и было необходимо добавить `pip install --upgrade pip`
- Для сервисов comment и ui необходимо было добавить `gem install bundler:1.17.2`
### Дополнительное задание
Т.к. я сразу писал на alpine образах, поэтому оптимизировать их не было смысла.

**Вес образов до выполнения дополнительного задания:**
```shell
REPOSITORY           TAG       IMAGE ID       CREATED          SIZE
baykanurov/comment   1.0       4a0cdac51e5b   30 seconds ago   286MB
baykanurov/ui        1.0       1def719ed381   45 seconds ago   289MB
baykanurov/post      1.0       23c8f2aca095   35 minutes ago   121MB
mongo                4.4       e772806c1f73   2 weeks ago      432MB
```
Протестировал сборку с Ubuntu для сервиса ui, результаты:
```shell
REPOSITORY           TAG       IMAGE ID       CREATED              SIZE
baykanurov/ui        2.0       2d7b29a1f364   About a minute ago   487MB
baykanurov/comment   1.0       4a0cdac51e5b   6 minutes ago        286MB
baykanurov/ui        1.0       1def719ed381   6 minutes ago        289MB
baykanurov/post      1.0       23c8f2aca095   40 minutes ago       121MB
mongo                4.4       e772806c1f73   2 weeks ago          432MB
```
Как можно увидеть вес существенно отличается от образа `ui:1.0`.

**src/ui/ubuntu.Dockerfile** - Dockerfile для сервиса ui на основе образа Ubuntu.

Также тестировал запуск образов с альтернативными alias меняя переменные окружения в Dockerfile соответственно.

Дополнительно добавил для MongoDB volume чтобы данные сохранялись.
```shell
docker volume create reddit_db
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:4.4
docker run -d --network=reddit --network-alias=post baykanurov/post:1.0
docker run -d --network=reddit --network-alias=comment baykanurov/comment:1.0
docker run -d --network=reddit -p 9292:9292 baykanurov/ui:1.0
```

## Docker-4
### Что было сделано:
- Изучено как работают сети Docker
- Написан docker-compose для сервисов нашего приложения
- Параметризированы значения в docker compose для:
  - тегов образов для всех сервисов
  - порт публикации сервиса ui
  - username
- Также для всех параметров добавлены default values
- Задано имя для каждого контейнера
- Имя проекта можно задать через name в docker-compose
### Дополнительное задание
Добавил файл docker-compose.override.yml который пробрасывает код сервиса как volume и добавляет возможность запускать puma для руби приложений в дебаг
режиме с двумя воркерами

## Gitlab CI 1
### Что было сделано:
- Развернул Gitlab с помощью omnibus-установки ([docker-compose.yml](gitlab-ci%2Fdocker-compose.yml))
- Зашёл под root в Gitlab
P.S. Чтобы получить пароль от root надо выполнить команду
```shell
sudo docker exec -it gitlab_web_1 grep 'Password:' /etc/gitlab/initial_root_password
```
- Создал группу homework и в ней проект example и запушил свой репозиторий в него
- Поднял раннер
```shell
docker run -d --name gitlab-runner --restart always -v /srv/gitlabrunner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest
```
- Зарегистрировал раннер в группе
```shell
docker exec -it gitlab-runner gitlab-runner register \
 --url http://62.84.127.187/ \
 --non-interactive \
 --locked=false \
 --name DockerRunner \
 --executor docker \
 --docker-image alpine:latest \
 --registration-token GR1348941Q63XnHnAzsVaqBBbxFJ_ \
 --tag-list "linux,xenial,ubuntu,docker" \
 --run-untagged
```
- Провёл тесты с приложением reddit на CI
- Написал стадии для Staging и Production
- Добавил условия для джобы
- Добавил динамические окружения

## Monitoring 1
### Что было сделано:
- Запустил prometheus
```shell
docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus
```
- Упорядочил структуру репозитория для Docker
- Создал Dockerfile и конфигурацию для Prometheus
- Собрал все образы для сервисов приложения
```shell
for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done
```
- Добавил сервис prometheus в docker-compose
- Изучил взаимодействие с метриками Prometheus и протестировал отслеживание состояния сервисов которые подключены к мониторингу
- Добавил Node exporter для сбора информации о работе Docker
хоста
- Запушил образы в Docker Hub
  -  [prometheus](https://hub.docker.com/repository/docker/baykanurov/prometheus/general)
  - [post](https://hub.docker.com/repository/docker/baykanurov/post/general)
  - [comment](https://hub.docker.com/repository/docker/baykanurov/comment/general)
  - [ui](https://hub.docker.com/repository/docker/baykanurov/ui/general)

## Kubernetes-1
### Что было сделано:
1. Развернул ВМ для master ноды
```shell
yc compute instance create \
 --name k8s-master-node \
 --zone ru-central1-a \
 --cores 4 \
 --memory 4GB \
 --preemptible \
 --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2004-lts,size=40,type=network-ssd \
 --ssh-key ~/.ssh/id_ed25519.pub
```
2. Установил на неё docker через docker-machine
```shell
docker-machine create \
 --driver generic \
 --generic-ip-address=62.84.115.226 \
 --generic-ssh-user yc-user \
 --generic-ssh-key ~/.ssh/id_ed25519 \
 k8s-master-node
```
3. Подключился к ВМ
```shell
docker-machine ssh k8s-master-node
```
4. Настроил ВМ для установки master ноды кластера Kubernetes
```shell
sudo su -

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

rm /etc/containerd/config.toml
systemctl restart containerd
```
5. Установил master ноду
```shell
kubeadm init \
--apiserver-cert-extra-sans=62.84.115.226  \
--apiserver-advertise-address=0.0.0.0 \
--control-plane-endpoint=62.84.115.226  \
--pod-network-cidr=10.244.0.0/16
```
**Вывод:**
```shell
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join 62.84.115.226:6443 --token 8ccohc.w08nqkgiblfldqo4 \
        --discovery-token-ca-cert-hash sha256:85832ab657eb313170aaef519a0c9ad3b1fe0768ed7843896f2fab53361dd556 \
        --control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 62.84.115.226:6443 --token 8ccohc.w08nqkgiblfldqo4 \
        --discovery-token-ca-cert-hash sha256:85832ab657eb313170aaef519a0c9ad3b1fe0768ed7843896f2fab53361dd556

```
6. Добавил kubeconfig в домашнюю директорию
```shell
su - yc-user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
7. Присоединяемся к хосту
```shell
kubeadm join 62.84.115.226:6443 --token 8ccohc.w08nqkgiblfldqo4 \
      --discovery-token-ca-cert-hash sha256:85832ab657eb313170aaef519a0c9ad3b1fe0768ed7843896f2fab53361dd556 \
      --control-plane
```
8. Установка надстройки Pod network
```shell
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```
**P.S. Я взял Flannel**
9. Проверим что всё успешно поднялось
```shell
root@k8s-master-node:~# kubectl get pods -A
NAMESPACE      NAME                                      READY   STATUS    RESTARTS   AGE
kube-flannel   kube-flannel-ds-ps26v                     1/1     Running   0          52s
kube-system    coredns-5dd5756b68-76xf5                  1/1     Running   0          5m18s
kube-system    coredns-5dd5756b68-nbznk                  1/1     Running   0          5m18s
kube-system    etcd-k8s-master-node                      1/1     Running   0          5m37s
kube-system    kube-apiserver-k8s-master-node            1/1     Running   0          5m39s
kube-system    kube-controller-manager-k8s-master-node   1/1     Running   0          5m37s
kube-system    kube-proxy-qm8h5                          1/1     Running   0          5m18s
kube-system    kube-scheduler-k8s-master-node            1/1     Running   0          5m37s
```
10. Проделал аналогичные операции для worker ноды, кроме `kubeadm init`
11. Соединяем **master ноду** с **worker нодой** с помощью команды полученной при инициализации master ноды _(от root)_
```shell
root@k8s-worker-node:~# kubeadm join 62.84.115.226:6443 --token guab0t.smmqatepoj14a0t4 --discovery-token-ca-cert-hash sha256:85832ab657eb313170aaef519a0c9ad3b1fe0768ed7843896f2fab53361dd556
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```
12. Проверим что всё успешно
```shell
yc-user@k8s-master-node:~$ kubectl get nodes
NAME              STATUS   ROLES           AGE   VERSION
k8s-master-node   Ready    control-plane   21m   v1.28.2
k8s-worker-node   Ready    <none>          18s   v1.28.2
```
13. Дополнительно: Установка calico
wget https://projectcalico.docs.tigera.io/manifests/calico.yaml
sed -i -r -e 's/^([ ]+)# (- name: CALICO_IPV4POOL_CIDR)$\n/\1\2\n\1  value: "10.244.0.0\/16"/g' calico.yaml
kubectl apply -f calico.yaml


14. Запустим наши deployments
```shell
yc-user@k8s-master-node:~$ kubectl apply -f reddit/
deployment.apps/comment-deployment created
deployment.apps/mongo-deployment created
deployment.apps/post-deployment created
deployment.apps/ui-deployment created
```
15. Проверим, что всё успешно
```shell
yc-user@k8s-master-node:~$ kubectl get pods -A -o custom-columns=NAME:.metadata.name,IP:.status.podIP,NAME:.spec.nodeName
NAME                                       IP              NAME
comment-deployment-57c7d5855d-f5qdd        10.244.24.196   k8s-worker-node
mongo-deployment-6d5bf6767b-gp8dw          10.244.24.195   k8s-worker-node
post-deployment-8657f4bb56-l7q57           10.244.24.194   k8s-worker-node
ui-deployment-549696fdd-dnmmw              10.244.24.193   k8s-worker-node
kube-flannel-ds-6vgqv                      10.128.0.35     k8s-worker-node
kube-flannel-ds-ps26v                      10.128.0.24     k8s-master-node
calico-kube-controllers-7ddc4f45bc-225tx   10.244.24.197   k8s-worker-node
calico-node-86bvx                          10.128.0.24     k8s-master-node
calico-node-hzjm6                          10.128.0.35     k8s-worker-node
coredns-5dd5756b68-76xf5                   10.244.0.3      k8s-master-node
coredns-5dd5756b68-nbznk                   10.244.0.2      k8s-master-node
etcd-k8s-master-node                       10.128.0.24     k8s-master-node
kube-apiserver-k8s-master-node             10.128.0.24     k8s-master-node
kube-controller-manager-k8s-master-node    10.128.0.24     k8s-master-node
kube-proxy-54z7w                           10.128.0.35     k8s-worker-node
kube-proxy-qm8h5                           10.128.0.24     k8s-master-node
kube-scheduler-k8s-master-node             10.128.0.24     k8s-master-node
```
```shell
yc-user@k8s-master-node:~$ kubectl get pods -A
NAMESPACE      NAME                                       READY   STATUS    RESTARTS   AGE
default        comment-deployment-57c7d5855d-f5qdd        1/1     Running   0          11m
default        mongo-deployment-5d754ccc49-2d9mg          1/1     Running   0          59s
default        post-deployment-8657f4bb56-l7q57           1/1     Running   0          11m
default        ui-deployment-549696fdd-dnmmw              1/1     Running   0          11m
kube-flannel   kube-flannel-ds-6vgqv                      1/1     Running   0          17m
kube-flannel   kube-flannel-ds-ps26v                      1/1     Running   0          33m
kube-system    calico-kube-controllers-7ddc4f45bc-225tx   1/1     Running   0          8m14s
kube-system    calico-node-86bvx                          1/1     Running   0          8m14s
kube-system    calico-node-hzjm6                          1/1     Running   0          8m14s
kube-system    coredns-5dd5756b68-76xf5                   1/1     Running   0          38m
kube-system    coredns-5dd5756b68-nbznk                   1/1     Running   0          38m
kube-system    etcd-k8s-master-node                       1/1     Running   0          38m
kube-system    kube-apiserver-k8s-master-node             1/1     Running   0          38m
kube-system    kube-controller-manager-k8s-master-node    1/1     Running   0          38m
kube-system    kube-proxy-54z7w                           1/1     Running   0          17m
kube-system    kube-proxy-qm8h5                           1/1     Running   0          38m
kube-system    kube-scheduler-k8s-master-node             1/1     Running   0          38m
```
16. После успешного выполнения ДЗ удалили docker хосты и ВМ
```shell
docker-machine rm -f $(docker-machine ls -q)
yc compute instance delete k8s-worker-node
yc compute instance delete k8s-master-node
```
