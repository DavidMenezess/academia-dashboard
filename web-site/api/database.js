const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

class Database {
    constructor() {
        this.dbPath = path.join(__dirname, 'data', 'academia.db');
        this.db = null;
        this.init();
    }

    init() {
        // Criar diretório se não existir
        const dataDir = path.dirname(this.dbPath);
        if (!fs.existsSync(dataDir)) {
            fs.mkdirSync(dataDir, { recursive: true });
        }

        // Conectar ao banco
        this.db = new sqlite3.Database(this.dbPath, (err) => {
            if (err) {
                console.error('Erro ao conectar ao banco de dados:', err);
            } else {
                console.log('✅ Conectado ao banco de dados SQLite');
                this.createTables();
            }
        });
    }

    createTables() {
        const tables = [
            // Tabela de usuários
            `CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                name TEXT NOT NULL,
                role TEXT NOT NULL CHECK(role IN ('admin', 'cashier')),
                category TEXT NOT NULL,
                permissions TEXT DEFAULT '[]',
                last_login DATETIME,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN DEFAULT 1
            )`,

            // Tabela de controle de caixa
            `CREATE TABLE IF NOT EXISTS cash_control (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category TEXT NOT NULL,
                is_open BOOLEAN DEFAULT 0,
                initial_cash REAL DEFAULT 0,
                current_balance REAL DEFAULT 0,
                today_sales REAL DEFAULT 0,
                last_opened DATETIME,
                last_closed DATETIME,
                observations TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`,

            // Tabela de vendas
            `CREATE TABLE IF NOT EXISTS sales (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sale_id TEXT UNIQUE NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                category TEXT NOT NULL,
                cashier TEXT NOT NULL,
                total REAL NOT NULL,
                payment_method TEXT NOT NULL,
                change_amount REAL DEFAULT 0,
                status TEXT DEFAULT 'completed',
                observations TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`,

            // Tabela de itens de venda
            `CREATE TABLE IF NOT EXISTS sale_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sale_id TEXT NOT NULL,
                customer_name TEXT,
                customer_document TEXT,
                product_name TEXT NOT NULL,
                product_id INTEGER,
                quantity INTEGER NOT NULL,
                unit_price REAL NOT NULL,
                total REAL NOT NULL,
                type TEXT NOT NULL,
                observations TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
            )`,

            // Tabela de produtos
            `CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                price REAL NOT NULL,
                type TEXT NOT NULL CHECK(type IN ('product', 'membership', 'daily', 'biweekly')),
                description TEXT,
                is_active BOOLEAN DEFAULT 1,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`,

            // Tabela de relatórios
            `CREATE TABLE IF NOT EXISTS reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                report_type TEXT NOT NULL,
                category TEXT,
                period_start DATE NOT NULL,
                period_end DATE NOT NULL,
                total_sales REAL DEFAULT 0,
                total_transactions INTEGER DEFAULT 0,
                data TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`
        ];

        tables.forEach((sql, index) => {
            this.db.run(sql, (err) => {
                if (err) {
                    console.error(`Erro ao criar tabela ${index + 1}:`, err);
                } else {
                    console.log(`✅ Tabela ${index + 1} criada/verificada`);
                }
            });
        });

        // Inserir dados iniciais
        this.insertInitialData();
    }

