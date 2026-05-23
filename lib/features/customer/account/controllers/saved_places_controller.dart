import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPlacesController extends GetxController {
  static SavedPlacesController get to => Get.find<SavedPlacesController>();

  final RxList<Map<String, dynamic>> favoritePlaces = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> savedPlaces = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final favStr = prefs.getString('favoritePlaces');
    if (favStr != null) {
      final List<dynamic> decoded = jsonDecode(favStr);
      favoritePlaces.value = decoded.cast<Map<String, dynamic>>();
    }

    final savedStr = prefs.getString('savedPlaces');
    if (savedStr != null) {
      final List<dynamic> decoded = jsonDecode(savedStr);
      savedPlaces.value = decoded.cast<Map<String, dynamic>>();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoritePlaces', jsonEncode(favoritePlaces));
    await prefs.setString('savedPlaces', jsonEncode(savedPlaces));
  }

  // Favorites logic
  bool isFavorite(String parkingId) {
    return favoritePlaces.any((place) => place['parking_lot']['id'].toString() == parkingId);
  }

  Future<void> addFavorite(Map<String, dynamic> parkingLot) async {
    final id = parkingLot['id'].toString();
    final index = favoritePlaces.indexWhere((place) => place['parking_lot']['id'].toString() == id);
    
    if (index < 0) {
      favoritePlaces.insert(0, {
        'parking_lot': parkingLot,
        'added_at': DateTime.now().toIso8601String(),
        'tags': <String>[], // Custom tags user can add
        'visit_count': 1, // Mock visit count
      });
      await _saveData();
    }
  }

  Future<void> removeFavorite(String parkingId) async {
    favoritePlaces.removeWhere((place) => place['parking_lot']['id'].toString() == parkingId);
    await _saveData();
  }

  Future<void> toggleFavorite(Map<String, dynamic> parkingLot) async {
    final id = parkingLot['id'].toString();
    final index = favoritePlaces.indexWhere((place) => place['parking_lot']['id'].toString() == id);
    
    if (index >= 0) {
      favoritePlaces.removeAt(index);
    } else {
      favoritePlaces.insert(0, {
        'parking_lot': parkingLot,
        'added_at': DateTime.now().toIso8601String(),
        'tags': <String>[], // Custom tags user can add
        'visit_count': 1, // Mock visit count
      });
    }
    await _saveData();
  }

  Future<void> addFavoriteTag(String parkingId, String tag) async {
    final index = favoritePlaces.indexWhere((place) => place['parking_lot']['id'].toString() == parkingId);
    if (index >= 0) {
      final tags = List<String>.from(favoritePlaces[index]['tags'] ?? []);
      if (!tags.contains(tag)) {
        tags.add(tag);
        favoritePlaces[index]['tags'] = tags;
        favoritePlaces.refresh();
        await _saveData();
      }
    }
  }

  // Saved logic
  bool isSaved(String parkingId) {
    return savedPlaces.any((place) => place['parking_lot']['id'].toString() == parkingId);
  }

  Future<void> savePlace(Map<String, dynamic> parkingLot, String folder, String note) async {
    final id = parkingLot['id'].toString();
    final index = savedPlaces.indexWhere((place) => place['parking_lot']['id'].toString() == id);
    
    final newSavedPlace = {
      'parking_lot': parkingLot,
      'folder': folder,
      'note': note,
      'saved_at': DateTime.now().toIso8601String(),
    };

    if (index >= 0) {
      savedPlaces[index] = newSavedPlace;
    } else {
      savedPlaces.insert(0, newSavedPlace);
    }
    await _saveData();
  }

  Future<void> removeSaved(String parkingId) async {
    savedPlaces.removeWhere((place) => place['parking_lot']['id'].toString() == parkingId);
    await _saveData();
  }

  // Clear cache (called from Account page)
  Future<void> clearAllCache() async {
    favoritePlaces.clear();
    savedPlaces.clear();
    await _saveData();
    Get.snackbar('Thành công', 'Đã xoá toàn bộ dữ liệu lưu trữ tạm thời', snackPosition: SnackPosition.TOP);
  }
}
