# HERENCIA ARGENTINA — Sistema de Inventario y Marketplace

Aplicación web desarrollada con **Flask** y **SQLite** para la gestión integral de un negocio de venta de mates y yerba en el contexto de la asignatura "Sistemas de Información para la Manufactura". El proyecto evolucionó desde un CRUD básico de productos hacia una plataforma completa que combina **control de inventario**, **administración de usuarios y clientes**, **marketplace con carrito de compras** y **generación de reportes** en Excel y PDF.

## Descripción general

**HERENCIA ARGENTINA** permite a distintos perfiles de usuario operar sobre el mismo sistema:

- **Visitantes y clientes**: explorar el catálogo de productos, registrarse, comprar en línea y gestionar sus órdenes.
- **Supervisores y gerentes**: administrar stock, usuarios, clientes, órdenes de compra y exportar reportes operativos.

El stock se descuenta automáticamente al confirmar una compra y se restaura cuando una orden es anulada o cancelada.

## Autores:
- **Amavet, Pablo**
- **Botto, Santiago**
- **Paulon, Valentin**

## Características principales

### Inventario de productos
- CRUD completo de productos (crear, leer, actualizar, eliminar)
- Control de stock con indicadores visuales según disponibilidad
- Campos orientados al negocio: tipo de material, precio unitario, proveedor y descripción
- Reportes filtrables por stock y precio (Excel / PDF)

### Autenticación y roles
- Registro público de clientes con validación de contraseña
- Inicio y cierre de sesión con contraseñas hasheadas (Werkzeug)
- Control de acceso por rol mediante decoradores `@login_required` y `@role_required`

| Rol | Permisos principales |
|-----|----------------------|
| **Cliente** | Ver catálogo, carrito, checkout, mis órdenes, editar/anular órdenes pendientes |
| **Usuario común** | Acceso limitado (consulta de catálogo) |
| **Supervisor** | Gestión de productos, clientes, usuarios (consulta), órdenes y reportes |
| **Gerente** | Todo lo del supervisor + alta/edición/eliminación de usuarios |

### Gestión de clientes y usuarios
- CRUD de clientes (persona física o jurídica)
- CRUD de usuarios internos (solo gerente)
- Relación uno a uno entre `Usuario` (categoría `cliente`) y `Cliente`
- Creación automática de registro de cliente al dar de alta un usuario cliente

### Marketplace
- Carrito de compras en sesión
- Validación de stock antes de agregar o modificar cantidades
- Checkout con dirección de entrega
- Órdenes con estados: `pendiente_confirmacion`, `confirmada`, `en_transito`, `completada`, `cancelada`
- Clientes pueden editar órdenes pendientes y anular las no finalizadas
- Supervisores/gerentes pueden cambiar el estado de las órdenes

### Reportes
Exportación en **Excel** (openpyxl) y **PDF** (reportlab) para:
- Productos (filtros por stock y precio)
- Órdenes (filtros por fecha y monto)
- Clientes
- Usuarios (filtro opcional por categoría)

## Modelo de base de datos

La base de datos SQLite (`productos.db`) se crea automáticamente al iniciar la aplicación. Contiene **5 tablas** relacionadas:

### `producto`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer (PK) | Identificador único |
| `nombre` | String(100) | Nombre del producto |
| `cantidad` | Integer | Unidades en stock |
| `tipo_material` | String(100) | Material (ej.: calabaza, madera, acero) |
| `precio` | Float | Precio por unidad |
| `descripcion` | Text | Descripción opcional |
| `proveedor` | String(100) | Proveedor |
| `fecha_creacion` | DateTime | Fecha de alta |

### `usuario`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer (PK) | Identificador único |
| `nombre` | String(100) | Nombre completo |
| `email` | String(120) | Email único |
| `password_hash` | String(128) | Contraseña hasheada |
| `categoria` | String(20) | `cliente`, `usuario_comun`, `supervisor` o `gerente` |
| `fecha_creacion` | DateTime | Fecha de alta |

### `cliente`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer (PK) | Identificador único |
| `identificador` | String(50) | DNI, CUIT u otro identificador único |
| `tipo_persona` | String(20) | `fisica` o `juridica` |
| `nombre` | String(200) | Razón social o nombre |
| `direccion` | String(300) | Dirección |
| `telefono` | String(20) | Teléfono |
| `mail` | String(120) | Email de contacto |
| `datos_adicionales` | Text | Información extra |
| `usuario_id` | Integer (FK → `usuario.id`) | Usuario asociado (opcional, único) |
| `fecha_creacion` | DateTime | Fecha de alta |

### `orden_compra`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer (PK) | Identificador interno |
| `identificador` | Integer | Número de orden visible (desde 1000) |
| `cliente_id` | Integer (FK → `cliente.id`) | Cliente que realizó la compra |
| `fecha` | DateTime | Fecha de la orden |
| `estado` | String(30) | Estado del pedido |
| `direccion_entrega` | String(300) | Dirección de envío |

### `item_orden`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Integer (PK) | Identificador único |
| `orden_id` | Integer (FK → `orden_compra.id`) | Orden asociada |
| `producto_id` | Integer (FK → `producto.id`) | Producto incluido |
| `cantidad` | Integer | Cantidad comprada |

**Relaciones:**
- `Usuario` ↔ `Cliente`: uno a uno (opcional)
- `Cliente` → `OrdenCompra`: uno a muchos
- `OrdenCompra` ↔ `Producto`: muchos a muchos a través de `ItemOrden`

