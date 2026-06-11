# 📱 KronoCore Frontend - Flutter Business Suite

Aplicación multiplataforma (Web, Android, iOS, Desktop) diseñada para la gestión integral de negocios, con un enfoque en UX moderna y rendimiento optimizado.

## 🎨 Características Principales
* **Modo Oscuro/Claro:** Implementado con `Provider` para una experiencia visual personalizada.
* **Arquitectura Controller-Service:** Separación clara entre la interfaz (UI), la lógica de control y las llamadas a la API.
* **Navegación Avanzada:** Uso de `GoRouter` para manejo de rutas profundas y protegidas.
* **Diseño Atómico:** Componentes reutilizables bajo el prefijo `Krono` (KronoCard, StatusChip, etc.).

## 🛠️ Stack Tecnológico
* **Flutter SDK 3.x**
* **Provider:** Gestión de estado global (Temas, Sesión).
* **http:** Comunicación con el Backend Spring Boot.
* **GoRouter:** Enrutamiento declarativo.
* **Intl:** Formateo de fechas y moneda local.

## ⚙️ Instalación y Configuración

### Requisitos Previos
* Flutter SDK instalado (`flutter doctor` debe estar en verde).
* Navegador Chrome o Emulador Android/iOS.

### Pasos para Ejecutar
1. **Instalar Dependencias:**
   ```bash
   flutter pub get
   ```
2. **Configurar la API:**
   - El archivo `lib/data/api_client.dart` detecta automáticamente tu entorno:
     - En **Web**: usa `localhost:8080`.
     - En **Android**: usa `10.0.2.2:8080`.
3. **Lanzar Aplicación:**
   - **Web:** `flutter run -d chrome`
   - **Móvil:** `flutter run`

## 📂 Estructura del Proyecto
* `lib/global/`: Elementos compartidos (modelos, widgets comunes, utilidades de diseño).
* `lib/data/`: Capa de datos. Contiene el `ApiClient` y los `Services` que hablan con el Backend.
* `lib/pages/`: Módulos de la aplicación. Cada carpeta contiene su `Screen` (vista) y su `Controller` (lógica).
* `lib/layout/`: Estructura base de la app (Sidebar, Navbar y navegación).

---

## 💡 Guía de Usuario Rápida
1. **Acceso:** Si es la primera vez, inicia el Backend y regístrate desde la pantalla de Login.
2. **Dashboard:** Visualiza un resumen de las métricas clave de tu negocio.
3. **Ventas:** Añade productos al carrito y procesa el pago. El stock se descontará automáticamente en el Backend.
4. **Inventario:** Gestiona tus productos y recibe alertas visuales cuando el stock sea bajo.
5. **Clientes:** Accede al historial completo y datos de contacto de tus clientes.
