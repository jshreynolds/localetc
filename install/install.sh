#! /bin/sh

if [ $# -ne 1 ] 
then
   echo "please provide a name for your machine"
fi 

sudo -v

set name = $1

./bootstrap.sh
./brew.sh
./cc.sh
./ohmyzsh.sh
./nodenv.sh
./rbenv.sh
./sdkman.sh
./vim.sh
./macos.sh $name
