# Github Actions Runner Docker image
This folder contains files required to build the Github Actions Runner Docker image.  There is a workflow to build this image and stick it in a container registry.  There are two dockerfiles in this project.<br>
* actions-runner-dind.dockerfile
* actions-runner-dind-rootless.dockerfile

<br>
[Actions Runner Controller (ARC)](https://github.com/actions-runner-controller/actions-runner-controller)<br>
[detailed-docs](https://github.com/actions-runner-controller/actions-runner-controller/blob/master/docs/detailed-docs.md)<br>
[Helm Values](https://github.com/actions-runner-controller/actions-runner-controller/tree/master/charts/actions-runner-controller)<br>


## Deploying with Helm
Add the actions-runner-controller helm repo.<br>
```
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
```
<br>

Download and customize the values.yaml file.  Update the file to include the authentication to Github and the custom Runner image.<br>
```
wget https://github.com/actions-runner-controller/actions-runner-controller/blob/master/charts/actions-runner-controller/values.yaml

authSecret:
  enabled: true
  create: true
  name: "controller-manager"
  annotations: {}
  github_token: "ghp_123456789"

dockerRegistryMirror: ""
image:
  repository: "summerwind/actions-runner-controller"
  actionsRunnerRepositoryAndTag: "ataylorregistry.azurecr.io/actions-runner-dind:v2.298.2-ubuntu-20.04-532db11e"
  dindSidecarRepositoryAndTag: "docker:dind"
  pullPolicy: IfNotPresent
  actionsRunnerImagePullSecrets: [acr-access]
```
<br>


Deploy the Helm chart.<br>
```
helm upgrade --install --namespace actions-runner-system --create-namespace --values ~/values.yml --wait actions-runner-controller actions-runner-controller/actions-runner-controller
```
<br>

Create the Runner Deployment.<br>
```
cat <<EOF | kubectl apply -f -
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: runnerdeploy
spec:
  replicas: 1
  template:
    spec:
      organization: teokyllc
EOF
```