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
