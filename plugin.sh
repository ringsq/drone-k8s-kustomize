#!/bin/sh

set -eu pipefail

"${PLUGIN_DEBUG:-false}" && set -x && printenv

if [ -z "$PLUGIN_KUBECONFIG" ] || [ -z "$PLUGIN_FOLDERPATH" ]; then
    echo "KUBECONFIG and/or FOLDERPATH not supplied"
    exit 1
fi

if [ -n "$PLUGIN_KUBECONFIG" ];then
    [ -d $HOME/.kube ] || mkdir $HOME/.kube
    echo "# Plugin PLUGIN_KUBECONFIG available" >&2
    echo "$PLUGIN_KUBECONFIG" > $HOME/.kube/config
    unset PLUGIN_KUBECONFIG
fi

cd "${PLUGIN_FOLDERPATH}"

${tag:-$DRONE_SEMVER}

kustomize edit set image "$PLUGIN_IMAGE":$tag

[ -n "${PLUGIN_DEBUG:-false}" ] && kustomize build

if [ "$PLUGIN_DRYRUN" = false ]; then
    kustomize build | kubectl apply -f -
fi