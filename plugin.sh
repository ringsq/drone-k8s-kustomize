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

# echo "---- Checking if migrations flag set ----"
# PLUGIN_MIGRATION_JOB="${PLUGIN_MIGRATION_JOB:-false}"
# if [ $PLUGIN_MIGRATION_JOB == true ]
#     then
#     PLUGIN_NAMESPACE="${PLUGIN_NAMESPACE:-missing}"
#     if [ PLUGIN_NAMESPACE != "missing" ]
#         then
#         echo "Deleting the k8s Job resource: ${PLUGIN_JOBNAME} in Namespace: ${PLUGIN_NAMESPACE}"
#         kubectl delete -n ${PLUGIN_NAMESPACE} job/${PLUGIN_JOBNAME}
#     else
#         echo "No namespace defined"
#     fi
# else
#     echo "Migration variable not detected. This is a regular deployment"
# fi

cd "${PLUGIN_FOLDERPATH}"

DRONE_SEMVER="${tag:-$DRONE_SEMVER}"

kustomize edit set image "$PLUGIN_IMAGE":$DRONE_SEMVER

[ -n "${PLUGIN_DEBUG:-false}" ] && kustomize build

if [ "$PLUGIN_DRYRUN" = false ]; then
    kustomize build | kubectl apply -f -
else
    kustomize build | kubectl apply -f - --dry-run=server
fi
