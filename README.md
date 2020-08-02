GitOps
------

Source of truth for Kubernetes cluster state.

Using 

  * Kustomize
  * eksctl (AWS CLI for EKS)

## Quickstart

  * Navigate to `kustomize.yaml` in `./dev` or `./prod`
  * Make changes to appropriate image tags to reflect commit sha (generated from `make docker-build-and-push` in the application's repository)
  * `make deploy ENV=<dev|prod>`
