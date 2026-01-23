select * from dibimbing_customer
select * from dibimbing_customer_address
select * from dibimbing_merchant
select * from dibimbing_order

---LATIHAN---
--Easy 1
SELECT *
FROM dibimbing_customer
ORDER BY id_pelanggan
LIMIT 5;

--Easy 2
SELECT id_pelanggan, nama
FROM dibimbing_customer
WHERE pengguna_aktif = 1;

--Easy 3
SELECT COUNT(*) AS total_pelanggan
FROM dibimbing_customer;

--Easy 4
SELECT AVG(umur) AS rata_umur_aktif
FROM dibimbing_customer
WHERE pengguna_aktif = 1;

--Easy 5
SELECT MIN(harga) AS harga_terendah,
       MAX(harga) AS harga_tertinggi
FROM dibimbing_order;

--Medium 1
SELECT
  CASE
    WHEN umur < 20 THEN 'Remaja'
    WHEN umur < 40 THEN 'Dewasa'
    ELSE 'Senior'
  END AS kategori_umur,
  COUNT(*) AS jumlah
FROM dibimbing_customer
GROUP BY
  CASE
    WHEN umur < 20 THEN 'Remaja'
    WHEN umur < 40 THEN 'Dewasa'
    ELSE 'Senior'
  END
ORDER BY jumlah DESC;

--Medium 2
SELECT o.id_order, o.tanggal_pembelian, c.nama AS nama_pelanggan, o.harga
FROM dibimbing_order o
JOIN dibimbing_customer c ON o.id_pelanggan = c.id_pelanggan
ORDER BY o.tanggal_pembelian DESC, o.id_order DESC
LIMIT 10;

--Medium 3
SELECT m.nama_merchant, SUM(o.harga) AS total_gmv
FROM dibimbing_order o
JOIN dibimbing_merchant m ON o.id_merchant = m.id_merchant
GROUP BY m.nama_merchant
ORDER BY total_gmv DESC;

--Medium 4
SELECT
  CASE WHEN o.bayar_cash = 1 THEN 'CASH' ELSE 'NONCASH' END AS tipe_bayar,
  COUNT(*) AS jumlah_transaksi,
  SUM(o.harga) AS total_harga
FROM dibimbing_order o
GROUP BY CASE WHEN o.bayar_cash = 1 THEN 'CASH' ELSE 'NONCASH' END;

--Medium 5
SELECT a.id_pelanggan, a.alamat, a.kota, a.provinsi
FROM dibimbing_customer_address a
JOIN (
  SELECT id_pelanggan, MIN(id_alamat) AS min_alamat
  FROM dibimbing_customer_address
  GROUP BY id_pelanggan
) x ON a.id_pelanggan = x.id_pelanggan AND a.id_alamat = x.min_alamat;

--Hard 1
WITH gmv AS (
  SELECT o.id_pelanggan, SUM(o.harga) AS total_gmv
  FROM dibimbing_order o
  GROUP BY o.id_pelanggan
),
ranked AS (
  SELECT
    g.id_pelanggan, g.total_gmv,
    DENSE_RANK() OVER (ORDER BY g.total_gmv DESC) AS rk
  FROM gmv g
)
SELECT r.rk, r.id_pelanggan, c.nama, r.total_gmv
FROM ranked r
JOIN dibimbing_customer c ON c.id_pelanggan = r.id_pelanggan
WHERE r.rk <= 3
ORDER BY r.rk, r.id_pelanggan;

--Hard 2
WITH t AS (
  SELECT
    o.*,
    ROW_NUMBER() OVER (
      PARTITION BY o.id_pelanggan
      ORDER BY o.tanggal_pembelian DESC, o.id_order DESC
    ) AS rn
  FROM dibimbing_order o
)
SELECT id_order, id_pelanggan, id_merchant, tanggal_pembelian, harga
FROM t
WHERE rn = 1;

--Hard 3
WITH gmv_m AS (
  SELECT id_merchant, SUM(harga) AS gmv
  FROM dibimbing_order
  GROUP BY id_merchant
),
total AS (
  SELECT SUM(gmv) AS total_gmv FROM gmv_m
)
SELECT
  m.nama_merchant,
  g.gmv,
  ROUND(100.0 * g.gmv / t.total_gmv, 2) AS pct_gmv
