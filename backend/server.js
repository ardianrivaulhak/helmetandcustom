require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

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
    try {
      await pool.query("ALTER TABLE products ALTER COLUMN image_url TYPE TEXT");
      await pool.query("ALTER TABLE products ADD COLUMN IF NOT EXISTS address TEXT");
      await pool.query("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS image_url TEXT");
      await pool.query("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS image_urls TEXT");
    } catch (e) {}
  })
  .catch(err => {
    console.error('❌ PostgreSQL error:', err.message);
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

    // For list view, only send the first image to reduce response size
    const data = result.rows.map(row => {
      if (row.image_url) {
        try {
          const images = JSON.parse(row.image_url);
          if (Array.isArray(images) && images.length > 0) {
            // Only send first image for thumbnail
            row.image_url = JSON.stringify([images[0]]);
          }
        } catch (e) {}
      }
      return row;
    });

    res.json({
      data,
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

app.post('/api/products', async (req, res) => {
  try {
    const { name, description, price, category, rating, address, images_base64 } = req.body;
    let imageUrl = null;

    // Store base64 images as data URLs in JSON array
    if (images_base64 && Array.isArray(images_base64) && images_base64.length > 0) {
      const dataUrls = images_base64.map(b64 => `data:image/jpeg;base64,${b64}`);
      imageUrl = JSON.stringify(dataUrls);
      console.log('Product images:', dataUrls.length, 'base64 images received');
    }

    console.log('Adding product:', name, price, category);
    const result = await pool.query(
      'INSERT INTO products (name, description, price, image_url, category, rating, address) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [name, description, parseFloat(price), imageUrl, category, parseFloat(rating) || 4.5, address || null]
    );
    console.log('✅ Product added:', result.rows[0].id);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('❌ Add product error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/products/:id', async (req, res) => {
  try {
    const { name, description, price, category, rating, address, images_base64 } = req.body;
    const id = req.params.id;

    let result;
    if (images_base64 && Array.isArray(images_base64) && images_base64.length > 0) {
      const dataUrls = images_base64.map(b64 => `data:image/jpeg;base64,${b64}`);
      const imageUrl = JSON.stringify(dataUrls);
      result = await pool.query(
        'UPDATE products SET name=$1, description=$2, price=$3, image_url=$4, category=$5, rating=$6, address=$7, updated_at=CURRENT_TIMESTAMP WHERE id=$8 RETURNING *',
        [name, description, parseFloat(price), imageUrl, category, parseFloat(rating) || 4.5, address || null, id]
      );
    } else {
      result = await pool.query(
        'UPDATE products SET name=$1, description=$2, price=$3, category=$4, rating=$5, address=$6, updated_at=CURRENT_TIMESTAMP WHERE id=$7 RETURNING *',
        [name, description, parseFloat(price), category, parseFloat(rating) || 4.5, address || null, id]
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

    const result = await pool.query(`
      SELECT r.*, p.name as product_name 
      FROM reviews r LEFT JOIN products p ON r.product_id = p.id 
      ORDER BY r.created_at DESC
      LIMIT $1 OFFSET $2
    `, [limit, offset]);

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

app.post('/api/reviews', async (req, res) => {
  try {
    const { product_id, user_id, user_name, comment, rating, images_base64 } = req.body;
    if (!comment || !user_name) {
      return res.status(400).json({ error: 'Nama dan komentar wajib' });
    }
    const uid = (user_id && user_id !== '0' && user_id !== 'null') ? parseInt(user_id) : null;
    const pid = (product_id && product_id !== '0' && product_id !== 'null') ? parseInt(product_id) : null;

    let imageUrlsJson = null;
    if (images_base64 && Array.isArray(images_base64) && images_base64.length > 0) {
      const dataUrls = images_base64.map(b64 => `data:image/jpeg;base64,${b64}`);
      imageUrlsJson = JSON.stringify(dataUrls);
    }

    const result = await pool.query(
      'INSERT INTO reviews (product_id, user_id, user_name, comment, rating, image_urls) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [pid, uid, user_name, comment, parseInt(rating) || 5, imageUrlsJson]
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
