#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.mcp-router::help() {
  echo 'Install MCP Router for managing MCP servers

    This step will:
    - Install MCP Router via Homebrew cask
    - Launch the MCP Router application'
}

MCP_ROUTER_APP="/Applications/MCP Router.app"

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.mcp-router::test() {
  # Check if MCP Router was installed manually (not via our cask)
  brew list mcp-router >/dev/null 2>&1
  MCP_ROUTER_INSTALLED=$?

  if [ $MCP_ROUTER_INSTALLED -eq 0 ]; then
    ih::log::debug "mcp-router was installed manually and should be uninstalled"
    return 1
  fi

  # Check if IH MCP Router cask is installed
  brew list ih-mcp-router >/dev/null 2>&1
  IH_MCP_ROUTER_INSTALLED=$?

  if [ $IH_MCP_ROUTER_INSTALLED -ne 0 ]; then
    ih::log::debug "ih-mcp-router cask is not installed"
    return 1
  fi

  # Check if the app exists
  if [ ! -d "$MCP_ROUTER_APP" ]; then
    ih::log::debug "MCP Router.app not found at $MCP_ROUTER_APP"
    return 1
  fi

  return 0
}

function ih::setup::core.mcp-router::deps() {
  echo "core.shell"
}

function ih::setup::core.mcp-router::install() {
  # Check if MCP Router was installed manually (not via our cask)
  brew list mcp-router >/dev/null 2>&1
  MCP_ROUTER_INSTALLED=$?

  if [ $MCP_ROUTER_INSTALLED -eq 0 ]; then
    ih::log::warn "MCP Router was installed manually via 'brew install mcp-router'"
    ih::log::info "Uninstalling manual installation to avoid conflicts"
    brew uninstall mcp-router
  fi

  # Install via our cask
  ih::log::info "Installing MCP Router via Homebrew cask"
  if [ "$(uname -m)" = "arm64" ]; then
    arch -arm64 brew reinstall ih-mcp-router
  else
    brew reinstall ih-mcp-router
  fi

  INSTALL_SUCCESS=$?
  if [ $INSTALL_SUCCESS -ne 0 ]; then
    ih::log::error "Failed to install MCP Router"
    return 1
  fi

  # Launch the app
  ih::log::info "Launching MCP Router application"
  open -a "MCP Router" 2>/dev/null || {
    ih::log::warn "Failed to launch MCP Router automatically"
    ih::log::info "You can launch it manually from Applications"
  }

  ih::log::info "MCP Router has been installed successfully"
  return 0
}
