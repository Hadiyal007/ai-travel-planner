import 'dart:async';
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/places_service.dart';

/// A text field that looks up Google Places suggestions as the user
/// types (debounced) and lets them tap one to fill the field. Falls
/// back to plain free-text entry — whatever text is in the field is
/// the value used, whether or not a suggestion was tapped, so a
/// missing/invalid API key degrades to a normal text field rather
/// than blocking the form.
class PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  State<PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  final _placesService = PlacesService();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String value) async {
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _placesService.autocomplete(value);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Places autocomplete failed: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load suggestions — you can still type freely';
        _isLoading = false;
        _suggestions = [];
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon),
            suffixIcon: _isLoading
                ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : null,
          ),
          validator: widget.validator,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.hairline),
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.hairline),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20, color: AppTheme.inkMuted),
                  title: Text(suggestion.description),
                  onTap: () {
                    widget.controller.text = suggestion.description;
                    setState(() => _suggestions = []);
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}