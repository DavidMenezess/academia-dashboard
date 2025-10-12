const express = require('express');
const cors = require('cors');
const multer = require('multer');
const XLSX = require('xlsx');
const csv = require('csv-parser');
const fs = require('fs-extra');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Configuração do multer para upload de arquivos
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, 'uploads');
    fs.ensureDirSync(uploadDir);
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['.xlsx', '.xls', '.csv'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowedTypes.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Apenas arquivos Excel (.xlsx, .xls) e CSV (.csv) são permitidos!'), false);
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB
  }
});

// Caminho para o arquivo de dados
const DATA_FILE = path.join(__dirname, '../data/academia_data.json');

// Função para ler dados atuais
function readCurrentData() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
    }
    return null;
  } catch (error) {
    console.error('Erro ao ler dados atuais:', error);
    return null;
  }
}

// Função para salvar dados atualizados
function saveData(data) {
  try {
    data.ultima_atualizacao = new Date().toISOString();
    fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
    return true;
  } catch (error) {
    console.error('Erro ao salvar dados:', error);
    return false;
  }
}

// Função para processar arquivo Excel
function processExcelFile(filePath) {
  try {
    const workbook = XLSX.readFile(filePath);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const jsonData = XLSX.utils.sheet_to_json(worksheet);
    
    return processData(jsonData);
  } catch (error) {
    console.error('Erro ao processar Excel:', error);
    throw new Error('Erro ao processar arquivo Excel');
  }
}

// Função para processar arquivo CSV
function processCSVFile(filePath) {
  return new Promise((resolve, reject) => {
    const results = [];
    fs.createReadStream(filePath)
      .pipe(csv())
      .on('data', (data) => results.push(data))
      .on('end', () => {
        try {
          const processedData = processData(results);
          resolve(processedData);
        } catch (error) {
          reject(error);
        }
      })
      .on('error', reject);
  });
}

// Função para processar dados (Excel ou CSV)
function processData(data) {
  const currentData = readCurrentData() || {
    academia: {},
    estatisticas: {},
    membros: {},
    aulas: {},
    financeiro: {},
    metas: {},
    versao: "1.0.0"
  };

  // Processar cada linha do arquivo
  data.forEach(row => {
    // Mapear colunas para campos do sistema
    const mapping = {
      'total_membros': ['total_membros', 'membros_total', 'total_members'],
      'membros_ativos': ['membros_ativos', 'membros_activos', 'active_members'],
      'receita_mensal': ['receita_mensal', 'receita_mes', 'monthly_revenue'],
      'aulas_realizadas': ['aulas_realizadas', 'aulas_mes', 'classes_month'],
      'instrutores_ativos': ['instrutores_ativos', 'instrutores', 'instructors']
    };

    // Atualizar estatísticas
    Object.keys(mapping).forEach(field => {
      mapping[field].forEach(column => {
        if (row[column] !== undefined && row[column] !== '') {
          const value = parseFloat(row[column]) || parseInt(row[column]) || row[column];
          if (!isNaN(value)) {
            currentData.estatisticas[field] = value;
          }
        }
      });
    });

    // Processar dados específicos por tipo
    if (row.tipo === 'membro' || row.type === 'member') {
      // Processar dados de membros
      if (row.faixa_etaria || row.age_range) {
        const faixa = row.faixa_etaria || row.age_range;
        if (!currentData.membros.por_faixa_etaria) {
          currentData.membros.por_faixa_etaria = {};
        }
        currentData.membros.por_faixa_etaria[faixa] = 
          (currentData.membros.por_faixa_etaria[faixa] || 0) + 1;
      }
    }

    if (row.tipo === 'aula' || row.type === 'class') {
      // Processar dados de aulas
      const aula = row.aula || row.class || 'musculacao';
      if (!currentData.aulas[aula]) {
        currentData.aulas[aula] = { total: 0, participantes_media: 0 };
      }
      currentData.aulas[aula].total += 1;
    }
  });

  return currentData;
}

// Rotas da API

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Obter dados atuais
app.get('/api/data', (req, res) => {
  try {
    const data = readCurrentData();
    if (data) {
      res.json(data);
    } else {
      res.status(404).json({ error: 'Dados não encontrados' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Erro ao obter dados' });
  }
});

// Upload e processamento de arquivo
app.post('/api/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhum arquivo enviado' });
    }

    const filePath = req.file.path;
    const fileExt = path.extname(req.file.originalname).toLowerCase();
    
    let processedData;
    
    if (fileExt === '.csv') {
      processedData = await processCSVFile(filePath);
    } else if (['.xlsx', '.xls'].includes(fileExt)) {
      processedData = processExcelFile(filePath);
    } else {
      return res.status(400).json({ error: 'Formato de arquivo não suportado' });
    }

    // Salvar dados atualizados
    if (saveData(processedData)) {
      // Limpar arquivo temporário
      fs.unlinkSync(filePath);
      
      res.json({
        success: true,
        message: 'Dados atualizados com sucesso!',
        data: processedData,
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(500).json({ error: 'Erro ao salvar dados' });
    }

  } catch (error) {
    console.error('Erro no upload:', error);
    
    // Limpar arquivo temporário em caso de erro
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({ 
      error: 'Erro ao processar arquivo',
      details: error.message 
    });
  }
});

// Atualizar dados manualmente
app.post('/api/update', (req, res) => {
  try {
    const newData = req.body;
    if (saveData(newData)) {
      res.json({
        success: true,
        message: 'Dados atualizados com sucesso!',
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(500).json({ error: 'Erro ao salvar dados' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Erro ao atualizar dados' });
  }
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 API da Academia rodando na porta ${PORT}`);
  console.log(`📊 Endpoints disponíveis:`);
  console.log(`   GET  /health - Health check`);
  console.log(`   GET  /api/data - Obter dados atuais`);
  console.log(`   POST /api/upload - Upload de arquivo Excel/CSV`);
  console.log(`   POST /api/update - Atualizar dados manualmente`);
});

module.exports = app;

