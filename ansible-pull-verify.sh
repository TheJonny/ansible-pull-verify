#!/bin/bash
set -e -u -x

remote="$1"
playbook="$2"

tag="$(printf "%s" "$remote" | base64 --wrap=0)"
dir="$HOME/.ansible-pull-verify/$tag"

mkdir -p "$dir"
cd "$dir"

cat > gpgwrap  <<END_GPGWRAP
gpg --no-default-keyring --keyring "$dir/keyring.gpg" --trust-model=always "\$@"
END_GPGWRAP
chmod +x gpgwrap

function pull
{
	git -c gpg.program="$dir/gpgwrap" -C working-copy pull --ff-only --verify-signature -- "$@"
	ln -sf working-copy/keyring.gpg keyring.gpg
}

export remote
export -f pull

function yesno {
	echo "$1"
	select yn in "Yes" "No"
	do
		case $yn in
			Yes ) return 0;;
			No ) return 1;;
		esac
	done
}

function initialize
{
	tmp="$(mktemp -d)"
	git clone "$remote" "$tmp"
	cp "$tmp/keyring.gpg" .
	echo "The repository contains these keys to verify commits"
	./gpgwrap --list-keys
	yesno "Do you trust them all?" || return 1
	(
		set -e
		trap "rm -rf working-copy keyring.gpg" EXIT
		git init working-copy
		pull "$tmp"
		trap "" EXIT
	)
	rm -rf "$tmp"
	git -C working-copy remote add origin "$remote"
}

function run_ansible {
	cd working-copy
	exec ansible-playbook -c local "$playbook" -t all -l "localhost,$(hostname),$(hostname -f)"
}

if [ -d working-copy ]
then
	pull "$remote"
else
	initialize
fi
run_ansible
