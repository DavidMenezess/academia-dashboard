const AWS = require('aws-sdk');

// Configurar AWS
AWS.config.update({
    region: process.env.AWS_REGION || 'us-east-1'
});

const dynamodb = new AWS.DynamoDB();

async function createTable() {
    const tableName = process.env.DYNAMODB_TABLE || 'academia-dashboard';
    
    const params = {
        TableName: tableName,
        KeySchema: [
            {
                AttributeName: 'PK',
                KeyType: 'HASH' // Partition key
            },
            {
                AttributeName: 'SK',
                KeyType: 'RANGE' // Sort key
            }
        ],
        AttributeDefinitions: [
            {
                AttributeName: 'PK',
                AttributeType: 'S'
            },
            {
                AttributeName: 'SK',
                AttributeType: 'S'
            },
            {
                AttributeName: 'category',
                AttributeType: 'S'
            },
            {
                AttributeName: 'timestamp',
                AttributeType: 'S'
            }
        ],
        GlobalSecondaryIndexes: [
            {
                IndexName: 'CategoryIndex',
                KeySchema: [
                    {
                        AttributeName: 'category',
                        KeyType: 'HASH'
                    },
                    {
                        AttributeName: 'timestamp',
                        KeyType: 'RANGE'
                    }
                ],
                Projection: {
                    ProjectionType: 'ALL'
                },
                BillingMode: 'PAY_PER_REQUEST' // Free Tier friendly
            }
        ],
        BillingMode: 'PAY_PER_REQUEST', // Free Tier friendly
        Tags: [
            {
                Key: 'Project',
                Value: 'Academia Dashboard'
            },
            {
                Key: 'Environment',
                Value: 'Production'
            },
            {
                Key: 'CostCenter',
                Value: 'Free-Tier'
            }
        ]
    };

    try {
        console.log(`🔍 Verificando se a tabela ${tableName} existe...`);
        
        // Verificar se a tabela já existe
        try {
            await dynamodb.describeTable({ TableName: tableName }).promise();
            console.log(`✅ Tabela ${tableName} já existe!`);
            return;
        } catch (error) {
            if (error.code === 'ResourceNotFoundException') {
                console.log(`📝 Criando tabela ${tableName}...`);
            } else {
                throw error;
            }
        }

        // Criar a tabela
        const result = await dynamodb.createTable(params).promise();
        console.log(`🚀 Tabela ${tableName} criada com sucesso!`);
        console.log(`📊 Status: ${result.TableDescription.TableStatus}`);
        
        // Aguardar a tabela ficar ativa
        console.log('⏳ Aguardando tabela ficar ativa...');
        await waitForTableActive(tableName);
        
        console.log('✅ Tabela está ativa e pronta para uso!');
        
    } catch (error) {
        if (error.code === 'ResourceInUseException') {
            console.log(`✅ Tabela ${tableName} já existe!`);
        } else {
            console.error('❌ Erro ao criar tabela:', error);
            throw error;
        }
    }
}

async function waitForTableActive(tableName) {
    const maxAttempts = 30;
    let attempts = 0;
    
    while (attempts < maxAttempts) {
        try {
            const result = await dynamodb.describeTable({ TableName: tableName }).promise();
            
            if (result.Table.TableStatus === 'ACTIVE') {
                return;
            }
            
            console.log(`⏳ Status atual: ${result.Table.TableStatus} (tentativa ${attempts + 1}/${maxAttempts})`);
            
            // Aguardar 10 segundos antes da próxima verificação
            await new Promise(resolve => setTimeout(resolve, 10000));
            attempts++;
            
        } catch (error) {
            console.error('Erro ao verificar status da tabela:', error);
            throw error;
        }
    }
    
    throw new Error('Timeout aguardando tabela ficar ativa');
}

async function main() {
    try {
        console.log('🗄️ Configurando DynamoDB para Academia Dashboard');
        console.log('==============================================');
        
        // Verificar credenciais AWS
        console.log('🔑 Verificando credenciais AWS...');
        const sts = new AWS.STS();
        const identity = await sts.getCallerIdentity().promise();
        console.log(`✅ Conectado como: ${identity.Arn}`);
        console.log(`🌍 Região: ${AWS.config.region}`);
        
        // Criar tabela
        await createTable();
        
        console.log('');
        console.log('🎉 Configuração concluída com sucesso!');
        console.log('==============================================');
        console.log('📊 Sua tabela DynamoDB está pronta para uso!');
        console.log('💰 Custo: $0.00 (dentro do Free Tier)');
        console.log('');
        console.log('🚀 Próximos passos:');
        console.log('1. Execute o servidor: npm start');
        console.log('2. Acesse: http://localhost:3000');
        console.log('3. Os dados serão inseridos automaticamente');
        
    } catch (error) {
        console.error('❌ Erro na configuração:', error);
        process.exit(1);
    }
}

// Executar se chamado diretamente
if (require.main === module) {
    main();
}

module.exports = { createTable, waitForTableActive };