FROM gmv_m g
CROSS JOIN total t
JOIN dibimbing_merchant m ON m.id_merchant = g.id_merchant
ORDER BY g.gmv DESC;

--Hard 4
WITH all_tx AS (
  SELECT COUNT(*) AS cnt_all, SUM(harga) AS gmv_all
  FROM dibimbing_order
),
fraud_tx AS (
  SELECT COUNT(*) AS cnt_fraud, SUM(o.harga) AS gmv_fraud
  FROM dibimbing_order o
  JOIN dibimbing_customer c ON o.id_pelanggan = c.id_pelanggan
  WHERE c.penipu = 1
)
SELECT
  f.cnt_fraud,
  a.cnt_all,
  ROUND(100.0 * f.cnt_fraud / a.cnt_all, 2) AS pct_trx_fraud,
  f.gmv_fraud,
  a.gmv_all,
  ROUND(100.0 * f.gmv_fraud / a.gmv_all, 2) AS pct_gmv_fraud
FROM fraud_tx f CROSS JOIN all_tx a;

--Hard 5
WITH gmv_m AS (
  SELECT id_merchant, SUM(harga) AS gmv
  FROM dibimbing_order
  GROUP BY id_merchant
)
SELECT m.nama_merchant, g.gmv
FROM gmv_m g
JOIN dibimbing_merchant m ON m.id_merchant = g.id_merchant
WHERE g.gmv > (SELECT AVG(g2.gmv) FROM gmv_m g2)
ORDER BY g.gmv DESC;

---TUGAS---
--Easy 1
SELECT id_order, metode_bayar
FROM dibimbing_order
WHERE bayar_cash = 0;

--Easy 2
SELECT provinsi, COUNT(DISTINCT id_pelanggan) AS jumlah_pelanggan
FROM dibimbing_customer_address
GROUP BY provinsi
ORDER BY jumlah_pelanggan DESC;

--Easy 3
SELECT metode_bayar, COUNT(*) AS jumlah_transaksi
FROM dibimbing_order
GROUP BY metode_bayar
ORDER BY jumlah_transaksi DESC;

--Easy 4
SELECT id_merchant, SUM(harga) AS total_harga
FROM dibimbing_order
GROUP BY id_merchant
ORDER BY total_harga DESC;

--Easy 5
SELECT COUNT(*) AS pelanggan_non_penipu
FROM dibimbing_customer
WHERE penipu = 0;

--Medium 1
SELECT 'Pelanggan' AS sumber, kota AS lokasi
FROM dibimbing_customer_address
UNION
SELECT 'Merchant' AS sumber, nama_merchant AS lokasi
FROM dibimbing_merchant;

--Medium 2
WITH agg AS (
  SELECT ca.kota, o.metode_bayar, COUNT(*) AS cnt
  FROM dibimbing_order o
  JOIN dibimbing_customer_address ca ON o.id_pelanggan = ca.id_pelanggan
  GROUP BY ca.kota, o.metode_bayar
),
mx AS (
  SELECT kota, MAX(cnt) AS max_cnt
  FROM agg
  GROUP BY kota
)
SELECT a.kota, a.metode_bayar, a.cnt
FROM agg a
JOIN mx  m ON a.kota = m.kota AND a.cnt = m.max_cnt
ORDER BY a.kota, a.metode_bayar;

--Medium 3
SELECT
  CASE
    WHEN bulan_lahir IN ('Januari','Februari','Maret') THEN 'Q1'
    WHEN bulan_lahir IN ('April','Mei','Juni')          THEN 'Q2'
    WHEN bulan_lahir IN ('Juli','Agustus','September')  THEN 'Q3'
    WHEN bulan_lahir IN ('Oktober','November','Desember') THEN 'Q4'
    ELSE 'Unknown'
  END AS kuartal_lahir,
  COUNT(*) AS jumlah
FROM dibimbing_customer
GROUP BY
  CASE
    WHEN bulan_lahir IN ('Januari','Februari','Maret') THEN 'Q1'
    WHEN bulan_lahir IN ('April','Mei','Juni')          THEN 'Q2'
    WHEN bulan_lahir IN ('Juli','Agustus','September')  THEN 'Q3'
    WHEN bulan_lahir IN ('Oktober','November','Desember') THEN 'Q4'
    ELSE 'Unknown'
  END;

