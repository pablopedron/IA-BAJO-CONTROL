-- =====================================================================
--  BBDD: gestion_combustible
--  Motor objetivo: MariaDB >= 10.2.1 (también válido en MySQL >= 8.0.16)
--  Requisitos: CHECK reales (10.2.1+), funciones de ventana (10.2+)
-- =====================================================================

DROP DATABASE IF EXISTS gestion_combustible;
CREATE DATABASE gestion_combustible
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE gestion_combustible;

-- =====================================================================
-- 1. TABLAS MAESTRAS / CATÁLOGOS
-- =====================================================================

CREATE TABLE tipo_iva (
  id_iva      TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(40)      NOT NULL,
  porcentaje  DECIMAL(5,2)     NOT NULL,
  PRIMARY KEY (id_iva),
  CONSTRAINT uq_iva_nombre UNIQUE (nombre),
  CONSTRAINT ck_iva_pct CHECK (porcentaje BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE categoria_producto (
  id_categoria SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(80)       NOT NULL,
  descripcion  VARCHAR(255)      NULL,
  PRIMARY KEY (id_categoria),
  CONSTRAINT uq_categoria_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE tipo_combustible (
  id_combustible TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(40)      NOT NULL,
  unidad         ENUM('L','KWH','KG') NOT NULL DEFAULT 'L',
  PRIMARY KEY (id_combustible),
  CONSTRAINT uq_combustible_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

-- =====================================================================
-- 2. CLIENTES
-- =====================================================================

CREATE TABLE cliente (
  id_cliente   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo         ENUM('EMPRESA','AUTONOMO','PARTICULAR') NOT NULL DEFAULT 'EMPRESA',
  razon_social VARCHAR(150) NOT NULL,
  nif          VARCHAR(20)  NOT NULL,
  email        VARCHAR(150) NOT NULL,
  telefono     VARCHAR(25)  NULL,
  fecha_alta   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo       BOOLEAN      NOT NULL DEFAULT 1,
  PRIMARY KEY (id_cliente),
  CONSTRAINT uq_cliente_nif   UNIQUE (nif),
  CONSTRAINT uq_cliente_email UNIQUE (email)
) ENGINE=InnoDB;

CREATE TABLE direccion (
  id_direccion  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente    INT UNSIGNED NOT NULL,
  tipo          ENUM('FISCAL','ENVIO','OTRA') NOT NULL DEFAULT 'FISCAL',
  linea1        VARCHAR(150) NOT NULL,
  linea2        VARCHAR(150) NULL,
  codigo_postal VARCHAR(10)  NOT NULL,
  ciudad        VARCHAR(80)  NOT NULL,
  provincia     VARCHAR(80)  NULL,
  pais          CHAR(2)      NOT NULL DEFAULT 'ES',
  PRIMARY KEY (id_direccion),
  -- Necesaria para la FK compuesta desde pedido (dirección debe ser del mismo cliente)
  CONSTRAINT uq_direccion_cliente UNIQUE (id_direccion, id_cliente),
  CONSTRAINT fk_direccion_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE contacto (
  id_contacto  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente   INT UNSIGNED NOT NULL,
  nombre       VARCHAR(80)  NOT NULL,
  apellidos    VARCHAR(120) NULL,
  email        VARCHAR(150) NOT NULL,
  telefono     VARCHAR(25)  NULL,
  cargo        VARCHAR(80)  NULL,
  es_principal BOOLEAN      NOT NULL DEFAULT 0,
  PRIMARY KEY (id_contacto),
  CONSTRAINT uq_contacto_email UNIQUE (id_cliente, email),
  CONSTRAINT fk_contacto_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE usuario (
  id_usuario    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente    INT UNSIGNED NOT NULL,
  email         VARCHAR(150) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  rol           ENUM('ADMIN','GESTOR','LECTOR') NOT NULL DEFAULT 'LECTOR',
  activo        BOOLEAN      NOT NULL DEFAULT 1,
  ultimo_acceso DATETIME     NULL,
  PRIMARY KEY (id_usuario),
  CONSTRAINT uq_usuario_email UNIQUE (email),
  CONSTRAINT fk_usuario_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 3. PRODUCTOS, PEDIDOS, FACTURACIÓN
-- =====================================================================

CREATE TABLE producto (
  id_producto  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  sku          VARCHAR(30)  NOT NULL,
  nombre       VARCHAR(150) NOT NULL,
  descripcion  TEXT         NULL,
  id_categoria SMALLINT UNSIGNED NOT NULL,
  id_iva       TINYINT UNSIGNED  NOT NULL,
  tipo         ENUM('SOFTWARE','HARDWARE','SERVICIO') NOT NULL,
  periodicidad ENUM('UNICO','MENSUAL','ANUAL') NOT NULL DEFAULT 'UNICO',
  precio_base  DECIMAL(10,2) NOT NULL,
  stock_actual INT NOT NULL DEFAULT 0,          -- solo relevante para HARDWARE
  activo       BOOLEAN NOT NULL DEFAULT 1,
  PRIMARY KEY (id_producto),
  CONSTRAINT uq_producto_sku UNIQUE (sku),
  CONSTRAINT ck_producto_precio CHECK (precio_base >= 0),
  CONSTRAINT ck_producto_stock  CHECK (stock_actual >= 0),
  CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria)
    REFERENCES categoria_producto (id_categoria),
  CONSTRAINT fk_producto_iva FOREIGN KEY (id_iva)
    REFERENCES tipo_iva (id_iva)
) ENGINE=InnoDB;

CREATE TABLE pedido (
  id_pedido                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  numero_pedido            VARCHAR(20)  NOT NULL,
  id_cliente               INT UNSIGNED NOT NULL,
  id_direccion_facturacion INT UNSIGNED NOT NULL,
  id_direccion_envio       INT UNSIGNED NULL,
  fecha_pedido             DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('BORRADOR','CONFIRMADO','FACTURADO','CANCELADO') NOT NULL DEFAULT 'BORRADOR',
  observaciones            VARCHAR(500) NULL,
  PRIMARY KEY (id_pedido),
  CONSTRAINT uq_pedido_numero UNIQUE (numero_pedido),
  CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente),
  -- FK compuestas: la dirección debe pertenecer al MISMO cliente del pedido
  CONSTRAINT fk_pedido_dir_fact FOREIGN KEY (id_direccion_facturacion, id_cliente)
    REFERENCES direccion (id_direccion, id_cliente),
  CONSTRAINT fk_pedido_dir_envio FOREIGN KEY (id_direccion_envio, id_cliente)
    REFERENCES direccion (id_direccion, id_cliente),
  INDEX idx_pedido_cliente_fecha (id_cliente, fecha_pedido)
) ENGINE=InnoDB;

CREATE TABLE linea_pedido (
  id_pedido        INT UNSIGNED      NOT NULL,
  num_linea        SMALLINT UNSIGNED NOT NULL,
  id_producto      INT UNSIGNED      NOT NULL,
  cantidad         INT UNSIGNED      NOT NULL,
  precio_unitario  DECIMAL(10,2)     NOT NULL,   -- snapshot del precio en el momento de la venta
  descuento_pct    DECIMAL(5,2)      NOT NULL DEFAULT 0,
  porcentaje_iva   DECIMAL(5,2)      NOT NULL,   -- snapshot del IVA aplicado
  PRIMARY KEY (id_pedido, num_linea),
  CONSTRAINT ck_linea_cantidad  CHECK (cantidad > 0),
  CONSTRAINT ck_linea_precio    CHECK (precio_unitario >= 0),
  CONSTRAINT ck_linea_descuento CHECK (descuento_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_linea_iva       CHECK (porcentaje_iva BETWEEN 0 AND 100),
  CONSTRAINT fk_linea_pedido FOREIGN KEY (id_pedido)
    REFERENCES pedido (id_pedido) ON DELETE CASCADE,
  CONSTRAINT fk_linea_producto FOREIGN KEY (id_producto)
    REFERENCES producto (id_producto),
  INDEX idx_linea_producto (id_producto)
) ENGINE=InnoDB;

CREATE TABLE factura (
  id_factura             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  numero_factura         VARCHAR(20)  NOT NULL,
  id_pedido              INT UNSIGNED NOT NULL,
  tipo                   ENUM('ORDINARIA','RECTIFICATIVA') NOT NULL DEFAULT 'ORDINARIA',
  id_factura_rectificada INT UNSIGNED NULL,
  fecha_emision          DATE         NOT NULL,
  fecha_vencimiento      DATE         NOT NULL,
  estado ENUM('EMITIDA','PAGADA','VENCIDA','ANULADA') NOT NULL DEFAULT 'EMITIDA',
  PRIMARY KEY (id_factura),
  CONSTRAINT uq_factura_numero UNIQUE (numero_factura),
  CONSTRAINT ck_factura_fechas CHECK (fecha_vencimiento >= fecha_emision),
  CONSTRAINT fk_factura_pedido FOREIGN KEY (id_pedido)
    REFERENCES pedido (id_pedido),
  CONSTRAINT fk_factura_rectificada FOREIGN KEY (id_factura_rectificada)
    REFERENCES factura (id_factura),
  INDEX idx_factura_pedido (id_pedido)
) ENGINE=InnoDB;

CREATE TABLE pago (
  id_pago     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_factura  INT UNSIGNED NOT NULL,
  fecha_pago  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  importe     DECIMAL(12,2) NOT NULL,
  metodo      ENUM('TRANSFERENCIA','TARJETA','DOMICILIACION','OTRO') NOT NULL,
  referencia  VARCHAR(60)  NULL,
  PRIMARY KEY (id_pago),
  CONSTRAINT ck_pago_importe CHECK (importe > 0),
  CONSTRAINT fk_pago_factura FOREIGN KEY (id_factura)
    REFERENCES factura (id_factura),
  INDEX idx_pago_factura (id_factura)
) ENGINE=InnoDB;

CREATE TABLE licencia (
  id_licencia    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  clave_licencia VARCHAR(40)  NOT NULL,
  id_cliente     INT UNSIGNED NOT NULL,
  id_producto    INT UNSIGNED NOT NULL,
  id_pedido      INT UNSIGNED NULL,          -- NULL si es una licencia de prueba/regalo
  num_linea      SMALLINT UNSIGNED NULL,
  fecha_inicio   DATE         NOT NULL,
  fecha_fin      DATE         NULL,          -- NULL = perpetua
  max_vehiculos  INT UNSIGNED NOT NULL,
  estado ENUM('ACTIVA','SUSPENDIDA','CADUCADA','REVOCADA') NOT NULL DEFAULT 'ACTIVA',
  PRIMARY KEY (id_licencia),
  CONSTRAINT uq_licencia_clave UNIQUE (clave_licencia),
  CONSTRAINT ck_licencia_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  CONSTRAINT ck_licencia_max CHECK (max_vehiculos > 0),
  CONSTRAINT fk_licencia_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente),
  CONSTRAINT fk_licencia_producto FOREIGN KEY (id_producto)
    REFERENCES producto (id_producto),
  CONSTRAINT fk_licencia_linea FOREIGN KEY (id_pedido, num_linea)
    REFERENCES linea_pedido (id_pedido, num_linea),
  INDEX idx_licencia_cliente (id_cliente)
) ENGINE=InnoDB;

-- =====================================================================
-- 4. FLOTA Y CONSUMO DE COMBUSTIBLE (núcleo de tu software)
-- =====================================================================

CREATE TABLE vehiculo (
  id_vehiculo        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente         INT UNSIGNED NOT NULL,
  id_combustible     TINYINT UNSIGNED NOT NULL,
  matricula          VARCHAR(15)  NOT NULL,
  bastidor           CHAR(17)     NULL,
  marca              VARCHAR(60)  NOT NULL,
  modelo             VARCHAR(80)  NOT NULL,
  anio               SMALLINT UNSIGNED NULL,
  capacidad_deposito DECIMAL(6,2) NULL,
  odometro_inicial   INT UNSIGNED NOT NULL DEFAULT 0,
  activo             BOOLEAN      NOT NULL DEFAULT 1,
  PRIMARY KEY (id_vehiculo),
  CONSTRAINT uq_vehiculo_matricula UNIQUE (id_cliente, matricula),
  CONSTRAINT uq_vehiculo_bastidor  UNIQUE (id_cliente, bastidor),
  CONSTRAINT ck_vehiculo_anio CHECK (anio IS NULL OR anio BETWEEN 1950 AND 2100),
  CONSTRAINT ck_vehiculo_deposito CHECK (capacidad_deposito IS NULL OR capacidad_deposito > 0),
  CONSTRAINT fk_vehiculo_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente),
  CONSTRAINT fk_vehiculo_combustible FOREIGN KEY (id_combustible)
    REFERENCES tipo_combustible (id_combustible)
) ENGINE=InnoDB;

CREATE TABLE conductor (
  id_conductor INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente   INT UNSIGNED NOT NULL,
  nombre       VARCHAR(80)  NOT NULL,
  apellidos    VARCHAR(120) NOT NULL,
  dni          VARCHAR(20)  NOT NULL,
  email        VARCHAR(150) NULL,
  telefono     VARCHAR(25)  NULL,
  activo       BOOLEAN      NOT NULL DEFAULT 1,
  PRIMARY KEY (id_conductor),
  CONSTRAINT uq_conductor_dni UNIQUE (id_cliente, dni),
  CONSTRAINT fk_conductor_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente (id_cliente)
) ENGINE=InnoDB;

-- Relación N:M vehículo <-> conductor con histórico
CREATE TABLE asignacion_vehiculo (
  id_vehiculo  INT UNSIGNED NOT NULL,
  id_conductor INT UNSIGNED NOT NULL,
  fecha_inicio DATE         NOT NULL,
  fecha_fin    DATE         NULL,
  PRIMARY KEY (id_vehiculo, id_conductor, fecha_inicio),
  CONSTRAINT ck_asignacion_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  CONSTRAINT fk_asig_vehiculo FOREIGN KEY (id_vehiculo)
    REFERENCES vehiculo (id_vehiculo),
  CONSTRAINT fk_asig_conductor FOREIGN KEY (id_conductor)
    REFERENCES conductor (id_conductor),
  INDEX idx_asig_conductor (id_conductor)
) ENGINE=InnoDB;

CREATE TABLE estacion_servicio (
  id_estacion   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(120) NOT NULL,
  marca         VARCHAR(60)  NULL,
  direccion     VARCHAR(200) NULL,
  ciudad        VARCHAR(80)  NULL,
  codigo_postal VARCHAR(10)  NULL,
  latitud       DECIMAL(9,6) NULL,
  longitud      DECIMAL(9,6) NULL,
  PRIMARY KEY (id_estacion),
  CONSTRAINT ck_estacion_lat CHECK (latitud  IS NULL OR latitud  BETWEEN -90  AND 90),
  CONSTRAINT ck_estacion_lon CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180)
) ENGINE=InnoDB;

CREATE TABLE repostaje (
  id_repostaje    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_vehiculo     INT UNSIGNED    NOT NULL,
  id_conductor    INT UNSIGNED    NULL,
  id_estacion     INT UNSIGNED    NULL,
  id_combustible  TINYINT UNSIGNED NOT NULL,
  fecha_hora      DATETIME        NOT NULL,
  cantidad        DECIMAL(8,2)    NOT NULL,   -- litros, kWh o kg según tipo_combustible.unidad
  precio_unitario DECIMAL(6,3)    NOT NULL,
  odometro        INT UNSIGNED    NOT NULL,
  deposito_lleno  BOOLEAN         NOT NULL DEFAULT 1,
  PRIMARY KEY (id_repostaje),
  CONSTRAINT uq_repostaje_vehiculo_fecha UNIQUE (id_vehiculo, fecha_hora),
  CONSTRAINT ck_repostaje_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_repostaje_precio   CHECK (precio_unitario > 0),
  CONSTRAINT fk_repostaje_vehiculo FOREIGN KEY (id_vehiculo)
    REFERENCES vehiculo (id_vehiculo),
  CONSTRAINT fk_repostaje_conductor FOREIGN KEY (id_conductor)
    REFERENCES conductor (id_conductor),
  CONSTRAINT fk_repostaje_estacion FOREIGN KEY (id_estacion)
    REFERENCES estacion_servicio (id_estacion),
  CONSTRAINT fk_repostaje_combustible FOREIGN KEY (id_combustible)
    REFERENCES tipo_combustible (id_combustible),
  INDEX idx_repostaje_fecha (fecha_hora),
  INDEX idx_repostaje_conductor (id_conductor),
  INDEX idx_repostaje_estacion (id_estacion)
) ENGINE=InnoDB;

-- =====================================================================
-- 5. TRIGGERS: integridad que un CHECK/FK no puede expresar
--    (vehículo y conductor deben ser del mismo cliente)
-- =====================================================================

DELIMITER $$

CREATE TRIGGER trg_asignacion_bi BEFORE INSERT ON asignacion_vehiculo
FOR EACH ROW
BEGIN
  IF (SELECT id_cliente FROM vehiculo   WHERE id_vehiculo  = NEW.id_vehiculo)
  <> (SELECT id_cliente FROM conductor  WHERE id_conductor = NEW.id_conductor) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El vehiculo y el conductor pertenecen a clientes distintos';
  END IF;
END$$

CREATE TRIGGER trg_asignacion_bu BEFORE UPDATE ON asignacion_vehiculo
FOR EACH ROW
BEGIN
  IF (SELECT id_cliente FROM vehiculo   WHERE id_vehiculo  = NEW.id_vehiculo)
  <> (SELECT id_cliente FROM conductor  WHERE id_conductor = NEW.id_conductor) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El vehiculo y el conductor pertenecen a clientes distintos';
  END IF;
END$$

CREATE TRIGGER trg_repostaje_bi BEFORE INSERT ON repostaje
FOR EACH ROW
BEGIN
  IF NEW.id_conductor IS NOT NULL AND
     (SELECT id_cliente FROM vehiculo  WHERE id_vehiculo  = NEW.id_vehiculo)
  <> (SELECT id_cliente FROM conductor WHERE id_conductor = NEW.id_conductor) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El conductor del repostaje no pertenece al cliente del vehiculo';
  END IF;
END$$

CREATE TRIGGER trg_repostaje_bu BEFORE UPDATE ON repostaje
FOR EACH ROW
BEGIN
  IF NEW.id_conductor IS NOT NULL AND
     (SELECT id_cliente FROM vehiculo  WHERE id_vehiculo  = NEW.id_vehiculo)
  <> (SELECT id_cliente FROM conductor WHERE id_conductor = NEW.id_conductor) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El conductor del repostaje no pertenece al cliente del vehiculo';
  END IF;
END$$

DELIMITER ;

-- =====================================================================
-- 6. VISTAS (los datos derivados NO se almacenan: se calculan)
-- =====================================================================

CREATE VIEW vista_pedido_totales AS
SELECT t.id_pedido,
       SUM(t.base)         AS base_imponible,
       SUM(t.iva)          AS iva,
       SUM(t.base + t.iva) AS total
FROM (
  SELECT id_pedido,
         ROUND(cantidad * precio_unitario * (1 - descuento_pct / 100), 2) AS base,
         ROUND(cantidad * precio_unitario * (1 - descuento_pct / 100) * porcentaje_iva / 100, 2) AS iva
  FROM linea_pedido
) t
GROUP BY t.id_pedido;

CREATE VIEW vista_gasto_mensual_vehiculo AS
SELECT id_vehiculo,
       DATE_FORMAT(fecha_hora, '%Y-%m')               AS mes,
       COUNT(*)                                        AS num_repostajes,
       SUM(cantidad)                                   AS cantidad_total,
       SUM(ROUND(cantidad * precio_unitario, 2))       AS importe_total
FROM repostaje
GROUP BY id_vehiculo, DATE_FORMAT(fecha_hora, '%Y-%m');

CREATE VIEW vista_consumo_repostaje AS
SELECT r.id_repostaje,
       r.id_vehiculo,
       r.fecha_hora,
       r.cantidad,
       r.odometro,
       r.odometro - LAG(r.odometro) OVER (PARTITION BY r.id_vehiculo ORDER BY r.fecha_hora) AS km_recorridos,
       ROUND(
         r.cantidad / NULLIF(r.odometro - LAG(r.odometro) OVER (PARTITION BY r.id_vehiculo ORDER BY r.fecha_hora), 0) * 100
       , 2) AS consumo_cada_100km
FROM repostaje r;

CREATE VIEW vista_factura_saldo AS
SELECT f.id_factura,
       f.numero_factura,
       tot.total,
       COALESCE(SUM(p.importe), 0)              AS pagado,
       tot.total - COALESCE(SUM(p.importe), 0)  AS pendiente
FROM factura f
JOIN vista_pedido_totales tot ON tot.id_pedido = f.id_pedido
LEFT JOIN pago p ON p.id_factura = f.id_factura
GROUP BY f.id_factura, f.numero_factura, tot.total;
