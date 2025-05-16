import 'package:flutter/material.dart';
import '../services/product_service.dart';

class ProductSuggestionChips extends StatefulWidget {
  final ProductService productService;
  final Function(String) onSuggestionSelected;

  const ProductSuggestionChips({
    Key? key,
    required this.productService,
    required this.onSuggestionSelected,
  }) : super(key: key);

  @override
  State<ProductSuggestionChips> createState() => _ProductSuggestionChipsState();
}

class _ProductSuggestionChipsState extends State<ProductSuggestionChips> {
  List<String> _suggestions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final suggestions = await widget.productService.getProductSuggestions();

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Error loading suggestions: $_error',
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 12,
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _suggestions.map((suggestion) {
          return ActionChip(
            label: Text(suggestion),
            backgroundColor: Colors.blue[50],
            labelStyle: TextStyle(
              color: Colors.blue[900],
              fontSize: 12,
            ),
            onPressed: () => widget.onSuggestionSelected(suggestion),
          );
        }).toList(),
      ),
    );
  }
}
