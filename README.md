# 🖥️ TechZone · Sistema de Gestión de Inventario y Ventas (PostgreSQL)

[![CI](https://github.com/allisonrvargas/techzone-inventario-postgresql/actions/workflows/ci.yml/badge.svg)](https://github.com/allisonrvargas/techzone-inventario-postgresql/actions/workflows/ci.yml)
[![Licencia: MIT](https://img.shields.io/badge/licencia-MIT-green.svg)](LICENSE)

## Descripción del Proyecto
TechZone es una solución integral para el control de inventario, proveedores y registros de ventas en PostgreSQL. Permite automatizar la deducción de inventario, validar existencias en tiempo real y consultar reportes analíticos de rendimiento comercial.

## Cómo ejecutarlo

Requiere PostgreSQL 14 o superior. Con Docker:

```bash
docker run --name techzone -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=techzone -p 5432:5432 -d postgres:16
# espera unos segundos y luego, en este orden:
for f in db.sql insert.sql procedure.sql queries.sql; do docker exec -i techzone psql -U postgres -d techzone -v ON_ERROR_STOP=1 < $f; done
```

El orden importa: `db.sql` crea las tablas, `insert.sql` carga los datos, `procedure.sql` crea el procedimiento `registrar_venta` y `queries.sql` ejecuta las 6 consultas. El CI de este repositorio corre los cuatro scripts en cada cambio.

## Modelo Entidad-Relación

![Modelo entidad-relación](image-6.png)


## Creación de Tablas

![Creación de tablas](image-7.png)

# Evidencias de Consultas SQL (queries.sql)
1️⃣ Listar los productos con stock menor a 5 unidades.

![Resultado de la consulta 1](image.png)



2️⃣ Calcular ventas totales de un mes específico.

![Resultado de la consulta 2](image-1.png)



3️⃣ Obtener el cliente con más compras realizadas.

![Resultado de la consulta 3](image-2.png)



4️⃣ Listar los productos más vendidos.

![Resultado de la consulta 4](image-3.png)



5️⃣ Consultar ventas realizadas en un rango de fechas.

![Resultado de la consulta 5](image-4.png)




6️⃣ Identificar clientes que no han comprado en los últimos 6 meses.

![Resultado de la consulta 6](image-5.png)
