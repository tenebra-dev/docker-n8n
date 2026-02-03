# ============================================
# Terraform Configuration for n8n on GCP
# ============================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Provider Configuration
# ============================================

provider "google" {
  project = var.project_id
  region  = var.region
}

# ============================================
# Compute Instance (VM)
# ============================================

resource "google_compute_instance" "n8n_vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  # Tags para aplicar regras de firewall
  tags = ["http-server", "https-server", "n8n-server"]

  # Boot disk configuration
  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  # Network configuration
  network_interface {
    network = "default"
    
    # External IP (ephemeral)
    access_config {
      # Deixe vazio para IP efêmero
      # Para IP estático, descomente a linha abaixo e crie o recurso google_compute_address
      # nat_ip = google_compute_address.n8n_static_ip.address
    }
  }

  # Startup script - Instala Docker e Docker Compose
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    echo "=== Atualizando sistema ==="
    apt-get update
    apt-get upgrade -y
    
    echo "=== Instalando Docker ==="
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    echo "=== Instalando Docker Compose ==="
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    
    echo "=== Configurando Docker ==="
    systemctl enable docker
    systemctl start docker
    
    # Adicionar usuário padrão ao grupo docker
    usermod -aG docker ${var.ssh_user}
    
    echo "=== Criando diretório para aplicação ==="
    mkdir -p /home/${var.ssh_user}/docker-n8n
    chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/docker-n8n
    
    echo "=== Instalação concluída ==="
    docker --version
    docker compose version
  EOF

  # Permitir que a VM seja parada (economia de custos)
  allow_stopping_for_update = true

  # Metadata
  metadata = {
    enable-oslogin = "FALSE"
  }

  # Labels para organização
  labels = {
    environment = var.environment
    app         = "n8n"
    managed_by  = "terraform"
  }
}

# ============================================
# Firewall Rules
# ============================================

# Regra para n8n (porta 5678)
resource "google_compute_firewall" "allow_n8n" {
  name    = "allow-n8n-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5678"]
  }

  source_ranges = var.allowed_ip_ranges
  target_tags   = ["n8n-server"]
  
  description = "Allow n8n web interface access"
}

# Regra para SSH (se precisar restringir)
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ip_ranges
  target_tags   = ["n8n-server"]
  
  description = "Allow SSH access to n8n VM"
}

# ============================================
# Static IP (Opcional - Descomente se precisar)
# ============================================

# resource "google_compute_address" "n8n_static_ip" {
#   name   = "n8n-static-ip-${var.environment}"
#   region = var.region
# }