    insertInitialData() {
        // Verificar se já existem usuários
        this.db.get("SELECT COUNT(*) as count FROM users", (err, row) => {
            if (err) {
                console.error('Erro ao verificar usuários:', err);
                return;
            }

            if (row.count === 0) {
                console.log('📝 Inserindo usuários iniciais...');
                
                const initialUsers = [
                    {
                        username: 'admin',
                        password: 'admin123',
                        name: 'Administrador',
                        role: 'admin',
                        category: 'admin',
                        permissions: JSON.stringify(['manage_users', 'view_all_reports', 'manage_products'])
                    },
                    {
                        username: 'caixa_manha',
                        password: 'manha123',
                        name: 'Caixa Manhã',
                        role: 'cashier',
                        category: 'caixa-manha',
                        permissions: JSON.stringify(['add_sales', 'view_daily_reports', 'manage_products'])
                    },
                    {
                        username: 'caixa_tarde',
                        password: 'tarde123',
                        name: 'Caixa Tarde',
                        role: 'cashier',
                        category: 'caixa-tarde',
                        permissions: JSON.stringify(['add_sales', 'view_daily_reports', 'manage_products'])
                    },
                    {
                        username: 'caixa_noite',
                        password: 'noite123',
                        name: 'Caixa Noite',
                        role: 'cashier',
                        category: 'caixa-noite',
                        permissions: JSON.stringify(['add_sales', 'view_daily_reports', 'manage_products'])
                    }
                ];

                const insertUser = `INSERT INTO users (username, password, name, role, category, permissions) 
                                  VALUES (?, ?, ?, ?, ?, ?)`;

                initialUsers.forEach(user => {
                    this.db.run(insertUser, [
                        user.username,
                        user.password,
                        user.name,
                        user.role,
                        user.category,
                        user.permissions
                    ], (err) => {
                        if (err) {
                            console.error('Erro ao inserir usuário:', err);
                        } else {
                            console.log(`✅ Usuário ${user.username} inserido`);
                        }
                    });
                });
            }
        });

        // Verificar se já existem produtos
        this.db.get("SELECT COUNT(*) as count FROM products", (err, row) => {
            if (err) {
                console.error('Erro ao verificar produtos:', err);
                return;
            }

            if (row.count === 0) {
                console.log('📝 Inserindo produtos iniciais...');
                
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

                const insertProduct = `INSERT INTO products (name, price, type) VALUES (?, ?, ?)`;

                initialProducts.forEach(product => {
                    this.db.run(insertProduct, [
                        product.name,
                        product.price,
                        product.type
                    ], (err) => {
                        if (err) {
                            console.error('Erro ao inserir produto:', err);
                        } else {
                            console.log(`✅ Produto ${product.name} inserido`);
                        }
                    });
                });
            }
        });
    }

