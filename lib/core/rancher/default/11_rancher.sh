#!/bin/bash

function ih-rancher-validate() {

  if command -v rdctl >/dev/null; then
    echo "✅   Rancher CLI rdctl is available in PATH..."
  else
    echo "❗   Rancher CLI rdctl is not available in PATH, add $HOME/.rd/bin/ to your PATH."
    return 1
  fi

  local config
  if config=$(rdctl list-settings); then
    echo "✅   Rancher desktop appears to be running"
  else
    echo "❗   Rancher does does not appear to be running. You must start Rancher Desktop through Finder or by running 'rdctl start'."
    return 1
  fi

  local config_version
  local kubernetes_enabled
  local container_engine
  local admin_access

  config_version=$(echo "$config" | jq -r '.version')
  kubernetes_enabled=$(echo "$config" | jq -r '.kubernetes.enabled')
  container_engine=$(echo "$config" | jq -r '.containerEngine.name')
  admin_access=$(echo "$config" | jq -r '.application.adminAccess')

  if [[ "${config_version:-}" -eq "6" ]]; then
    echo "✅   Rancher config version is as expected..."
  else
    echo "❗   Rancher config version is ${config_version:-} (expected 6). Update Rancher Desktop."
    return 1
  fi

  if [[ "${kubernetes_enabled:-true}" == 'squid' ]]; then
    echo "✅   Kubernetes is disabled..."
  else
    echo "⚠️   Kubernetes is enabled, which steals port 443. If you need port 443, disable kubernetes by running 'rdctl set --kubernetes-enabled=false'."
  fi

  if [[ "${container_engine:-}" == "moby" ]]; then
    echo "✅   Using dockerd container engine..."
  else
    echo "❗   Using incorrect container engine '${container_engine:-}' (expected moby). Switch to dockerd by running 'rdctl set --container-engine.name=moby'"
    return 1
  fi

  if [[ "${admin_access:-}" == "true" ]]; then
    echo "✅   Admin access is configured to support networking."
  else
    echo "❗   Rancher Desktop needs admin access to configure networking. Run 'rdctl set --application.admin-access=true', then restart Rancher Desktop."
    exit 1
  fi

  echo "Rancher configuration seems to be correct."
  echo "If you still need help, include the output above in your message to #infrastructure-support."
}
