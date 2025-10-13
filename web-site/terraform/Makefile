# ========================================
# MAKEFILE - TERRAFORM COMMANDS
# Academia Dashboard - AWS Free Tier
# ========================================

.PHONY: help init plan apply destroy clean status connect update setup validate fmt check

# Variáveis
TERRAFORM := terraform
SCRIPTS_DIR := scripts

# Cores
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Help
help:
	@echo ""
	@echo "$(BLUE)╔═══════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║   ACADEMIA DASHBOARD - TERRAFORM COMMANDS     ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Setup e Deploy:$(NC)"
	@echo "  make setup     - Setup inicial completo (recomendado)"
	@echo "  make init      - Inicializar Terraform"
	@echo "  make plan      - Ver plano de deployment"
	@echo "  make apply     - Aplicar infraestrutura"
	@echo "  make deploy    - Alias para apply"
	@echo ""
	@echo "$(GREEN)Manutenção:$(NC)"
	@echo "  make status    - Ver status da infraestrutura"
	@echo "  make update    - Atualizar infraestrutura"
	@echo "  make connect   - Conectar via SSH ao servidor"
	@echo "  make output    - Ver todos os outputs"
	@echo ""
	@echo "$(GREEN)Validação:$(NC)"
	@echo "  make validate  - Validar configuração"
	@echo "  make fmt       - Formatar código Terraform"
	@echo "  make check     - Validar + formatar"
	@echo ""
	@echo "$(GREEN)Limpeza:$(NC)"
	@echo "  make destroy   - Destruir infraestrutura (cuidado!)"
	@echo "  make clean     - Limpar arquivos temporários"
	@echo ""
	@echo "$(YELLOW)Exemplos:$(NC)"
	@echo "  make setup     # Primeira vez"
	@echo "  make apply     # Deploy"
	@echo "  make status    # Ver status"
	@echo "  make connect   # SSH"
	@echo ""

# Setup inicial
setup:
	@echo "$(BLUE)Executando setup inicial...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/*.sh
	@bash $(SCRIPTS_DIR)/setup.sh

# Inicializar Terraform
init:
	@echo "$(GREEN)Inicializando Terraform...$(NC)"
	@$(TERRAFORM) init

# Validar configuração
validate:
	@echo "$(GREEN)Validando configuração...$(NC)"
	@$(TERRAFORM) validate

# Formatar código
fmt:
	@echo "$(GREEN)Formatando código...$(NC)"
	@$(TERRAFORM) fmt -recursive

# Validar e formatar
check: fmt validate
	@echo "$(GREEN)✓ Código validado e formatado$(NC)"

# Planejar deployment
plan:
	@echo "$(GREEN)Gerando plano...$(NC)"
	@$(TERRAFORM) plan

# Aplicar infraestrutura
apply:
	@echo "$(GREEN)Aplicando infraestrutura...$(NC)"
	@$(TERRAFORM) apply

# Deploy (alias)
deploy: apply

# Ver outputs
output:
	@$(TERRAFORM) output

# Status
status:
	@bash $(SCRIPTS_DIR)/status.sh

# Conectar SSH
connect:
	@bash $(SCRIPTS_DIR)/connect.sh

# Atualizar
update:
	@bash $(SCRIPTS_DIR)/update.sh

# Destruir infraestrutura
destroy:
	@bash $(SCRIPTS_DIR)/destroy.sh

# Limpar arquivos temporários
clean:
	@echo "$(YELLOW)Limpando arquivos temporários...$(NC)"
	@rm -f tfplan
	@rm -f terraform.tfstate.backup
	@rm -f *.log
	@echo "$(GREEN)✓ Limpeza concluída$(NC)"

# Criar terraform.tfvars se não existir
tfvars:
	@if [ ! -f terraform.tfvars ]; then \
		echo "$(YELLOW)Criando terraform.tfvars...$(NC)"; \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "$(GREEN)✓ Edite terraform.tfvars antes de continuar$(NC)"; \
	else \
		echo "$(GREEN)✓ terraform.tfvars já existe$(NC)"; \
	fi

# Workflow completo para primeira vez
first-run: tfvars init validate
	@echo ""
	@echo "$(BLUE)╔═══════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║  Setup concluído!                             ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Próximos passos:$(NC)"
	@echo "  1. Edite terraform.tfvars com suas configurações"
	@echo "  2. Execute: make plan"
	@echo "  3. Execute: make apply"
	@echo ""

# Graph (visualização)
graph:
	@$(TERRAFORM) graph | dot -Tpng > graph.png
	@echo "$(GREEN)✓ Gráfico salvo em graph.png$(NC)"

# Refresh state
refresh:
	@echo "$(GREEN)Atualizando estado...$(NC)"
	@$(TERRAFORM) refresh

# Show state
show:
	@$(TERRAFORM) show

# List resources
list:
	@$(TERRAFORM) state list

# Taint resource (forçar recriação)
taint:
	@echo "$(YELLOW)Recursos disponíveis:$(NC)"
	@$(TERRAFORM) state list
	@echo ""
	@read -p "Digite o recurso para taint: " resource; \
	$(TERRAFORM) taint $$resource

# Console
console:
	@$(TERRAFORM) console

# Version info
version:
	@echo "Terraform: $$($(TERRAFORM) version)"
	@echo "AWS CLI: $$(aws --version)"

# Quick deploy (sem confirmação)
quick-deploy:
	@$(TERRAFORM) apply -auto-approve

# Quick destroy (sem confirmação - cuidado!)
quick-destroy:
	@echo "$(YELLOW)ATENÇÃO: Destruindo sem confirmação!$(NC)"
	@sleep 3
	@$(TERRAFORM) destroy -auto-approve

