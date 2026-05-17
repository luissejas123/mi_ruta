# 🔒 Guía de Seguridad - Mi Ruta

## Archivos Sensibles (NO COMMITEAR)

Estos archivos contienen información confidencial y **NUNCA** deben subirse a Git:

### ❌ Prohibido Commitear:
- `.env` - Variables de entorno locales
- `google-services.json` - Configuración de Firebase (Android)
- `GoogleService-Info.plist` - Configuración de Firebase (iOS)
- `*.pem`, `*.key`, `*.p12` - Certificados y claves privadas
- `debug.keystore` - Keystore de Android
- Archivos `.backup`, `.tmp`, `.secret`

### ✅ Permitido Commitear:
- `.env.example` - Plantilla de variables (sin datos reales)
- `pubspec.yaml` - Dependencias del proyecto
- `google-services.json.example` - Plantilla de configuración

## Configuración Inicial

### Para Nuevos Desarrolladores:

1. **Clonar el repositorio:**
   ```bash
   git clone <repo-url>
   cd mi_ruta
   ```

2. **Copiar archivos de ejemplo:**
   ```bash
   cp .env.example .env
   cp android/app/google-services.json.example android/app/google-services.json (si existe)
   ```

3. **Llenar con datos reales:**
   - Editar `.env` con tus credenciales de Firebase
   - Descargar `google-services.json` desde Firebase Console
   - Descargar `GoogleService-Info.plist` desde Firebase Console (para iOS)

## Firebase Credentials

### Obtener Credenciales:
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. **Para Android:** Descarga `google-services.json`
4. **Para iOS:** Descarga `GoogleService-Info.plist`
5. Coloca en las rutas correctas (se ignoran en Git automáticamente)

## Verificación de Seguridad

Antes de hacer commit, verifica que no haya archivos sensibles:

```bash
# Ver archivos que se van a commitear
git status

# Ver diferencias
git diff

# Verificar que .env y google-services.json NO aparezcan
```

## En Caso de Fuga Accidental

Si accidentalmente commiteaste un archivo sensible:

```bash
# Eliminar del historial de Git
git rm --cached archivo-sensible.ext
git commit -m "🔒 Remove sensitive file from git history"

# Generar nuevas credenciales en Firebase
# Actualizar los tokens/claves
```

## Checklist de Seguridad

- [ ] `.env` está lleno con valores reales pero NO commiteado
- [ ] `google-services.json` está en `.gitignore`
- [ ] No hay archivos `.key` o `.pem` en el repositorio
- [ ] `.env.example` no contiene datos reales
- [ ] El equipo tiene acceso a las credenciales por otro medio seguro
- [ ] Se ejecutó `git status` antes de hacer push

## Preguntas Frecuentes

**P: ¿Por qué el `.env` se ignora en Git?**
R: Porque contiene datos sensibles que no deben ser públicos.

**P: ¿Cómo comparten credenciales los desarrolladores?**
R: Usa un gestor de secretos como 1Password, LastPass, o mantén un documento privado en Google Drive.

**P: ¿Qué pasa si olvido la contraseña de Firebase?**
R: Resetéala desde la [Consola de Firebase](https://console.firebase.google.com/).

---

**Última actualización:** 29 de abril de 2026
