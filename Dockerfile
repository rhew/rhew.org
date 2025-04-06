

FROM alpine:latest as hugo-builder
RUN apk add --update hugo

WORKDIR /var/hugo

COPY hugo-src/config.toml .
COPY hugo-src/archetypes ./archetypes
COPY hugo-src/content ./content

RUN mkdir -p themes/rhew-org-theme
RUN apk add --update git
RUN git clone https://github.com/panr/hugo-theme-terminal.git themes/rhew-org-theme
RUN git clone https://github.com/martignoni/hugo-video.git themes/hugo-video
RUN hugo --minify


FROM caddy:2.8
COPY Caddyfile /etc/caddy/Caddyfile
COPY site /usr/share/caddy
COPY --from=hugo-builder /var/hugo/public /usr/share/caddy/projects
