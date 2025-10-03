class AppConfig {
  static bool _useLocalMode = false;
  
  static bool get useLocalMode => _useLocalMode;
  
  static void setLocalMode(bool value) {
    _useLocalMode = value;
    print(value 
      ? '📱 Modo LOCAL activado - Sin conexión a internet'
      : '🌐 Modo FIRESTORE activado - Con conexión a internet'
    );
  }
  
  static String get modeDescription {
    return _useLocalMode 
      ? 'Modo Sin Conexión\nTodos los datos se almacenan localmente'
      : 'Modo Con Conexión\nDatos sincronizados con Firestore';
  }
  
  static String get modeIcon {
    return _useLocalMode ? '📱' : '🌐';
  }
}