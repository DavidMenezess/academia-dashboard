// Sistema de Upload de Arquivos Excel/CSV para Academia Dashboard
class AcademiaUploadHandler {
    constructor() {
        this.apiUrl = 'http://localhost:3000/api';
        this.uploadForm = null;
        this.progressBar = null;
        this.statusMessage = null;
        this.init();
    }

    init() {
        this.createUploadInterface();
        this.bindEvents();
    }

    createUploadInterface() {
        // Criar interface de upload se não existir
        if (!document.getElementById('upload-section')) {
            const uploadSection = document.createElement('div');
            uploadSection.id = 'upload-section';
            uploadSection.innerHTML = `
                <div class="upload-container" style="
                    background: white;
                    border-radius: 12px;
                    padding: 24px;
                    margin: 20px 0;
                    box-shadow: var(--shadow);
                    border: 2px dashed var(--border-color);
                    transition: var(--transition);
                ">
                    <div class="upload-header" style="text-align: center; margin-bottom: 20px;">
                        <h3 style="color: var(--primary-color); margin-bottom: 8px;">
                            📊 Atualizar Dados da Academia
                        </h3>
                        <p style="color: var(--text-secondary); font-size: 14px;">
                            Faça upload de arquivos Excel (.xlsx, .xls) ou CSV (.csv) para atualizar os dados automaticamente
                        </p>
                    </div>
                    
                    <form id="upload-form" enctype="multipart/form-data" style="text-align: center;">
                        <div class="file-input-container" style="margin-bottom: 20px;">
                            <input type="file" id="file-input" accept=".xlsx,.xls,.csv" 
                                   style="display: none;">
                            <label for="file-input" class="file-input-label" style="
                                display: inline-block;
                                padding: 12px 24px;
                                background: var(--primary-color);
                                color: white;
                                border-radius: 8px;
                                cursor: pointer;
                                transition: var(--transition);
                                font-weight: 500;
                            ">
                                📁 Escolher Arquivo
                            </label>
                            <span id="file-name" style="
                                display: block;
                                margin-top: 8px;
                                color: var(--text-secondary);
                                font-size: 14px;
                            "></span>
                        </div>
                        
                        <div class="progress-container" id="progress-container" style="display: none;">
                            <div class="progress-bar" style="
                                width: 100%;
                                height: 8px;
                                background: var(--border-color);
                                border-radius: 4px;
                                overflow: hidden;
                                margin-bottom: 10px;
                            ">
                                <div id="progress-bar" style="
                                    height: 100%;
                                    background: var(--success-color);
                                    width: 0%;
                                    transition: width 0.3s ease;
                                "></div>
                            </div>
                            <div id="progress-text" style="
                                font-size: 12px;
                                color: var(--text-secondary);
                                text-align: center;
                            ">0%</div>
                        </div>
                        
                        <button type="submit" id="upload-btn" disabled style="
                            padding: 12px 32px;
                            background: var(--secondary-color);
                            color: white;
                            border: none;
                            border-radius: 8px;
                            cursor: pointer;
                            font-weight: 500;
                            transition: var(--transition);
                            opacity: 0.5;
                        ">
                            🚀 Atualizar Dados
                        </button>
                        
                        <div id="status-message" style="
                            margin-top: 16px;
                            padding: 12px;
                            border-radius: 8px;
                            font-size: 14px;
                            display: none;
                        "></div>
                    </form>
                    
                    <div class="upload-info" style="
                        margin-top: 20px;
                        padding: 16px;
                        background: var(--background-color);
                        border-radius: 8px;
                        font-size: 13px;
                        color: var(--text-secondary);
                    ">
                        <h4 style="color: var(--primary-color); margin-bottom: 8px;">📋 Formato do Arquivo:</h4>
                        <p><strong>Colunas suportadas:</strong></p>
                        <ul style="margin: 8px 0; padding-left: 20px;">
                            <li><code>total_membros</code> - Total de membros</li>
                            <li><code>membros_ativos</code> - Membros ativos</li>
                            <li><code>receita_mensal</code> - Receita mensal</li>
                            <li><code>aulas_realizadas</code> - Aulas realizadas</li>
                            <li><code>instrutores_ativos</code> - Instrutores ativos</li>
                            <li><code>faixa_etaria</code> - Faixa etária (18-25, 26-35, etc.)</li>
                            <li><code>aula</code> - Tipo de aula (musculacao, pilates, spinning)</li>
                        </ul>
                        <p style="margin-top: 12px;">
                            <a href="/api/template-exemplo.csv" download 
                               style="color: var(--primary-color); text-decoration: none;">
                                📥 Baixar template de exemplo
                            </a>
                        </p>
                    </div>
                </div>
            `;
            
            // Inserir após o primeiro card do dashboard
            const firstCard = document.querySelector('.dashboard-card');
            if (firstCard) {
                firstCard.parentNode.insertBefore(uploadSection, firstCard.nextSibling);
            }
        }
    }

