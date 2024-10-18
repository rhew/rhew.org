# Get source from wayback machine

https://superuser.com/questions/828907/how-to-download-a-website-from-the-archive-org-wayback-machine

```
wget -rc --accept-regex '.*http://rhew.org/.*' http://web.archive.org/web/20180116030939/http://rhew.org/
```

# Build and serve with Caddy (in foreground)

```
docker build -t rhew.org .
docker run -p 80:80 rhew.org
```

http://127.0.0.1:80

# Remote

```
ssh rhew.org
git pull origin main
docker-compose build
```

## Site

Change user and password below.

```
echo 'PODCAST_USER=Bob' > secrets.env
echo "PODCAST_PASSWORD_HASH='$(docker run --rm caddy caddy hash-password --plaintext 'hiccup')'" >> secrets.env

docker-compose up -d rhew.org
```

## Podcast stripper

Add "`OPEN_AI_KEY`" to `podcast-stripper/secrets.env`.

```
docker-compose up -d stripper
```

## Podcast manager

```
docker-compose up -d manager
```
