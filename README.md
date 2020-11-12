# Drone kustomize plugin
Kustomize plugin for Drone CI.

# Build Status
[![Build Status](https://drone.m5.run/api/badges/magna5/drone-k8s-kustomize/status.svg)](https://drone.m5.run/magna5/drone-k8s-kustomize)

# Usage
The most basic usage requires `kubeconfig` (preferably as secret) with
kubeconfig content and `folderpath` pointing to a path inside a repo where
`kustomization.yaml` file is placed. For debugging purpose one can set `debug` and `dryrun ` flags which default to `false`

```
steps:
  - name: deploy-stage
    image: cloudowski/drone-kustomize
    settings:
      kubeconfig:
        from_secret: kubeconfig
      folderpath: deploy/overlays/production
      debug: true
      dryrun: true

```
