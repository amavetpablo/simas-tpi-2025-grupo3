-- ERP Database Schema for MariaDB based on Brainstorming clase 2
-- Encoding and SQL mode
SET NAMES utf8mb4;
SET SQL_MODE = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- Drop and create database
DROP DATABASE IF EXISTS erp_db;
CREATE DATABASE erp_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE erp_db;

-- Reference tables and core entities
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('ADMIN','MANAGER','OPERATOR','VIEWER') NOT NULL DEFAULT 'VIEWER',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150),
  phone VARCHAR(50),
  tax_id VARCHAR(50),
  billing_name VARCHAR(150),
  billing_address VARCHAR(255),
  city VARCHAR(100),
  province VARCHAR(100),
  country VARCHAR(100),
  postal_code VARCHAR(20),
  priority_level ENUM('NORMAL','ALTA','URGENTE') NOT NULL DEFAULT 'NORMAL',
  priority_until DATE NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_customers_tax (tax_id)
) ENGINE=InnoDB;

CREATE TABLE suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150),
  phone VARCHAR(50),
  tax_id VARCHAR(50),
  address VARCHAR(255),
  city VARCHAR(100),
  province VARCHAR(100),
  country VARCHAR(100),
  postal_code VARCHAR(20),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_suppliers_tax (tax_id)
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  technical_specs TEXT,
  warehouse_location VARCHAR(100),
  sale_price DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  purchase_price DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  abc_class ENUM('A','B','C') NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Current stock by product (maintained by triggers on stock_movements)
