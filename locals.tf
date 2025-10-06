locals {
  prefix = join("-", [var.environment, var.location])
  tags = {
    location    = var.location
    environment = var.environment
  }
  sshkey           = base64encode(tls_private_key.cluster.private_key_openssh)
  user_data_server = <<EOF
    #cloud-config
    users:
      - name: ${var.cluster.username}
        groups: sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        lock_passwd: false
        hashed_passwd: ${var.cluster.user_hashed_password}

    runcmd:
      - |
        until ip -4 -o addr show dev $(ip -o link show | awk -F': ' '/enp/{print $2; exit}') | grep -q 'inet '; do
          echo "Waiting for network..."
          sleep 2
        done

        iface=$(ip -4 -o addr show | grep enp | awk '{print $2}')
        nodeip=$(ip -4 -o addr show | grep enp | awk '{print $4}' | cut -d/ -f1)
        
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
          --cluster-init \
          --disable=traefik \
          --disable-cloud-controller \
          --kubelet-arg cloud-provider=external \
          --node-ip=$nodeip \
          --flannel-iface=$iface \
          --tls-san=${var.cluster.k3s_san}" \
          INSTALL_K3S_SKIP_START=false sh -
  EOF
  user_data_agent  = <<EOF
    #cloud-config
    users:
      - name: ${var.cluster.username}
        groups: sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        lock_passwd: false
        hashed_passwd: ${var.cluster.user_hashed_password}
    write_files:
      - content: ${local.sshkey}
        path: /tmp/sshkey
        permissions: '0600'
    runcmd:
      - |
        until ip -4 -o addr show dev $(ip -o link show | awk -F': ' '/enp/{print $2; exit}') | grep -q 'inet '; do
          echo "Waiting for network..."
          sleep 2
        done

        iface=$(ip -4 -o addr show | grep enp | awk '{print $2}')
        nodeip=$(ip -4 -o addr show | grep enp | awk '{print $4}' | cut -d/ -f1)

        cat /tmp/sshkey | base64 -d > /root/.ssh/ed25519
        chmod 600 /root/.ssh/ed25519
        cluster_token=$(ssh -i /root/.ssh/ed25519 -o StrictHostKeyChecking=False root@${var.cluster.primary_server_ip} "cat /var/lib/rancher/k3s/server/agent-token")

        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent \
        --kubelet-arg cloud-provider=external \
        --server=https://${var.cluster.primary_server_ip}:6443 \
        --node-ip=$nodeip \
        --flannel-iface=$iface \
        --token=$cluster_token" INSTALL_K3S_SKIP_START=false sh -
  EOF
}