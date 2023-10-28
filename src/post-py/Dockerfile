FROM python:3.6.0-alpine

ENV WORKDIR /app
ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

WORKDIR $WORKDIR
COPY . ./

RUN apk --no-cache --update add build-base && \
    pip install --upgrade pip && \
    pip install -r requirements.txt && \
    apk del build-base

ENTRYPOINT ["python3", "post_app.py"]
