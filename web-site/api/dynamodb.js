const AWS = require('aws-sdk');

// Configurar DynamoDB
AWS.config.update({
    region: process.env.AWS_REGION || 'us-east-1'
});

const dynamodb = new AWS.DynamoDB.DocumentClient();

class DynamoDBService {
    constructor() {
        this.tableName = process.env.DYNAMODB_TABLE || 'academia-dashboard';
        this.init();
    }

    async init() {
        console.log('🗄️ Inicializando DynamoDB...');
        console.log(`📊 Tabela: ${this.tableName}`);
        console.log(`🌍 Região: ${AWS.config.region}`);
    }

    // ========================================
    // MÉTODOS DE AUTENTICAÇÃO
    // ========================================

    async authenticateUser(username, password) {
        try {
            const params = {
                TableName: this.tableName,
                Key: {
                    PK: `USER#${username}`,
                    SK: 'PROFILE'
                }
            };

            const result = await dynamodb.get(params).promise();
            
            if (result.Item && result.Item.password === password && result.Item.is_active) {
                // Atualizar último login
                await this.updateLastLogin(username);
                
                return {
                    id: result.Item.id,
                    username: result.Item.username,
                    name: result.Item.name,
                    role: result.Item.role,
                    category: result.Item.category,
                    permissions: result.Item.permissions
                };
            }
            
            return null;
        } catch (error) {
            console.error('Erro na autenticação:', error);
            throw error;
        }
    }

    async updateLastLogin(username) {
        try {
            const params = {
                TableName: this.tableName,
                Key: {
                    PK: `USER#${username}`,
                    SK: 'PROFILE'
                },
                UpdateExpression: 'SET last_login = :timestamp',
                ExpressionAttributeValues: {
                    ':timestamp': new Date().toISOString()
                }
            };

            await dynamodb.update(params).promise();
        } catch (error) {
            console.error('Erro ao atualizar último login:', error);
        }
    }

    // ========================================
    // MÉTODOS DE USUÁRIOS
    // ========================================

    async getAllUsers() {
        try {
            const params = {
                TableName: this.tableName,
                FilterExpression: 'begins_with(PK, :pk) AND SK = :sk',
                ExpressionAttributeValues: {
                    ':pk': 'USER#',
                    ':sk': 'PROFILE'
                }
            };

            const result = await dynamodb.scan(params).promise();
            
            return result.Items.map(user => ({
                id: user.id,
                username: user.username,
                name: user.name,
                role: user.role,
                category: user.category,
                permissions: user.permissions,
                last_login: user.last_login,
                created_at: user.created_at,
                is_active: user.is_active
            }));
        } catch (error) {
            console.error('Erro ao listar usuários:', error);
            throw error;
        }
    }

    async createUser(user) {
        try {
            const userId = `USER_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            const params = {
                TableName: this.tableName,
                Item: {
                    PK: `USER#${user.username}`,
                    SK: 'PROFILE',
                    id: userId,
                    username: user.username,
                    password: user.password,
                    name: user.name,
                    role: user.role,
                    category: user.category,
                    permissions: user.permissions || [],
                    created_at: new Date().toISOString(),
                    is_active: true
                }
            };

