require('dotenv').config();
const { Pool } = require('pg');

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

const products = [
  { name: 'Helm Bogo Classic Hitam', description: 'Helm bogo classic warna hitam polos, cocok untuk daily use. Ukuran allsize dengan busa tebal nyaman dipakai.', price: 185000, category: 'Half-face', rating: 4.5 },
  { name: 'Helm Retro Chrome Silver', description: 'Helm retro dengan finishing chrome silver mengkilap. Dilengkapi kaca visor bening anti UV.', price: 250000, category: 'Open-face', rating: 4.8 },
  { name: 'Helm Full Face Racing Red', description: 'Helm full face dengan desain racing warna merah. Double visor, ventilasi udara optimal.', price: 450000, category: 'Full-face', rating: 4.7 },
  { name: 'Helm Bogo Kulit Coklat', description: 'Helm bogo dengan bahan kulit sintetis warna coklat vintage. Tampilan klasik dan elegan.', price: 220000, category: 'Half-face', rating: 4.3 },
  { name: 'Helm Open Face Navy Blue', description: 'Helm open face warna navy blue dengan stripe putih. Ringan dan nyaman untuk perjalanan jauh.', price: 275000, category: 'Open-face', rating: 4.6 },
  { name: 'Helm Full Face Black Matte', description: 'Helm full face finishing black matte premium. SNI certified, ventilasi ganda, busa removable.', price: 520000, category: 'Full-face', rating: 4.9 },
  { name: 'Helm Half Face Pink Lady', description: 'Helm half face khusus wanita warna pink pastel. Desain feminim dengan motif bunga.', price: 165000, category: 'Half-face', rating: 4.2 },
  { name: 'Helm Retro Cream Vintage', description: 'Helm retro cream dengan aksen kulit coklat. Gaya vintage 70an yang timeless.', price: 235000, category: 'Open-face', rating: 4.4 },
  { name: 'Helm Full Face White Gold', description: 'Helm full face putih dengan aksen gold. Premium quality, double visor anti fog.', price: 580000, category: 'Full-face', rating: 4.8 },
  { name: 'Helm Bogo Motif Army', description: 'Helm bogo dengan motif army/loreng hijau. Tampilan maskulin dan gagah.', price: 195000, category: 'Half-face', rating: 4.1 },
  { name: 'Helm Open Face Titanium Grey', description: 'Helm open face warna titanium grey metalik. Material ABS ringan dan kuat.', price: 310000, category: 'Open-face', rating: 4.5 },
  { name: 'Helm Full Face Carbon Fiber', description: 'Helm full face dengan material carbon fiber. Super ringan, aerodinamis, untuk rider profesional.', price: 1250000, category: 'Full-face', rating: 5.0 },
  { name: 'Helm Half Face Doff Green', description: 'Helm half face warna hijau doff. Simple dan cocok untuk riding harian.', price: 155000, category: 'Half-face', rating: 4.0 },
  { name: 'Helm Retro Polkadot', description: 'Helm retro dengan motif polkadot hitam putih. Unik dan eye-catching.', price: 210000, category: 'Open-face', rating: 4.3 },
  { name: 'Helm Full Face Dual Visor Blue', description: 'Helm full face biru metalik dengan dual visor. Inner sun visor built-in.', price: 485000, category: 'Full-face', rating: 4.6 },
  { name: 'Helm Bogo Stiker Racing', description: 'Helm bogo dengan stiker racing sporty. Warna dasar putih dengan grafis merah biru.', price: 175000, category: 'Half-face', rating: 4.2 },
  { name: 'Helm Open Face Maroon Classic', description: 'Helm open face warna maroon classic. Cocok untuk motor klasik dan cafe racer.', price: 285000, category: 'Open-face', rating: 4.7 },
  { name: 'Helm Full Face Yellow Fluo', description: 'Helm full face kuning fluorescent high visibility. Aman untuk riding malam hari.', price: 495000, category: 'Full-face', rating: 4.5 },
  { name: 'Helm Half Face Transparan', description: 'Helm half face dengan visor transparan bening. Desain minimalis dan modern.', price: 145000, category: 'Half-face', rating: 3.9 },
  { name: 'Helm Retro British Flag', description: 'Helm retro dengan motif bendera Inggris. Gaya mod British yang ikonik.', price: 245000, category: 'Open-face', rating: 4.4 },
  { name: 'Helm Full Face Red Bull Edition', description: 'Helm full face edisi spesial dengan desain racing premium. Limited edition.', price: 750000, category: 'Full-face', rating: 4.9 },
  { name: 'Helm Bogo Polos Putih', description: 'Helm bogo putih polos classic. Bisa custom stiker sesuai selera.', price: 135000, category: 'Half-face', rating: 4.0 },
  { name: 'Helm Open Face Kaca Smoke', description: 'Helm open face dengan kaca smoke gelap. Melindungi dari silau matahari.', price: 265000, category: 'Open-face', rating: 4.5 },
  { name: 'Helm Full Face AGV Replica', description: 'Helm full face replica desain AGV. Grafis colorful, cocok untuk anak muda.', price: 425000, category: 'Full-face', rating: 4.3 },
  { name: 'Helm Half Face Anak Mickey', description: 'Helm half face untuk anak-anak motif Mickey Mouse. Ringan dan aman untuk si kecil.', price: 125000, category: 'Half-face', rating: 4.6 },
];

async function seed() {
  console.log('Seeding 25 products...');
  
  for (const p of products) {
    try {
      await pool.query(
        'INSERT INTO products (name, description, price, category, rating) VALUES ($1, $2, $3, $4, $5)',
        [p.name, p.description, p.price, p.category, p.rating]
      );
      console.log(`✅ Added: ${p.name}`);
    } catch (err) {
      console.error(`❌ Error adding ${p.name}:`, err.message);
    }
  }

  console.log('\nDone! 25 products seeded.');
  process.exit(0);
}

seed();
