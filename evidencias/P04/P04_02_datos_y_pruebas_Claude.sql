-- =====================================================================
--  Datos de ejemplo + pruebas de integridad
--  Ejecutar DESPUÉS de 01_esquema.sql
--  Parte A: debe ejecutarse sin errores.
--  Parte B: cada sentencia DEBE fallar con el error indicado.
--           Ejecútalas una a una (o con: mariadb --force ...).
-- =====================================================================

USE gestion_combustible;

-- ---------------------------------------------------------------------
-- PARTE A: DATOS VÁLIDOS
-- ---------------------------------------------------------------------

INSERT INTO tipo_iva (nombre, porcentaje) VALUES
  ('General', 21.00), ('Reducido', 10.00), ('Exento', 0.00);

INSERT INTO categoria_producto (nombre, descripcion) VALUES
  ('Software de flotas',   'Licencias de la plataforma de gestión de combustible'),
  ('Hardware telemetría',  'Dispositivos OBD-II / GPS'),
  ('Servicios',            'Implantación, formación y soporte');

INSERT INTO tipo_combustible (nombre, unidad) VALUES
  ('Gasolina 95', 'L'), ('Diésel', 'L'), ('GLP', 'L'), ('Eléctrico', 'KWH');

INSERT INTO producto (sku, nombre, id_categoria, id_iva, tipo, periodicidad, precio_base, stock_actual) VALUES
  ('SW-FLOTA-BAS', 'FuelControl Básico (por vehículo)', 1, 1, 'SOFTWARE', 'MENSUAL', 4.90, 0),
  ('HW-OBD-01',    'Dispositivo OBD-II GPS',            2, 1, 'HARDWARE', 'UNICO',  59.00, 120),
  ('SV-IMPL-01',   'Implantación y formación',          3, 1, 'SERVICIO', 'UNICO', 450.00, 0);

INSERT INTO cliente (id_cliente, tipo, razon_social, nif, email, telefono) VALUES
  (1, 'EMPRESA', 'Transportes García S.L.',    'B12345678', 'admin@transportesgarcia.example', '931234567'),
  (2, 'EMPRESA', 'Logística Mediterránea S.A.', 'A87654321', 'info@logmed.example', NULL);

INSERT INTO direccion (id_direccion, id_cliente, tipo, linea1, codigo_postal, ciudad, provincia) VALUES
  (1, 1, 'FISCAL', 'Calle Mayor 1',        '08001', 'Barcelona', 'Barcelona'),
  (2, 1, 'ENVIO',  'Polígono Norte, nave 4','08110', 'Montcada',  'Barcelona'),
  (3, 2, 'FISCAL', 'Avenida del Puerto 20', '46002', 'Valencia',  'Valencia');

INSERT INTO contacto (id_cliente, nombre, apellidos, email, es_principal) VALUES
  (1, 'Marta', 'García Ruiz', 'marta@transportesgarcia.example', 1);

INSERT INTO usuario (id_cliente, email, password_hash, rol) VALUES
  (1, 'marta@transportesgarcia.example', '$2y$10$hashdeejemplo', 'ADMIN');

INSERT INTO pedido (id_pedido, numero_pedido, id_cliente, id_direccion_facturacion, id_direccion_envio, estado) VALUES
  (1, 'PED-2026-0001', 1, 1, 2, 'CONFIRMADO');

INSERT INTO linea_pedido (id_pedido, num_linea, id_producto, cantidad, precio_unitario, descuento_pct, porcentaje_iva) VALUES
  (1, 1, 1, 10,   4.90,  0, 21),
  (1, 2, 2, 10,  59.00, 10, 21),
  (1, 3, 3,  1, 450.00,  0, 21);

INSERT INTO factura (id_factura, numero_factura, id_pedido, fecha_emision, fecha_vencimiento) VALUES
  (1, 'F-2026-0001', 1, '2026-11-17', '2026-12-17');

INSERT INTO pago (id_factura, importe, metodo, referencia) VALUES
  (1, 500.00, 'TRANSFERENCIA', 'TRF-0001');

INSERT INTO licencia (clave_licencia, id_cliente, id_producto, id_pedido, num_linea, fecha_inicio, fecha_fin, max_vehiculos) VALUES
  ('FC-BAS-2026-AAAA-0001', 1, 1, 1, 1, '2026-11-17', '2027-11-16', 10);

INSERT INTO vehiculo (id_vehiculo, id_cliente, id_combustible, matricula, marca, modelo, anio, capacidad_deposito, odometro_inicial) VALUES
  (1, 1, 2, '1234ABC', 'Renault', 'Master', 2022, 80.00, 120000),
  (2, 2, 1, '5678DEF', 'Seat',    'Ibiza',  2020, 40.00,  60000);

