# Corrección: Finalización Automática de Viaje al Minimizar App

## Problema Identificado
Cuando el usuario iniciaba un viaje en `ruta_navegacion_page.dart` y minimizaba la aplicación, el viaje se finalizaba automáticamente después de unos minutos. Esto sucedía porque el método `dispose()` de la página llamaba a `NavigationStopped()`, deteniendo el tracking de GPS.

## Solución Implementada

### Cambios en la Arquitectura del Bloc

#### 1. **navigation_event.dart**
Agregados nuevos eventos para pausar y reanudar el tracking:
```dart
class NavigationPaused extends NavigationEvent {
  const NavigationPaused();
}

class NavigationResumed extends NavigationEvent {
  const NavigationResumed();
}
```

#### 2. **navigation_state.dart**
Agregado nuevo campo para trackear si el viaje está pausado:
```dart
final bool isPaused;
```

#### 3. **navigation_bloc.dart**
Agregados manejadores para pausa/reanudación:
- `_onNavigationPaused()`: Pausa el timer pero mantiene el estado actual
- `_onNavigationResumed()`: Reanuda el timer cuando la app vuelve a foreground
- Actualizado el handler `_onNavigationStopped()`: Ahora solo se llama cuando el usuario realmente termina el viaje

### Cambios en la Página

#### **ruta_navegacion_page.dart**

##### 1. **Implementación de WidgetsBindingObserver**
```dart
class _RutaNavegacionViewState extends State<_RutaNavegacionView>
    with WidgetsBindingObserver
```

##### 2. **Nuevo método para detectar cambios de ciclo de vida**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.paused:
    case AppLifecycleState.detached:
      _navBloc.add(const NavigationPaused());
      break;
    case AppLifecycleState.resumed:
      _navBloc.add(const NavigationResumed());
      break;
    case AppLifecycleState.hidden:
      _navBloc.add(const NavigationPaused());
      break;
    case AppLifecycleState.inactive:
      break;
  }
}
```

##### 3. **Actualización de initState**
- Se agrega el observer a WidgetsBinding
```dart
WidgetsBinding.instance.addObserver(this);
```

##### 4. **Actualización de dispose**
- Ya NO llama a `NavigationStopped()` automáticamente
- Solo remueve el observer
- El tracking solo se detiene cuando el usuario realmente termina el viaje

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _mapController?.dispose();
  super.dispose();
}
```

##### 5. **Método _onBackPressed**
Nuevo método que detiene el tracking cuando el usuario navega hacia atrás:
```dart
void _onBackPressed() {
  _navBloc.add(const NavigationStopped());
  Navigator.of(context).pop();
}
```

##### 6. **Actualización de _showSummarySheet**
Agrega la limpieza final cuando el usuario cierra la hoja de resumen:
```dart
onClose: () {
  Navigator.of(ctx).pop();
  _navBloc.add(const NavigationStopped());
  Navigator.of(context).popUntil((r) => r.isFirst);
}
```

## Flujo de Funcionamiento

### Ciclo de Vida Normal (Sin Minimizar)

```
RutaNavegacionPage iniciada
    ↓
NavigationStarted → Inicia tracking GPS
    ↓
Usuario durante viaje
    ↓
Llega al destino → NavigationState.phase = 'arrived'
    ↓
Muestra resumen de viaje
    ↓
Usuario cierra resumen → NavigationStopped (Detiene tracking)
    ↓
Navega de regreso
```

### Ciclo de Vida Con Minimización

```
RutaNavegacionPage iniciada
    ↓
NavigationStarted → Inicia tracking GPS
    ↓
Usuario minimiza app → didChangeAppLifecycleState(paused)
    ↓
NavigationPaused → Pausa timer (pero mantiene ubicación actual)
    ↓
Usuario abre app → didChangeAppLifecycleState(resumed)
    ↓
NavigationResumed → Reanuda timer
    ↓
Viaje continúa normalmente
    ↓
(El viaje NO se finaliza)
```

## Beneficios

✅ **El viaje persiste cuando la app se minimiza**
- El usuario puede recibir llamadas, mensajes, etc. sin perder su viaje

✅ **GPS continúa rastreando en background** (si los permisos lo permiten)
- La ubicación se mantiene actualizada

✅ **El viaje solo finaliza cuando:**
- El usuario llega al destino, O
- El usuario presiona el botón de atrás, O
- El usuario cierra la hoja de resumen

✅ **Respeta la arquitectura BLoC**
- Los cambios están centralizados en el Bloc
- La página solo actúa como observer del ciclo de vida

✅ **Compatible con ambas plataformas**
- iOS y Android (incluyendo iOS 13.2+ con AppLifecycleState.hidden)

## Archivos Modificados

```
lib/features/user/presentation/bloc/
├── navigation_event.dart          (Nuevos eventos: Paused, Resumed)
├── navigation_state.dart          (Nuevo campo: isPaused)
└── navigation_bloc.dart           (Nuevos handlers)

lib/features/user/presentation/pages/
└── ruta_navegacion_page.dart      (WidgetsBindingObserver, ciclo de vida)
```

## Notas para Futuro Desarrollo

1. **Background Location Tracking**: Si quieres rastrear la ubicación incluso después de que la app está completamente cerrada, considera usar `background_fetch` o `flutter_foreground_task`.

2. **Persistencia del Viaje**: Si necesitas persistencia de datos del viaje en caso de crash, integra una base de datos local (sqflite).

3. **Notificaciones**: Considera agregar notificaciones cuando se aproxima la parada de descenso.
