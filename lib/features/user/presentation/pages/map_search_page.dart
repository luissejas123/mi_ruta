import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/data/datasources/places_datasource.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_bar_field.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_error_banner.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_results_body.dart';

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
