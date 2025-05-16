import 'package:flutter/material.dart';
import '../../models/store.dart';
import '../../state/store_state.dart';
import '../../widgets/store_card.dart';
import '../auth/edit_profile_screen.dart';
import '../products/product_search_screen.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';

class StoreListScreen extends StatefulWidget {
  final StoreState storeState;
  final AuthService authService;

  const StoreListScreen({
    Key? key,
    required this.storeState,
    required this.authService,
  }) : super(key: key);

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  late final ProductService _productService;

  @override
  void initState() {
    super.initState();
    _productService = ProductService(authService: widget.authService);
    widget.storeState.loadStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Stores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductSearchScreen(
                    productService: _productService,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfileScreen(authService: widget.authService),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Store>>(
        stream: widget.storeState.stores,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final stores = snapshot.data!;
          if (stores.isEmpty) {
            return const Center(
              child: Text('No stores available'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.storeState.loadStores(),
            child: ListView.builder(
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return StoreCard(
                  store: store,
                  productService: _productService,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddStoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Store Name'),
              onChanged: (value) {
                // Handle store name input
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Category'),
              onChanged: (value) {
                // Handle category input
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement store addition logic
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