    // Métodos para usuários
    authenticateUser(username, password) {
        return new Promise((resolve, reject) => {
            const sql = `SELECT * FROM users WHERE username = ? AND password = ? AND is_active = 1`;
            this.db.get(sql, [username, password], (err, row) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row);
                }
            });
        });
    }

    updateLastLogin(userId) {
        return new Promise((resolve, reject) => {
            const sql = `UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?`;
            this.db.run(sql, [userId], (err) => {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    }

    getAllUsers() {
        return new Promise((resolve, reject) => {
            const sql = `SELECT * FROM users ORDER BY created_at DESC`;
            this.db.all(sql, [], (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(rows);
                }
            });
        });
    }

    createUser(user) {
        return new Promise((resolve, reject) => {
            const sql = `INSERT INTO users (username, password, name, role, category, permissions) 
                        VALUES (?, ?, ?, ?, ?, ?)`;
            this.db.run(sql, [
                user.username,
                user.password,
                user.name,
                user.role,
                user.category,
                JSON.stringify(user.permissions || [])
            ], function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve(this.lastID);
                }
            });
        });
    }

    updateUser(userId, user) {
        return new Promise((resolve, reject) => {
            const sql = `UPDATE users SET username = ?, password = ?, name = ?, role = ?, 
                        category = ?, permissions = ?, is_active = ? WHERE id = ?`;
            this.db.run(sql, [
                user.username,
                user.password,
                user.name,
                user.role,
                user.category,
                JSON.stringify(user.permissions || []),
                user.is_active,
                userId
            ], (err) => {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    }

    deleteUser(userId) {
        return new Promise((resolve, reject) => {
            const sql = `DELETE FROM users WHERE id = ?`;
            this.db.run(sql, [userId], (err) => {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    }

    // Métodos para controle de caixa
    getCashControl(category) {
        return new Promise((resolve, reject) => {
            const sql = `SELECT * FROM cash_control WHERE category = ? ORDER BY created_at DESC LIMIT 1`;
            this.db.get(sql, [category], (err, row) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row || {
                        category: category,
                        is_open: false,
                        initial_cash: 0,
                        current_balance: 0,
                        today_sales: 0
                    });
                }
            });
        });
    }

    updateCashControl(category, cashData) {
        return new Promise((resolve, reject) => {
            const sql = `INSERT OR REPLACE INTO cash_control 
                        (category, is_open, initial_cash, current_balance, today_sales, 
                         last_opened, last_closed, observations) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;
            this.db.run(sql, [
                category,
                cashData.is_open,
                cashData.initial_cash,
                cashData.current_balance,
                cashData.today_sales,
                cashData.last_opened,
                cashData.last_closed,
                cashData.observations
            ], (err) => {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    }

    // Métodos para vendas
    createSale(saleData) {
        return new Promise((resolve, reject) => {
            const saleId = `SALE_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            const sql = `INSERT INTO sales (sale_id, category, cashier, total, payment_method, 
                        change_amount, status, observations) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;
            
            this.db.run(sql, [
                saleId,
                saleData.category,
                saleData.cashier,
                saleData.total,
                saleData.payment_method,
                saleData.change_amount || 0,
                saleData.status || 'completed',
                saleData.observations || ''
            ], function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve(saleId);
                }
            });
        });
    }

    createSaleItems(saleId, items) {
        return new Promise((resolve, reject) => {
            const sql = `INSERT INTO sale_items 
                        (sale_id, customer_name, customer_document, product_name, product_id,
                         quantity, unit_price, total, type, observations) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
            
            let completed = 0;
            const total = items.length;
            
            if (total === 0) {
                resolve();
                return;
            }
            
            items.forEach(item => {
                this.db.run(sql, [
                    saleId,
                    item.customer_name || 'Cliente não informado',
                    item.customer_document || 'Não informado',
                    item.product_name,
                    item.product_id || null,
                    item.quantity,
                    item.unit_price,
                    item.total,
                    item.type,
                    item.observations || ''
                ], (err) => {
                    if (err) {
                        reject(err);
                        return;
                    }
                    
                    completed++;
                    if (completed === total) {
                        resolve();
                    }
                });
            });
        });
    }

    getSales(category, startDate, endDate) {
        return new Promise((resolve, reject) => {
            let sql = `SELECT s.*, GROUP_CONCAT(si.product_name || ' (x' || si.quantity || ')') as products
                      FROM sales s
                      LEFT JOIN sale_items si ON s.sale_id = si.sale_id
                      WHERE s.category = ?`;
            const params = [category];
            
            if (startDate && endDate) {
                sql += ` AND s.timestamp BETWEEN ? AND ?`;
                params.push(startDate, endDate);
            }
            
            sql += ` GROUP BY s.sale_id ORDER BY s.timestamp DESC`;
            
            this.db.all(sql, params, (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(rows);
                }
            });
        });
    }

    // Métodos para produtos
    getAllProducts() {
        return new Promise((resolve, reject) => {
            const sql = `SELECT * FROM products WHERE is_active = 1 ORDER BY name`;
            this.db.all(sql, [], (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(rows);
                }
            });
        });
    }

    createProduct(product) {
        return new Promise((resolve, reject) => {
            const sql = `INSERT INTO products (name, price, type, description) VALUES (?, ?, ?, ?)`;
            this.db.run(sql, [
                product.name,
                product.price,
                product.type,
                product.description || ''
            ], function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve(this.lastID);
                }
            });
        });
    }

    // Método para fechar conexão
    close() {
        if (this.db) {
            this.db.close((err) => {
                if (err) {
                    console.error('Erro ao fechar banco de dados:', err);
                } else {
                    console.log('✅ Conexão com banco de dados fechada');
                }
            });
        }
    }
}

module.exports = Database;




