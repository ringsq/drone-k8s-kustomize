#!/bin/sh

set -eu pipefail

"${PLUGIN_DEBUG:-false}" && set -x && printenv

echo ">>> Checking for kubeconfig for the k8s cluster config and k8s manifests directory path <<<"

if [ -z "$PLUGIN_KUBECONFIG" ] || [ -z "$PLUGIN_FOLDERPATH" ]; then
    echo "KUBECONFIG and/or FOLDERPATH not supplied"
    exit 1
fi

echo ">>> Setting kubeconfig to access the k8s cluster <<<"
if [ -n "$PLUGIN_KUBECONFIG" ];then
    [ -d $HOME/.kube ] || mkdir $HOME/.kube
    echo "# Plugin PLUGIN_KUBECONFIG available" >&2
    echo "$PLUGIN_KUBECONFIG" > $HOME/.kube/config
    unset PLUGIN_KUBECONFIG
fi

echo ">>> Checking for the deployment operation to be performed. It could be db migration job or k8s resource deployment like: deployment or namespace <<<"
PLUGIN_MIGRATION_JOB="${PLUGIN_MIGRATION_JOB:-false}"
if [ $PLUGIN_MIGRATION_JOB == true ]
    then
    PLUGIN_NAMESPACE="${PLUGIN_NAMESPACE:-default}"
    if [ PLUGIN_NAMESPACE != "default" ]
        then
        echo ">>> Deleting the k8s Job resource: ${PLUGIN_JOBNAME} in Namespace: ${PLUGIN_NAMESPACE}. <<<"
        kubectl delete -n ${PLUGIN_NAMESPACE} job/${PLUGIN_JOBNAME} || true
    else
        echo ">>> No namespace defined <<<"
    fi
else
    echo ">>> Migration variable not detected. This is a regular deployment <<<"
fi

cd "${PLUGIN_FOLDERPATH}"

if [ $PLUGIN_MIGRATION_JOB == false ]
    then
    echo ">>> Executing k8s manifests at path provided $PLUGIN_FOLDERPATH.... <<<"
    DRONE_SEMVER="${tag:-$DRONE_SEMVER}"
    PLUGIN_IMAGE="${PLUGIN_IMAGE:-NULL}"
    if [ $PLUGIN_IMAGE == "NULL" ]; then
        echo ">>> Don't need to set the image path and version for Containers <<<"
    else
        echo ">>> Setting the image path and version for Containers <<<"
        kustomize edit set image "$PLUGIN_IMAGE":$DRONE_SEMVER
    fi

    PLUGIN_INIT_CONTAINERS="${PLUGIN_INIT_CONTAINERS:-NULL}"
    if [ $PLUGIN_INIT_CONTAINERS == "NULL" ]; then
        echo ">>> Don't need to set any initContainers' image paths and versions <<<"
    else
        echo ">>> Setting the initContainers' image paths and versions <<<"
        original_ifs="$IFS"
        IFS="|"
        for image in $PLUGIN_INIT_CONTAINERS
        do
            kustomize edit set image "$image":$DRONE_SEMVER
        done
        IFS="$original_ifs"
    fi
else
    echo ">>> Setting the DRONE_SEMVER <<<"
    DRONE_SEMVER="${DRONE_SEMVER:-latest}"
fi

echo ">>> Deployment  Manifests: <<<"
[ -n "${PLUGIN_DEBUG:-false}" ] && kustomize build


if [ "$PLUGIN_DRYRUN" = false ]; then
    kustomize build | kubectl apply -f -
else
    kustomize build | kubectl apply -f - --dry-run=server
fi
