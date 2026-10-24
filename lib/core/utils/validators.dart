/// Clase centralizada con validadores para todos los campos del registro
class FormValidators {
  // Expresiones regulares
  static const String _emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String _namePattern = r"^[a-záéíóúñ\s]{2,}$";
  static const String _idPattern = r'^[0-9]{5,}$'; // Al menos 5 dígitos
  static const String _phonePattern = r'^[0-9]{7,}$'; // Al menos 7 dígitos

  /// Valida nombre completo
  /// - No puede estar vacío o contener solo espacios
  /// - Solo debe contener letras y espacios
  /// - Longitud mínima 3 caracteres (ej: "Juan Pérez")
  /// - Debe tener al menos 2 palabras
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre completo es requerido';
    }

    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    if (!RegExp(_namePattern, caseSensitive: false).hasMatch(value.trim())) {
      return 'El nombre solo puede contener letras';
    }

    final parts = value.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) {
      return 'Por favor ingresa nombre y apellido';
    }

    if (parts.length > 4) {
      return 'El nombre es muy largo';
    }

    return null;
  }

  /// Valida carnet de identidad
  /// - No puede estar vacío
  /// - Solo números
  /// - Longitud: 5-12 dígitos (depende del país)
  static String? validateGovernmentId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El carnet de identidad es requerido';
    }

    final trimmed = value.trim();

    if (!RegExp(_idPattern).hasMatch(trimmed)) {
      return 'El carnet debe contener solo números (mínimo 5 dígitos)';
    }

    if (trimmed.length > 12) {
      return 'El carnet no puede exceder 12 dígitos';
    }

    return null;
  }

  /// Valida número de teléfono
  /// - No puede estar vacío
  /// - Solo números
  /// - Longitud: 7-15 dígitos (varía por país)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de teléfono es requerido';
    }

    final trimmed = value.trim();

    if (!RegExp(r'^[0-9]{7,}$').hasMatch(trimmed)) {
      return 'El teléfono debe contener solo números (mínimo 7 dígitos)';
    }

    if (trimmed.length > 15) {
      return 'El teléfono no puede exceder 15 dígitos';
    }

    return null;
  }

  /// Valida correo electrónico
  /// - No puede estar vacío
  /// - Debe cumplir formato RFC 5322 simplificado
  /// - Longitud máxima 254 caracteres
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es requerido';
    }

    final trimmed = value.trim();

    if (trimmed.length > 254) {
      return 'El correo es muy largo';
    }

    if (!RegExp(_emailPattern).hasMatch(trimmed)) {
      return 'Por favor ingresa un correo válido (ej: usuario@ejemplo.com)';
    }

    return null;
  }

  /// Valida contraseña
  /// Requisitos mínimos de seguridad:
  /// - Longitud mínima: 8 caracteres
  /// - Debe contener al menos: 1 mayúscula, 1 minúscula, 1 número
  /// - Opcionalmente: caracteres especiales recomendados (!@#$%^&*)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (value.length > 128) {
      return 'La contraseña es muy larga';
    }

    // Verifica mayúscula
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una mayúscula';
    }

    // Verifica minúscula
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una minúscula';
    }

    // Verifica número
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un número';
    }

    return null;
  }

  /// Valida que las contraseñas coincidan
  static String? validatePasswordMatch(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Valida todos los campos de registro
  /// Retorna un mapa con errores por campo
  static Map<String, String> validateAllRegistrationFields({
    required String fullName,
    required String governmentId,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final Map<String, String> errors = {};

    final nameError = validateFullName(fullName);
    if (nameError != null) errors['fullName'] = nameError;

    final idError = validateGovernmentId(governmentId);
    if (idError != null) errors['governmentId'] = idError;

    final phoneError = validatePhoneNumber(phoneNumber);
    if (phoneError != null) errors['phoneNumber'] = phoneError;

    final emailError = validateEmail(email);
    if (emailError != null) errors['email'] = emailError;

    final passwordError = validatePassword(password);
    if (passwordError != null) errors['password'] = passwordError;

    final confirmError = validatePasswordMatch(password, confirmPassword);
    if (confirmError != null) errors['confirmPassword'] = confirmError;

    return errors;
  }

  /// Verifica si todos los campos son válidos
  static bool areAllFieldsValid({
    required String fullName,
    required String governmentId,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final errors = validateAllRegistrationFields(
      fullName: fullName,
      governmentId: governmentId,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    return errors.isEmpty;
  }

  // ===============================================
  // LOGIN VALIDATORS
  // ===============================================

  /// Valida email para login
  /// - No puede estar vacío
  /// - Debe cumplir formato válido
  static String? validateLoginEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }

    final trimmed = value.trim();

    if (!RegExp(_emailPattern).hasMatch(trimmed)) {
      return 'Por favor ingresa un correo válido';
    }

    return null;
  }

  /// Valida contraseña para login
  /// - No puede estar vacía
  /// - Longitud mínima: 6 caracteres (más lenient que registro)
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    if (value.length > 128) {
      return 'La contraseña es muy larga';
    }

    return null;
  }

  /// Valida todos los campos de login
  /// Retorna un mapa con errores por campo
  static Map<String, String> validateAllLoginFields({
    required String email,
    required String password,
  }) {
    final Map<String, String> errors = {};

    final emailError = validateLoginEmail(email);
    if (emailError != null) errors['email'] = emailError;

    final passwordError = validateLoginPassword(password);
    if (passwordError != null) errors['password'] = passwordError;

    return errors;
  }

  /// Verifica si todos los campos de login son válidos
  static bool areLoginFieldsValid({
    required String email,
    required String password,
  }) {
    final errors = validateAllLoginFields(email: email, password: password);
    return errors.isEmpty;
  }

  /// Valida que el email no esté vacío o sea solo espacios
  /// Útil para validación en tiempo real
  static bool isEmailFieldNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  /// Valida que la contraseña no esté vacía
  /// Útil para validación en tiempo real
  static bool isPasswordFieldNotEmpty(String value) {
    return value.isNotEmpty;
  }
}
