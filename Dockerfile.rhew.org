FROM caddy:2.8
COPY Caddyfile /etc/caddy/Caddyfile
COPY site /usr/share/caddy
