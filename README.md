# Build and serve locally (in foreground)

## Configure secrets

Change user and password below.

```
echo 'PODCAST_USER=Bob' > podcast-stripper/secrets.env
echo "PODCAST_PASSWORD_HASH='$(docker run --rm caddy caddy hash-password --plaintext 'hiccup')'" >> podcast-stripper/secrets.env
mkdir podcast-stripper
touch stripper-secrets.env

```

## Build and serve

```
make rhew.org-local
docker-compose -f compose.yml -f compose.local.yml up rhew.org 
curl https://localhost
curl https://localhost/projects
```

# Remote

```
ssh rhew.org
```

## Build podcast manager and stripper. See https://github.com/rhew/short-spot

```
pushd short-spot
git pull origin main
make
popd
```

## Build site

```
cd rhew.org
git pull origin main
docker-compose build
```

## Configure secrets

  - See above for podcast directory secrets
  - See https://github.com/rhew/short-spot for openai secrets

## Run
```
docker-compose up -d rhew.org
docker-compose up -d manager
docker-compose up -d stripper
```

# Notes

## Get source from wayback machine

https://superuser.com/questions/828907/how-to-download-a-website-from-the-archive-org-wayback-machine

```
wget -rc --accept-regex '.*http://rhew.org/.*' http://web.archive.org/web/20180116030939/http://rhew.org/
```

