# ============================================
# Variables - Valores configuráveis
# ============================================

variable "project_id" {
  description = "ID do projeto no GCP"
  type        = string
}

variable "region" {
  description = "Região do GCP (ex: us-central1, southamerica-east1)"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona do GCP (ex: us-central1-a)"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Nome da instância VM"
  type        = string
  default     = "n8n-vm"
}

variable "machine_type" {
  description = "Tipo de máquina (e2-micro para free tier, e2-small/medium para produção)"
  type        = string
  default     = "e2-micro"
  
  validation {
    condition     = contains(["e2-micro", "e2-small", "e2-medium", "e2-standard-2", "e2-standard-4"], var.machine_type)
    error_message = "Machine type deve ser um dos tipos válidos: e2-micro, e2-small, e2-medium, e2-standard-2, e2-standard-4"
  }
}

variable "boot_disk_image" {
  description = "Imagem do sistema operacional"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size" {
  description = "Tamanho do disco em GB"
  type        = number
  default     = 30
  
  validation {
    condition     = var.boot_disk_size >= 10 && var.boot_disk_size <= 1000
    error_message = "Disk size deve estar entre 10 e 1000 GB"
  }
}

variable "boot_disk_type" {
  description = "Tipo do disco (pd-standard, pd-balanced, pd-ssd)"
  type        = string
  default     = "pd-balanced"
  
  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd"], var.boot_disk_type)
    error_message = "Disk type deve ser: pd-standard, pd-balanced, ou pd-ssd"
  }
}

variable "environment" {
  description = "Ambiente (development, test, staging, production)"
  type        = string
  default     = "test"
  
  validation {
    condition     = contains(["development", "test", "staging", "production"], var.environment)
    error_message = "Environment deve ser: development, test, staging, ou production"
  }
}

variable "allowed_ip_ranges" {
  description = "Lista de IPs permitidos para acessar a VM (CIDR notation). Use ['0.0.0.0/0'] para qualquer IP (menos seguro)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_user" {
  description = "Usuário SSH padrão (geralmente o mesmo do sistema)"
  type        = string
  default     = "ubuntu"
}

# ============================================
# Custos estimados por machine_type
# ============================================

# e2-micro    (us-central1): FREE TIER - $0/mês
# e2-small    (us-central1): ~$12/mês  (~R$ 60)
# e2-medium   (us-central1): ~$24/mês  (~R$ 120)
# e2-standard-2 (us-central1): ~$48/mês (~R$ 240)

# IMPORTANTE: Free tier só funciona em regiões US (us-west1, us-central1, us-east1)
# IMPORTANTE: southamerica-east1 NÃO tem free tier e é ~20% mais caro
