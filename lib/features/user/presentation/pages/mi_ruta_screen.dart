import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/notifications/presentation/pages/notification_demo_screens.dart';
import 'package:mi_ruta/features/user/presentation/pages/test_widgets_screen.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_search_header.dart';

class MiRutaScreen extends StatefulWidget {
  const MiRutaScreen({super.key});

  @override
  State<MiRutaScreen> createState() => _MiRutaScreenState();
}

class _MiRutaScreenState extends State<MiRutaScreen> {
  static const LatLng _defaultCenter = LatLng(-17.391032, -66.1568);
  LatLng? _mapCenter;
  String? _statusText;
  GoogleMapController? _mapController;
  bool _isLoadingConnection = true;
  double _balance = 5.0;
  bool _showStopAnnouncementOverlay = false;
  bool _showTripCompleteOverlay = false;
  bool _showDiscountBanner = false;
  bool _showGiftAvailable = false;
  bool _showRouteChangeBanner = false;
  bool _serviceActiveAlert = false;
  bool _serviceSuspendedAlert = false;
  int _selectedStars = 0;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isLoadingConnection = true;
      _statusText = null;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusText =
            'Activa el servicio de ubicación para ver tu posición real.';
        _mapCenter = _defaultCenter;
        _isLoadingConnection = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _statusText = 'Permiso de ubicación denegado. Usa el mapa manualmente.';
        _mapCenter = _defaultCenter;
        _isLoadingConnection = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    setState(() {
      _mapCenter = LatLng(position.latitude, position.longitude);
      _statusText = null;
      _isLoadingConnection = false;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_mapCenter!, 15));
  }

  void _onSearchTap() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar destino'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: '¿A dónde vamos ...?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 3) {
      final authBloc = context.read<AuthBloc>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authBloc,
            child: const TestWidgetsScreen(),
          ),
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _handleRecharge() {
    setState(() {
      _balance += 20.0;
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AbonoSaldoExitosoScreen()),
    );
  }

  void _handlePayment() {
    final newBalance = _balance - 3.0;
    setState(() {
      _balance = newBalance < 0 ? 0 : newBalance;
    });

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PagoExitosoScreen()))
        .then((_) {
      if (_balance <= 2.0) {
        _showLowBalanceDialog();
      }
    });
  }

  void _handleDiscount() {
    setState(() {
      _showDiscountBanner = true;
      _showGiftAvailable = true;
      _selectedIndex = 0;
    });
  }

  void _handleBenefitConfirmation() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ConfirmacionBeneficioScreen()),
    );
  }

  void _handleServiceActive() {
    setState(() {
      _serviceActiveAlert = true;
      _serviceSuspendedAlert = false;
      _selectedIndex = 2;
    });
  }

  void _handleServiceSuspended() {
    setState(() {
      _serviceSuspendedAlert = true;
      _serviceActiveAlert = false;
      _selectedIndex = 2;
    });
  }

  void _handleRouteChange() {
    setState(() {
      _showRouteChangeBanner = true;
      _selectedIndex = 0;
    });
  }

  void _handleTripRating() {
    setState(() {
      _showTripCompleteOverlay = true;
      _selectedIndex = 0;
    });
  }

  void _handleAnnounceStop() {
    setState(() {
      _showStopAnnouncementOverlay = true;
      _selectedIndex = 0;
    });
  }

  void _showLowBalanceDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.account_balance_wallet, color: Colors.pink),
                  SizedBox(width: 12),
                  Text(
                    '¡Saldo Bajo!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu saldo actual es Bs. 2.00. Por favor recarga para evitar contratiempos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleRecharge();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                  ),
                  child: const Text('Recargar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLowBalance() {
    _showLowBalanceDialog();
  }

  void _showDiscountGiftDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¡Felicidades!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Felicidades!\nRecibiste un 15%\nde descuento en\nun negocio local',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                  ),
                  child: const Text('Usar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetMapOverlays() {
    setState(() {
      _showStopAnnouncementOverlay = false;
      _showTripCompleteOverlay = false;
      _showDiscountBanner = false;
      _showGiftAvailable = false;
      _showRouteChangeBanner = false;
    });
  }

  Widget _buildWalletScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billetera',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo disponible',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bs. ${_balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Usa esta sección para recargar saldo, ver beneficios y notificaciones importantes.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleRecharge,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Recargar saldo'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _handleDiscount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Obtener descuento especial'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _handleBenefitConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Validar carnet'),
          ),
          if (_balance <= 2.0) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Saldo bajo: recarga antes de tomar el próximo viaje para evitar cortes.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutesScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rutas y Servicios',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ruta activa',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Av. República → Plaza Colón',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Línea 212 - Próxima salida en 5 min',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handlePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Pagar viaje'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _handleTripRating,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Finalizar viaje'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _handleRouteChange,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Detectar cambio de ruta'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _handleServiceActive,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Servicio activo'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _handleServiceSuspended,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Servicio suspendido'),
          ),
          if (_serviceActiveAlert) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    '¡Servicio Activo!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Divider(height: 1),
                  SizedBox(height: 16),
                  Text('Línea 10 Suspendida Temporalmente'),
                  SizedBox(height: 12),
                  Divider(height: 1),
                  SizedBox(height: 12),
                  Text('Tiempo Estimado: 1 hora'),
                ],
              ),
            ),
          ],
          if (_serviceSuspendedAlert) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    '¡Servicio Suspendido!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Divider(height: 1),
                  SizedBox(height: 16),
                  Text('Línea 10 Suspendida Temporalmente'),
                  SizedBox(height: 12),
                  Divider(height: 1),
                  SizedBox(height: 12),
                  Text('Tiempo Estimado: 1 hora'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingConnection() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Espera un momento', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Set<Marker> get _markers {
    if (_mapCenter == null) return {};
    return {
      Marker(
        markerId: const MarkerId('mi_ubicacion'),
        position: _mapCenter!,
        infoWindow: const InfoWindow(title: 'Mi ubicación'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: Column(
          children: [
            MapSearchHeader(onSearchTap: _onSearchTap),
            Expanded(
              child: _selectedIndex == 0
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: _isLoadingConnection
                              ? _buildLoadingConnection()
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _mapCenter!,
                                    zoom: 15,
                                  ),
                                  onMapCreated: (controller) =>
                                      _mapController = controller,
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: false,
                                  markers: _markers,
                                  zoomControlsEnabled: false,
                                ),
                        ),
                        if (_statusText != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 20,
                            child: Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _statusText!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        if (_showRouteChangeBanner)
                          Positioned(
                            top: 90,
                            left: 16,
                            right: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.orange),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Parece que hubo un cambio de ruta',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showRouteChangeBanner = false;
                                      });
                                    },
                                    child: const Text('Verificar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_showDiscountBanner)
                          Positioned(
                            top: _showRouteChangeBanner ? 170 : 90,
                            left: 16,
                            right: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.amber.shade200,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: const [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.check, color: Colors.white, size: 18),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '¡Felicidades! recibiste un descuento especial',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_showGiftAvailable)
                          Positioned(
                            bottom: 120,
                            right: 16,
                            child: GestureDetector(
                              onTap: _showDiscountGiftDialog,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Text(
                                          '1',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_showStopAnnouncementOverlay)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.35),
                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade200,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: const Text(
                                          '!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Anunciaste tu parada al micro',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _showStopAnnouncementOverlay = false;
                                            });
                                            _handlePayment();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber.shade700,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          child: const Text('Pagar Viaje'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_showTripCompleteOverlay)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.35),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.brown.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      '¿Como fue tu servicio?',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade200,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade700,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: const Icon(Icons.check, color: Colors.white, size: 32),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Completaste tu viaje',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              const CircleAvatar(
                                                radius: 28,
                                                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Trufi 234',
                                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.shade200,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: const Text(
                                                        'ZTER-2341',
                                                        style: TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.directions_car, color: Colors.black54),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Califica tu viaje',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(5, (index) {
                                            final starIndex = index + 1;
                                            return IconButton(
                                              icon: Icon(
                                                starIndex <= _selectedStars
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedStars = starIndex;
                                                });
                                              },
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _showTripCompleteOverlay = false;
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber.shade700,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                            ),
                                            child: const Text('Enviar'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(flex: 2),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 90,
                          child: ElevatedButton(
                            onPressed: _handleAnnounceStop,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Bajar'),
                          ),
                        ),
                      ],
                    )
                  : _selectedIndex == 1
                      ? _buildWalletScreen()
                      : _buildRoutesScreen(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