INSERT INTO conductor (id_conductor, id_cliente, nombre, apellidos, dni) VALUES
  (1, 1, 'Luis',  'Pérez Soto',   '11111111A'),
  (2, 2, 'Ana',   'Martín Vidal', '22222222B');

INSERT INTO asignacion_vehiculo (id_vehiculo, id_conductor, fecha_inicio) VALUES
  (1, 1, '2026-01-01');

INSERT INTO estacion_servicio (id_estacion, nombre, marca, ciudad, latitud, longitud) VALUES
  (1, 'Estación Diagonal', 'Repsol', 'Barcelona', 41.390205, 2.154007);

INSERT INTO repostaje (id_vehiculo, id_conductor, id_estacion, id_combustible, fecha_hora, cantidad, precio_unitario, odometro) VALUES
  (1, 1, 1, 2, '2026-11-01 08:30:00', 62.50, 1.559, 120400),
  (1, 1, 1, 2, '2026-11-08 18:10:00', 58.20, 1.571, 121100),
  (1, 1, 1, 2, '2026-11-15 07:45:00', 60.00, 1.549, 121800);

-- Comprobaciones de las vistas (deben devolver filas coherentes)
SELECT * FROM vista_pedido_totales;
SELECT * FROM vista_factura_saldo;
SELECT * FROM vista_gasto_mensual_vehiculo;
SELECT * FROM vista_consumo_repostaje ORDER BY id_vehiculo, fecha_hora;

-- ---------------------------------------------------------------------
-- PARTE B: PRUEBAS NEGATIVAS (cada una DEBE dar error)
-- ---------------------------------------------------------------------

-- B1. NIF duplicado -> ERROR 1062 (Duplicate entry)
INSERT INTO cliente (razon_social, nif, email) VALUES ('Otra S.L.', 'B12345678', 'otra@example.com');

-- B2. Pedido del cliente 1 con la dirección fiscal del cliente 2 -> ERROR 1452 (FK compuesta)
INSERT INTO pedido (numero_pedido, id_cliente, id_direccion_facturacion) VALUES ('PED-2026-0002', 1, 3);

-- B3. Línea con cantidad 0 -> ERROR 4025 (MariaDB) / 3819 (MySQL): CHECK
INSERT INTO linea_pedido (id_pedido, num_linea, id_producto, cantidad, precio_unitario, porcentaje_iva)
VALUES (1, 4, 1, 0, 4.90, 21);

-- B4. Línea con producto inexistente -> ERROR 1452 (FK)
INSERT INTO linea_pedido (id_pedido, num_linea, id_producto, cantidad, precio_unitario, porcentaje_iva)
VALUES (1, 5, 999, 1, 10.00, 21);

-- B5. Borrar un cliente con pedidos -> ERROR 1451 (FK RESTRICT)
DELETE FROM cliente WHERE id_cliente = 1;

-- B6. Pago con importe negativo -> ERROR 4025 / 3819: CHECK
INSERT INTO pago (id_factura, importe, metodo) VALUES (1, -10.00, 'TARJETA');

-- B7. Factura que vence antes de emitirse -> ERROR 4025 / 3819: CHECK
INSERT INTO factura (numero_factura, id_pedido, fecha_emision, fecha_vencimiento)
VALUES ('F-2026-0002', 1, '2026-12-01', '2026-11-01');

-- B8. Asignar el conductor del cliente 2 al vehículo del cliente 1 -> ERROR 1644 (trigger)
INSERT INTO asignacion_vehiculo (id_vehiculo, id_conductor, fecha_inicio) VALUES (1, 2, '2026-11-17');

-- B9. Repostaje con conductor de otro cliente -> ERROR 1644 (trigger)
INSERT INTO repostaje (id_vehiculo, id_conductor, id_combustible, fecha_hora, cantidad, precio_unitario, odometro)
VALUES (1, 2, 2, '2026-11-16 10:00:00', 30.00, 1.55, 121900);

-- B10. Matrícula duplicada dentro del mismo cliente -> ERROR 1062
INSERT INTO vehiculo (id_cliente, id_combustible, matricula, marca, modelo) VALUES (1, 2, '1234ABC', 'Ford', 'Transit');

-- B11. Dos repostajes del mismo vehículo en el mismo instante -> ERROR 1062
INSERT INTO repostaje (id_vehiculo, id_combustible, fecha_hora, cantidad, precio_unitario, odometro)
VALUES (1, 2, '2026-11-15 07:45:00', 10.00, 1.55, 121850);

-- B12. Licencia con fecha fin anterior al inicio -> ERROR 4025 / 3819: CHECK
INSERT INTO licencia (clave_licencia, id_cliente, id_producto, fecha_inicio, fecha_fin, max_vehiculos)
VALUES ('FC-TEST-0002', 1, 1, '2026-11-17', '2026-01-01', 5);
