#!/usr/bin/env bash

# DEPLOYMENT UTILITY
# Used to grab default admin credentials post-bootstrap
# Requires active cluster access, does nothing on its own (contains no sensitive data)
echo "GRAFANA"
kubectl get secret -n victoria-metrics victoria-metrics-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d
echo -e "\nARGOCD"
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
exit 0
