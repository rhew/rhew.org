# source command not available with default shell
SHELL := /bin/bash

.PHONY: all rhew.org

all: rhew.org

rhew.org:
	docker compose build rhew.org 8ball

rhew.org-local:
	docker compose -f compose.yml -f compose.local.yml build rhew.org 8ball
