# Minikube-Cluster

  This script will enable you to run your application locally in kubernetes so that your environment replicates production.

## 1. Installation

  0.  `Run` the `install.sh` script 
  ``` 
    $ ./install.sh
  ```
  1.  This script will automate the following:
        1. Installing prerequisites.
        2. Setup minikube and addons.
        3. Installing operators.
  
  2.  A description of each stage is detailed below.

  3. **Prerequisites**

      In order to ensure versions are consistant across devices we use a tool called asdf to install and manage application versions for us, similar to `rvm` or `nvm`.

        0. `brew`: Install from [here](https://brew.sh/)
        1. `virtualbox`: can be installed with `brew install --cask virtualbox`
        2. `asdf`: can be installed with `brew install asdf`
            1. `minikube` plugin: `asdf plugin-add minikube`
            2. `skaffold` plugin: `asdf plugin-add skaffold`
            3. `kubectl` plugin: `asdf plugin-add kubectl`

  4. **Setup minikube and addons**

      Minikube is a tool to run a kubernetes cluster on your local machine allowing
      you to simulate networking as it would exist in NP and prod. We also enable 2
      addons for minikube which allow us to use ingress resources, and add a DNS
      resolver to allow using the ingresses locally.