FROM caddy:2.6
COPY Caddyfile /etc/caddy/Caddyfile
COPY site /usr/share/caddy
