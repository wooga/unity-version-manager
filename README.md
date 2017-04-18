# unity version manager 

A script that just manipulates a link to the current unity version to save a small amount of sanity

[![Build Status](https://travis-ci.org/wooga/unity-version-manager.svg?branch=master)](https://travis-ci.org/wooga/unity-version-manager)[![license](https://img.shields.io/github/license/wooga/unity-version-manager.svg?style=flat-square)]()[![GitHub release](https://img.shields.io/github/release/wooga/unity-version-manager.svg?style=flat-square)]()

## Setup

_install with brew_

```bash
brew tap wooga/tools
brew install wooga/unity-version-manager
```

_install with ruby gems_

```bash
gem install wooga_uvm
```


## Usage

```bash

Commands:
  Usage:
  uvm current
  uvm list
  uvm use <version>
  uvm clear
  uvm detect
  uvm launch [<project-path>] [<platform>]
  uvm version
  uvm (-h | --help)
  uvm --version
  
Options:
--version         print version
-h, --help        show this help message and exit

Commands:
clear             Remove the link so you can install a new version without overwriting
current           Print the current version in use
detect            Find which version of unity was used to generate the project in current dir
help              Describe available commands or one specific command
launch            Launch the current version of unity
list              list unity versions available
use               Use specific version of unity

```


## MIT License

Copyright (C) 2016 Wooga
