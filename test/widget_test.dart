// Tests de widgets que NO dependen de Firebase ni BLoC.
// InsertarCorreoPage requiere AuthBloc, por lo que se omite aquí.
// Para tests de integración con Firebase, usar integration_test/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/boton_amarillo.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/input_con_sombra.dart';

void main() {
  testWidgets('IniciarSesionPage muestra título y botones', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: IniciarSesionPage()));

    expect(find.text('MiRuta'), findsOneWidget);
    expect(find.text('Tu ruta, tu viaje,\ntu pago.'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Registrarte'), findsOneWidget);
  });

  testWidgets('BotonAmarillo ejecuta callback al presionar', (
    WidgetTester tester,
  ) async {
    bool presionado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BotonAmarillo(
            texto: 'Prueba',
            alPresionar: () => presionado = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Prueba'));
    expect(presionado, isTrue);
  });

  testWidgets('InputConSombra muestra hint text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InputConSombra(hint: 'Test hint')),
      ),
    );

    expect(find.widgetWithText(TextField, 'Test hint'), findsOneWidget);
  });
}
