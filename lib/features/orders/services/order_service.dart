import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../pos/models/order_item_draft.dart';
import '../models/order.dart';

class OrderServiceException implements Exception {
  OrderServiceException(this.message, {this.statusCode, this.raw});
  final String message;
  final int? statusCode;
  final Object? raw;

  @override
  String toString() => message;
}

class OrderService {
  OrderService._();

  static Future<List<Order>> getStaffOrders({
    String? status,
    String? type,
    String? date,
  }) async {
    try {
      final res = await ApiClient.instance.get(
        ApiEndpoints.staffOrders,
        queryParameters: {
          'status': ?status,
          'type': ?type,
          'date': ?date,
        },
      );
      return _parseList(res.data);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  static Future<Order> getOrderDetail(int id) async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.staffOrderDetail(id));
      return Order.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  static Future<Order> updateOrderStatus(
    int id,
    String status, {
    String? notes,
  }) async {
    try {
      final res = await ApiClient.instance.patch(
        ApiEndpoints.updateOrderStatus(id),
        data: {
          'status': status,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return Order.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Create walk-in order (kasir flow).
  static Future<Order> createWalkInOrder({
    required List<OrderItemDraft> items,
    required String paymentMethod, // cash | qris | virtual_account
    String? paymentChannel,
    String? promoCode,
    String? notes,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.createOrder,
        data: {
          'order_type': 'walkin',
          'payment_method': paymentMethod,
          'payment_channel': ?paymentChannel,
          'items': items.map((i) => i.toApiPayload()).toList(),
          if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return Order.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Polling endpoint for QRIS/VA payment status.
  static Future<String> getPaymentStatus(int id) async {
    try {
      final res = await ApiClient.instance
          .get(ApiEndpoints.orderPaymentStatus(id));
      final data = _unwrapMap(res.data);
      return data['payment_status']?.toString() ?? 'unpaid';
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Cancel an order (used by walk-in QRIS/VA cancel flow before payment).
  static Future<void> cancelOrder(int id) async {
    try {
      await ApiClient.instance.delete(ApiEndpoints.cancelOrder(id));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  static OrderServiceException _map(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? msg;
    if (data is Map && data['message'] is String) {
      msg = data['message'] as String;
    }
    return OrderServiceException(
      msg ?? extractApiError(e),
      statusCode: status,
      raw: data,
    );
  }

  static Map<String, dynamic> _unwrapMap(Object? body) {
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return const {};
  }

  static List<Order> _parseList(Object? body) {
    final list = body is Map && body['data'] is List
        ? body['data'] as List<dynamic>
        : (body is List ? body : const <dynamic>[]);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList();
  }
}
