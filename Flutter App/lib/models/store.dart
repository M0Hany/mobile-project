import 'package:hive_ce/hive.dart';
import 'product.dart';

part 'store.g.dart';

@HiveType(typeId: 1)
class Store {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final String? category;

  @HiveField(5)
  final double? rating;

  @HiveField(6)
  final String? imageUrl;

  @HiveField(7)
  List<Product> products;

  @HiveField(8)
  final double? distance;

  @HiveField(9)
  final String? routePolyline;

  @HiveField(10)
  final List<String>? directions;

  Store({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.category,
    this.rating,
    this.imageUrl,
    List<Product>? products,
    this.distance,
    this.routePolyline,
    this.directions,
  }) : this.products = products ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'rating': rating,
      'image_url': imageUrl,
      'products': products.map((product) => product.toMap()).toList(),
      'distance': distance,
      'route_polyline': routePolyline,
      'directions': directions,
    };
  }

  factory Store.fromMap(Map<String, dynamic> map) {
    // Helper function to parse numeric values
    double parseNumeric(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    return Store(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      name: map['name'],
      latitude: parseNumeric(map['latitude']),
      longitude: parseNumeric(map['longitude']),
      category: map['category'],
      rating: map['rating'] != null ? parseNumeric(map['rating']) : null,
      imageUrl: map['image_url'],
      products: map['products'] != null
          ? (map['products'] as List)
              .map((product) => Product.fromMap(product))
              .toList()
          : [],
      distance: map['distance'] != null ? parseNumeric(map['distance']) : null,
      routePolyline: map['route_polyline'],
      directions: map['directions'] != null
          ? (map['directions'] as List).cast<String>()
          : null,
    );
  }

  Store copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    String? category,
    double? rating,
    String? imageUrl,
    List<Product>? products,
    double? distance,
    String? routePolyline,
    List<String>? directions,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      products: products ?? this.products,
      distance: distance ?? this.distance,
      routePolyline: routePolyline ?? this.routePolyline,
      directions: directions ?? this.directions,
    );
  }
}
