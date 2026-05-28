import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/category.dart';
import '../models/menu.dart';

class MenuService {
  MenuService._();

  static Future<List<Menu>> getMenus() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.menus);
      final list = _unwrapList(res.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map(Menu.fromJson)
          .where((m) => m.isActive)
          .toList();
    } on DioException catch (e) {
      throw Exception(extractApiError(e));
    }
  }

  static Future<List<MenuCategory>> getCategories() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.categories);
      final list = _unwrapList(res.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map(MenuCategory.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(extractApiError(e));
    }
  }

  static List<dynamic> _unwrapList(Object? body) {
    if (body is Map && body['data'] is List) {
      return body['data'] as List<dynamic>;
    }
    if (body is List) return body;
    return const [];
  }
}
