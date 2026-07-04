#!/usr/bin/env bash

LC_ALL=C tr -dc '0-9a-zA-Z' < /dev/urandom | head -c 100
printf '\n'
