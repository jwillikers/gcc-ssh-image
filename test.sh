#!/usr/bin/env bash
set -o errexit

podman run --userns keep-id --volume "$PWD":/home/user:Z --rm --name test-container -dt -p 2222:22 localhost/gcc-ssh
sleep 5
nc -z localhost 22

podman exec --user user --rm test-container g++ test/main.cpp
podman exec --user user --rm test-container ./a.out
rm a.out

podman stop test-container
