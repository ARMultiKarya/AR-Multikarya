-- =========================================================================
-- DATABASE INTI: PT AR MULTI KARYA
-- Deskripsi: Skema Tabel dan Data Awal untuk Database MySQL / MariaDB
-- =========================================================================

CREATE DATABASE IF NOT EXISTS pt_ar_multikarya_db;
USE pt_ar_multikarya_db;

-- 1. Tabel Settings Profil Perusahaan
CREATE TABLE IF NOT EXISTS settings (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    bankName VARCHAR(50),
    bankAccount VARCHAR(50),
    bankHolder VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Tabel Users & Autentikasi
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    passwordHash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL COMMENT 'admin, finance, sppg, mitra',
    whatsapp VARCHAR(20) DEFAULT NULL,
    plainPassword VARCHAR(255) DEFAULT NULL,
    profilePic LONGTEXT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Tabel Supplier
CREATE TABLE IF NOT EXISTS suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Tabel Barang
CREATE TABLE IF NOT EXISTS barang (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplierId INT NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL COMMENT 'SAK, PCS, M3, BATANG, dll',
    stock DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    notes TEXT,
    CONSTRAINT fk_barang_supplier FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Tabel Price List (Riwayat Harga Standard)
CREATE TABLE IF NOT EXISTS price_lists (
    id INT AUTO_INCREMENT PRIMARY KEY,
    barangId INT NOT NULL,
    hargaBeli DECIMAL(15,2) NOT NULL,
    hargaJual DECIMAL(15,2) NOT NULL,
    effectiveDate DATE NOT NULL,
    CONSTRAINT fk_price_barang FOREIGN KEY (barangId) REFERENCES barang(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Tabel Customer / Mitra
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    company VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Tabel Purchase Order (PO)
CREATE TABLE IF NOT EXISTS po (
    id INT AUTO_INCREMENT PRIMARY KEY,
    poNumber VARCHAR(50) UNIQUE NOT NULL,
    supplierId INT NOT NULL DEFAULT 0 COMMENT '0 artinya memesan ke PT AR MULTI KARYA',
    customerId INT NOT NULL,
    poDate DATE NOT NULL,
    deliveryRequestDate DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'Draft' COMMENT 'Draft, Belum diproses, Dikirim, Diterima Parsial, Selesai, Lunas, Dibatalkan',
    jenis VARCHAR(20) NOT NULL DEFAULT 'Barang' COMMENT 'Barang / Jasa',
    deskripsi TEXT,
    createdByDetail VARCHAR(100),
    createdBy VARCHAR(50),
    budgetLimit DECIMAL(15,2) DEFAULT 0.00,
    totalAmount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    fileSuratJalan LONGTEXT COMMENT 'Menyimpan base64 atau path file Surat Jalan',
    fileInvoiceLunas LONGTEXT COMMENT 'Menyimpan base64 atau path berkas Invoice Lunas',
    CONSTRAINT fk_po_customer FOREIGN KEY (customerId) REFERENCES customers(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Tabel Detail Barang PO
CREATE TABLE IF NOT EXISTS po_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    poId INT NOT NULL,
    barangId INT NOT NULL,
    qty DECIMAL(10,2) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    total DECIMAL(15,2) NOT NULL,
    CONSTRAINT fk_poitems_po FOREIGN KEY (poId) REFERENCES po(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_poitems_barang FOREIGN KEY (barangId) REFERENCES barang(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Tabel Bukti Pembelian (Invoice Pembelian Supplier / SJ Supplier)
CREATE TABLE IF NOT EXISTS bukti_pembelian (
    id INT AUTO_INCREMENT PRIMARY KEY,
    receiptNumber VARCHAR(50) UNIQUE NOT NULL,
    poId INT DEFAULT NULL,
    supplierId INT NOT NULL,
    receiptDate DATE NOT NULL,
    fileBukti LONGTEXT COMMENT 'Menyimpan base64 bukti pembelian',
    CONSTRAINT fk_bukti_po FOREIGN KEY (poId) REFERENCES po(id) ON DELETE SET NULL,
    CONSTRAINT fk_bukti_supplier FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Tabel Detail Barang Bukti Pembelian
CREATE TABLE IF NOT EXISTS bukti_pembelian_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    buktiPembelianId INT NOT NULL,
    barangId INT NOT NULL,
    qty DECIMAL(10,2) NOT NULL,
    unitCost DECIMAL(15,2) NOT NULL,
    CONSTRAINT fk_bpitems_bp FOREIGN KEY (buktiPembelianId) REFERENCES bukti_pembelian(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bpitems_barang FOREIGN KEY (barangId) REFERENCES barang(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. Tabel Invoice Penjualan
CREATE TABLE IF NOT EXISTS invoice_jual (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoiceNumber VARCHAR(50) UNIQUE NOT NULL,
    customerId INT NOT NULL,
    invoiceDate DATE NOT NULL,
    dueDate DATE NOT NULL,
    createdByDetail VARCHAR(100),
    discount DECIMAL(15,2) DEFAULT 0.00,
    taxRate DECIMAL(5,2) DEFAULT 2.00 COMMENT 'Persentase Pajak (Default 2%)',
    subtotal DECIMAL(15,2) NOT NULL,
    taxAmount DECIMAL(15,2) NOT NULL,
    grandTotal DECIMAL(15,2) NOT NULL,
    hpp DECIMAL(15,2) NOT NULL,
    refPoId INT DEFAULT NULL,
    statusKonfirmasi VARCHAR(30) DEFAULT 'Pending' COMMENT 'Pending, Diterima',
    tanggalDiterima DATE DEFAULT NULL,
    namaPenerima VARCHAR(100) DEFAULT NULL,
    berkasPenerimaan LONGTEXT COMMENT 'Base64 berkas konfirmasi penerimaan barang oleh customer',
    CONSTRAINT fk_invoice_customer FOREIGN KEY (customerId) REFERENCES customers(id) ON UPDATE CASCADE,
    CONSTRAINT fk_invoice_po FOREIGN KEY (refPoId) REFERENCES po(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. Tabel Detail Barang Invoice Penjualan
CREATE TABLE IF NOT EXISTS invoice_jual_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoiceJualId INT NOT NULL,
    barangId INT NOT NULL,
    qty DECIMAL(10,2) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    total DECIMAL(15,2) NOT NULL,
    hpp DECIMAL(15,2) NOT NULL,
    CONSTRAINT fk_invitems_inv FOREIGN KEY (invoiceJualId) REFERENCES invoice_jual(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_invitems_barang FOREIGN KEY (barangId) REFERENCES barang(id) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 13. Tabel Chat Room / Komunikasi
CREATE TABLE IF NOT EXISTS chat_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender VARCHAR(50) NOT NULL,
    role VARCHAR(20) NOT NULL,
    channelId VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    timestamp DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 14. Tabel Audit Logs / Log Aktivitas Keamanan
CREATE TABLE IF NOT EXISTS logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    action VARCHAR(100) NOT NULL,
    details TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================================
-- SEED DATA AWAL (DEMO DATA MIGRATION)
-- =========================================================================

-- Seed Settings
INSERT INTO settings (id, name, address, phone, email, bankName, bankAccount, bankHolder)
VALUES ('pt_ar_multi_karya_profile', 'PT AR MULTI KARYA', 'Jl. Borobudur No. 12, Magelang, Jawa Tengah', '0812-3456-7890', 'finance@armultikarya.co.id', 'Bank Mandiri', '136-00-1234567-8', 'PT AR MULTI KARYA');

-- Seed Users (Password Default: username masing-masing)
-- Contoh: admin -> admin, finance -> finance, dll.
INSERT INTO users (id, username, passwordHash, role, whatsapp, plainPassword, profilePic) VALUES
(1, 'admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 'admin', '081234567890', 'admin', ''),
(2, 'finance', '8df9911e3b6eb4cf617cc18104df60f781df5a7fcf71d4715f2065842c676722', 'finance', '081234567891', 'finance', ''),
(3, 'sppg', 'e85bdeea476b5717e1659b065f6f84f4270ab1475fde39d0052115bf69a42ff9', 'sppg', '081234567892', 'sppg', ''),
(4, 'mitra', 'ef7c6cba58cf82997b990feec6b78b1cf73b4a0b3a6b1b0c46fac8a56ca70549', 'mitra', '081234567893', 'mitra', '');

-- Seed Suppliers
INSERT INTO suppliers (id, name, code, phone, email, address) VALUES
(1, 'PT Semen Sentosa', 'SPL-001', '081122334455', 'sales@semensentosa.com', 'Kawasan Industri Candi, Semarang'),
(2, 'CV Pasir Agung', 'SPL-002', '081234560001', 'cvpasiragung@gmail.com', 'Muntilan, Magelang'),
(3, 'UD Kayu Rapi', 'SPL-003', '082155667788', 'kayurapi@outlook.com', 'Secang, Magelang');

-- Seed Barang
INSERT INTO barang (id, supplierId, code, name, unit, stock, notes) VALUES
(1, 1, 'BRG-SMN', 'Semen Gresik 50kg', 'SAK', 150.00, 'Semen tipe PCC'),
(2, 2, 'BRG-PSR', 'Pasir Merapi Merah', 'M3', 45.00, 'Pasir cor kualitas premium'),
(3, 3, 'BRG-KYU', 'Balok Kayu Sengon 4x6x400', 'PCS', 80.00, 'Kayu kering oven'),
(4, 1, 'BRG-BTN', 'Besi Beton 8mm', 'BATANG', 200.00, 'Besi SNI standar beton cor');

-- Seed Price List
INSERT INTO price_lists (id, barangId, hargaBeli, hargaJual, effectiveDate) VALUES
(1, 1, 60000.00, 65000.00, '2026-07-01'),
(2, 2, 190000.00, 210000.00, '2026-07-01'),
(3, 3, 15000.00, 18000.00, '2026-07-01'),
(4, 4, 43000.00, 47000.00, '2026-07-01');

-- Seed Customers
INSERT INTO customers (id, name, company, phone, email, address) VALUES
(1, 'PT Pembangunan Jaya', 'PT Pembangunan Jaya Tbk', '087711223344', 'procurement@pembangunanjaya.com', 'Jl. Jendral Sudirman No. 5, Jakarta'),
(2, 'CV Abadi Makmur', 'CV Abadi Makmur Jaya', '089922334455', 'abadimakmur@gmail.com', 'Jl. Pemuda No. 45, Magelang');

-- Seed Purchase Order (PO)
INSERT INTO po (id, poNumber, supplierId, customerId, poDate, deliveryRequestDate, status, jenis, deskripsi, createdByDetail, createdBy, budgetLimit, totalAmount) VALUES
(1, 'PO-202607-0001', 0, 1, '2026-07-10', '2026-07-22', 'Selesai', 'Barang', 'Pembelian bahan baku cor jalan tahap 1', 'SPPG Ngawen Muntilan', 'sppg', 0.00, 7950000.00);

-- Seed PO Items
INSERT INTO po_items (id, poId, barangId, qty, price, total) VALUES
(1, 1, 1, 50.00, 65000.00, 3250000.00),
(2, 1, 4, 100.00, 47000.00, 4700000.00);

-- Seed Bukti Pembelian
INSERT INTO bukti_pembelian (id, receiptNumber, poId, supplierId, receiptDate, fileBukti) VALUES
(1, 'BP-202607-0001', 1, 1, '2026-07-12', '');

-- Seed Bukti Pembelian Items
INSERT INTO bukti_pembelian_items (id, buktiPembelianId, barangId, qty, unitCost) VALUES
(1, 1, 1, 50.00, 60000.00),
(2, 1, 4, 100.00, 43000.00);

-- Seed Invoice Penjualan
INSERT INTO invoice_jual (id, invoiceNumber, customerId, invoiceDate, dueDate, createdByDetail, discount, taxRate, subtotal, taxAmount, grandTotal, hpp, refPoId, statusKonfirmasi) VALUES
(1, 'INV-202607-0001', 1, '2026-07-15', '2026-08-15', 'SPPG Ngawen Muntilan', 100000.00, 2.00, 4300000.00, 84000.00, 4284000.00, 3950000.00, 1, 'Diterima');

-- Seed Invoice Penjualan Items
INSERT INTO invoice_jual_items (id, invoiceJualId, barangId, qty, price, total, hpp) VALUES
(1, 1, 1, 30.00, 65000.00, 1950000.00, 1800000.00),
(2, 1, 4, 50.00, 47000.00, 2350000.00, 2150000.00);

-- Seed Chat Room Messages
INSERT INTO chat_messages (id, sender, role, channelId, content, timestamp) VALUES
(1, 'admin', 'admin', 'koordinasi-umum', 'Halo semuanya, selamat datang di koordinasi internal PT AR Multi Karya!', NOW() - INTERVAL 5 HOUR),
(2, 'sppg', 'sppg', 'koordinasi-umum', 'Halo Admin! Siap berkoordinasi. PO baru untuk Semen Gresik sudah saya input ya.', NOW() - INTERVAL 4 HOUR),
(3, 'finance', 'finance', 'koordinasi-umum', 'Terima kasih informasinya. Saya segera periksa bukti pembelian dan mencocokkan stok masuk.', NOW() - INTERVAL 3 HOUR),
(4, 'mitra', 'mitra', 'koordinasi-umum', 'Terima kasih, laporan laba rugi mingguan terlihat sangat rapi dan transparan.', NOW() - INTERVAL 2 HOUR),
(5, 'sppg', 'sppg', 'divisi-po-logistik', 'Mohon info harga semen gresik untuk PO hari ini apakah ada penyesuaian?', NOW() - INTERVAL 1 HOUR);

-- Seed Logs
INSERT INTO logs (id, timestamp, action, details) VALUES
(1, NOW(), 'Sistem Diinisialisasi', 'Database MySQL berhasil di-seeding dengan data demo awal.');