            await dynamodb.put(params).promise();
            return userId;
        } catch (error) {
            console.error('Erro ao criar usuário:', error);
            throw error;
        }
    }

    async updateUser(username, user) {
        try {
            const updateExpression = 'SET username = :username, password = :password, name = :name, role = :role, category = :category, permissions = :permissions, is_active = :is_active';
            
            const params = {
                TableName: this.tableName,
                Key: {
                    PK: `USER#${username}`,
                    SK: 'PROFILE'
                },
                UpdateExpression: updateExpression,
                ExpressionAttributeValues: {
                    ':username': user.username,
                    ':password': user.password,
                    ':name': user.name,
                    ':role': user.role,
                    ':category': user.category,
                    ':permissions': user.permissions || [],
                    ':is_active': user.is_active
                }
            };

            await dynamodb.update(params).promise();
        } catch (error) {
            console.error('Erro ao atualizar usuário:', error);
            throw error;
        }
    }

    async deleteUser(username) {
        try {
            const params = {
                TableName: this.tableName,
                Key: {
                    PK: `USER#${username}`,
                    SK: 'PROFILE'
                }
            };

            await dynamodb.delete(params).promise();
        } catch (error) {
            console.error('Erro ao deletar usuário:', error);
            throw error;
        }
    }

    // ========================================
    // MÉTODOS DE CONTROLE DE CAIXA
    // ========================================

    async getCashControl(category) {
        try {
            const params = {
                TableName: this.tableName,
                Key: {
                    PK: `CASH#${category}`,
                    SK: 'CONTROL'
                }
            };

            const result = await dynamodb.get(params).promise();
            
            return result.Item || {
                category: category,
                is_open: false,
                initial_cash: 0,
                current_balance: 0,
                today_sales: 0
            };
        } catch (error) {
            console.error('Erro ao obter controle de caixa:', error);
            throw error;
        }
    }

    async updateCashControl(category, cashData) {
        try {
            const params = {
                TableName: this.tableName,
                Item: {
                    PK: `CASH#${category}`,
                    SK: 'CONTROL',
                    category: category,
                    is_open: cashData.is_open,
                    initial_cash: cashData.initial_cash,
                    current_balance: cashData.current_balance,
                    today_sales: cashData.today_sales,
                    last_opened: cashData.last_opened,
                    last_closed: cashData.last_closed,
                    observations: cashData.observations,
                    updated_at: new Date().toISOString()
                }
            };

            await dynamodb.put(params).promise();
        } catch (error) {
            console.error('Erro ao atualizar controle de caixa:', error);
            throw error;
        }
    }

    // ========================================
    // MÉTODOS DE VENDAS
    // ========================================

    async createSale(saleData) {
        try {
            const saleId = `SALE_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            // Criar venda principal
            const saleParams = {
                TableName: this.tableName,
                Item: {
                    PK: `SALE#${saleId}`,
                    SK: 'INFO',
                    sale_id: saleId,
                    category: saleData.category,
                    cashier: saleData.cashier,
                    total: saleData.total,
                    payment_method: saleData.payment_method,
                    change_amount: saleData.change_amount || 0,
                    status: saleData.status || 'completed',
                    observations: saleData.observations || '',
                    timestamp: new Date().toISOString(),
                    created_at: new Date().toISOString()
                }
            };

            await dynamodb.put(saleParams).promise();

            // Criar itens da venda
            for (let i = 0; i < saleData.items.length; i++) {
                const item = saleData.items[i];
                const itemParams = {
                    TableName: this.tableName,
                    Item: {
                        PK: `SALE#${saleId}`,
                        SK: `ITEM#${i}`,
                        sale_id: saleId,
                        customer_name: item.customer_name || 'Cliente não informado',
                        customer_document: item.customer_document || 'Não informado',
                        product_name: item.product_name,
                        product_id: item.product_id || null,
                        quantity: item.quantity,
                        unit_price: item.unit_price,
                        total: item.total,
                        type: item.type,
                        observations: item.observations || '',
                        created_at: new Date().toISOString()
                    }
                };

                await dynamodb.put(itemParams).promise();
            }

            return saleId;
        } catch (error) {
            console.error('Erro ao criar venda:', error);
            throw error;
        }
    }

    async getSales(category, startDate, endDate) {
        try {
            let params = {
                TableName: this.tableName,
                FilterExpression: 'begins_with(PK, :pk) AND SK = :sk',
                ExpressionAttributeValues: {
                    ':pk': 'SALE#',
                    ':sk': 'INFO'
                }
            };

            if (category) {
                params.FilterExpression += ' AND category = :category';
                params.ExpressionAttributeValues[':category'] = category;
            }

            if (startDate && endDate) {
                params.FilterExpression += ' AND timestamp BETWEEN :start_date AND :end_date';
                params.ExpressionAttributeValues[':start_date'] = startDate;
                params.ExpressionAttributeValues[':end_date'] = endDate;
            }

            const result = await dynamodb.scan(params).promise();
            return result.Items;
        } catch (error) {
            console.error('Erro ao listar vendas:', error);
            throw error;
        }
    }

    // ========================================
    // MÉTODOS DE PRODUTOS
    // ========================================

    async getAllProducts() {
        try {
            const params = {
                TableName: this.tableName,
                FilterExpression: 'begins_with(PK, :pk) AND SK = :sk',
                ExpressionAttributeValues: {
                    ':pk': 'PRODUCT#',
                    ':sk': 'INFO'
                }
            };

            const result = await dynamodb.scan(params).promise();
            return result.Items;
        } catch (error) {
            console.error('Erro ao listar produtos:', error);
            throw error;
        }
    }

    async createProduct(product) {
        try {
            const productId = `PRODUCT_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            const params = {
                TableName: this.tableName,
                Item: {
                    PK: `PRODUCT#${productId}`,
                    SK: 'INFO',
                    id: productId,
                    name: product.name,
                    price: product.price,
                    type: product.type,
                    description: product.description || '',
                    is_active: true,
                    created_at: new Date().toISOString()
                }
            };

            await dynamodb.put(params).promise();
            return productId;
        } catch (error) {
            console.error('Erro ao criar produto:', error);
            throw error;
        }
    }

    // ========================================
    // MÉTODOS DE INICIALIZAÇÃO
    // ========================================

    async insertInitialData() {
        try {
            // Verificar se já existem usuários
            const users = await this.getAllUsers();
            
            if (users.length === 0) {
                console.log('📝 Inserindo usuários iniciais no DynamoDB...');
                
                const initialUsers = [
                    {
                        username: 'admin',
                        password: 'admin123',
                        name: 'Administrador',
                        role: 'admin',
                        category: 'admin',
                        permissions: ['manage_users', 'view_all_reports', 'manage_products']
                    },
                    {
                        username: 'caixa_manha',
                        password: 'manha123',
                        name: 'Caixa Manhã',
                        role: 'cashier',
                        category: 'caixa-manha',
                        permissions: ['add_sales', 'view_daily_reports', 'manage_products']
                    },
                    {
                        username: 'caixa_tarde',
                        password: 'tarde123',
                        name: 'Caixa Tarde',
                        role: 'cashier',
                        category: 'caixa-tarde',
                        permissions: ['add_sales', 'view_daily_reports', 'manage_products']
                    },
                    {
                        username: 'caixa_noite',
                        password: 'noite123',
                        name: 'Caixa Noite',
                        role: 'cashier',
                        category: 'caixa-noite',
                        permissions: ['add_sales', 'view_daily_reports', 'manage_products']
                    }
                ];

                for (const user of initialUsers) {
                    await this.createUser(user);
                    console.log(`✅ Usuário ${user.username} inserido`);
                }
            }

            // Verificar se já existem produtos
            const products = await this.getAllProducts();
            
            if (products.length === 0) {
                console.log('📝 Inserindo produtos iniciais no DynamoDB...');
                
                const initialProducts = [
                    { name: 'Mensalidade - Musculação', price: 120.00, type: 'membership' },
                    { name: 'Mensalidade - Aeróbico', price: 80.00, type: 'membership' },
                    { name: 'Mensalidade - Completa', price: 150.00, type: 'membership' },
                    { name: 'Diária - Musculação', price: 15.00, type: 'daily' },
                    { name: 'Diária - Aeróbico', price: 10.00, type: 'daily' },
                    { name: 'Quinzena - Musculação', price: 60.00, type: 'biweekly' },
                    { name: 'Quinzena - Aeróbico', price: 40.00, type: 'biweekly' },
                    { name: 'Whey Protein', price: 89.90, type: 'product' },
                    { name: 'Creatina', price: 45.00, type: 'product' },
                    { name: 'BCAA', price: 35.00, type: 'product' },
                    { name: 'Multivitamínico', price: 25.00, type: 'product' },
                    { name: 'Garrafa Térmica', price: 15.00, type: 'product' }
                ];

                for (const product of initialProducts) {
                    await this.createProduct(product);
                    console.log(`✅ Produto ${product.name} inserido`);
                }
            }

            console.log('✅ Dados iniciais inseridos com sucesso!');
        } catch (error) {
            console.error('Erro ao inserir dados iniciais:', error);
        }
    }
}

module.exports = DynamoDBService;


