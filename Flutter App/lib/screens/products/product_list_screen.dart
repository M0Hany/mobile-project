import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/products/product_card.dart';
import 'package:logger/logger.dart';
import '../map/store_directions_screen.dart';

class ProductListScreen extends StatefulWidget {
  final int storeId;
  final String storeName;
  final ProductService productService;
  final double? storeLatitude;
  final double? storeLongitude;

  const ProductListScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
    required this.productService,
    this.storeLatitude,
    this.storeLongitude,
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _logger = Logger();
  List<Product> _products = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        widget.productService.getStoreProducts(widget.storeId),
        widget.productService.getProductCategories(),
      ]);

      setState(() {
        _products = futures[0] as List<Product>;
        _categories = futures[1] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading products', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _navigateToDirections() {
    if (widget.storeLatitude == null || widget.storeLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store location is not available'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDirectionsScreen(
          storeName: widget.storeName,
          storeLatitude: widget.storeLatitude!,
          storeLongitude: widget.storeLongitude!,
        ),
      ),
    );
  }

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
        actions: [
          if (widget.storeLatitude != null && widget.storeLongitude != null)
            IconButton(
              icon: const Icon(Icons.directions),
              onPressed: _navigateToDirections,
              tooltip: 'Get directions',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_categories.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setState(() => _selectedCategory =
                                    selected ? category : null);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              _products.isEmpty
                                  ? 'No products available'
                                  : 'No products match your filters',
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              return ProductCard(
                                product: _filteredProducts[index],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