## Tecnologías utilizadas

| Componente | Tecnología |
|------------|------------|
| Backend | Python 3.x, Flask 2.3.3 |
| ORM / BD | Flask-SQLAlchemy 3.0.5, SQLite |
| Seguridad | Werkzeug 2.3.7 (hash de contraseñas) |
| Reportes Excel | openpyxl 3.1.2 |
| Reportes PDF | reportlab 4.0.7 |
| Frontend | HTML5, Bootstrap 5, Font Awesome 6, CSS personalizado |

## Instalación

### Prerrequisitos
- Python 3.7 o superior
- pip

### Pasos

1. **Clonar o descargar el proyecto**
   ```bash
   cd "Entrega 5 - WS"
   ```

2. **Crear y activar un entorno virtual (recomendado)**
   ```bash
   python -m venv venv
   source venv/bin/activate        # Linux / macOS
   # venv\Scripts\activate           # Windows
   ```

3. **Instalar dependencias**
   ```bash
   pip install -r requirements.txt
   ```

4. **Ejecutar la aplicación**
   ```bash
   python app.py
   ```

5. **Abrir en el navegador**
   ```
   http://localhost:5000
   ```

Al primer arranque se crean las tablas y un usuario **gerente** por defecto para pruebas:

| Campo | Valor |
|-------|-------|
| Email | `valeblitochile@gmail.com` |
| Contraseña | `SIMA2025` |
| Rol | Gerente |

> Cambiar la `SECRET_KEY` en `app.py` y las credenciales por defecto antes de usar en producción.

## Uso del sistema

### Catálogo (página principal `/`)
- Lista todos los productos con stock, material, precio y proveedor
- Accesible sin login; las acciones de compra y administración requieren autenticación
- Los clientes pueden agregar productos al carrito desde el catálogo

### Flujo del cliente (marketplace)
1. **Registrarse** en `/registro` o **iniciar sesión** en `/login`
2. Agregar productos al **carrito** (`/carrito`)
3. Confirmar compra en **checkout** (`/checkout`) indicando dirección de entrega
4. Consultar **mis órdenes** (`/mis-ordenes`)
5. Editar o anular órdenes en estado *Pendiente de Confirmación*

### Flujo administrativo (supervisor / gerente)
1. Gestionar **productos**: agregar, editar, eliminar y generar reportes
2. Gestionar **clientes** y consultar su información
3. Supervisar **todas las órdenes** (`/ordenes`) y actualizar su estado
4. Exportar reportes de productos, órdenes, clientes y usuarios
5. *(Solo gerente)* Administrar usuarios del sistema (`/usuarios`)

### Estados de una orden
| Estado | Descripción |
|--------|-------------|
| Pendiente de Confirmación | Recién creada; editable por el cliente |
| Confirmada | Aceptada por el negocio |
| En Tránsito | En camino al cliente |
| Completada | Entregada; no modificable |
| Cancelada | Anulada; el stock se restaura |

## Rutas principales

| Ruta | Descripción | Roles |
|------|-------------|-------|
| `/` | Catálogo de productos | Todos |
| `/login`, `/logout`, `/registro` | Autenticación | Público |
| `/agregar`, `/editar/<id>`, `/eliminar/<id>` | CRUD productos | Supervisor, Gerente |
| `/usuarios/*` | Gestión de usuarios | Gerente (escritura), Supervisor (lectura) |
| `/clientes/*` | Gestión de clientes | Supervisor, Gerente |
| `/carrito/*` | Carrito de compras | Cliente |
| `/checkout` | Finalizar compra | Cliente |
| `/mis-ordenes`, `/ordenes/ver/<id>` | Órdenes del cliente | Cliente |
| `/ordenes` | Todas las órdenes | Supervisor, Gerente |
| `/productos/generar-reporte` | Reporte de inventario | Supervisor, Gerente |
| `/ordenes/generar-reporte` | Reporte de ventas | Supervisor, Gerente |
| `/clientes/generar-reporte` | Reporte de clientes | Supervisor, Gerente |
| `/usuarios/generar-reporte` | Reporte de usuarios | Supervisor, Gerente |

## Configuración

### Base de datos
- URI: `sqlite:///productos.db` (configurada en `app.py`)
- Las tablas se crean con `db.create_all()` al iniciar la aplicación
- Para reiniciar desde cero, eliminar `productos.db` y volver a ejecutar `python app.py`

### Personalización
- **Clave secreta**: modificar `SECRET_KEY` en `app.py`
- **Estilos**: editar `static/css/theme.css` y `templates/base.html`
- **Validaciones**: reglas de contraseña y formularios en `app.py`

## Solución de problemas

### Error de dependencias
```bash
pip install --upgrade pip
pip install -r requirements.txt --force-reinstall
```

### Puerto en uso
Modificar el puerto al final de `app.py`:
```python
app.run(debug=True, port=5001)
```

### Base de datos corrupta o desactualizada
```bash
rm productos.db          # Linux / macOS
del productos.db         # Windows
python app.py            # Recrea tablas y usuario gerente
```

## Notas de desarrollo

- Modo **debug** habilitado por defecto (`debug=True`)
- El carrito se almacena en la **sesión de Flask**, no en la base de datos
- Las contraseñas se validan con mínimo 8 caracteres y al menos 1 número

---

**HERENCIA ARGENTINA** — Desarrollado con Flask y Python
