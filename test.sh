#!/usr/bin/env bash
set -o errexit

podman run --rm --name test-container -dt -p 2222:22 localhost/gcc-ssh
sleep 5
nc -z localhost 22

podman exec --userns keep-id --user user --rm --volume "$PWD":/home/user:Z --name test-container localhost/gcc-ssh g++ test/main.cpp
podman exec --userns keep-id --user user --rm --volume "$PWD":/home/user:Z --name test-container localhost/gcc-ssh ./a.out
rm a.out

podman stop test-container