    bindEvents() {
        const fileInput = document.getElementById('file-input');
        const uploadForm = document.getElementById('upload-form');
        const uploadBtn = document.getElementById('upload-btn');
        const fileName = document.getElementById('file-name');

        if (fileInput) {
            fileInput.addEventListener('change', (e) => {
                const file = e.target.files[0];
                if (file) {
                    fileName.textContent = `📄 ${file.name} (${this.formatFileSize(file.size)})`;
                    uploadBtn.disabled = false;
                    uploadBtn.style.opacity = '1';
                } else {
                    fileName.textContent = '';
                    uploadBtn.disabled = true;
                    uploadBtn.style.opacity = '0.5';
                }
            });
        }

        if (uploadForm) {
            uploadForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleUpload();
            });
        }
    }

    async handleUpload() {
        const fileInput = document.getElementById('file-input');
        const file = fileInput.files[0];
        
        if (!file) {
            this.showMessage('Por favor, selecione um arquivo.', 'error');
            return;
        }

        // Validar tipo de arquivo
        const allowedTypes = ['.xlsx', '.xls', '.csv'];
        const fileExt = '.' + file.name.split('.').pop().toLowerCase();
        
        if (!allowedTypes.includes(fileExt)) {
            this.showMessage('Apenas arquivos Excel (.xlsx, .xls) e CSV (.csv) são permitidos.', 'error');
            return;
        }

        // Validar tamanho (10MB)
        if (file.size > 10 * 1024 * 1024) {
            this.showMessage('Arquivo muito grande. Tamanho máximo: 10MB', 'error');
            return;
        }

        this.showProgress(true);
        this.showMessage('Enviando arquivo...', 'info');

        try {
            const formData = new FormData();
            formData.append('file', file);

            const response = await fetch(`${this.apiUrl}/upload`, {
                method: 'POST',
                body: formData
            });

            const result = await response.json();

            if (response.ok && result.success) {
                this.showMessage('✅ Dados atualizados com sucesso! Recarregando dashboard...', 'success');
                
                // Recarregar dados do dashboard após 2 segundos
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            } else {
                this.showMessage(`❌ Erro: ${result.error || 'Erro desconhecido'}`, 'error');
            }

        } catch (error) {
            console.error('Erro no upload:', error);
            this.showMessage('❌ Erro de conexão. Verifique se a API está rodando.', 'error');
        } finally {
            this.showProgress(false);
        }
    }

    showProgress(show) {
        const progressContainer = document.getElementById('progress-container');
        const progressBar = document.getElementById('progress-bar');
        const progressText = document.getElementById('progress-text');
        
        if (show) {
            progressContainer.style.display = 'block';
            this.simulateProgress(progressBar, progressText);
        } else {
            progressContainer.style.display = 'none';
            progressBar.style.width = '0%';
            progressText.textContent = '0%';
        }
    }

    simulateProgress(progressBar, progressText) {
        let progress = 0;
        const interval = setInterval(() => {
            progress += Math.random() * 15;
            if (progress > 90) progress = 90;
            
            progressBar.style.width = progress + '%';
            progressText.textContent = Math.round(progress) + '%';
            
            if (progress >= 90) {
                clearInterval(interval);
            }
        }, 200);
    }

    showMessage(message, type) {
        const statusMessage = document.getElementById('status-message');
        if (statusMessage) {
            statusMessage.textContent = message;
            statusMessage.style.display = 'block';
            
            // Remover classes anteriores
            statusMessage.className = '';
            
            // Adicionar classe baseada no tipo
            switch (type) {
                case 'success':
                    statusMessage.style.background = '#d1fae5';
                    statusMessage.style.color = '#065f46';
                    statusMessage.style.border = '1px solid #a7f3d0';
                    break;
                case 'error':
                    statusMessage.style.background = '#fee2e2';
                    statusMessage.style.color = '#991b1b';
                    statusMessage.style.border = '1px solid #fca5a5';
                    break;
                case 'info':
                    statusMessage.style.background = '#dbeafe';
                    statusMessage.style.color = '#1e40af';
                    statusMessage.style.border = '1px solid #93c5fd';
                    break;
            }
        }
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }
}

// Inicializar quando o DOM estiver carregado
document.addEventListener('DOMContentLoaded', () => {
    new AcademiaUploadHandler();
});

