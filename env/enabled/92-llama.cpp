#! /bin/bash

# llama.cpp environment configuration
# Sets up paths for both hand-compiled and Homebrew installations

# Homebrew installation path
export LLAMA_CPP_BREW_PATH=/opt/homebrew/opt/llama.cpp

# Local hand-compiled installation path
# Defaults to ~/tech/llama.cpp if LLAMA_CPP_LOCAL_PATH is not set
export LLAMA_CPP_LOCAL_PATH="${LLAMA_CPP_LOCAL_PATH:-$HOME/tech/llama.cpp}"

# Add both to PATH, with local (hand-compiled) first, then brew
# This ensures locally compiled versions take precedence
if [ -d "$LLAMA_CPP_LOCAL_PATH/build/bin" ]; then
    export PATH="$LLAMA_CPP_LOCAL_PATH/build/bin:$PATH"
fi

if [ -d "$LLAMA_CPP_BREW_PATH/bin" ]; then
    export PATH="$LLAMA_CPP_BREW_PATH/bin:$PATH"
fi

