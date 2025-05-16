import 'package:rxdart/rxdart.dart';
import '../models/store.dart';
import '../services/store_service.dart';

class StoreState {
  final StoreService _storeService;
  final BehaviorSubject<List<Store>> _storesSubject =
      BehaviorSubject<List<Store>>.seeded([]);
  final BehaviorSubject<List<Store>> _favoriteStoresSubject =
      BehaviorSubject<List<Store>>.seeded([]);
  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject<bool>.seeded(
    false,
  );

  StoreState(this._storeService);

  Stream<List<Store>> get stores => _storesSubject.stream;
  Stream<List<Store>> get favoriteStores => _favoriteStoresSubject.stream;
  Stream<bool> get isLoading => _loadingSubject.stream;

  Stream<StoreStateData> get state => Rx.combineLatest3(
        stores,
        favoriteStores,
        isLoading,
        (List<Store> stores, List<Store> favoriteStores, bool isLoading) =>
            StoreStateData(
          stores: stores,
          favoriteStores: favoriteStores,
          isLoading: isLoading,
        ),
      );

  Future<void> loadStores() async {
    _loadingSubject.add(true);
    try {
      final stores = await _storeService.getAllStores();
      _storesSubject.add(stores);
    } catch (e) {
      // Handle error
    } finally {
      _loadingSubject.add(false);
    }
  }

  Future<void> loadFavoriteStores() async {
    _loadingSubject.add(true);
    try {
      final favoriteStores = await _storeService.getFavoriteStores();
      _favoriteStoresSubject.add(favoriteStores);
    } catch (e) {
      // Handle error
    } finally {
      _loadingSubject.add(false);
    }
  }

  Future<void> toggleFavorite(int storeId) async {
    try {
      await _storeService.toggleFavorite(storeId);
      await loadFavoriteStores();
    } catch (e) {
      // Handle error
    }
  }

  void dispose() {
    _storesSubject.close();
    _favoriteStoresSubject.close();
    _loadingSubject.close();
  }
}

class StoreStateData {
  final List<Store> stores;
  final List<Store> favoriteStores;
  final bool isLoading;

  StoreStateData({
    required this.stores,
    required this.favoriteStores,
    required this.isLoading,
  });
}
