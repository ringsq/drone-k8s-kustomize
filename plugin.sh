#!/bin/sh

set -eu pipefail

PLUGIN_KUBECONFIG="test data" ##remove post testing
PLUGIN_FOLDERPATH="deploy/overlays/production" # remove post testing
PLUGIN_DEBUG=false
PLUGIN_DRYRUN=true # set to true post testing

"${PLUGIN_DEBUG:-false}" && set -x

if [ -z "$PLUGIN_KUBECONFIG" ] || [ -z "$PLUGIN_FOLDERPATH" ]; then
    echo "KUBECONFIG and/or FILEPATH not supplied"
    exit 1
fi

if [ -n "$PLUGIN_KUBECONFIG" ];then
    #[ -d $HOME/.kube ] || mkdir $HOME/.kube  # uncomment post testing
    [ -d $HOME/.test ] || mkdir $HOME/.test # delete post testing
    echo "# Plugin PLUGIN_KUBECONFIG available" >&2
    #echo "$PLUGIN_KUBECONFIG" > $HOME/.kube/config # uncomment post testing
    echo "$PLUGIN_KUBECONFIG" > $HOME/.test/config # delete post testing
    unset PLUGIN_KUBECONFIG
fi

[ -n "${PLUGIN_DEBUG:-false}" ] && kustomize build "${PLUGIN_FOLDERPATH}"

if [ "$PLUGIN_DRYRUN" = false ]; then
    kustomize build | kubectl apply -f -
fi