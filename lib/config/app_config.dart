// lib/config/app_config.dart

// Configuración de URL base para producción UPC y emulador Android
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

const String _UPC_URL = "https://ea3-api.upc.edu";
const String _ANDROID_EMULATOR_URL = "http://10.0.2.2:9000";

// Selecciona la URL base según plataforma:
// - Web y desktop usan siempre la URL de producción UPC (https)
// - Android emulador usa la IP especial para localhost
// - iOS, desktop, etc. usan la URL de producción
final String API_BASE_URL = kIsWeb
    ? 'https://ea3-api.upc.edu/api'
    : (Platform.isAndroid ? 'http://10.0.2.2:9000/api' : 'https://ea3-api.upc.edu/api');