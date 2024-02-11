#! /bin/bash

#Java has no numerical latest so this must be done manually
asdf plugin-add java
latest=$(asdf latest java "adoptopenjdk-[0-9]")
asdf install java "$latest"
asdf global java "$latest"

export R_EXTRA_CONFIGURE_OPTIONS='--enable-R-shlib --with-cairo'
export PACKS="clojure deno elixir golang haskell helm kubectl nodejs poetry python ruby rust scala skaffold terraform"

for pack in $PACKS
do
    asdf plugin add "$pack"
    latest=$(asdf latest "$pack")  
    asdf install "$pack" "$latest"
    asdf global "$pack" "$latest"
done
