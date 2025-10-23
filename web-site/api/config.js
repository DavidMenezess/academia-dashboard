// ========================================
// CONFIGURAÇÃO DO BANCO DE DADOS
// ========================================

const config = {
    // Escolha o banco de dados: 'dynamodb' ou 'sqlite'
    database: process.env.DATABASE_TYPE || 'sqlite',
    
    // Configurações do DynamoDB
    dynamodb: {
        region: process.env.AWS_REGION || 'us-east-1',
        tableName: process.env.DYNAMODB_TABLE || 'academia-dashboard',
        // Usar IAM Role (recomendado para EC2)
        useIAMRole: process.env.AWS_USE_IAM_ROLE === 'true',
        // Ou usar credenciais diretas (não recomendado para produção)
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    },
    
    // Configurações do SQLite
    sqlite: {
        databasePath: process.env.SQLITE_PATH || './data/academia.db'
    },
    
    // Configurações gerais
    api: {
        port: process.env.PORT || 3000,
        cors: {
            origin: process.env.CORS_ORIGIN || '*',
            credentials: true
        }
    },
    
    // Configurações de segurança
    security: {
        jwtSecret: process.env.JWT_SECRET || 'academia-secret-key-change-in-production',
        sessionTimeout: process.env.SESSION_TIMEOUT || 24 * 60 * 60 * 1000 // 24 horas
    }
};

// ========================================
// VALIDAÇÃO DE CONFIGURAÇÃO
// ========================================

function validateConfig() {
    const errors = [];
    
    if (config.database === 'dynamodb') {
        // Validar configurações do DynamoDB
        if (!config.dynamodb.useIAMRole) {
            if (!config.dynamodb.accessKeyId || !config.dynamodb.secretAccessKey) {
                errors.push('AWS credentials são obrigatórias quando useIAMRole é false');
            }
        }
        
        if (!config.dynamodb.region) {
            errors.push('AWS region é obrigatória');
        }
        
        if (!config.dynamodb.tableName) {
            errors.push('Nome da tabela DynamoDB é obrigatório');
        }
    }
    
    if (errors.length > 0) {
        console.error('❌ Erros de configuração:');
        errors.forEach(error => console.error(`   - ${error}`));
        console.error('\n💡 Soluções:');
        console.error('   1. Configure as variáveis de ambiente necessárias');
        console.error('   2. Ou use SQLite (DATABASE_TYPE=sqlite)');
        console.error('   3. Ou configure IAM Role na EC2');
        return false;
    }
    
    return true;
}

// ========================================
// INFORMAÇÕES DE CONFIGURAÇÃO
// ========================================

function getConfigInfo() {
    return {
        database: config.database,
        region: config.database === 'dynamodb' ? config.dynamodb.region : 'local',
        tableName: config.database === 'dynamodb' ? config.dynamodb.tableName : 'SQLite',
        port: config.api.port,
        cors: config.api.cors.origin,
        timestamp: new Date().toISOString()
    };
}

// ========================================
// CONFIGURAÇÃO DE AMBIENTE
// ========================================

function setupEnvironment() {
    console.log('🔧 Configuração do Ambiente');
    console.log('==============================================');
    console.log(`📊 Banco de dados: ${config.database.toUpperCase()}`);
    
    if (config.database === 'dynamodb') {
        console.log(`🌍 Região AWS: ${config.dynamodb.region}`);
        console.log(`📋 Tabela: ${config.dynamodb.tableName}`);
        console.log(`🔑 Autenticação: ${config.dynamodb.useIAMRole ? 'IAM Role' : 'Credenciais'}`);
    } else {
        console.log(`💾 Arquivo SQLite: ${config.sqlite.databasePath}`);
    }
    
    console.log(`🚀 Porta da API: ${config.api.port}`);
    console.log(`🌐 CORS: ${config.api.cors.origin}`);
    console.log('==============================================');
}

// ========================================
// EXPORTS
// ========================================

module.exports = {
    config,
    validateConfig,
    getConfigInfo,
    setupEnvironment
};




