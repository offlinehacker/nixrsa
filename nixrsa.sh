#!/usr/bin/env bash

set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function usage() {
    echo "Usage:"
    echo "    nix-cert -h                                               Display this help message."
    echo "    nix-cert cert -c <configuration> [-o <certs>]             Generate certs."
    echo "    nix-cert ovpn -c <configuration> -n <name> [-o <certs>]   Generate ovpn files."
}

# Parse options to the `nix-cert` command
while getopts ":h" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
   \? )
     echo "Invalid Option: -$OPTARG" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))

subcommand=$1; shift  # Remove 'pip' from the argument list
case "$subcommand" in
  # Parse options to the install sub command
  cert)
    action="cert"

    # Process package options
    while getopts "c:o:" opt; do
      case ${opt} in
        c )
          configuration=$OPTARG
          ;;
        o )
          out=$OPTARG
          ;;
        \? )
          echo "Invalid Option: -$OPTARG" 1>&2
          exit 1
          ;;
        : )
          echo "Invalid Option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done
    shift $((OPTIND -1))
    ;;

  ovpn)
    action="ovpn"

    # Process package options
    while getopts "c:o:n:" opt; do
      case ${opt} in
        c )
          configuration=$OPTARG
          ;;
        o )
          out=$OPTARG
          ;;
        n )
          name=$OPTARG
          ;;
        \? )
          echo "Invalid Option: -$OPTARG" 1>&2
          exit 1
          ;;
        : )
          echo "Invalid Option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done
    shift $((OPTIND -1))
    ;;


esac

if [ -z "$action" ]; then
  usage
  exit 0
fi

if [ -z "$configuration" ]; then
  echo "Missing Option: configuration"
  usage
  exit 1
fi

shift

if [ -z "$out" ]; then out="ca"; fi
case "$action" in
  # Parse options to the install sub command
  cert)
    mkdir -p build $out
    rm -rf build/*
    cp -rf $out/* build/ 2>/dev/null || echo "no output present"
    nix-build $DIR/default.nix -A certs \
        --argstr configuration $(readlink -f $configuration) "$@"
    rm -rf $out/* || true
    cp -r result/* $out
    path=$(readlink -f result) && rm result && nix-store --delete $path
  ;;

  ovpn)
    mkdir -p build $out
    rm -rf build/*
    cp -rf $out/* build/ 2>/dev/null || echo "no output present"

    nix-build $DIR/default.nix -A ovpn \
       --argstr configuration $(readlink -f $configuration) \
       --argstr name $name "$@"
    cp -f result $name.ovpn
    path=$(readlink -f result) && rm result && nix-store --delete $path
  ;;
esac