CREATE TABLE product_stock (
  product_id INT PRIMARY KEY,
  quantity_on_hand BIGINT NOT NULL DEFAULT 0,
  CONSTRAINT fk_product_stock_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Stock movements ledger
CREATE TABLE stock_movements (
  movement_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  movement_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  movement_type ENUM('PURCHASE_RECEIPT','SALE_SHIPMENT','RETURN_IN','RETURN_OUT','ADJUSTMENT') NOT NULL,
  quantity_signed BIGINT NOT NULL,
  reference_table VARCHAR(50) NULL,
  reference_id BIGINT NULL,
  note VARCHAR(255) NULL,
  CONSTRAINT fk_stock_movements_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_stock_movements_product_date (product_id, movement_date)
) ENGINE=InnoDB;

-- Purchases
CREATE TABLE purchase_orders (
  purchase_order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  supplier_id INT NOT NULL,
  order_date DATE NOT NULL,
  status ENUM('CREATED','RECEIVED','INVOICED','CANCELLED') NOT NULL DEFAULT 'CREATED',
  total_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_po_supplier_date (supplier_id, order_date)
) ENGINE=InnoDB;

CREATE TABLE purchase_order_items (
  purchase_order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  quantity BIGINT NOT NULL,
  unit_cost DECIMAL(15,2) NOT NULL,
  status ENUM('CREATED','RECEIVED','CANCELLED') NOT NULL DEFAULT 'CREATED',
  received_qty BIGINT DEFAULT NULL,
  line_total DECIMAL(15,2) GENERATED ALWAYS AS (unit_cost * quantity) VIRTUAL,
  CONSTRAINT fk_poi_po FOREIGN KEY (purchase_order_id)
    REFERENCES purchase_orders(purchase_order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_poi_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_poi_prod (product_id)
) ENGINE=InnoDB;

-- Sales
CREATE TABLE sales_orders (
  sales_order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date DATE NOT NULL,
  status ENUM('CREATED','SHIPPED','INVOICED','CANCELLED') NOT NULL DEFAULT 'CREATED',
  total_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_so_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_so_customer_date (customer_id, order_date)
) ENGINE=InnoDB;

CREATE TABLE sales_order_items (
  sales_order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  sales_order_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  quantity BIGINT NOT NULL,
  unit_price DECIMAL(15,2) NOT NULL,
  status ENUM('CREATED','SHIPPED','CANCELLED') NOT NULL DEFAULT 'CREATED',
  shipped_qty BIGINT DEFAULT NULL,
  line_total DECIMAL(15,2) GENERATED ALWAYS AS (unit_price * quantity) VIRTUAL,
  CONSTRAINT fk_soi_so FOREIGN KEY (sales_order_id)
    REFERENCES sales_orders(sales_order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_soi_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_soi_prod (product_id)
) ENGINE=InnoDB;

-- Invoices (facturas)
CREATE TABLE purchase_invoices (
  purchase_invoice_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id BIGINT NOT NULL,
  invoice_date DATE NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  status ENUM('ISSUED','PAID','CANCELLED') NOT NULL DEFAULT 'ISSUED',
  paid_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_pi_po FOREIGN KEY (purchase_order_id)
    REFERENCES purchase_orders(purchase_order_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_pi_po (purchase_order_id)
) ENGINE=InnoDB;

CREATE TABLE sales_invoices (
  sales_invoice_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  sales_order_id BIGINT NOT NULL,
  invoice_date DATE NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  status ENUM('ISSUED','PAID','CANCELLED') NOT NULL DEFAULT 'ISSUED',
  received_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_si_so FOREIGN KEY (sales_order_id)
    REFERENCES sales_orders(sales_order_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_si_so (sales_order_id)
) ENGINE=InnoDB;

-- Returns (devoluciones)
CREATE TABLE returns (
  return_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  type ENUM('SALE_RETURN','PURCHASE_RETURN') NOT NULL,
  customer_id INT NULL,
  supplier_id INT NULL,
  sales_order_id BIGINT NULL,
  purchase_order_id BIGINT NULL,
  product_id INT NOT NULL,
  quantity BIGINT NOT NULL,
  reason VARCHAR(255) NULL,
  approved TINYINT(1) NOT NULL DEFAULT 0,
  refund_amount DECIMAL(15,2) DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ret_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_ret_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_ret_so FOREIGN KEY (sales_order_id)
    REFERENCES sales_orders(sales_order_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_ret_po FOREIGN KEY (purchase_order_id)
    REFERENCES purchase_orders(purchase_order_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_ret_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Helper: ensure product_stock row exists
DELIMITER $$
CREATE TRIGGER trg_product_stock_init
AFTER INSERT ON products
FOR EACH ROW
BEGIN
  INSERT INTO product_stock(product_id, quantity_on_hand) VALUES (NEW.product_id, 0);
END $$
DELIMITER ;

-- Ledger-driven stock: insert to stock_movements updates product_stock
DELIMITER $$
CREATE TRIGGER trg_stock_movements_apply
AFTER INSERT ON stock_movements
FOR EACH ROW
BEGIN
  INSERT INTO product_stock(product_id, quantity_on_hand)
    VALUES (NEW.product_id, NEW.quantity_signed)
  ON DUPLICATE KEY UPDATE quantity_on_hand = quantity_on_hand + VALUES(quantity_on_hand);
END $$
DELIMITER ;

-- When purchase items are marked RECEIVED, add stock movement (+)
DELIMITER $$
CREATE TRIGGER trg_poi_received_insert
AFTER INSERT ON purchase_order_items
FOR EACH ROW
BEGIN
  IF NEW.status = 'RECEIVED' THEN
    INSERT INTO stock_movements(product_id, movement_type, quantity_signed, reference_table, reference_id, note)
    VALUES (NEW.product_id, 'PURCHASE_RECEIPT', COALESCE(NEW.received_qty, NEW.quantity), 'purchase_order_items', NEW.purchase_order_item_id, 'Auto: PO item received');
  END IF;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_poi_received_update
AFTER UPDATE ON purchase_order_items
FOR EACH ROW
BEGIN
  IF NEW.status = 'RECEIVED' AND (OLD.status IS NULL OR OLD.status <> 'RECEIVED') THEN
    INSERT INTO stock_movements(product_id, movement_type, quantity_signed, reference_table, reference_id, note)
    VALUES (NEW.product_id, 'PURCHASE_RECEIPT', COALESCE(NEW.received_qty, NEW.quantity), 'purchase_order_items', NEW.purchase_order_item_id, 'Auto: PO item received');
  END IF;
END $$
DELIMITER ;

-- When sales items are marked SHIPPED, add stock movement (-)
DELIMITER $$
CREATE TRIGGER trg_soi_shipped_insert
AFTER INSERT ON sales_order_items
FOR EACH ROW
BEGIN
  IF NEW.status = 'SHIPPED' THEN
    INSERT INTO stock_movements(product_id, movement_type, quantity_signed, reference_table, reference_id, note)
    VALUES (NEW.product_id, 'SALE_SHIPMENT', -1 * COALESCE(NEW.shipped_qty, NEW.quantity), 'sales_order_items', NEW.sales_order_item_id, 'Auto: SO item shipped');
  END IF;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_soi_shipped_update
AFTER UPDATE ON sales_order_items
FOR EACH ROW
BEGIN
  IF NEW.status = 'SHIPPED' AND (OLD.status IS NULL OR OLD.status <> 'SHIPPED') THEN
    INSERT INTO stock_movements(product_id, movement_type, quantity_signed, reference_table, reference_id, note)
    VALUES (NEW.product_id, 'SALE_SHIPMENT', -1 * COALESCE(NEW.shipped_qty, NEW.quantity), 'sales_order_items', NEW.sales_order_item_id, 'Auto: SO item shipped');
  END IF;
END $$
DELIMITER ;

-- When a return is approved, move stock accordingly
DELIMITER $$
CREATE TRIGGER trg_return_approved_insert
AFTER INSERT ON returns
FOR EACH ROW
BEGIN
  IF NEW.approved = 1 THEN
    IF NEW.type = 'SALE_RETURN' THEN
      INSERT INTO stock_movements(product_id, movement_type, quantity_signed, reference_table, reference_id, note)
      VALUES (NEW.product_id, 'RETURN_IN', NEW.quantity, 'returns', NEW.return_id, 'Auto: Sale return approved');
    ELSEIF NEW.type = 'PURCHASE_RETURN' THEN
      INSERT INTO stock_movements(product_id, movement_type, quantity_signed, reference_table, reference_id, note)
      VALUES (NEW.product_id, 'RETURN_OUT', -1 * NEW.quantity, 'returns', NEW.return_id, 'Auto: Purchase return approved');
    END IF;
  END IF;
END $$
DELIMITER ;

-- Views and helpful reports
CREATE OR REPLACE VIEW v_current_stock AS
SELECT p.product_id, p.sku, p.name, COALESCE(ps.quantity_on_hand, 0) AS quantity_on_hand
FROM products p
LEFT JOIN product_stock ps ON ps.product_id = p.product_id;

CREATE OR REPLACE VIEW v_sales_summary AS
SELECT so.sales_order_id, so.order_date, c.name AS customer_name, so.status, so.total_amount
FROM sales_orders so
JOIN customers c ON c.customer_id = so.customer_id;

CREATE OR REPLACE VIEW v_purchases_summary AS
SELECT po.purchase_order_id, po.order_date, s.name AS supplier_name, po.status, po.total_amount
FROM purchase_orders po
JOIN suppliers s ON s.supplier_id = po.supplier_id;

-- Basic computed totals maintenance via triggers (optional minimal updates)
DELIMITER $$
CREATE TRIGGER trg_po_items_amount
AFTER INSERT ON purchase_order_items
FOR EACH ROW
BEGIN
  UPDATE purchase_orders
  SET total_amount = (
    SELECT COALESCE(SUM(unit_cost * quantity), 0)
    FROM purchase_order_items WHERE purchase_order_id = NEW.purchase_order_id
  )
  WHERE purchase_order_id = NEW.purchase_order_id;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_so_items_amount
AFTER INSERT ON sales_order_items
FOR EACH ROW
BEGIN
  UPDATE sales_orders
  SET total_amount = (
    SELECT COALESCE(SUM(unit_price * quantity), 0)
    FROM sales_order_items WHERE sales_order_id = NEW.sales_order_id
  )
  WHERE sales_order_id = NEW.sales_order_id;
END $$
DELIMITER ;

-- Sample indexes for common queries
CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_products_name ON products(name);

-- Done


