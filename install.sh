#!/bin/bash -e
#
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
NC=$(tput sgr0)

#Check for Homebrew, install if not installed
echo "${GREEN}Checking brew installed...${NC}"
if test ! "$(which brew)"; then
    echo "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
#
brew update
#
# install virtual box
echo "${GREEN}Installing virtual box...${NC}"
#
brew install --cask virtualbox
#
echo "${GREEN}Installing asdf and plugins...${NC}"
#
# instal asdf
brew install asdf
#
echo -e "\n. $(brew --prefix asdf)/asdf.sh" >> ~/.zshrc
#
#add asdf plugins
#
PLUGINS=('minikube' 'skaffold' 'kubectl' 'kustomize')
#
for plugin in "${PLUGINS[@]}"
do
   asdf plugin-add "$plugin" || true
done

# Install required versions
asdf install
#
# minikube cluster configuration
echo "${GREEN}Setting up minikube cluster...${NC}"
#
minikube start \
      --driver=virtualbox \
      --cni=auto \
      --bootstrapper=kubeadm \
      --kubernetes-version=${K8S_VERSION:-v1.21.2} \
      --memory 6g \
      --cpus 4 \
      --addons ingress \
      --addons ingress-dns \
      --addons metrics-server
#
# fetch cluster ip address
echo "${GREEN}Minikube cluster ip is...${NC}"
IPaddress=$(minikube ip)
echo "$IPaddress"
#
# creating resolver dir in /etc if not already present
echo "${GREEN}creating dir /etc/resolver${NC}"
sudo mkdir -p /etc/resolver
# delete previous kube file if present
sudo rm -fv /etc/resolver/kube
echo "${GREEN}creating kube file in /etc/resolver/${NC}"
echo "${GREEN}contents of file...${NC}"
cat <<EOF | sudo tee /etc/resolver/kube
domain kube
nameserver $IPaddress
search_order 1
timeout 5
EOF
#
# ensure submodules are checked out
git submodule update --init
#
# installing operators to control the provisioning and everyday opertions of stateful applications
#
kubectl apply -f manifests/operators/postgres-operator/configmap.yaml
# 
echo "${GREEN}Installing custom resources and manifests...${NC}"
# 
paths=(
   'operators/postgres-operator/manifests/postgresql.crd.yaml'
   'operators/postgres-operator/manifests/operatorconfiguration.crd.yaml'
   'operators/postgres-operator/manifests/operator-service-account-rbac.yaml'
   'manifests/operators/postgres-operator/postgresql-operator-configuration.yaml'
   'manifests/operators/postgres-operator/min-postgres-deployment.yaml'
   'manifests/operators/postgres-operator/postgres-operator.yaml'
   'operators/redis-operator/example/operator/all-redis-operator-resources.yaml'
)
#
for path in "${paths[@]}"
do
   kubectl create -f "$path" || true
done
# Create Namespaces
kubectl create namespace monitoring
kubectl create namespace argocd
# 
# Install other manifests/apps
echo "${GREEN}Installing kustomizations...${NC}"
echo "${GREEN}Installing Grafana...${NC}"
echo "${GREEN}Installing NFS Provisioner...${NC}"
paths=(
   'grafana'
   'manifests/operators/nfs-provisioner'
)
for path in "${paths[@]}"
do
   kubectl create -k "$path" || true
done
#
# Install Sealed Secrets Operator
echo "${GREEN}installing sealed-secrets operator...${NC}"
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
#
# Install ArgoCD
echo "${GREEN}Installing ArgoCD...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# 
# Prometheus
echo "${GREEN}Add Prometheus Helm repo and install Prometheus${NC}"
#
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# Install Pprometheus
# 
helm install prometheus prometheus-community/prometheus -n monitoring
# 
# 
echo "${GREEN}local cluster is now running ✅${NC}"
echo "${BLUE}Your minikube IP address is '$IPaddress'${NC}"
# 
echo "${YELLOW}'minikube stop' to stop 🛑 ${NC}"
echo "${GREEN}'minikube start' to start$ ✅ ${NC}"
echo "${RED}'minikube delete' to delete ❌ ${NC}"
# 
#
echo "${GREEN}ArgoCD username: admin${NC}"
echo "${GREEN} use this cmd to obtain password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo${NC}"
echo "${GREEN}Grafana username: admin, password: admin${NC}"
#
