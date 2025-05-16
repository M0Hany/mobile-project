import 'package:flutter/material.dart';
import '../../models/store.dart';
import '../../services/product_service.dart';
import '../../widgets/store_search_card.dart';
import '../../widgets/product_suggestion_chips.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import '../map/stores_map_screen.dart';

class ProductSearchScreen extends StatefulWidget {
  final ProductService productService;

  const ProductSearchScreen({
    Key? key,
    required this.productService,
  }) : super(key: key);

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final _logger = Logger();
  final _searchController = TextEditingController();
  List<Store> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    // Cancel any previous debounce timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    // Set up a new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final results = await widget.productService.searchProducts(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        _logger.e('Error searching products', error: e);
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
            _searchResults = [];
          });
        }
      }
    });
  }

  void _onSuggestionSelected(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  void _navigateToMapView() {
    _logger.i('Navigating to map view with ${_searchResults.length} stores');
    _logger.d(
        'Store data: ${_searchResults.map((store) => '${store.name}: (${store.latitude}, ${store.longitude})').join(', ')}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoresMapScreen(
          stores: _searchResults,
          searchQuery: _searchController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        actions: [
          if (_searchResults.isNotEmpty && _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: _navigateToMapView,
              tooltip: 'View on map',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
          if (_searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ProductSuggestionChips(
                productService: widget.productService,
                onSuggestionSelected: _onSuggestionSelected,
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No stores found with matching products',
                style: TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
              ),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final store = _searchResults[index];
                  return StoreSearchCard(
                    store: store,
                    productService: widget.productService,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
