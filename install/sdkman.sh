#! /bin/zsh

#Install java and supporting tools via sdkman
curl -s "https://get.sdkman.io" | bash
. ~/etc/env/enabled/99-sdkman
sdk install java
sdk install scala
sdk install ant
sdk install maven
sdk install gradle
sdk install leiningen


