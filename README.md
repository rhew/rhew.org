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

# Run in production

```
docker pull origin main
docker build -t rhew.org .
docker run -d -p 443:443 --restart unless-stopped rhew.org
```

