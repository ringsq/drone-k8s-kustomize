# Drone kustomize plugin
Kustomize plugin for Drone CI.

# Build Status
[![Build Status](https://drone.m5.run/api/badges/magna5/drone-k8s-kustomize/status.svg)](https://drone.m5.run/magna5/drone-k8s-kustomize)

# Usage
```
steps:
  - name: deploy
    image: gauravgaglani/k8s-kustomize
    settings:
      image: docker.pkg.github.com/magna5/companies_master_service/companies_master_service_image
      kubeconfig:
        from_secret: kubeconfig
      folderpath: deploy/overlays/production
      debug: true
      dryrun: true

```

Above step can be used for deploying an application which has k8s resource definitions in Kustomize format.
Configuration

| Field      |                 Description                  | Optional | Defaults |
| :--------- | :------------------------------------------: | :------: | :------: |
| image      |           an image to be deployed            |    no    |          |
| kubeconfig |   kubeconfig as a secret in drone secrets    |    no    |          |
| folderpath | a path where kustomization.yaml can be found |    no    |          |
| debug      |       print commands and their output        |   yes    |  false   |
| dryrun     |       print kustomization build output       |   yes    |  false   |