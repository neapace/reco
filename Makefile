# variable definitions
NAME := reco
DESC := tool to use reconfigure.io
PREFIX ?= usr/local
VERSION := $(shell git describe --tags --always --dirty)
SHA := $(shell git rev-parse HEAD)
GOVERSION := $(shell echo $$(go version) | grep -Eo '\d+.\d+.\d+')
BUILDTIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILDDATE := $(shell date -u +"%B %d, %Y")
BUILDER ?= $(shell echo "`git config user.name` <`git config user.email`>")
TARGET := x86_64-linux
GOOS := linux
PKG_RELEASE ?= 1
PROJECT_URL := "https://github.com/ReconfigueIO/$(NAME)"
GOPACKAGE := "github.com/ReconfigureIO/$(NAME)"
LDFLAGS := -X 'main.version=$(VERSION)' \
           -X 'main.buildTime=$(BUILDTIME)' \
           -X 'main.builder=$(BUILDER)' \
           -X 'main.goversion=$(GOVERSION)' \
           -X 'main.target=$(TARGET)' \
           -X 'github.com/ReconfigureIO/reco.alternativePlatformServer=$(API_SERVER)'
CODEBUILD_NAME := "sample-snap-builder"
GO_EXTENSION :=

.PHONY: fmt dependencies test coverage benchmark packages integration integration-real 

all: dependencies test packages

dist:
	mkdir -p $@

build/${TARGET}:
	mkdir -p $@

# development tasks
fmt:
	go fmt -x $$(go list ./... | grep -v /vendor/)

test: fmt
	go test -v $$(go list ./... | grep -v /vendor/ | grep -v /cmd/)

PACKAGES := $(shell find ./* -type d | grep -v vendor)

coverage:
	@go test -coverprofile=coverage.txt -covermode=atomic
	@go tool cover -html=coverage.txt -o cover.html

benchmark:
	@echo "Running tests..."
	@go test -bench=. $$(go list ./... | grep -v /vendor/ | grep -v /cmd/)

dependencies:
	glide install

integration: dependencies
	@tmpdir=`mktemp -d`; \
	trap 'rm -rf "$$tmpdir"' EXIT; \
	$(MAKE) integration-real TMPDIR=$$tmpdir 

integration-real: 
	go build -o $(TMPDIR)/reco ./cmd/reco
	$(TMPDIR)/reco version
	git clone "https://github.com/ReconfigureIO/examples" $(TMPDIR)/examples
	$(TMPDIR)/reco check --source $(TMPDIR)/examples/addition
	$(TMPDIR)/reco check --source $(TMPDIR)/examples/histogram-array
	$(TMPDIR)/reco check --source $(TMPDIR)/examples/histogram-parallel

CMD_SOURCES := $(shell find cmd -name main.go)
TARGETS := $(patsubst cmd/%/main.go,build/${TARGET}/%,$(CMD_SOURCES))
PKG_TARGETS := $(patsubst cmd/%/main.go,dist/%-${VERSION}-${TARGET}.zip,$(CMD_SOURCES))

build/${TARGET}/%${GO_EXTENSION}: cmd/%/main.go | build/${TARGET}
	GOOS=${GOOS} go build -ldflags "$(LDFLAGS)" -o $@ $<

dist/%-${VERSION}-${TARGET}.zip: build/${TARGET}/%${GO_EXTENSION} | dist
	cd build/${TARGET}/ && zip -r $(CURDIR)/$@ *

packages: $(PKG_TARGETS)

install: $(TARGETS)
	cp ${TARGETS} /go/bin
clean:
	rm -rf ./dist $(TARGETS) ./build

upload:
	aws s3 sync "dist" "s3://reconfigure.io/reco/releases/"

# local development
devbox:
	bash -c "docker images | grep recodev || docker build -t recodev docker"
	docker run -it -v $(GOPATH)/src:/go/src -w /go/src/$(GOPACKAGE) recodev bash
