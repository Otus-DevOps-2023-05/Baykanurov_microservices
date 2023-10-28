FROM ubuntu:16.04

ENV WORKDIR /app
ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

WORKDIR $WORKDIR

COPY . ./

RUN apt-get update && \
    apt-get install -y ruby-full ruby-dev build-essential && \
    gem install bundler:1.17.2 --no-ri --no-rdoc && \
    bundle install

ENTRYPOINT ["puma"]
