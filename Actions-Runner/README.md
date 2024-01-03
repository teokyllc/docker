# Github Actions Runner Docker image
This folder contains files required to build the Github Actions Runner Docker image.  There is a workflow to build this image and stick it in a container registry.  There are two dockerfiles in this project.<br>
* actions-runner-dind.dockerfile
* actions-runner-dind-rootless.dockerfile


[Actions Runner Controller (ARC)](https://github.com/actions-runner-controller/actions-runner-controller)<br>
[detailed-docs](https://github.com/actions-runner-controller/actions-runner-controller/blob/master/docs/detailed-docs.md)<br>
[Helm Values](https://github.com/actions-runner-controller/actions-runner-controller/tree/master/charts/actions-runner-controller)<br>


## Deploying with Helm
Add the actions-runner-controller helm repo.<br>
```
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
```
<br>

Create a secret for Github auth.<br>
```
kubectl create secret generic controller-manager \
    -n actions-runner-system \
    --from-literal=github_token=ghp_fhv17VA4q
```
<br>


Deploy the Helm chart.<br>
```
# Update Helm repos
helm repo update

# View configured values for a chart
helm --namespace actions-runner-system get values actions-runner-controller

# Upgrade adding an additional value
helm upgrade --install --namespace actions-runner-system \
    --create-namespace \
    --reuse-values \
    --set metrics.serviceMonitor.enabled=false \
    actions-runner-controller actions-runner-controller/actions-runner-controller


# https://github.com/actions/actions-runner-controller/releases
helm upgrade --install --namespace actions-runner-system \
    --create-namespace \
    --version 0.23.7 \
    actions-runner-controller actions-runner-controller/actions-runner-controller

```
<br>

Create the Runner Deployment.<br>
```
kubectl apply -f - <<EOF
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: runnerdeploy
  namespace: actions-runner-system
spec:
  replicas: 5
  template:
    spec:
      image: "1234567890.dkr.ecr.us-east-2.amazonaws.com/github-actions-runner:lastest"
      organization: teokyllc
EOF
```
