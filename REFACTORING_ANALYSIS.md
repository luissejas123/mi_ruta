# Análisis de Refactorización - Páginas Flutter

## 📊 Resumen Ejecutivo

| Página | Líneas | Estado | Prioridad |
|--------|--------|--------|-----------|
| **rutas_inicio_page.dart** | 869 | 🔴 Crítico | 1 |
| **ruta_navegacion_page.dart** | 333 | 🟠 Grandes | 2 |
| **movimientos_page.dart** | 263 | 🟡 Medio | 3 |
| **rutas_seleccion_page.dart** | 206 | 🟢 Bien | - |
| **wallet_page.dart** | 212 | 🟡 Medio | 4 |
| **map_search_page.dart** | 114 | 🟢 Bien | - |
| **rutas_sugerencias_page.dart** | 94 | 🟢 Bien | - |
| **maps_page.dart** | 76 | 🟢 Bien | - |

---

## 🔴 PRIORIDAD 1: rutas_inicio_page.dart (869 líneas)

### Problemas Críticos
- **Violación del SRP**: Mezcla múltiples responsabilidades (ubicación, caché, búsqueda, UI)
- **Complejidad extrema**: 40+ métodos privados, lógica anidada profunda
- **Widgets anidados internos**: `_SearchProgressDialog`, `_CacheDownloadDialog`
- **Métodos muy largos**: `_findRoutes()` ~150 líneas, `_downloadRoutesInChunks()` ~100 líneas

### Responsabilidades Identificadas
1. ✅ Gestión de ubicación GPS del usuario
2. ✅ Interfaz de entrada origen/destino
3. ✅ Modo de selección de pin en mapa
4. ✅ Descarga y almacenamiento en caché de rutas
5. ✅ Búsqueda de rutas con algoritmos complejos
6. ✅ Geocodificación inversa
7. ✅ Diálogos de progreso

### Oportunidades de Extracción

#### 1. **RouteCache Manager Widget** (crear nuevo)
```dart
// Extraer toda la lógica de caché
- _initializeRouteCache()
- _downloadRoutesInChunks()
- _cacheLoadingFuture
- _cacheInitialized
- _downloadProgressNotifier
- _downloadTotalNotifier
```
**Beneficio**: 150+ líneas extraídas, reutilizable

#### 2. **LocationInput Card Widget** (crear nuevo)
```dart
// Extraer la tarjeta de entrada
- Componente visual: origen + destino + botón buscar
- Input fields con LocationRow
- Independiente del mapa
```
**Beneficio**: 80+ líneas extraídas, componente limpio

#### 3. **MapPinSelector Widget** (crear nuevo)
```dart
// Extraer todo el modo pin
- MapPinOverlay
- MapPinConfirmPanel
- _togglePinMode()
- _reverseGeocode()
- _confirmPin()
- _isCameraMoving, _pinAddress, _pinFor
```
**Beneficio**: 120+ líneas extraídas, reutilizable

#### 4. **RouteSearchService** (crear nuevo)
```dart
// Extraer lógica de búsqueda
- _findRoutes()
- _hasPointNearTargets()
- _calculateDistance()
- _convertRouteEntityToOsmRoute()
- _toRadians()
```
**Beneficio**: Lógica testeable, reutilizable

#### 5. **Reusable Dialogs** (crear widgets)
```dart
// Extraer diálogos
- _CacheDownloadDialog → CacheDownloadDialog (lib/features/user/presentation/widgets/)
- _SearchProgressDialog → SearchProgressDialog (lib/features/user/presentation/widgets/)
```
**Beneficio**: 100+ líneas extraídas, reutilizables

### Plan de Refactorización
1. Crear `route_cache_manager_widget.dart`
2. Crear `location_input_card.dart`
3. Crear `map_pin_selector.dart`
4. Crear `route_search_service.dart`
5. Mover diálogos a widgets reutilizables
6. Refactorizar `rutas_inicio_page.dart` para usar los nuevos widgets

**Resultado esperado**: Página reducida a ~300 líneas

---

## 🟠 PRIORIDAD 2: ruta_navegacion_page.dart (333 líneas)

