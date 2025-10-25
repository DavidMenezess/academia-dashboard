const express = require('express');
const Database = require('./database');
const router = express.Router();

// Inicializar banco de dados
const db = new Database();

// Middleware para CORS
router.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    
    if (req.method === 'OPTIONS') {
        res.sendStatus(200);
    } else {
        next();
    }
});

// Middleware para parsing JSON
router.use(express.json());

// ========================================
// ROTAS DE AUTENTICAÇÃO
// ========================================

// Login
router.post('/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        if (!username || !password) {
            return res.status(400).json({
                success: false,
                message: 'Username e password são obrigatórios'
            });
        }
        
        const user = await db.authenticateUser(username, password);
        
        if (user) {
            await db.updateLastLogin(user.id);
            
            res.json({
                success: true,
                user: {
                    id: user.id,
                    username: user.username,
                    name: user.name,
                    role: user.role,
                    category: user.category,
                    permissions: JSON.parse(user.permissions)
                }
            });
        } else {
            res.status(401).json({
                success: false,
                message: 'Usuário ou senha incorretos'
            });
        }
    } catch (error) {
        console.error('Erro no login:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// ========================================
// ROTAS DE USUÁRIOS
// ========================================

// Listar todos os usuários
router.get('/users', async (req, res) => {
    try {
        const users = await db.getAllUsers();
        res.json({
            success: true,
            users: users.map(user => ({
                id: user.id,
                username: user.username,
                name: user.name,
                role: user.role,
                category: user.category,
                permissions: JSON.parse(user.permissions),
                last_login: user.last_login,
                created_at: user.created_at,
                is_active: user.is_active
            }))
        });
    } catch (error) {
        console.error('Erro ao listar usuários:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// Criar usuário
router.post('/users', async (req, res) => {
    try {
        const user = req.body;
        
        if (!user.username || !user.password || !user.name || !user.role) {
            return res.status(400).json({
                success: false,
                message: 'Dados obrigatórios: username, password, name, role'
            });
        }
        
        const userId = await db.createUser(user);
        
        res.status(201).json({
            success: true,
            message: 'Usuário criado com sucesso',
            userId: userId
        });
    } catch (error) {
        console.error('Erro ao criar usuário:', error);
        
        if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
            res.status(400).json({
                success: false,
                message: 'Username já existe'
            });
        } else {
            res.status(500).json({
                success: false,
                message: 'Erro interno do servidor'
            });
        }
    }
});

// Atualizar usuário
router.put('/users/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        const user = req.body;
        
        await db.updateUser(userId, user);
        
        res.json({
            success: true,
            message: 'Usuário atualizado com sucesso'
        });
    } catch (error) {
        console.error('Erro ao atualizar usuário:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// Deletar usuário
router.delete('/users/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        
        await db.deleteUser(userId);
        
        res.json({
            success: true,
            message: 'Usuário deletado com sucesso'
        });
    } catch (error) {
        console.error('Erro ao deletar usuário:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// ========================================
// ROTAS DE CONTROLE DE CAIXA
// ========================================

// Obter controle de caixa
router.get('/cash-control/:category', async (req, res) => {
    try {
        const category = req.params.category;
        const cashControl = await db.getCashControl(category);
        
        res.json({
            success: true,
            cashControl: cashControl
        });
    } catch (error) {
        console.error('Erro ao obter controle de caixa:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// Atualizar controle de caixa
router.post('/cash-control/:category', async (req, res) => {
    try {
        const category = req.params.category;
        const cashData = req.body;
        
        await db.updateCashControl(category, cashData);
        
        res.json({
            success: true,
            message: 'Controle de caixa atualizado com sucesso'
        });
    } catch (error) {
        console.error('Erro ao atualizar controle de caixa:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// ========================================
// ROTAS DE VENDAS
// ========================================

// Criar venda
router.post('/sales', async (req, res) => {
    try {
        const saleData = req.body;
        
        if (!saleData.category || !saleData.cashier || !saleData.total || !saleData.items) {
            return res.status(400).json({
                success: false,
                message: 'Dados obrigatórios: category, cashier, total, items'
            });
        }
        
        const saleId = await db.createSale(saleData);
        await db.createSaleItems(saleId, saleData.items);
        
        // Atualizar controle de caixa
        const cashControl = await db.getCashControl(saleData.category);
        cashControl.today_sales += saleData.total;
        cashControl.current_balance = cashControl.initial_cash + cashControl.today_sales;
        await db.updateCashControl(saleData.category, cashControl);
        
        res.status(201).json({
            success: true,
            message: 'Venda criada com sucesso',
            saleId: saleId
        });
    } catch (error) {
        console.error('Erro ao criar venda:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// Listar vendas
router.get('/sales/:category', async (req, res) => {
    try {
        const category = req.params.category;
        const { start_date, end_date } = req.query;
        
        const sales = await db.getSales(category, start_date, end_date);
        
        res.json({
            success: true,
            sales: sales
        });
    } catch (error) {
        console.error('Erro ao listar vendas:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// ========================================
// ROTAS DE PRODUTOS
// ========================================

// Listar produtos
router.get('/products', async (req, res) => {
    try {
        const products = await db.getAllProducts();
        
        res.json({
            success: true,
            products: products
        });
    } catch (error) {
        console.error('Erro ao listar produtos:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// Criar produto
router.post('/products', async (req, res) => {
    try {
        const product = req.body;
        
        if (!product.name || !product.price || !product.type) {
            return res.status(400).json({
                success: false,
                message: 'Dados obrigatórios: name, price, type'
            });
        }
        
        const productId = await db.createProduct(product);
        
        res.status(201).json({
            success: true,
            message: 'Produto criado com sucesso',
            productId: productId
        });
    } catch (error) {
        console.error('Erro ao criar produto:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// ========================================
// ROTAS DE RELATÓRIOS
// ========================================

// Relatório de vendas
router.get('/reports/sales/:category', async (req, res) => {
    try {
        const category = req.params.category;
        const { start_date, end_date } = req.query;
        
        const sales = await db.getSales(category, start_date, end_date);
        
        const totalSales = sales.reduce((sum, sale) => sum + sale.total, 0);
        const totalTransactions = sales.length;
        
        res.json({
            success: true,
            report: {
                period: {
                    start: start_date,
                    end: end_date
                },
                category: category,
                total_sales: totalSales,
                total_transactions: totalTransactions,
                sales: sales
            }
        });
    } catch (error) {
        console.error('Erro ao gerar relatório:', error);
        res.status(500).json({
            success: false,
            message: 'Erro interno do servidor'
        });
    }
});

// ========================================
// ROTA DE SAÚDE
// ========================================

// Health check
router.get('/health', (req, res) => {
    res.json({
        success: true,
        message: 'API funcionando corretamente',
        timestamp: new Date().toISOString(),
        database: 'SQLite'
    });
});

// ========================================
// ROTA 404
// ========================================

router.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint não encontrado'
    });
});

module.exports = router;






