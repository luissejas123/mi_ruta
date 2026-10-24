import 'package:flutter/material.dart';

class LegalBottomSheet extends StatelessWidget {
  final bool isDriver;

  const LegalBottomSheet({super.key, required this.isDriver});

  static void show(BuildContext context, {required bool isDriver}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LegalBottomSheet(isDriver: isDriver),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Para modo oscuro/claro
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final titleColor = isDark ? Colors.white : Colors.black;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: isDriver
                  ? _buildDriverTerms(textColor, titleColor)
                  : _buildPassengerTerms(textColor, titleColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Términos y Condiciones',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerTerms(Color textColor, Color titleColor) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
        children: [
          const TextSpan(text: 'Al utilizar Mi Ruta como '),
          TextSpan(
            text: 'Pasajero',
            style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
          ),
          const TextSpan(text: ', aceptas las siguientes políticas:\n\n'),
          TextSpan(
            text: '1. Uso de la Billetera y Pagos\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: titleColor,
            ),
          ),
          const TextSpan(
            text:
                'Las recargas y pagos mediante código QR son definitivos. "Mi Ruta" no se hace responsable por transferencias a cuentas erróneas o uso indebido de los fondos. El saldo de la billetera no es canjeable por dinero en efectivo.\n\n',
          ),
          TextSpan(
            text: '2. Privacidad y Ubicación\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: titleColor,
            ),
          ),
          const TextSpan(
            text:
                'Para usar el mapa interactivo y localizar rutas cercanas, la aplicación requiere acceso a tu ubicación en primer plano. Estos datos no se venden a terceros y se utilizan exclusivamente para mejorar tu experiencia calculando las rutas de transporte.\n\n',
          ),
          TextSpan(
            text: '3. Conducta Cívica\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: titleColor,
            ),
          ),
          const TextSpan(
            text:
                'El usuario se compromete a mantener un comportamiento cívico y respetuoso al abordar los transportes asociados a la red. Cualquier reporte de mal comportamiento puede resultar en la suspensión de la cuenta.\n\n',
          ),
          TextSpan(
            text: '4. Limitación de Responsabilidad\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: titleColor,
            ),
          ),
          const TextSpan(
            text:
                'Mi Ruta actúa únicamente como un intermediario tecnológico para facilitar el pago y seguimiento de rutas. No somos dueños de los vehículos y no nos responsabilizamos por retrasos o inconvenientes durante el trayecto.',
          ),
        ],
      ),
    );
  }

  Widget _buildDriverTerms(Color textColor, Color titleColor) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
        children: [
          const TextSpan(text: 'Al utilizar Mi Ruta como '),
          TextSpan(
            text: 'Chofer / Conductor',
            style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
          ),
          const TextSpan(
            text: ', aceptas las siguientes políticas obligatorias:\n\n',
          ),
          const TextSpan(
            text: '1. Seguimiento GPS Continuo (Ubicación en 2do Plano)\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          const TextSpan(
            text:
                'Es estrictamente OBLIGATORIO otorgar permisos de ubicación en segundo plano ("Permitir todo el tiempo"). Esto es vital para el funcionamiento del servicio, ya que permite a los pasajeros ver la posición del vehículo en tiempo real incluso si la aplicación del chofer está minimizada o la pantalla está apagada. Al aceptar estos términos, consientes el rastreo de tu ubicación durante tu jornada.\n\n',
          ),
          TextSpan(
            text: '2. Responsabilidad y Seguridad\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: titleColor,
            ),
          ),
          const TextSpan(
            text:
                'El chofer declara tener licencia de conducir vigente y el vehículo asegurado contra accidentes (SOAT u otros). La plataforma Mi Ruta es una herramienta tecnológica y no asume ninguna responsabilidad civil o penal por incidentes físicos, de tránsito o daños a terceros.\n\n',
          ),
          TextSpan(
            text: '3. Pagos y Retenciones\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: titleColor,
            ),
          ),
          const TextSpan(
            text:
                'La plataforma procesa los pasajes vía código QR. Se retendrán los porcentajes de comisión acordados previamente antes del desembolso a la cuenta bancaria del conductor. Los desembolsos se rigen por los calendarios de pago establecidos.\n\n',
          ),
          TextSpan(
            text: '4. Suspensión del Servicio\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: titleColor,
            ),
          ),
          const TextSpan(
            text:
                'El incumplimiento de las rutas, apagar deliberadamente el GPS, o el trato inadecuado a los pasajeros, resultará en la suspensión temporal o permanente de la cuenta.',
          ),
        ],
      ),
    );
  }
}
