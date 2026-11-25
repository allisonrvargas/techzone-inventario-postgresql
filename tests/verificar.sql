-- Verificaciones de los scripts de TechZone. Cada ASSERT falla con un mensaje si algo no se cumple.
-- Se ejecuta después de db.sql, insert.sql y procedure.sql.
DO $$
DECLARE
    v_cliente INT; v_producto INT; v_precio NUMERIC; v_stock_antes INT; v_stock_despues INT;
    v_ventas_antes INT; v_detalles_antes INT; v_total NUMERIC;
BEGIN
    -- 1. Hay datos en todas las tablas
    ASSERT (SELECT COUNT(*) FROM proveedores)    > 0, 'proveedores vacía';
    ASSERT (SELECT COUNT(*) FROM categorias)     > 0, 'categorias vacía';
    ASSERT (SELECT COUNT(*) FROM productos)      > 0, 'productos vacía';
    ASSERT (SELECT COUNT(*) FROM clientes)       > 0, 'clientes vacía';
    ASSERT (SELECT COUNT(*) FROM ventas)         > 0, 'ventas vacía';
    ASSERT (SELECT COUNT(*) FROM detalle_ventas) > 0, 'detalle_ventas vacía';

    -- 2. Coherencia de los datos de ejemplo
    ASSERT (SELECT COUNT(*) FROM detalle_ventas WHERE subtotal <> cantidad * precio_unitario) = 0,
        'hay detalles cuyo subtotal no es cantidad x precio';
    ASSERT (SELECT COUNT(*) FROM ventas v
            WHERE v.total <> (SELECT COALESCE(SUM(d.subtotal), 0) FROM detalle_ventas d WHERE d.id_venta = v.id_venta)) = 0,
        'hay ventas cuyo total no coincide con la suma de sus detalles';

    -- 3. registrar_venta: caso exitoso (descuenta stock, crea venta y detalle con el total correcto)
    SELECT id_cliente INTO v_cliente FROM clientes ORDER BY id_cliente LIMIT 1;
    SELECT id_producto, precio, stock INTO v_producto, v_precio, v_stock_antes FROM productos WHERE stock >= 2 ORDER BY id_producto LIMIT 1;
    ASSERT v_producto IS NOT NULL, 'no hay un producto con stock >= 2 para probar';
    SELECT COUNT(*) INTO v_ventas_antes FROM ventas;
    SELECT COUNT(*) INTO v_detalles_antes FROM detalle_ventas;

    CALL registrar_venta(v_cliente, v_producto, 2);

    SELECT stock INTO v_stock_despues FROM productos WHERE id_producto = v_producto;
    ASSERT v_stock_despues = v_stock_antes - 2, 'el stock no bajó en 2';
    ASSERT (SELECT COUNT(*) FROM ventas) = v_ventas_antes + 1, 'no se creó la venta';
    ASSERT (SELECT COUNT(*) FROM detalle_ventas) = v_detalles_antes + 1, 'no se creó el detalle';
    SELECT total INTO v_total FROM ventas ORDER BY id_venta DESC LIMIT 1;
    ASSERT v_total = v_precio * 2, 'el total de la venta no es precio x cantidad';

    -- 4. registrar_venta: stock insuficiente falla y no cambia nada
    BEGIN
        CALL registrar_venta(v_cliente, v_producto, v_stock_despues + 1);
        RAISE EXCEPTION 'FALLO: se aceptó una venta sin stock suficiente';
    EXCEPTION WHEN raise_exception THEN
        ASSERT SQLERRM LIKE 'ERROR: Stock insuficiente%', 'mensaje inesperado: ' || SQLERRM;
    END;
    ASSERT (SELECT stock FROM productos WHERE id_producto = v_producto) = v_stock_despues, 'el stock cambió tras una venta rechazada';
    ASSERT (SELECT COUNT(*) FROM ventas) = v_ventas_antes + 1, 'se creó una venta rechazada';

    -- 5. registrar_venta: cliente o producto inexistentes
    BEGIN
        CALL registrar_venta(-1, v_producto, 1);
        RAISE EXCEPTION 'FALLO: se aceptó un cliente inexistente';
    EXCEPTION WHEN raise_exception THEN
        ASSERT SQLERRM LIKE 'ERROR: El cliente%', 'mensaje inesperado: ' || SQLERRM;
    END;
    BEGIN
        CALL registrar_venta(v_cliente, -1, 1);
        RAISE EXCEPTION 'FALLO: se aceptó un producto inexistente';
    EXCEPTION WHEN raise_exception THEN
        ASSERT SQLERRM LIKE 'ERROR: El producto%', 'mensaje inesperado: ' || SQLERRM;
    END;

    -- 6. Las restricciones de la base rechazan datos inválidos
    BEGIN
        INSERT INTO productos (nombre, id_categoria, precio, stock, id_proveedor)
        SELECT 'Prueba', id_categoria, -1, 0, (SELECT MIN(id_proveedor) FROM proveedores) FROM categorias LIMIT 1;
        RAISE EXCEPTION 'FALLO: se aceptó un precio negativo';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO clientes (nombre, email) SELECT 'Repetido', email FROM clientes LIMIT 1;
        RAISE EXCEPTION 'FALLO: se aceptó un correo repetido';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;

    RAISE NOTICE 'TechZone: todas las verificaciones pasaron';
END $$;