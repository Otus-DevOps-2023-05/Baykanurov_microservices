FROM ruby:2.7.8-alpine

ENV WORKDIR /app
ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

WORKDIR $WORKDIR

COPY . ./

RUN apk update --no-cache && \
    apk add --no-cache build-base && \
    gem install bundler:1.17.2 && \
    bundle install

CMD ["puma"]