--Medium 4
SELECT ca.provinsi, SUM(o.harga) AS total_gmv
FROM dibimbing_order o
JOIN dibimbing_customer_address ca ON o.id_pelanggan = ca.id_pelanggan
GROUP BY ca.provinsi
ORDER BY total_gmv DESC;

--Medium 5

-- 		Hitung baris dengan UNION ALL (menghitung duplikat)
SELECT COUNT(*) AS cnt_union_all
FROM (
  SELECT kota FROM dibimbing_customer_address
  UNION ALL
  SELECT kota FROM dibimbing_customer_address
) t;

-- 		Hitung baris unik dengan UNION (menghapus duplikat)
SELECT COUNT(*) AS cnt_union
FROM (
  SELECT kota FROM dibimbing_customer_address
  UNION
  SELECT kota FROM dibimbing_customer_address
) t;

--Hard 1
WITH base AS (
  SELECT
    o.id_pelanggan,
    MAX(o.tanggal_pembelian) AS last_tx,
    COUNT(*) AS freq,
    SUM(o.harga) AS monetary
  FROM dibimbing_order o
  GROUP BY o.id_pelanggan
),
feat AS (
  SELECT
    b.*,
    CURRENT_DATE - b.last_tx AS recency_days
  FROM base b
),
score AS (
  SELECT
    f.*,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,   -- recency kecil lebih baik
    NTILE(5) OVER (ORDER BY freq DESC)          AS f_score,
    NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
  FROM feat f
)
SELECT
  s.id_pelanggan, s.recency_days, s.freq, s.monetary,
  s.r_score, s.f_score, s.m_score,
  (6 - s.r_score) + s.f_score + s.m_score AS total_score
FROM score s
ORDER BY total_score DESC;

--Hard 2
SELECT
  o.id_merchant,
  o.tanggal_pembelian,
  SUM(o.harga) OVER (
    PARTITION BY o.id_merchant
    ORDER BY o.tanggal_pembelian, o.id_order
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_gmv
FROM dibimbing_order o
ORDER BY o.id_merchant, o.tanggal_pembelian, o.id_order;

--Hard 3
WITH cust AS (
  SELECT
    id_pelanggan,
    EXTRACT(YEAR FROM tanggal_registrasi)::INT AS reg_year
  FROM dibimbing_customer
),
tx_year AS (
  SELECT DISTINCT
    o.id_pelanggan,
    EXTRACT(YEAR FROM o.tanggal_pembelian)::INT AS tx_year
  FROM dibimbing_order o
),
cohort AS (
  SELECT c.reg_year, COUNT(*) AS pelanggan_cohort
  FROM cust c
  GROUP BY c.reg_year
),
retained AS (
  SELECT c.reg_year, COUNT(DISTINCT c.id_pelanggan) AS pelanggan_retained
  FROM cust c
  JOIN tx_year t1 ON t1.id_pelanggan = c.id_pelanggan AND t1.tx_year = c.reg_year
  JOIN tx_year t2 ON t2.id_pelanggan = c.id_pelanggan AND t2.tx_year = c.reg_year + 1
  GROUP BY c.reg_year
)
SELECT
  co.reg_year,
  co.pelanggan_cohort,
  COALESCE(r.pelanggan_retained, 0) AS pelanggan_retained_next_year,
  ROUND(100.0 * COALESCE(r.pelanggan_retained, 0) / NULLIF(co.pelanggan_cohort,0), 2) AS retention_pct
FROM cohort co
LEFT JOIN retained r ON r.reg_year = co.reg_year
ORDER BY co.reg_year;

--Hard 4
WITH agg AS (
  SELECT ca.provinsi, o.metode_bayar, COUNT(*) AS cnt
  FROM dibimbing_order o
  JOIN dibimbing_customer_address ca ON o.id_pelanggan = ca.id_pelanggan
  GROUP BY ca.provinsi, o.metode_bayar
),
ranked AS (
  SELECT
    provinsi, metode_bayar, cnt,
    ROW_NUMBER() OVER (
      PARTITION BY provinsi
      ORDER BY cnt DESC, metode_bayar ASC
    ) AS rn
  FROM agg
)
SELECT provinsi, metode_bayar, cnt
FROM ranked
WHERE rn = 1
ORDER BY provinsi;
