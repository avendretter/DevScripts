#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Source: https://github.com/maxfield-allison/dnsweaver
APP="DNSWeaver"
var_tags="${var_tags:-dns;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -x /usr/local/bin/dnsweaver ]]; then
    msg_error "No DNSWeaver installation found"
    exit 1
  fi
  if check_for_gh_release "dnsweaver" "maxfield-allison/dnsweaver"; then
    GO_VERSION="1.26" setup_go
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "dnsweaver" "maxfield-allison/dnsweaver" "tarball"
    msg_info "Building DNSWeaver"
    cd /opt/dnsweaver
    CGO_ENABLED=0 $STD go build -mod=readonly -ldflags="-s -w" -o /usr/local/bin/dnsweaver.new ./cmd/dnsweaver
    chmod 755 /usr/local/bin/dnsweaver.new
    mv -f /usr/local/bin/dnsweaver.new /usr/local/bin/dnsweaver
    msg_ok "Built DNSWeaver"
    if systemctl is-active --quiet dnsweaver; then
      systemctl restart dnsweaver
    fi
    msg_ok "Updated DNSWeaver"
  fi
  exit
}

start
build_container
description
msg_ok "DNSWeaver installed. Configure /etc/dnsweaver/dnsweaver.env before enabling the service."
