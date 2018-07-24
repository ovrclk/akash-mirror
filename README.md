# akash-mirror

akash-mirror is a helper utility to deploy a static mirror of any website on to the [Akash](http://akash.network) TestNet.

## Usage

You can deploy a static mirror of a website by running `akash-mirror DOMAIN`, for eg: `akash-mirror gregosuri.com`. The mirrored site will be deployed to the Akash TestNet and will use the tokens from your local wallet to pay. By default, it uses `master` key which can be changed by specifying `-k KEY`. 

Example deployment of [akash.network](https://akash.network):

```sh
$ akash-mirror -k gosuri -u https://akash.network akash.network

==> akash-mirror: Deploying akash.network (mirror) to Akash TestNet
    akash-mirror: [mirror: begin] mirroring https://akash.network to /Users/gosuri/code/go/src/github.com/ovrclk/tools/hashed/akashnet/akash.network-mirror
    akash-mirror: [mirror: done] successfully mirrored https://akash.network -> /Users/gosuri/code/go/src/github.com/ovrclk/tools/hashed/akashnet/akash.network-mirror
    akash-mirror: [make-image: begin] building container quay.io/ovrclk/demo-akash.network
==> akash-mirror: [make-image: done] docker image quay.io/ovrclk/demo-akash.network successfully built, using:
    akash-mirror:
    akash-mirror: 	$ docker build . -t quay.io/ovrclk/demo-akash.network
    akash-mirror:
    akash-mirror: [push-image: begin] pushing quay.io/ovrclk/demo-akash.network
==> akash-mirror: [push-image: done] image pushed to remote repository quay.io/ovrclk/demo-akash.network, using:
    akash-mirror:
    akash-mirror: 	$ docker push quay.io/ovrclk/demo-akash.network
    akash-mirror:
    akash-mirror: [check-perm: begin] verify access to image (quay.io/ovrclk/demo-akash.network)
    akash-mirror: [check-perm done]: image (quay.io/ovrclk/demo-akash.network) is ready for deployment
    akash-mirror: [make-conf: begin] creating akash manifest (/Users/gosuri/code/go/src/github.com/ovrclk/tools/hashed/akashnet/akash.yml)
==> akash-mirror: [make-conf: done] successfully creating akash manifest (/Users/gosuri/code/go/src/github.com/ovrclk/tools/hashed/akashnet/akash.yml)
    akash-mirror:
    akash-mirror: 	$ cat > akash.yml <<EOF
---
services:
  web:
    image: quay.io/ovrclk/demo-akash.network
  ...
EOF
    akash-mirror:
    akash-mirror: [deployment-create: begin] deploying to akash testnet (/Users/gosuri/code/go/src/github.com/ovrclk/tools/hashed/akashnet/akash.yml)
==> akash-mirror: [deployment-create: done] deployment successful (2b77bdb00258be1eeb76ea57f1ac6d3c18baa2af43aebed2ce62e5ed706ad0c8), using:
    akash-mirror:
    akash-mirror: 	$ akash deployment create akash.yml -k gosuri -w > .akash
    akash-mirror:
    akash-mirror: [finish begin]
    akash-mirror: [finish kill container]: docker-docker
    akash-mirror: removing cache under /Users/gosuri/code/go/src/github.com/ovrclk/tools/hashed/akashnet

Deployment Successful
=====================

Endpoint:   akash.network.147-75-70-13.aksh.io
Deployment: 2b77bdb00258be1eeb76ea57f1ac6d3c18baa2af43aebed2ce62e5ed706ad0c8
Manifest:   /Users/gosuri/code/go/src/github.com/ovrclk/tools/hashed/akashnet/akash.yml
Image:      quay.io/ovrclk/demo-akash.network
```

### Getting help

Running `akash-mirror --help` will display the below help:

```
akash-mirror 0.0.1

Usage:
  akash-mirror [options] DOMAIN

Options:
  -d DIR --dir=DIR            Stage the files in DIR. [default: .]
  -u URL --url=URL            Use URL if different from DOMAIN.
  -i IMAGE --image=image      Use IMAGE as tag for container. [default: quay.io/ovrclk/demo-DOMAIN]
  --rm=false                  Always keep the files after the run. [default: true]
  -V --verbose                Run in verbose mode.
  -h --help                   Display this help message.
  -v --version                Display the version number.
```

# Installation

## Requirements

- Akash 0.2.2
- HTTrack ~> 3.49-2
- Docker ~> 18.03

## For OSX (Mac)

```sh
$ brew install ovrclk/tap/akash-mirror
```

## From source

```sh
$ git clone git@github.com:ovrclk/akash-mirror.git
$ cd akash-mirror
$ make install
```
