#!/bin/bash
set -euo pipefail
apt-get update
apt-get install --assume-yes --no-install-recommends \
    build-essential \
    vim \
    bash-completion \
    git \
    httpie \
    jq \
    zip \
    unzip \
    wget \
    mosh
