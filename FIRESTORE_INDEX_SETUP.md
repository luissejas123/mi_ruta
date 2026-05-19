# 🔧 Solución: Crear Índice Compuesto en Firestore

## ⚠️ Error Encontrado

Cuando intentas acceder a `movimientos_page` o `wallet_page`, aparece este error:

```
Exception: Error obteniendo historial: [cloud_firestore/failed-precondition]
The query requires an index. You can create it here: https://console.firebase.google.com/...
```

## ✅ Solución: Crear el Índice

### Opción 1: Automáticamente desde el Error (RECOMENDADO)

1. **Copia el link del error** que aparece en rojo
2. **Abre el link** en tu navegador
3. **Firestore te abrirá la página de índices**
4. **Click en "Crear índice"** (botón azul)
5. **Espera a que se cree** (toma 1-5 minutos)
6. **Vuelve a abrir la app** - ya debería funcionar ✅

**El link tiene este patrón:**
```
https://console.firebase.google.com/v1/r/project/mi-ruta-40d4d/firestore/indexes?create_composite=...
```

---

### Opción 2: Manualmente en Firebase Console

Si prefieres crear el índice manualmente:

#### Paso 1: Ir a Firestore
1. Abre [Firebase Console](https://console.firebase.google.com)
2. Selecciona proyecto **mi-ruta-40d4d**
3. Ve a **Firestore Database** (en el menú izquierdo)

#### Paso 2: Ir a Índices
1. Click en pestaña **"Índices"** (en la parte superior)
2. Selecciona **"Índices compuestos"** (si no está visible, scroll derecha)

#### Paso 3: Crear Índice
1. Click en botón **"Crear índice"** (verde/azul)
2. Completa los campos:

   | Campo | Valor |
   |-------|-------|
   | **Colección** | `transactions` |
   | **Campo 1** | `user_id` (Ascending) |
   | **Campo 2** | `timestamp` (Descending) |

3. Click en **"Crear"**
4. Espera a que la estado cambie a **"Habilitado"** (color verde)

**Pantalla esperada:**
```
Colección: transactions
Campos:
  1. user_id - Ascending ↑
  2. timestamp - Descending ↓
Estado: Habilitado ✅
```

---

### Opción 3: Usando Firebase CLI

Si tienes instalado Firebase CLI:

```bash
firebase firestore:indexes
firebase firestore:delete-indexes
```

Luego ejecuta nuevamente la app para que Firestore te sugiera crear el índice.

---

## 🔍 ¿Por qué es Necesario?

La consulta que hace la app es:

```dart
db.collection('transactions')
  .where('user_id', isEqualTo: userId)        // ← Campo 1
  .orderBy('timestamp', descending: true)     // ← Campo 2
```

Cuando combinas **WHERE + ORDERBY** en campos diferentes, Firestore requiere un **índice compuesto** para optimizar la búsqueda.

---

## ⏱️ Tiempo de Espera

- **Creación del índice**: 1-5 minutos típicamente
- **En proyectos complejos**: hasta 30 minutos
- **Estado**: Verde (✅ Habilitado) = listo para usar

Puedes cerrar la pestaña del navegador. El proceso continúa en background.

---

## ✨ Solución Temporal (Mientras se Crea el Índice)

El código fue actualizado para usar un **fallback automático**:

1. Si el índice no existe, intentará obtener transacciones **sin ordenar**
2. Luego las ordena **en memoria en la app**
3. Esto es menos eficiente pero funciona mientras se crea el índice

Por lo tanto, **la app seguirá funcionando** aunque salga el error, solo será un poco más lenta.

---

## 🧪 Cómo Verificar que Funciona

### Antes del Índice
```
❌ Error "failed-precondition" en movimientos_page
⚠️ Usa fallback en memoria (más lento)
```

### Después de Crear el Índice
```
✅ movimientos_page carga rápido sin errores
✅ Transacciones ordenadas correctamente
✅ Sin logs de advertencia
```

---

## 📋 Checklist Rápido

- [ ] Recibiste el error "failed-precondition"
- [ ] Copiaste el link del error O creaste el índice manualmente
- [ ] Firebase Console muestra estado "Habilitado" (verde)
- [ ] Esperaste 1-5 minutos para que se cree
- [ ] Reabriste la app
- [ ] movimientos_page ahora carga correctamente ✅

---

## 🆘 Si Aún Hay Problemas

### Problema: El link del error no funciona
**Solución:** Crear manualmente (ver Opción 2 arriba)

### Problema: El estado del índice sigue en "Creando..."
**Solución:** Esperar más tiempo o recargar la página de Firebase Console

### Problema: Sigue saliendo error después de 5 minutos
**Solución:** 
1. Verificar que el índice esté en estado "Habilitado" (verde)
2. Cerrar y abrir la app nuevamente
3. Limpiar caché: `flutter clean` y `flutter pub get`
4. Reconstruir: `flutter run`

### Problema: No aparece la opción de "Crear índice"
**Solución:** Probablemente el índice ya existe. Verificar en pestaña "Índices compuestos"

---

## 💡 Nota Técnica

El SDK de Firestore detecta automáticamente cuando necesitas un índice y:
1. Rechaza la consulta
2. Proporciona un link directo para crear el índice
3. El link prefillena todos los campos automáticamente

Por eso el error es en realidad **útil** - es la forma en que Firestore te ayuda.

---

**Una vez creado el índice, movimientos_page debería funcionar perfectamente. ¿Necesitas ayuda con algo más?**
