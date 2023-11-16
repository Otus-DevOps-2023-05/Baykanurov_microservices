FROM ruby:2.7.8-alpine

ENV WORKDIR /app
ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

WORKDIR $WORKDIR

COPY . ./

RUN apk update --no-cache && \
    apk add --no-cache build-base && \
    gem install bundler:1.17.2 && \
    bundle install

ENTRYPOINT ["puma"]
