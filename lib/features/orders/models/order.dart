import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/json_parse.dart';
import 'order_item.dart';

class OrderStatusLog {
  const OrderStatusLog({
    required this.id,
    required this.status,
    this.changedByName,
    required this.createdAt,
  });

  final int id;
  final String status;
  final String? changedByName;
  final DateTime? createdAt;

  factory OrderStatusLog.fromJson(Map<String, dynamic> json) {
    final user = json['changed_by_user'] as Map<String, dynamic>?;
    return OrderStatusLog(
      id: parseInt(json['id']),
      status: json['status']?.toString() ?? '',
      changedByName: user?['name']?.toString(),
      createdAt: parseDateTime(json['created_at']),
    );
  }
}

class Order {
  const Order({
    required this.id,
    this.customerName,
    this.customerPhone,
    this.cashierName,
    required this.orderType,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentChannel,
    this.qrCodeUrl,
    this.vaNumber,
    required this.queueNumber,
    required this.subtotal,
    this.discountAmount = 0,
    required this.total,
    this.notes,
    required this.items,
    required this.createdAt,
    this.pickupTime,
    this.statusLogs = const [],
  });

  final int id;
  final String? customerName;
  final String? customerPhone;
  final String? cashierName;
  final String orderType; // preorder | walkin
  final String status; // pending | processing | ready | completed | cancelled
  final String paymentMethod; // cash | qris | virtual_account
  final String paymentStatus; // unpaid | paid
  final String? paymentChannel;
  final String? qrCodeUrl;
  final String? vaNumber;
  final int queueNumber;
  final double subtotal;
  final double discountAmount;
  final double total;
  final String? notes;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? pickupTime;
  final List<OrderStatusLog> statusLogs;

  bool get isActive =>
      status == 'pending' || status == 'processing' || status == 'ready';
  bool get isPaid => paymentStatus == 'paid';
  bool get isWalkin => orderType == 'walkin';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'ready':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return AppColors.alert;
      case 'processing':
        return AppColors.primary;
      case 'ready':
        return AppColors.accent;
      case 'completed':
        return AppColors.grey;
      case 'cancelled':
        return AppColors.alert;
      default:
        return AppColors.grey;
    }
  }

  String get queueNumberFormatted => queueNumber.toString().padLeft(3, '0');

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'qris':
        return 'QRIS';
      case 'virtual_account':
        return 'Virtual Account';
      default:
        return paymentMethod;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final cashier = json['cashier'] as Map<String, dynamic>?;
    return Order(
      id: parseInt(json['id']),
      customerName: user?['name']?.toString() ?? json['customer_name']?.toString(),
      customerPhone: user?['phone']?.toString(),
      cashierName: cashier?['name']?.toString(),
      orderType: json['order_type']?.toString() ?? 'walkin',
      status: json['status']?.toString() ?? 'pending',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      paymentChannel: json['payment_channel']?.toString(),
      qrCodeUrl: json['qr_code_url']?.toString(),
      vaNumber: json['va_number']?.toString(),
      queueNumber: parseInt(json['queue_number']),
      subtotal: parseDouble(json['subtotal']),
      discountAmount: parseDouble(json['discount_amount']),
      total: parseDouble(json['total']),
      notes: json['notes']?.toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      pickupTime: parseDateTime(json['pickup_time']),
      statusLogs: (json['status_logs'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderStatusLog.fromJson)
          .toList(),
    );
  }
}