### Problemas
- **Lógica de rendering compleja**: Construcción de polilineas y marcadores duplicada
- **Métodos getter grandes**: `_polylines` getter ~80 líneas, `_markers` getter ~60 líneas
- **Cálculos de distancia repetidos**: `_dist()`, `_remainingMeters()`

### Responsabilidades Identificadas
1. ✅ Seguimiento GPS en tiempo real
2. ✅ Gestión de fase del viaje (walk start → on bus → walk end → arrived)
3. ✅ Renderización de mapa con polilineas y marcadores
4. ✅ Cálculos de distancia y ETA
5. ✅ Mostrar resumen del viaje

### Oportunidades de Extracción

#### 1. **RoutePolylineBuilder Widget** (crear nuevo)
```dart
// Extraer construcción de polilineas
- _polylines getter
- Lógica de trimming de polilineas según fase
- Estilos de línea (walk, transit, etc.)
```
**Beneficio**: 80+ líneas extraídas

#### 2. **RouteMarkerBuilder Widget** (crear nuevo)
```dart
// Extraer construcción de marcadores
- _markers getter
- Construcción de iconos customizados
- Información de ventanas
```
**Beneficio**: 60+ líneas extraídas

#### 3. **DistanceCalculator Service** (crear nuevo)
```dart
// Extraer cálculos de distancia
- _dist()
- _remainingMeters()
- _calculateETA()
```
**Beneficio**: Lógica testeable

### Plan de Refactorización
1. Extraer getters complejos a métodos/builders
2. Crear servicios de cálculo de distancia
3. Simplificar build() usando los nuevos widgets

**Resultado esperado**: Página reducida a ~250 líneas

---

## 🟡 PRIORIDAD 3: movimientos_page.dart (263 líneas)

### Problemas
- **Utilidades inline**: `_formatDate()`, `_getMonthName()` podrían ser globales
- **Componente repetido**: `_buildFilterButton()` construye botones similares
- **Tarjeta de transacción compleja**: Build inline muy largo (~40 líneas)

### Responsabilidades Identificadas
1. ✅ Mostrar historial de transacciones
2. ✅ Filtrado por período
3. ✅ Formateo de fechas
4. ✅ Integración con WalletBloc

### Oportunidades de Extracción

#### 1. **TransactionCard Widget** (crear nuevo)
```dart
// Extraer tarjeta de transacción
- Recibe: transaction, isTopUp
- Construye: icono + descripción + fecha + monto
- Estilos consistentes
```
**Beneficio**: ~50 líneas extraídas, reutilizable

#### 2. **PeriodFilterButton Widget** (crear nuevo)
```dart
// Extraer botón de filtro
- Recibe: label, isSelected, onTap
- Ya existe _buildFilterButton() → convertir a widget
```
**Beneficio**: Componente limpio, reutilizable

#### 3. **DateFormatter Utility** (crear en core/utils)
```dart
// Extraer formateo de fechas
DateFormatter.formatTimestamp(timestamp)
DateFormatter.getMonthName(month)
```
**Beneficio**: Reutilizable en toda la app

### Plan de Refactorización
1. Crear `transaction_card.dart`
2. Crear `period_filter_button.dart`
3. Crear `date_formatter.dart` en core/utils
4. Actualizar `movimientos_page.dart`

**Resultado esperado**: Página reducida a ~150 líneas

---

## 🟡 PRIORIDAD 4: wallet_page.dart (212 líneas)

### Problemas
- **Método repetido**: `_actionButton()` se llama 4 veces con parámetros similares
- **UI monolítica**: Toda la UI en build() con lógica de validación

### Responsabilidades Identificadas
1. ✅ Mostrar saldo disponible
2. ✅ Botones de acciones con navegación
3. ✅ Gestión de estados WalletBloc

### Oportunidades de Extracción

#### 1. **BalanceCard Widget** (crear nuevo)
```dart
// Extraer tarjeta de saldo
- Recibe: wallet
- Muestra: saldo formateado
```
**Beneficio**: ~30 líneas extraídas

