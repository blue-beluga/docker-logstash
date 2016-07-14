export GIT_REVISION=$(shell git rev-parse --short HEAD)

REGISTRY = docker.io
REPOSITORY = bluebeluga/logstash

PUSH_REGISTRIES = $(REGISTRY)

export FROM = bluebeluga/alpine

export LOGSTASH_VERSION=2.3.2
export LOGSTASH_SHA256=b3c9d943fa273c8087386736ef6809df9c5959bab870a6ab4723f58d48dd38c1
