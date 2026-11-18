#!/usr/bin/env bash
# Source: https://github.com/maxfield-allison/dnsweaver
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

GO_VERSION="1.26" setup_go
fetch_and_deploy_gh_release "dnsweaver" "maxfield-allison/dnsweaver" "tarball"

msg_info "Building DNSWeaver"
cd /opt/dnsweaver
CGO_ENABLED=0 $STD go build -mod=readonly -ldflags="-s -w" -o /usr/local/bin/dnsweaver ./cmd/dnsweaver
msg_ok "Built DNSWeaver"

msg_info "Creating DNSWeaver service"
install -d -m 700 /etc/dnsweaver
cat >/etc/dnsweaver/dnsweaver.env <<'EOF'
DNSWEAVER_PLATFORM=none
DNSWEAVER_DRY_RUN=true
DNSWEAVER_SOURCES=proxmox
EOF
chmod 600 /etc/dnsweaver/dnsweaver.env
cat >/etc/systemd/system/dnsweaver.service <<'EOF'
[Unit]
Description=DNSWeaver DNS synchronization
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/dnsweaver/dnsweaver.env
ExecStart=/usr/local/bin/dnsweaver
Restart=on-failure
RestartSec=10
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
msg_ok "Created DNSWeaver service (not enabled until configured)"

motd_ssh
customize
cleanup_lxc