#### 2. **WalletActionButton Widget** (crear nuevo)
```dart
// Extraer botón de acción
- Recibe: label, icon, onPressed
- Ya existe _actionButton() → convertir a widget
```
**Beneficio**: Componente reutilizable, limpia 4 llamadas

### Plan de Refactorización
1. Crear `balance_card.dart`
2. Crear `wallet_action_button.dart`
3. Actualizar `wallet_page.dart`

**Resultado esperado**: Página reducida a ~100 líneas

---

## 🟢 BIEN DISEÑADAS

### ✅ rutas_seleccion_page.dart (206 líneas)
- Componentes bien extraídos (RouteCard, RouteMapView)
- Responsabilidades claras
- Tamaño manejable

### ✅ map_search_page.dart (114 líneas)
- Enfocada en su función
- Widgets ya extraídos (SearchBarField, SearchResultsBody)
- Buen manejo de debounce

### ✅ rutas_sugerencias_page.dart (94 líneas)
- Página simple y clara
- Bien estructurada

### ✅ maps_page.dart (76 líneas)
- Mapa básico bien hecho
- Sin complejidad innecesaria

---

## 📋 Duplicación de Código Identificada

### 1. **Location Row UI Pattern**
```dart
// En rutas_inicio_page.dart (LocationRow widget)
// Usado en múltiples lugares
// ✅ Ya extraído correctamente
```

### 2. **Dialog Pattern - Progress**
```dart
// _CacheDownloadDialog, _SearchProgressDialog en rutas_inicio_page.dart
// Similar pattern en map_search_page.dart
// Oportunidad: Crear DialogBuilder helper
```

### 3. **Action Button Pattern**
```dart
// wallet_page.dart: _actionButton() repetido 4 veces
// Extraer a WalletActionButton widget
```

### 4. **Filter Button Pattern**
```dart
// movimientos_page.dart: _buildFilterButton()
// Extraer a PeriodFilterButton widget
```

### 5. **Transaction Row Pattern**
```dart
// movimientos_page.dart: ListView.builder → transaction card
// Extraer a TransactionCard widget
```

---

## 🎯 Estrategia de Refactorización Propuesta

### Fase 1: Preparación (Baja Prioridad)
- [ ] Crear `core/utils/date_formatter.dart`
- [ ] Preparar estructura de widgets reutilizables

### Fase 2: Widgets Simples (Alta Prioridad)
- [ ] Crear `balance_card.dart`
- [ ] Crear `wallet_action_button.dart`
- [ ] Crear `transaction_card.dart`
- [ ] Crear `period_filter_button.dart`
- [ ] Actualizar `wallet_page.dart` y `movimientos_page.dart`

### Fase 3: Widgets Complejos (Crítica)
- [ ] Crear `location_input_card.dart`
- [ ] Crear `map_pin_selector.dart`
- [ ] Crear servicios de búsqueda y caché
- [ ] Refactorizar `rutas_inicio_page.dart`

### Fase 4: Optimización (Mantenimiento)
- [ ] Mover diálogos reutilizables a widgets
- [ ] Crear `RoutePolylineBuilder` y `RouteMarkerBuilder`
- [ ] Refactorizar `ruta_navegacion_page.dart`

---

## 📊 Impacto Estimado

| Página | Líneas Actuales | Líneas Esperadas | Reducción |
|--------|-----------------|------------------|-----------|
| rutas_inicio_page | 869 | ~300 | 65% ↓ |
| ruta_navegacion_page | 333 | ~250 | 25% ↓ |
| movimientos_page | 263 | ~150 | 43% ↓ |
| wallet_page | 212 | ~100 | 53% ↓ |
| **Total** | **1677** | **~800** | **52% ↓** |

---

## ✨ Beneficios de Refactorización

1. **Mantenibilidad**: Código más enfocado y fácil de entender
2. **Reusabilidad**: Componentes reutilizables en toda la app
3. **Testabilidad**: Servicios aislados y testables
4. **Performance**: Menos rebuilds innecesarios
5. **Consistencia**: UI components reutilizables con estilos uniformes
