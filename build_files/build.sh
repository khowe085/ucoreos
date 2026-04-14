#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux tree

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable tuned
systemctl enable tailscaled.service
systemctl enable cockpit
systemctl enable netavark-firewalld-reload

### Podman
systemctl enable podman.socket
systemctl enable podman-clean-transient
systemctl enable podman-restart.service
systemctl enable podman.socket --global

mkdir -p /var/lib/systemd/linger
touch /var/lib/systemd/linger/core

### Podman Compose services
for dir in /usr/share/podman-compose/*/; do
    
    name=$(basename "$dir")
    mkdir -p /etc/containers/compose
    
    ln -sf "/usr/share/podman-compose/${name}" "/etc/containers/compose/${name}"
    
    cat > "/usr/lib/systemd/system/${name}.service" <<EOF
[Unit]
Description=${name} (Podman)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/etc/containers/compose/${name}
ExecStart=/usr/bin/podman-compose up -d
ExecStop=/usr/bin/podman-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable "${name}.service"
done