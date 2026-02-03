# ============================================
# Outputs - Informações úteis após criar
# ============================================

output "vm_name" {
  description = "Nome da VM criada"
  value       = google_compute_instance.n8n_vm.name
}

output "vm_zone" {
  description = "Zona onde a VM foi criada"
  value       = google_compute_instance.n8n_vm.zone
}

output "vm_machine_type" {
  description = "Tipo de máquina da VM"
  value       = google_compute_instance.n8n_vm.machine_type
}

output "vm_external_ip" {
  description = "IP externo da VM"
  value       = google_compute_instance.n8n_vm.network_interface[0].access_config[0].nat_ip
}

output "vm_internal_ip" {
  description = "IP interno da VM"
  value       = google_compute_instance.n8n_vm.network_interface[0].network_ip
}

output "n8n_url" {
  description = "URL para acessar o n8n"
  value       = "http://${google_compute_instance.n8n_vm.network_interface[0].access_config[0].nat_ip}:5678"
}

output "ssh_command" {
  description = "Comando para conectar via SSH"
  value       = "gcloud compute ssh ${google_compute_instance.n8n_vm.name} --zone=${google_compute_instance.n8n_vm.zone}"
}

output "estimated_monthly_cost" {
  description = "Custo estimado mensal (USD)"
  value = var.machine_type == "e2-micro" && var.region == "us-central1" ? "FREE (within free tier limits)" : (
    var.machine_type == "e2-small" ? "~$12 USD/month" : (
      var.machine_type == "e2-medium" ? "~$24 USD/month" : "Check GCP pricing calculator"
    )
  )
}

output "quickstart_commands" {
  description = "Comandos rápidos para começar"
  value = <<-EOT
  
  === PRÓXIMOS PASSOS ===
  
  1. Conectar na VM:
     ${format("gcloud compute ssh %s --zone=%s", google_compute_instance.n8n_vm.name, google_compute_instance.n8n_vm.zone)}
  
  2. Aguardar instalação do Docker (~2-3 minutos):
     sudo journalctl -u google-startup-scripts.service -f
  
  3. Copiar arquivos do projeto:
     gcloud compute scp --recurse ../docker-compose.yml ../.env ../Dockerfile ../entrypoint.sh ../init-data.sh ../package.json ../pnpm-lock.yaml ../scripts ../sql ../workflows ${google_compute_instance.n8n_vm.name}:~/docker-n8n --zone=${google_compute_instance.n8n_vm.zone}
  
  4. Na VM, subir os containers:
     cd ~/docker-n8n
     docker compose up -d
  
  5. Acessar n8n no navegador:
     http://${google_compute_instance.n8n_vm.network_interface[0].access_config[0].nat_ip}:5678
  
  === GERENCIAR VM ===
  
  Parar (economizar custos):
     gcloud compute instances stop ${google_compute_instance.n8n_vm.name} --zone=${google_compute_instance.n8n_vm.zone}
  
  Iniciar novamente:
     gcloud compute instances start ${google_compute_instance.n8n_vm.name} --zone=${google_compute_instance.n8n_vm.zone}
  
  Deletar (quando não precisar mais):
     terraform destroy
  
  EOT
}
