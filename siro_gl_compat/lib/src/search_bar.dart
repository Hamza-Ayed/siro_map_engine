import 'dart:async';

import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart' show LatLng;

import 'geocoder.dart';

/// A search field that finds places through [SiroGeocoder] and reports the
/// one the user picks. Typing waits [debounce] before it searches.
class SiroSearchBar extends StatefulWidget {
  const SiroSearchBar({
    super.key,
    required this.geocoder,
    required this.onSelected,
    this.near,
    this.country,
    this.hintText = 'Search places',
    this.debounce = const Duration(milliseconds: 350),
    this.maxResults = 6,
  });

  final SiroGeocoder geocoder;

  /// Called with the place the user picked.
  final ValueChanged<SiroPlace> onSelected;

  /// Biases the results towards this point.
  final LatLng? near;

  /// ISO country code to restrict the search, for example `JO`.
  final String? country;

  final String hintText;
  final Duration debounce;
  final int maxResults;

  @override
  State<SiroSearchBar> createState() => _SiroSearchBarState();
}

class _SiroSearchBarState extends State<SiroSearchBar> {
  final _input = TextEditingController();
  Timer? _timer;
  int _requestId = 0;
  List<SiroPlace> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    setState(() => _error = null);
    if (text.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    _timer = Timer(widget.debounce, () => _search(text));
  }

  Future<void> _search(String text) async {
    final id = ++_requestId;
    setState(() => _loading = true);
    try {
      final results = await widget.geocoder.search(
        text,
        near: widget.near,
        country: widget.country,
      );
      if (!mounted || id != _requestId) return;
      setState(() => _results = results.take(widget.maxResults).toList());
    } catch (error) {
      if (mounted && id == _requestId) setState(() => _error = '$error');
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  void _select(SiroPlace place) {
    _input.text = place.displayName;
    setState(() => _results = const []);
    FocusScope.of(context).unfocus();
    widget.onSelected(place);
  }

  void _clear() {
    _timer?.cancel();
    _input.clear();
    setState(() {
      _results = const [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
          child: TextField(
            controller: _input,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _loading
                      ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : (_input.text.isEmpty
                          ? null
                          : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close),
                            onPressed: _clear,
                          )),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (_results.isNotEmpty)
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final place in _results)
                  ListTile(
                    title: Text(place.displayName),
                    subtitle: Text(
                      [
                        if (place.category.isNotEmpty) place.category,
                        if (place.address.isNotEmpty) place.address,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _select(place),
                  ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
