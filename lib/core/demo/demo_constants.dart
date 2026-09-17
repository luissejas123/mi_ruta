/// TEMPORAL — "Modo prueba" 100% estático: sin Firebase Auth, sin Firestore.
/// Datos en memoria únicamente. Quitar este archivo y sus usos cuando el
/// modo prueba ya no se necesite para QA.
const String kStaticDemoDriverUid = 'static_demo_driver';
const String kStaticDemoAdminUid = 'static_demo_admin';
const String kStaticDemoPresidenteUid = 'static_demo_presidente';
const String kStaticDemoTickeadorUid = 'static_demo_tickeador';
const String kStaticDemoVehicleId = 'DEMO-001';
/// Línea del presidente demo — coincide con `lineNumber` de la unidad demo
/// del chofer, para que los dos demos sean consistentes entre sí.
const String kStaticDemoRouteRef = '101';
