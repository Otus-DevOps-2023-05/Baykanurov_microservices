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
  --generic-ip-address=51.250.84.88 \
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
