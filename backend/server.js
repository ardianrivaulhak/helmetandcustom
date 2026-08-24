require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Buat folder uploads
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Multer config
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => cb(null, Date.now() + '-' + file.originalname)
});
const upload = multer({ storage });

// PostgreSQL connection
const pool = new Pool(
  process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
      }
    : {
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'postgres',
        database: process.env.DB_NAME || 'helmet_store',
        port: process.env.DB_PORT || 5432,
      }
);

pool.query('SELECT NOW()')
  .then(async () => {
    console.log('✅ PostgreSQL connected');
    // Ensure image_url column exists in reviews
    try {
      await pool.query("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS image_url VARCHAR(500)");
    } catch (e) {
      // column already exists, ignore
    }
  })
  .catch(err => {
    console.error('❌ PostgreSQL error:', err.message);
    console.error('   Jalankan "npm run init-db" terlebih dahulu');
  });

// ============ AUTH ============

app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Semua field wajib diisi' });
    }

    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'Email sudah terdaftar' });
    }

    const result = await pool.query(
      'INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4) RETURNING id, name, email, role',
      [name, email, password, 'customer']
    );
    console.log('✅ User registered:', email);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Register error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email dan password wajib diisi' });
    }

    const result = await pool.query(
      'SELECT id, name, email, role FROM users WHERE email = $1 AND password = $2',
      [email, password]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Email atau password salah' });
    }

    console.log('✅ User logged in:', email);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Login error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// ============ PRODUCTS ============

app.get('/api/products', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 8;
    const offset = (page - 1) * limit;

    const countResult = await pool.query('SELECT COUNT(*) as total FROM products');
    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / limit);

    const result = await pool.query(
      'SELECT * FROM products ORDER BY created_at DESC LIMIT $1 OFFSET $2',
      [limit, offset]
    );

    res.json({
      data: result.rows,
      page,
      limit,
      total,
      totalPages,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM products WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/products', upload.single('image'), async (req, res) => {
  try {
    const { name, description, price, category, rating } = req.body;
    const imageUrl = req.file ? req.file.filename : null;
    const result = await pool.query(
      'INSERT INTO products (name, description, price, image_url, category, rating) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [name, description, parseFloat(price), imageUrl, category, parseFloat(rating) || 4.5]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/products/:id', upload.single('image'), async (req, res) => {
  try {
    const { name, description, price, category, rating } = req.body;
    const id = req.params.id;
    let result;
    if (req.file) {
      result = await pool.query(
        'UPDATE products SET name=$1, description=$2, price=$3, image_url=$4, category=$5, rating=$6, updated_at=CURRENT_TIMESTAMP WHERE id=$7 RETURNING *',
        [name, description, parseFloat(price), req.file.filename, category, parseFloat(rating) || 4.5, id]
      );
    } else {
      result = await pool.query(
        'UPDATE products SET name=$1, description=$2, price=$3, category=$4, rating=$5, updated_at=CURRENT_TIMESTAMP WHERE id=$6 RETURNING *',
        [name, description, parseFloat(price), category, parseFloat(rating) || 4.5, id]
      );
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/products/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM products WHERE id = $1', [req.params.id]);
    res.json({ message: 'Deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============ REVIEWS ============

app.get('/api/reviews', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    const countResult = await pool.query('SELECT COUNT(*) as total FROM reviews');
    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / limit);

    let result;
    try {
      result = await pool.query(`
        SELECT r.*, p.name as product_name 
        FROM reviews r LEFT JOIN products p ON r.product_id = p.id 
        ORDER BY r.created_at DESC
        LIMIT $1 OFFSET $2
      `, [limit, offset]);
    } catch (queryErr) {
      // Fallback without image_url if column doesn't exist
      result = await pool.query(`
        SELECT r.id, r.product_id, r.user_id, r.user_name, r.comment, r.rating, r.created_at, p.name as product_name 
        FROM reviews r LEFT JOIN products p ON r.product_id = p.id 
        ORDER BY r.created_at DESC
        LIMIT $1 OFFSET $2
      `, [limit, offset]);
    }

    console.log(`📋 Reviews: page ${page}, total ${total}, returned ${result.rows.length}`);
    res.json({
      data: result.rows,
      page,
      limit,
      total,
      totalPages,
    });
  } catch (error) {
    console.error('Reviews GET error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/reviews', upload.single('image'), async (req, res) => {
  try {
    const { product_id, user_id, user_name, comment, rating } = req.body;
    if (!comment || !user_name) {
      return res.status(400).json({ error: 'Nama dan komentar wajib' });
    }
    const imageUrl = req.file ? req.file.filename : null;
    const uid = (user_id && user_id !== '0' && user_id !== 'null') ? parseInt(user_id) : null;
    const pid = (product_id && product_id !== '0' && product_id !== 'null') ? parseInt(product_id) : null;
    const result = await pool.query(
      'INSERT INTO reviews (product_id, user_id, user_name, comment, rating, image_url) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [pid, uid, user_name, comment, parseInt(rating) || 5, imageUrl]
    );
    console.log('✅ Review added by:', user_name);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Review error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/reviews/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM reviews WHERE id = $1', [req.params.id]);
    res.json({ message: 'Deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============ LIKES ============

app.get('/api/likes/product/:productId', async (req, res) => {
  try {
    const result = await pool.query('SELECT COUNT(*) as total FROM likes WHERE product_id = $1', [req.params.productId]);
    res.json({ total: parseInt(result.rows[0].total) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/likes/check/:productId/:userId', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id FROM likes WHERE product_id = $1 AND user_id = $2',
      [req.params.productId, req.params.userId]
    );
    res.json({ liked: result.rows.length > 0 });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/likes/toggle', async (req, res) => {
  try {
    const { product_id, user_id } = req.body;
    if (!product_id || !user_id) {
      return res.status(400).json({ error: 'product_id dan user_id wajib' });
    }

    const existing = await pool.query(
      'SELECT id FROM likes WHERE product_id = $1 AND user_id = $2',
      [product_id, user_id]
    );

    if (existing.rows.length > 0) {
      await pool.query('DELETE FROM likes WHERE product_id = $1 AND user_id = $2', [product_id, user_id]);
      res.json({ liked: false });
    } else {
      await pool.query('INSERT INTO likes (product_id, user_id) VALUES ($1, $2)', [product_id, user_id]);
      res.json({ liked: true });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start (local) or export (Vercel)
if (process.env.VERCEL) {
  module.exports = app;
} else {
  app.listen(PORT, () => {
    console.log(`🚀 Server: http://localhost:${PORT}`);
    console.log(`📦 Products: http://localhost:${PORT}/api/products`);
    console.log(`🔐 Auth: POST http://localhost:${PORT}/api/auth/login`);
  });
}
