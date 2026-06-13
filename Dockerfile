

FROM alpine:3.23 AS hugo-builder
RUN apk add --update hugo python3 py3-pip

WORKDIR /var/hugo

COPY hugo-src/config.toml .
COPY hugo-src/archetypes ./archetypes
COPY hugo-src/content ./content
COPY hugo-src/layouts ./layouts
COPY hugo-src/static ./static

RUN mkdir -p themes/rhew-org-theme
RUN apk add --update git
RUN git clone https://github.com/panr/hugo-theme-terminal.git themes/rhew-org-theme
RUN git clone https://github.com/martignoni/hugo-video.git themes/hugo-video
ARG HUGO_BASEURL=https://rhew.org/projects/
ARG PAGEFIND_VERSION_SPEC=>=1.5,<1.6
RUN python3 -m venv /opt/pagefind \
    && /opt/pagefind/bin/pip install --no-cache-dir "pagefind[bin]${PAGEFIND_VERSION_SPEC}"
RUN hugo --minify --baseURL "${HUGO_BASEURL}"
RUN /opt/pagefind/bin/python -m pagefind --site public --exclude-selectors "header, footer"


FROM caddy:2.10
COPY Caddyfile /etc/caddy/Caddyfile
COPY site /usr/share/caddy
COPY --from=hugo-builder /var/hugo/public /usr/share/caddy/projects
