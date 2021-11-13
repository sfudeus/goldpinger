name ?= goldpinger
version ?= v3.3.0
bin ?= goldpinger
pkg ?= "github.com/bloomberg/goldpinger"
tag = $(name):$(version)
goos ?= ${GOOS}
namespace ?= "bloomberg/"
files = $(shell find . -iname "*.go")
arch ?= amd64


bin/$(bin): $(files)
	GOOS=${goos} PKG=${pkg} ARCH=${arch} VERSION=${version} BIN=${bin} ./build/build.sh

clean:
	rm -rf ./vendor
	rm -f ./bin/$(bin)

vendor:
	rm -rf ./vendor
	go mod vendor

# Download the latest swagger releases from: https://github.com/go-swagger/go-swagger/releases/
swagger:
	swagger generate server -t pkg -f ./swagger.yml --exclude-main -A goldpinger && \
	swagger generate client -t pkg -f ./swagger.yml -A goldpinger

build-multistage:
	docker build -t $(tag) -f ./Dockerfile .

build-multiarch:
	docker buildx build --platform linux/amd64 --platform linux/arm/v7 --platform linux/arm64 -t $(tag) -f ./Dockerfile .

push-multiarch:
	docker buildx build --platform linux/amd64 --platform linux/arm/v7 --platform linux/arm64 -t $(namespace)$(tag) -f ./Dockerfile --push .

build: GOOS=linux
build: bin/$(bin)
	docker build -t $(tag) -f ./build/Dockerfile-simple .

tag:
	docker tag $(tag) $(namespace)$(tag)

push:
	docker push $(namespace)$(tag)

run:
	go run ./cmd/goldpinger/main.go

version:
	@echo $(tag)


vendor-build:
	docker build -t $(tag)-vendor --build-arg TAG=$(tag) -f ./build/Dockerfile-vendor .

vendor-tag:
	docker tag $(tag)-vendor $(namespace)$(tag)-vendor

vendor-push:
	docker push $(namespace)$(tag)-vendor


.PHONY: clean vendor swagger build build-multistage build-multiarch push-multiarch vendor-build vendor-tag vendor-push tag push run version
