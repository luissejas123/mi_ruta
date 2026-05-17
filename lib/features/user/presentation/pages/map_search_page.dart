import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/data/datasources/places_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/presentation/widgets/place_prediction_tile.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_bar_field.dart';

export 'package:mi_ruta/features/user/domain/entities/place_result.dart';

class MapSearchPage extends StatefulWidget {
  final LatLng? currentLocation;

  const MapSearchPage({super.key, this.currentLocation});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
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
        _error = 'Error: $e';
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
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SearchBarField(
            controller: _controller,
            onChanged: _onTextChanged,
            onClear: _onClear,
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFFFBC02D),
              backgroundColor: Color(0xFFF1F3F4),
            ),
          if (_error != null) _SearchErrorBanner(message: _error!),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_predictions.isEmpty && !_isLoading) {
      return _controller.text.isEmpty
          ? const _SearchEmptyHint()
          : const Center(
              child: Text(
                'Sin resultados',
                style: TextStyle(color: Colors.black54),
              ),
            );
    }
    return ListView.separated(
      itemCount: _predictions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (_, i) => PlacePredictionTile(
        prediction: _predictions[i],
        onTap: () => _onPredictionTap(_predictions[i]),
      ),
    );
  }
}

// ── Widgets privados ─────────────────────────────────────────────────────────

class _SearchErrorBanner extends StatelessWidget {
  final String message;

  const _SearchErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyHint extends StatelessWidget {
  const _SearchEmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: Color(0xFFDDDDDD)),
          SizedBox(height: 12),
          Text(
            'Escribe una dirección o lugar',
            style: TextStyle(color: Colors.black45, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
