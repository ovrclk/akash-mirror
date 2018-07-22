# akash-mirror

akash-mirror is a helper utility to deploy a static mirror of any website on to the [Akash](http://akash.network) TestNet.

## Usage

You can deploy a static mirror of a website by running `akash-mirror DOMAIN`, for eg: `akash-mirror gregosuri.com`. The mirrored site will be deployed to the AkashTestNet and will use the tokens from your local wallet to pay. By default, it uses `master` key which can be changed by specifying `-k KEY`.

`akash-mirror -h` will display the below help:

```sh
akash-mirror 0.0.1

Usage:
  akash-mirror [options] DOMAIN

Options:
  -d DIR --dir=DIR            Stage the files in DIR. [default: /Users/gosuri/code/go/src/github.com/ovrclk/tools/akashify]
  -u URL --url=URL            Use URL if different from DOMAIN.
  -k KEY --url=KEY            Use KEY for deploying. [default: help]
  --rm=false                  Always keep the files after the run. [default: true]
  -V --verbose                Run in verbose mode.
  -h --help                   Display this help message.
  -v --version                Display the version number.
```

# Requirements

- HTTrack ~> 3.49-2
- Docker ~> 18.03

# Installation

## From source

```
$ git clone git@github.com:ovrclk/akash-mirror.git
$ cd test-runner
$ make install
``
