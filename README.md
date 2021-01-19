# .dotfiles

[![Build Status](https://travis-ci.com/msdundar/dotfiles.svg?branch=master)](https://travis-ci.com/msdundar/dotfiles)

A set of installation and configuration scripts for OSx.

## Install

`setup.sh` will install defined packages and configuration. `setup.sh` aims to be idempotent. You can run this script many times on the same computer without any side-effects.

```bash
$ ./setup.sh
```

## Tests

Scripts are tested with [shellcheck](https://github.com/koalaman/shellcheck):

```bash
$ ./test
```
