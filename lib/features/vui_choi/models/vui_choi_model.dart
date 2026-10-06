import 'package:cloud_firestore/cloud_firestore.dart';

class VuiChoiModel {
  final String id;
  final String name;
  final List<String> images;
  final String category; // "cafe", "rap_phim", "cong_vien"...
  final GeoPoint location;
  final String address;
  final String openHour;
  final String closeHour;
  final double ticketPrice;

  VuiChoiModel({
    required this.id,
    required this.name,
    required this.images,
    required this.category,
    required this.location,
    required this.address,
    required this.openHour,
    required this.closeHour,
    required this.ticketPrice,
  });

  factory VuiChoiModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VuiChoiModel(
      id: doc.id,
      name: data['name'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      category: data['category'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      address: data['address'] ?? '',
      openHour: data['openHour'] ?? '',
      closeHour: data['closeHour'] ?? '',
      ticketPrice: (data['ticketPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'images': images,
      'category': category,
      'location': location,
      'address': address,
      'openHour': openHour,
      'closeHour': closeHour,
      'ticketPrice': ticketPrice,
    };
  }
}