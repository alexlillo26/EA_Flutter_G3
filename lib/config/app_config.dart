// lib/config/app_config.dart

// URL base para la API desplegada a través del proxy de la UPC.
// Asegúrate de que esta ya incluya el /api si todas tus rutas lo usan después de la base.
// Si algunas rutas no usan /api después de la base (ej. http://ea3-api.upc.edu/auth/google),
// podrías tener dos constantes: API_BASE_URL_CON_API y API_BASE_URL_SIN_API.
const String API_BASE_URL = "http://ea3-api.upc.edu/api";

// Ejemplo si necesitaras la URL sin /api al final para alguna cosa específica:
// const String RAW_PROXY_URL = "http://ea3-api.upc.edu";