#!/usr/bin/env bash

brew install gettext
brew link --force gettext

brew install kubectl

kubectl version --short --client

brew install kubernetes-helm
brew install minikube

minikube version