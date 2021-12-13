#!/bin/sh

## Shell file for executing DB migrations, Deployments with
## automatic versioning of deployment images and tag based deployments of db migrations.
## The primary reason of using this drone plugin is, that we use
## kustomize declarative management for k8s deployment
## the native drone k8s plugin does not support kustomize
## The shell script is capable of deplopying to multiple environments

set -eu pipefail

"${PLUGIN_DEBUG:-false}" && set -x && printenv

echo ">>> Connecting to the AKS cluster <<<"

## IF PLUGIN_KUBECONFIG is not passed try connecting to the cluster with `az login...`
## otherwise add kubeconfig in the $HOME dierctory to connect with aks cluster
PLUGIN_KUBECONFIG=${PLUGIN_KUBECONFIG:-''}
if [ -z "$PLUGIN_KUBECONFIG" ]; then
    ## Auto load cluster config with a couple steps
    ## Step1: Login to az account
    ## Step2: Set the az account with the right subscription id
    ## Step3: Load the cluster config to connect to the cluster if the account is set with the right subscription_id id

    echo ">>> Signing into Azure <<<"
    az login --service-principal -u ${PLUGIN_AZURE_APPID} -p ${PLUGIN_AZURE_PASSWORD} --tenant ${PLUGIN_AZURE_TENANT} || exit 1

    echo ">>> Setting the az account with the right subscription id<<<"
    SUBSCRIPTION_ID=${PLUGIN_SUBSCRIPTION_ID:-"5b1538d5-2945-421f-92c2-9431ef5a283d"}
    az account set --subscription $SUBSCRIPTION_ID

    echo ">>> Adding Cluster $HOME/.kube/config <<<"
    az aks get-credentials --name ${PLUGIN_CLUSTER} --resource-group ${PLUGIN_CLUSTER_RG} || exit 1


else
    echo ">>> Copying kubeconfig to access the k8s cluster <<<"
    [ -d $HOME/.kube ] || mkdir $HOME/.kube
    echo "# Plugin PLUGIN_KUBECONFIG available" >&2
    echo "$PLUGIN_KUBECONFIG" > $HOME/.kube/config
    unset PLUGIN_KUBECONFIG
fi

echo ">>> Checking for the deployment operation to be performed. It could be DB migration job or k8s resource deployment like: deployment or namespace <<<"

## Delete the existing `migration` job if it exists.
## New migrations cannot be deployed without deleting the existing one.
PLUGIN_MIGRATION_JOB="${PLUGIN_MIGRATION_JOB:-false}"
if [ $PLUGIN_MIGRATION_JOB == true ]
    then
    PLUGIN_NAMESPACE="${PLUGIN_NAMESPACE:-default}"
    if [ PLUGIN_NAMESPACE != "default" ]
        then
        echo ">>> Deleting the existing DB migration Job resource: ${PLUGIN_JOBNAME} in Namespace: ${PLUGIN_NAMESPACE}. <<<"
        kubectl delete -n ${PLUGIN_NAMESPACE} job/${PLUGIN_JOBNAME} || true
    else
        echo ">>> Error: No namespace defined for the migration job. <<<"
    fi
fi

## Check if the folderpath for manifests is present
echo ">>> Checking for k8s manifests directory path <<<"
if [ -z "$PLUGIN_FOLDERPATH" ]; then
    echo "KUBECONFIG and/or FOLDERPATH not supplied"
    exit 1
fi

cd "${PLUGIN_FOLDERPATH}"

## Set the DRONE_SEMVER and DRONE_TAG ENV vars in the container if not set in drone
## DRONE_SEMVER ENV var is used for setting the image version of
## `initContainers` and service `containers`
## DRONE_TAG ENV var is used pass the release tag used for
## executing database migrations
echo ">>> Setting DRONE_SEMVER for deployments & DRONE_TAG for migrations <<<"
DRONE_SEMVER=${DRONE_SEMVER:-${DRONE_COMMIT_SHA:0:6}}
DRONE_TAG=${DRONE_TAG:-${DRONE_SEMVER}}
echo ">>> Using DRONE_TAG: ${DRONE_TAG} & DRONE_SEMVER: ${DRONE_SEMVER} <<<"

## Set the release tag on the `image` version for the deployment
echo ">>> Using PLUGIN_MIGRATION_JOB: ${PLUGIN_MIGRATION_JOB}  <<<"
if [ $PLUGIN_MIGRATION_JOB == false ]
    then
    echo ">>> Executing k8s manifests at path provided $PLUGIN_FOLDERPATH.... <<<"

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
fi

## Build the deployment manifests with kustomize declarative management and
## Execute the deployment
echo ">>> Deployment  Manifests: <<<"
[ -n "${PLUGIN_DEBUG:-false}" ] && kustomize build


if [ "$PLUGIN_DRYRUN" = false ]; then
    kustomize build | kubectl apply -f -
else
    kustomize build | kubectl apply -f - --dry-run=server
fi
