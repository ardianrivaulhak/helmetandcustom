# Backend Helmet Store

Simple Node.js + MySQL backend untuk manage produk helm.

## Setup

### 1. Install MySQL
Pastikan MySQL sudah terinstall dan running (bisa pakai XAMPP/Laragon).

### 2. Buat Database
Buka phpMyAdmin atau MySQL terminal, lalu jalankan file `database.sql`:
```sql
source database.sql
```
Atau copy-paste isi file `database.sql` ke phpMyAdmin.

### 3. Install Dependencies
```bash
cd backend
npm install
```

### 4. Konfigurasi Database
Edit file `server.js` bagian koneksi MySQL jika password beda:
```js
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',        // <-- isi password MySQL kamu
  database: 'helmet_store',
});
```

### 5. Jalankan Server
```bash
npm start
```
Server jalan di `http://localhost:3000`

## API Endpoints

| Method | URL | Keterangan |
|--------|-----|------------|
| GET | /api/products | Ambil semua produk |
| GET | /api/products/:id | Ambil produk by ID |
| POST | /api/products | Tambah produk baru |
| PUT | /api/products/:id | Update produk |
| DELETE | /api/products/:id | Hapus produk |

## Upload Gambar
Gambar diupload ke folder `uploads/` dan bisa diakses via:
```
http://localhost:3000/uploads/nama-file.jpg
```
