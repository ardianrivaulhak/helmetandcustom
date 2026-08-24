require('dotenv').config();
const { Client } = require('pg');

async function initDb() {
  // Skip CREATE DATABASE if using DATABASE_URL (Render provides it)
  if (!process.env.DATABASE_URL) {
    const adminClient = new Client({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      port: process.env.DB_PORT || 5432,
      database: 'postgres',
    });

    try {
      await adminClient.connect();
      const dbCheck = await adminClient.query("SELECT 1 FROM pg_database WHERE datname = 'helmet_store'");
      if (dbCheck.rows.length === 0) {
        await adminClient.query('CREATE DATABASE helmet_store');
        console.log('✅ Database helmet_store created');
      } else {
        console.log('✅ Database helmet_store already exists');
      }
      await adminClient.end();
    } catch (err) {
      console.error('Error creating database:', err.message);
      await adminClient.end();
      process.exit(1);
    }
  } else {
    console.log('✅ Using DATABASE_URL (skipping CREATE DATABASE)');
  }

  // Connect to helmet_store and create tables
  const client = new Client(
    process.env.DATABASE_URL
      ? {
          connectionString: process.env.DATABASE_URL,
          ssl: { rejectUnauthorized: false },
        }
      : {
          host: process.env.DB_HOST || 'localhost',
          user: process.env.DB_USER || 'postgres',
          password: process.env.DB_PASSWORD || 'postgres',
          port: process.env.DB_PORT || 5432,
          database: 'helmet_store',
        }
  );

  try {
    await client.connect();

    // Create tables
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(50) DEFAULT 'customer',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DOUBLE PRECISION NOT NULL,
        image_url VARCHAR(500),
        category VARCHAR(100),
        rating DOUBLE PRECISION DEFAULT 4.5,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS reviews (
        id SERIAL PRIMARY KEY,
        product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id),
        user_name VARCHAR(255),
        comment TEXT,
        rating INTEGER DEFAULT 5,
        image_url VARCHAR(500),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS likes (
        id SERIAL PRIMARY KEY,
        product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(product_id, user_id)
      )
    `);

    console.log('✅ Tables created');

    // Insert admin if not exists
    const adminCheck = await client.query("SELECT id FROM users WHERE email = 'admin@helmet.com'");
    if (adminCheck.rows.length === 0) {
      await client.query(
        "INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4)",
        ['Admin', 'admin@helmet.com', 'admin123', 'admin']
      );
      console.log('✅ Admin user created');
    }

    // Insert 20 products if empty
    const productCheck = await client.query("SELECT COUNT(*) as total FROM products");
    if (parseInt(productCheck.rows[0].total) === 0) {
      const products = [
        ['Helm Bogo Hijau', 'Helm bogo classic warna hijau tua dengan kaca visor bening. Ukuran Allsize, cocok untuk pria dan wanita.', 150000, 'helm1.jpg', 'Half-face', 4.8],
        ['Helm Bogo Hitam', 'Helm bogo hitam glossy dengan visor bening. Ukuran Allsize, desain klasik dan elegan.', 145000, 'helm2.jpg', 'Half-face', 4.7],
        ['Helm Retro Black', 'Helm retro hitam motif bintik merah dengan visor buka-tutup. Ukuran Allsize.', 175000, 'helm3.jpg', 'Open-face', 4.5],
        ['Helm Vespa Classic', 'Helm cocok untuk rider vespa classic dan motor retro. Ukuran Allsize.', 160000, 'helm4.jpg', 'Open-face', 4.6],
        ['Helm Touring Pro', 'Helm touring premium dengan ventilasi bagus untuk perjalanan jauh. Ukuran Allsize.', 250000, 'helm5.jpg', 'Full-face', 4.9],
        ['Helm Sport Racing', 'Helm sport racing dengan desain aerodinamis dan ringan. Ukuran Allsize.', 320000, 'helm6.jpg', 'Full-face', 4.9],
        ['Helm Classic Brown', 'Helm retro warna cokelat klasik dengan visor bening. Ukuran Allsize.', 165000, 'helm1.jpg', 'Open-face', 4.4],
        ['Helm Street Fighter', 'Helm street fighter hitam doff keren untuk daily use. Ukuran Allsize.', 195000, 'helm2.jpg', 'Half-face', 4.6],
        ['Helm Urban Grey', 'Helm urban warna abu-abu dengan desain minimalis. Ukuran Allsize.', 140000, 'helm3.jpg', 'Half-face', 4.3],
        ['Helm Cafe Racer', 'Helm cafe racer vintage untuk motor klasik. Ukuran Allsize.', 220000, 'helm4.jpg', 'Open-face', 4.7],
        ['Helm Motocross X1', 'Helm motocross dengan peak visor dan ventilasi maksimal. Ukuran Allsize.', 280000, 'helm5.jpg', 'Full-face', 4.8],
        ['Helm Adventure Trail', 'Helm adventure untuk touring dan off-road. Ukuran Allsize.', 350000, 'helm6.jpg', 'Full-face', 4.9],
        ['Helm Kids Blue', 'Helm anak warna biru dengan stiker kartun. Ukuran Allsize anak.', 95000, 'helm1.jpg', 'Half-face', 4.5],
        ['Helm Ladies Pink', 'Helm wanita warna pink soft elegan. Ukuran Allsize.', 155000, 'helm2.jpg', 'Half-face', 4.6],
        ['Helm Carbon Pro', 'Helm berbahan carbon fiber ultra ringan. Ukuran Allsize.', 450000, 'helm3.jpg', 'Full-face', 4.9],
        ['Helm Retro Cream', 'Helm retro warna cream classic dengan goggle. Ukuran Allsize.', 185000, 'helm4.jpg', 'Open-face', 4.5],
        ['Helm Double Visor', 'Helm double visor hitam untuk proteksi UV. Ukuran Allsize.', 210000, 'helm5.jpg', 'Half-face', 4.7],
        ['Helm Racing GP', 'Helm racing full face replica GP series. Ukuran Allsize.', 380000, 'helm6.jpg', 'Full-face', 4.8],
        ['Helm Modular Flip', 'Helm modular flip-up untuk kemudahan. Ukuran Allsize.', 275000, 'helm1.jpg', 'Full-face', 4.6],
        ['Helm Military Green', 'Helm military style warna hijau army. Ukuran Allsize.', 170000, 'helm2.jpg', 'Half-face', 4.4],
      ];

      for (const p of products) {
        await client.query(
          'INSERT INTO products (name, description, price, image_url, category, rating) VALUES ($1, $2, $3, $4, $5, $6)',
          p
        );
      }
      console.log('✅ 20 products inserted');
    }

    // Insert dummy reviews if empty
    const reviewCheck = await client.query("SELECT COUNT(*) as total FROM reviews");
    if (parseInt(reviewCheck.rows[0].total) === 0) {
      const reviews = [
        [1, 'Andi Pratama', 'Helm nya bagus banget, kualitas oke punya. Visor bening dan nyaman dipakai harian. Recommended!', 5],
        [2, 'Siti Rahayu', 'Barang sesuai foto, helm glossy nya keren. Packing juga aman sampai rumah.', 5],
        [3, 'Budi Santoso', 'Suka banget sama motifnya, keren abis. Ukurannya pas di kepala, gak kebesaran.', 4],
        [4, 'Dewi Lestari', 'Cocok banget buat vespa saya, tampilan jadi makin klasik. Seller ramah dan fast response.', 5],
        [5, 'Riko Wijaya', 'Helm touring yang ringan dan ventilasi nya mantap. Worth the price banget.', 4],
        [6, 'Maya Putri', 'Keren banget helmnya! Ringan dan aerodinamis. Pengiriman cepat dan aman.', 5],
        [1, 'Doni Saputra', 'Warna hijau nya bagus, cocok buat harian. Visor juga jernih.', 4],
        [2, 'Rina Marlina', 'Helm hitam glossy nya elegan. Saya puas banget sama kualitasnya.', 5],
        [3, 'Agus Hermawan', 'Desain retro nya mantap, bikin tampilan makin kece di jalan.', 5],
        [4, 'Linda Kusuma', 'Buat nemenin naik vespa tiap hari. Nyaman dan ringan.', 4],
        [5, 'Fajar Nugroho', 'Helm touring terbaik di harga segini. Ventilasi oke, ga gerah.', 5],
        [6, 'Nita Anggraini', 'Racing style nya keren. Suami suka banget. Pasti beli lagi.', 5],
        [7, 'Hendra Gunawan', 'Classic brown nya elegan banget. Cocok buat cafe racer.', 4],
        [8, 'Yuni Astuti', 'Street fighter look nya keren. Anak saya suka.', 4],
        [9, 'Bayu Pratama', 'Simpel dan minimalis. Cocok buat matic sehari-hari.', 4],
        [10, 'Mega Sari', 'Cafe racer vintage nya authentic banget. Love it!', 5],
        [11, 'Toni Setiawan', 'Motocross helmet terbaik. Ventilasi mantap buat off-road.', 5],
        [12, 'Ani Widya', 'Adventure helmet ini worth it banget untuk touring jauh.', 5],
        [13, 'Rizki Ramadhan', 'Beli buat anak, dia seneng banget warna birunya.', 5],
        [14, 'Sinta Dewi', 'Pink nya cantik! Akhirnya nemu helm yang cocok buat cewek.', 5],
      ];

      for (const r of reviews) {
        await client.query(
          'INSERT INTO reviews (product_id, user_name, comment, rating) VALUES ($1, $2, $3, $4)',
          r
        );
      }
      console.log('✅ 20 dummy reviews inserted');
    }

    await client.end();
    console.log('\n🎉 Database initialization complete!');
  } catch (err) {
    console.error('Error:', err.message);
    await client.end();
    process.exit(1);
  }
}

initDb();
