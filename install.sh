#! /bin/sh

if [ $# -ne 1 ] 
then
   echo
   echo "please provide a name for your machine as the first argument to this script"
   echo "EXAMPLE: ./install.sh mybook"
   exit 1
fi 

# Ask for the administrator password upfront
echo
echo "Enter your admin password at the prompt to use throughout the installation..."
echo

sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

set name = $1

# Generate ssh key
ssh-keygen

echo
read -p "Upload the public ssh key just generated [~/.ssh/id_rsa.pub] to github and hit Enter..."
echo

# Install xcode tools
xcode-select --install
# Accept the xcode license
sudo xcodebuild -license

echo
read -p "Install xcode command-line tools. Hit Enter when it's done..."
echo

#get the repo and do all the things!

git clone git@github.com:jshreynolds/localetc.git ~/etc

pushd ~/etc

./brew.sh
./cc.sh
./nodenv.sh
./rbenv.sh
./sdkman.sh
./vim.sh
./macos.sh $name
./ohmyzsh.sh
popd
