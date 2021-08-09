#!/usr/bin/env fish

set -l options (fish_opt --short a --long architecture --required-val)
set -a options (fish_opt --short m --long manifest --required-val)
set -a options (fish_opt --short n --long name --required-val)
set -a options (fish_opt --short h --long help)

argparse --max-args 0 $options -- $argv
or exit

if set -q _flag_help
    echo "build.fish [-a|--architecture] [-h|--help] [-m|--manifest] [-n|--name]"
    exit 0
end

set -l architecture (buildah info --format={{".host.arch"}})
if set -q _flag_architecture
    set architecture $_flag_architecture
end
echo "The image will be built for the $architecture architecture."

if set -q _flag_manifest
    set -l manifest $_flag_manifest
    echo "The image will be added to the $manifest manifest."
end

set -l name gcc-ssh
if set -q _flag_name
    set name $_flag_name
end

set -l container (buildah from --arch $architecture quay.io/jwillikers/openssh-server:latest)
set -l mountpoint (buildah mount $container)

podman run --rm --arch $architecture --volume $mountpoint:/mnt:Z registry.fedoraproject.org/fedora:latest \
    bash -c "dnf -y install --installroot /mnt --releasever 34 bash black clang-tools-extra cmake coreutils gdb gcc gcc-c++ git glibc-minimal-langpack ninja-build python3 python3-pip python3-wheel python-unversioned-command tar --nodocs --setopt install_weak_deps=False"
or exit

podman run --rm --arch $architecture --volume $mountpoint:/mnt:Z registry.fedoraproject.org/fedora:latest \
    bash -c "dnf -y clean all --installroot /mnt --releasever 34"
or exit

podman run --rm --arch $architecture --volume $mountpoint:/mnt:Z registry.fedoraproject.org/fedora:latest \
    bash -c "dnf -y install python3-pip python-unversioned-command; python -m pip install --root /mnt conan; python -m pip install --root /mnt cmakelang[yaml]"
or exit

buildah unmount $container
or exit

buildah config --workingdir /home/user $container
or exit

buildah config --label io.containers.autoupdate=registry $container
or exit

buildah config --author jordan@jwillikers.com $container
or exit

buildah config --arch $architecture $container
or exit

if set -q manifest
    buildah commit --rm --manifest $manifest $container $name
    or exit
else
    buildah commit --rm $container $name
    or exit
end
