import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/json_parse.dart';
import '../../orders/models/order.dart';

class QueueEstimate {
  const QueueEstimate({required this.activeCount, required this.minutes});
  final int activeCount;
  final int minutes;

  factory QueueEstimate.fromJson(Map<String, dynamic> json) => QueueEstimate(
        activeCount: parseInt(json['active_count']),
        minutes: parseInt(json['estimated_minutes']),
      );
}

class QueueService {
  QueueService._();

  static Future<List<Order>> getActiveQueue() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.queueActive);
      final body = res.data;
      final list = body is Map && body['data'] is List
          ? body['data'] as List<dynamic>
          : (body is List ? body : const <dynamic>[]);
      return list
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(extractApiError(e));
    }
  }

  static Future<QueueEstimate> getEstimate() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.queueEstimate);
      final body = res.data;
      final data = body is Map && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : Map<String, dynamic>.from(body as Map);
      return QueueEstimate.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractApiError(e));
    }
  }
}
