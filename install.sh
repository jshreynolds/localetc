#! /bin/bash

if [ $# -ne 1 ] 
then
   echo
   echo "please provide a name for your machine as the first argument to this script"
   echo "EXAMPLE: ./install.sh mybook"
   echo
   exit 1
fi 

# Ask for the administrator password upfront
echo
echo "Enter your admin password at the prompt to use throughout the installation..."
echo

sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Generate ssh key
if [[ ! -a $HOME/.ssh/id_rsa ]]; then
  ssh-keygen
  echo
fi

read -pr "Upload your public ssh key just generated [~/.ssh/id_rsa.pub] to github and hit Enter..."
echo

# Install xcode tools
xcode-select --install

read -pr "wait for xcode tools to install and then hit Enter..."
echo

#get the repo and do all the things!
git clone git@github.com:jshreynolds/localetc.git ~/etc


export The current GCP client configuratio=$1

#Run all installation scripts in install dir
~/etc/bin/source_folder ~/etc/install
