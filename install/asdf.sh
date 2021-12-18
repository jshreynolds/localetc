#! /bin/sh

#Java has no numerical latest so this must be done manually
asdf plugin-add java
latest=$(asdf latest java "adoptopenjdk-[0-9]")
asdf install java $latest
asdf global java $latest

#nodejs must have it's gpg key imported
asdf plugin add nodejs
bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'


export R_EXTRA_CONFIGURE_OPTIONS='--enable-R-shlib --with-cairo'
export PACKS="clojure elixir golang haskell helm kubectl nodejs poetry python R ruby rust scala terraform"

for pack in $PACKS
do
    asdf plugin-add $pack
    latest=$(asdf latest $pack)  
    asdf install $pack $latest
    asdf global $pack $latest
done

rehash
