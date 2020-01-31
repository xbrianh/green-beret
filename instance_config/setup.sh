#!/bin/bash
set -euo pipefail

sudo apt-get update
sudo apt-get upgrade --assume-yes

# avoid interactive installation for tzdata. This is a pain.
sudo ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y tzdata
sudo dpkg-reconfigure --frontend noninteractive tzdata

sudo apt-get install --assume-yes --no-install-recommends \
    build-essential \
    vim \
    vim-python-jedi \
    vim-addon-manager \
    bash-completion \
    git \
    httpie \
    jq \
    zip \
    unzip \
    wget \
    docker.io \
    locales \
    mosh

# configure docker
sudo systemctl start docker
sudo systemctl enable docker
sudo chmod 666 /var/run/docker.sock

# configure git
git clone https://github.com/awslabs/git-secrets.git
(cd git-secrets && sudo make install)
git secrets --register-aws --global
git secrets --install ~/.git-templates/git-secrets
git secrets --add --global 'BEGINPRIVATEKEY.*ENDPRIVATEKEY' # google private key pattern
git config --global init.templateDir ~/.git-templates/git-secrets
git config --global credential.helper store
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
mv git-completion.bash ~/.git-completion.bash
echo "source ~/.git-completion.bash" >> ~/.bashrc

# configure vim
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim-addons install python-jedi
vim +PluginInstall +qall 2>&1 > /dev/null

# configure locale for mosh
sudo locale-gen "en_US.UTF-8"
