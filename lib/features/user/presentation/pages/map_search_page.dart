import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/data/datasources/places_datasource.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_bar_field.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_error_banner.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_results_body.dart';

export 'package:mi_ruta/features/user/domain/entities/place_result.dart';

// ✅ Enum para distinguir origen o destino
enum SearchMode { origin, destination }

class MapSearchPage extends StatefulWidget {
  final LatLng? currentLocation;
  // ✅ Nuevo parámetro
  final SearchMode searchMode;

  const MapSearchPage({
    super.key,
    this.currentLocation,
    this.searchMode = SearchMode.destination,
  });

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  static const _amarillo = Color(0xFFFFC12F);

  final _controller = TextEditingController();
  final _datasource = PlacesDatasource();
  List<Map<String, dynamic>> _predictions = [];
  Timer? _debounce;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ✅ Texto del placeholder según el modo
  String get _hintText => widget.searchMode == SearchMode.origin
      ? 'Buscar punto de origen...'
      : 'Buscar destino...';

  // ✅ Título del AppBar según el modo
  String get _appBarTitle => widget.searchMode == SearchMode.origin
      ? 'Punto de origen'
      : 'Buscar destino';

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _predictions = [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPredictions(value.trim());
    });
  }

  void _onClear() {
    _controller.clear();
    setState(() {
      _predictions = [];
      _error = null;
    });
  }

  Future<void> _fetchPredictions(String input) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _datasource.fetchPredictions(
        input: input,
        location: widget.currentLocation,
      );
      if (!mounted) return;
      setState(() {
        _predictions = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al buscar: $e';
      });
    }
  }

  Future<void> _onPredictionTap(Map<String, dynamic> prediction) async {
    setState(() => _isLoading = true);
    try {
      final result = await _datasource.fetchPlaceDetail(prediction);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al obtener detalle: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ✅ AppBar con título dinámico
      appBar: AppBar(
        backgroundColor: _amarillo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          SearchBarField(
            controller: _controller,
            onChanged: _onTextChanged,
            onClear: _onClear,
            hintText: _hintText,
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              color: _amarillo,
              backgroundColor: Colors.white,
            ),
          if (_error != null) SearchErrorBanner(message: _error!),
          Expanded(
            child: SearchResultsBody(
              predictions: _predictions,
              isLoading: _isLoading,
              hasText: _controller.text.isNotEmpty,
              onTap: _onPredictionTap,
            ),
          ),
        ],
      ),
    );
  }
}