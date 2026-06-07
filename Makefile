# source command not available with default shell
SHELL := /bin/bash

HUGO_SOURCE := hugo-src
HUGO_LOCAL_BASEURL := http://localhost:1313/projects/
HUGO_LOCAL_DESTINATION := ../hugo-local-public

.PHONY: all rhew.org rhew.org-local hugo-local hugo-server

all: rhew.org

rhew.org:
	docker compose build rhew.org 8ball

rhew.org-local:
	docker compose -f compose.yml -f compose.local.yml build rhew.org 8ball

hugo-local:
	hugo --source $(HUGO_SOURCE) --destination $(HUGO_LOCAL_DESTINATION) --baseURL $(HUGO_LOCAL_BASEURL)

hugo-server:
	hugo server --source $(HUGO_SOURCE) --baseURL $(HUGO_LOCAL_BASEURL)
