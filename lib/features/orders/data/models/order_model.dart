import 'dart:convert';

import 'package:huystore/core/utils/helper.dart';

/// ===============================
/// Helpers chung
/// ===============================
DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    // epoch ms
    return DateTime.fromMillisecondsSinceEpoch(v);
  }
  if (v is String && v.trim().isNotEmpty) {
    return DateTime.tryParse(v);
  }
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String && v.isNotEmpty) return int.tryParse(v);
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String && v.isNotEmpty) return double.tryParse(v);
  return null;
}

T? _firstNonNull<T>(Map m, List<String> keys) {
  for (final k in keys) {
    if (m.containsKey(k) && m[k] != null) return m[k] as T;
  }
  return null;
}
 

class OrderStatusText {
  static const String waitingConfirm = "OrderWaitingConfirm";
  static const String getting = "OrderGetting";
  static const String received = "OrderReceived";
  static const String checking = "OrderChecking";
  static const String quotingPrice = "OrderQuotingPrice";
  static const String waitingConfirmPrice = "OrderWaitingConfirmPrice";
  static const String confirmPrice = "OrderConfirmPrice";
  static const String editing = "OrderEditing";
  static const String fixedWaitingDelivery = "OrderFixedWaitingDelivery";
  static const String delivering = "OrderDelivering";
  static const String completedDelivered = "OrderCompletedDelivered";
  static const String customerRefused = "OrderCustomerRefusedNotRepair";
}

/// ===============================
/// RepairMediaModel
/// ===============================
class RepairMediaModel {
  int? id;
  int? orderId;
  int? orderDetailId;
  int? orderStepId;
  String? fileUrl;
  String? fileType; // image | video | ...
  String? description;
  DateTime? uploadedAt;
  int? createdBy;

  RepairMediaModel({
    this.id,
    this.orderId,
    this.orderDetailId,
    this.orderStepId,
    this.fileUrl,
    this.fileType,
    this.description,
    this.uploadedAt,
    this.createdBy,
  });

  factory RepairMediaModel.fromJson(Map<String, dynamic> json) {
    return RepairMediaModel(
      id: _toInt(_firstNonNull(json, ['id', 'Id'])),
      orderId: _toInt(_firstNonNull(json, ['orderId', 'OrderId'])),
      orderDetailId: _toInt(
        _firstNonNull(json, ['orderDetailId', 'OrderDetailId']),
      ),
      orderStepId: _toInt(_firstNonNull(json, ['orderStepId', 'OrderStepId'])),
      fileUrl: _firstNonNull<String>(json, [
        'fileUrl',
        'FileUrl',
        'url',
        'Url',
      ]),
      fileType: _firstNonNull<String>(json, [
        'fileType',
        'FileType',
        'type',
        'Type',
      ]),
      description: _firstNonNull<String>(json, [
        'description',
        'Description',
        'note',
      ]),
      uploadedAt: _parseDate(_firstNonNull(json, ['uploadedAt', 'UploadedAt'])),
      createdBy: _toInt(_firstNonNull(json, ['createdBy', 'CreatedBy'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'Id': id,
    'OrderId': orderId,
    'OrderDetailId': orderDetailId,
    'OrderStepId': orderStepId,
    'FileUrl': fileUrl,
    'FileType': fileType,
    'Description': description,
    'UploadedAt': uploadedAt?.toIso8601String(),
    'CreatedBy': createdBy,
  };

  // Thêm phương thức copyWith để dễ dàng cập nhật

  RepairMediaModel copyWith({
    int? id,
    int? orderId,
    int? orderDetailId,
    int? orderStepId,
    String? fileUrl,
    String? fileType,
    String? description,
    DateTime? uploadedAt,
    int? createdBy,
  }) {
    return RepairMediaModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderDetailId: orderDetailId ?? this.orderDetailId,
      orderStepId: orderStepId ?? this.orderStepId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      description: description ?? this.description,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// ===============================
/// OrderStepModel
/// ===============================
class OrderStepModel {
  int? id;
  String? name;
  int? orderId;
  int? orderDetailId;
  int? serviceId;
  int? stepId;
  int? statusId;
  int? sortOrders;
  String? description;
  int? createdBy;
  DateTime? createdAt;
  int? updatedBy;
  DateTime? updatedAt;
  String? status;
  List<RepairMediaModel> medias;

  OrderStepModel({
    this.id,
    this.name,
    this.orderId,
    this.orderDetailId,
    this.serviceId,
    this.stepId,
    this.statusId,
    this.sortOrders,
    this.description,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.status,
    List<RepairMediaModel>? medias,
  }) : medias = medias ?? <RepairMediaModel>[];

  bool get isDone => statusId == StepStatusId.done;

  factory OrderStepModel.fromJson(Map<String, dynamic> json) {
    final rawMedias =
        _firstNonNull<List<dynamic>>(json, [
          'medias',
          'Media',
          'repairMedia',
          'RepairMedia',
        ]) ??
        const [];
    List<RepairMediaModel> parsedMedias = [];
    if (rawMedias is List) {
      parsedMedias = rawMedias
          .map((e) {
            try {
              if (e == null) return null;
              if (e is RepairMediaModel) return e;
              if (e is Map<String, dynamic>)
                return RepairMediaModel.fromJson(e);
              if (e is Map)
                return RepairMediaModel.fromJson((e).cast<String, dynamic>());
              if (e is String) {
                final decoded = jsonDecode(e);
                if (decoded is Map)
                  return RepairMediaModel.fromJson(
                    decoded.cast<String, dynamic>(),
                  );
              }
            } catch (_) {}
            return null;
          })
          .whereType<RepairMediaModel>()
          .toList();
    }

    return OrderStepModel(
      id: _toInt(_firstNonNull(json, ['id', 'Id'])),
      name: _firstNonNull<String>(json, ['name', 'Name']),
      orderId: _toInt(_firstNonNull(json, ['orderId', 'OrderId'])),
      orderDetailId: _toInt(
        _firstNonNull(json, ['orderDetailId', 'OrderDetailId']),
      ),
      serviceId: _toInt(_firstNonNull(json, ['serviceId', 'ServiceId'])),
      stepId: _toInt(_firstNonNull(json, ['stepId', 'StepId'])),
      statusId: _toInt(_firstNonNull(json, ['statusId', 'StatusId'])),
      sortOrders: _toInt(_firstNonNull(json, ['sortOrders', 'SortOrders'])),
      description: _firstNonNull<String>(json, ['description', 'Description']),
      createdBy: _toInt(_firstNonNull(json, ['createdBy', 'CreatedBy'])),
      createdAt: _parseDate(_firstNonNull(json, ['createdAt', 'CreatedAt'])),
      updatedBy: _toInt(_firstNonNull(json, ['updatedBy', 'UpdatedBy'])),
      updatedAt: _parseDate(_firstNonNull(json, ['updatedAt', 'UpdatedAt'])),
      status: _firstNonNull<String>(json, ['status', 'Status']),
      medias: parsedMedias,
    );
  }

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    'OrderId': orderId,
    'OrderDetailId': orderDetailId,
    'ServiceId': serviceId,
    'StepId': stepId,
    'StatusId': statusId,
    'SortOrders': sortOrders,
    'Description': description,
    'CreatedBy': createdBy,
    'CreatedAt': createdAt?.toIso8601String(),
    'UpdatedAt': updatedAt?.toIso8601String(),
    'UpdatedBy': updatedBy,
    'Status': status,
    'RepairMedia': medias.map((e) => e.toJson()).toList(),
  };

  OrderStepModel copyWith({
    int? id,
    String? name,
    int? orderId,
    int? orderDetailId,
    int? serviceId,
    int? stepId,
    int? statusId,
    int? sortOrders,
    String? description,
    int? createdBy,
    DateTime? createdAt,
    int? updatedBy,
    DateTime? updatedAt,
    String? status,
    List<RepairMediaModel>? medias,
  }) {
    return OrderStepModel(
      id: id ?? this.id,
      name: name ?? this.name,
      orderId: orderId ?? this.orderId,
      orderDetailId: orderDetailId ?? this.orderDetailId,
      serviceId: serviceId ?? this.serviceId,
      stepId: stepId ?? this.stepId,
      statusId: statusId ?? this.statusId,
      sortOrders: sortOrders ?? this.sortOrders,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      medias: medias ?? this.medias,
    );
  }
}

/// ===============================
/// OrderDetailModel
/// ===============================
class OrderDetailModel {
  int? id;
  int? orderId;
  int? serviceId;
  int? statusId;
  String? status;
  String? description;
  double? unitPrice;
  int? quantity;
  double? vatRate;
  double? totalAmount;
  String? serviceName;

  List<OrderStepModel> steps;
  List<RepairMediaModel> medias;

  OrderDetailModel({
    this.id,
    this.orderId,
    this.serviceId,
    this.statusId,
    this.status,
    this.description,
    this.unitPrice,
    this.quantity,
    this.vatRate,
    this.totalAmount,
    this.serviceName,
    List<OrderStepModel>? steps,
    List<RepairMediaModel>? medias,
  }) : steps = steps ?? <OrderStepModel>[],
       medias = medias ?? <RepairMediaModel>[];

  bool get isCompleted {
    if (steps.isNotEmpty) {
      return steps.every((s) => s.isDone);
    }
    return status == DetailStatusText.completed;
  }

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final rawSteps =
        _firstNonNull<List<dynamic>>(json, ['steps', 'Steps']) ?? const [];
    final rawMedias =
        _firstNonNull<List<dynamic>>(json, [
          'medias',
          'Media',
          'repairMedia',
          'RepairMedia',
        ]) ??
        const [];

    List<OrderStepModel> parsedSteps = [];
    if (rawSteps is List) {
      parsedSteps = rawSteps
          .map((e) {
            try {
              if (e == null) return null;
              if (e is OrderStepModel) return e;
              if (e is Map<String, dynamic>) return OrderStepModel.fromJson(e);
              if (e is Map)
                return OrderStepModel.fromJson((e).cast<String, dynamic>());
              if (e is String) {
                final decoded = jsonDecode(e);
                if (decoded is Map)
                  return OrderStepModel.fromJson(
                    decoded.cast<String, dynamic>(),
                  );
              }
            } catch (_) {}
            return null;
          })
          .whereType<OrderStepModel>()
          .toList();
    }

    List<RepairMediaModel> parsedDetailMedias = [];
    if (rawMedias is List) {
      parsedDetailMedias = rawMedias
          .map((e) {
            try {
              if (e == null) return null;
              if (e is RepairMediaModel) return e;
              if (e is Map<String, dynamic>)
                return RepairMediaModel.fromJson(e);
              if (e is Map)
                return RepairMediaModel.fromJson((e).cast<String, dynamic>());
              if (e is String) {
                final decoded = jsonDecode(e);
                if (decoded is Map)
                  return RepairMediaModel.fromJson(
                    decoded.cast<String, dynamic>(),
                  );
              }
            } catch (_) {}
            return null;
          })
          .whereType<RepairMediaModel>()
          .toList();
    }

    return OrderDetailModel(
      id: _toInt(_firstNonNull(json, ['id', 'Id'])),
      orderId: _toInt(_firstNonNull(json, ['orderId', 'OrderId'])),
      serviceId: _toInt(_firstNonNull(json, ['serviceId', 'ServiceId'])),
      statusId: _toInt(_firstNonNull(json, ['statusId', 'StatusId'])),
      status: _firstNonNull<String>(json, ['status', 'Status']),
      description: _firstNonNull<String>(json, ['description', 'Description']),
      unitPrice: _toDouble(_firstNonNull(json, ['unitPrice', 'UnitPrice'])),
      quantity: _toInt(_firstNonNull(json, ['quantity', 'Quantity'])),
      vatRate: _toDouble(_firstNonNull(json, ['vatRate', 'VATRate'])),
      totalAmount: _toDouble(
        _firstNonNull(json, ['totalAmount', 'TotalAmount']),
      ),
      serviceName: _firstNonNull<String>(json, ['serviceName', 'ServiceName']),
      steps: parsedSteps,
      medias: parsedDetailMedias,
    );
  }

  Map<String, dynamic> toJson() => {
    'Id': id,
    'OrderId': orderId,
    'ServiceId': serviceId,
    'StatusId': statusId,
    'Status': status,
    'Description': description,
    'UnitPrice': unitPrice,
    'Quantity': quantity,
    'VATRate': vatRate,
    'TotalAmount': totalAmount,
    'ServiceName': serviceName,
    'Steps': steps.map((e) => e.toJson()).toList(),
    'RepairMedia': medias.map((e) => e.toJson()).toList(),
  };

  OrderDetailModel copyWith({
    int? id,
    int? orderId,
    int? serviceId,
    int? statusId,
    String? status,
    String? description,
    double? unitPrice,
    int? quantity,
    double? vatRate,
    double? totalAmount,
    String? serviceName,
    List<OrderStepModel>? steps,
    List<RepairMediaModel>? medias,
  }) {
    return OrderDetailModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      serviceId: serviceId ?? this.serviceId,
      statusId: statusId ?? this.statusId,
      status: status ?? this.status,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      vatRate: vatRate ?? this.vatRate,
      totalAmount: totalAmount ?? this.totalAmount,
      serviceName: serviceName ?? this.serviceName,
      steps: steps ?? this.steps,
      medias: medias ?? this.medias,
    );
  }
}

/// ===============================
/// OrderModel
/// ===============================
class OrderModel {
  int? id;
  String? code;
  int? customerId;
  String? customerCode;
  String? customerName;
  String? customerAddress;
  String? phoneNumber;
  int? shopId;
  int? accountId;
  String? description;
  double? estimatedPrice;
  double? discountAmout;
  double? totalPrice;
  double? vatRate;
  double? extraFee;
  int? statusId;
  int? paymentStatus;
  String? status;
  DateTime? desiredTime;
  int? createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? updatedBy;
  DateTime? dateCompletion;

  List<OrderDetailModel> details;
  List<RepairMediaModel> medias;
  String? statusName;
  String? shopName;

  OrderModel({
    this.id,
    this.code,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.customerAddress,
    this.phoneNumber,
    this.shopId,
    this.accountId,
    this.description,
    this.estimatedPrice,
    this.totalPrice,
    this.vatRate,
    this.extraFee,
    this.discountAmout,
    this.statusId,
    this.status,
    this.paymentStatus,
    this.desiredTime,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.dateCompletion,
    List<OrderDetailModel>? details,
    List<RepairMediaModel>? medias,
    this.shopName,
    this.statusName,
  }) : details = details ?? <OrderDetailModel>[],
       medias = medias ?? <RepairMediaModel>[];

  bool get isCompleted =>
      details.isNotEmpty && details.every((d) => d.isCompleted);

  int get totalSteps {
    int t = 0;
    for (final d in details) {
      t += d.steps.length;
    }
    return t;
  }

  int get doneSteps {
    int dcount = 0;
    for (final d in details) {
      dcount += d.steps.where((s) => s.isDone).length;
    }
    return dcount;
  }

  double get progress {
    final t = totalSteps;
    if (t == 0) return 0;
    return doneSteps / t;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawDetails =
        _firstNonNull<List<dynamic>>(json, ['details', 'Details']) ?? const [];
    final rawMedias =
        _firstNonNull<List<dynamic>>(json, [
          'medias',
          'Media',
          'repairMedia',
          'RepairMedia',
        ]) ??
        const [];

    List<OrderDetailModel> parsedDetails = [];
    if (rawDetails is List) {
      parsedDetails = rawDetails
          .map((e) {
            try {
              if (e == null) return null;
              if (e is OrderDetailModel) return e;
              if (e is Map<String, dynamic>)
                return OrderDetailModel.fromJson(e);
              if (e is Map)
                return OrderDetailModel.fromJson((e).cast<String, dynamic>());
              if (e is String) {
                final decoded = jsonDecode(e);
                if (decoded is Map)
                  return OrderDetailModel.fromJson(
                    decoded.cast<String, dynamic>(),
                  );
              }
            } catch (_) {}
            return null;
          })
          .whereType<OrderDetailModel>()
          .toList();
    }

    List<RepairMediaModel> parsedMedias = [];
    if (rawMedias is List) {
      parsedMedias = rawMedias
          .map((e) {
            try {
              if (e == null) return null;
              if (e is RepairMediaModel) return e;
              if (e is Map<String, dynamic>)
                return RepairMediaModel.fromJson(e);
              if (e is Map)
                return RepairMediaModel.fromJson((e).cast<String, dynamic>());
              if (e is String) {
                final decoded = jsonDecode(e);
                if (decoded is Map)
                  return RepairMediaModel.fromJson(
                    decoded.cast<String, dynamic>(),
                  );
              }
            } catch (_) {}
            return null;
          })
          .whereType<RepairMediaModel>()
          .toList();
    }

    return OrderModel(
      id: _toInt(_firstNonNull(json, ['id', 'Id'])),
      code: _firstNonNull<String>(json, ['code', 'Code']),
      customerId: _toInt(_firstNonNull(json, ['customerId', 'CustomerId'])),
      customerCode: _firstNonNull<String>(json, [
        'customerCode',
        'CustomerCode',
      ]),
      customerName: _firstNonNull<String>(json, [
        'customerName',
        'CustomerName',
      ]),
      customerAddress: _firstNonNull<String>(json, [
        'customerAddress',
        'CustomerAddress',
      ]),
      phoneNumber: _firstNonNull<String>(json, [
        'phoneNumber',
        'PhoneNumber',
        'phone',
      ]),
      shopId: _toInt(_firstNonNull(json, ['shopId', 'ShopId'])),
      accountId: _toInt(_firstNonNull(json, ['accountId', 'AccountId'])),
      description: _firstNonNull<String>(json, ['description', 'Description']),
      estimatedPrice: _toDouble(
        _firstNonNull(json, ['estimatedPrice', 'EstimatedPrice']),
      ),
      totalPrice: _toDouble(_firstNonNull(json, ['totalPrice', 'TotalPrice'])),
      vatRate: _toDouble(
        _firstNonNull(json, ['vatRate', 'VatRate', 'VATRate']),
      ),
      extraFee: _toDouble(_firstNonNull(json, ['extraFee', 'ExtraFee'])),
      discountAmout: _toDouble(
        _firstNonNull(json, ['discountAmout', 'discountAmout']),
      ),
      statusId: _toInt(_firstNonNull(json, ['statusId', 'StatusId'])),
      paymentStatus: _toInt(
        _firstNonNull(json, ['PaymentStatus', 'PaymentStatus']),
      ),
      status: _firstNonNull<String>(json, ['status', 'Status']),
      desiredTime: _parseDate(
        _firstNonNull(json, ['desiredTime', 'DesiredTime']),
      ),
      createdBy: _toInt(_firstNonNull(json, ['createdBy', 'CreatedBy'])),
      createdAt: _parseDate(_firstNonNull(json, ['createdAt', 'CreatedAt'])),
      updatedAt: _parseDate(_firstNonNull(json, ['updatedAt', 'UpdatedAt'])),
      updatedBy: _toInt(_firstNonNull(json, ['updatedBy', 'UpdatedBy'])),
      dateCompletion: _parseDate(
        _firstNonNull(json, ['dateCompletion', 'DateCompletion']),
      ),
      details: parsedDetails,
      medias: parsedMedias,
      statusName: _firstNonNull<String>(json, ['statusName', 'StatusName']),
      shopName: _firstNonNull<String>(json, ['shopName', 'ShopName']),
    );
  }

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Code': code,
    'CustomerId': customerId,
    'CustomerCode': customerCode,
    'CustomerName': customerName,
    'CustomerAddress': customerAddress,
    'PhoneNumber': phoneNumber,
    'ShopId': shopId,
    'AccountId': accountId,
    'Description': description,
    'EstimatedPrice': estimatedPrice,
    'TotalPrice': totalPrice,
    'VatRate': vatRate,
    'DiscountAmout':discountAmout,
    'ExtraFee': extraFee,
    'StatusId': statusId,
    'PaymentStatus': paymentStatus,
    'Status': status,
    'DesiredTime': desiredTime?.toIso8601String(),
    'CreatedBy': createdBy,
    'CreatedAt': createdAt?.toIso8601String(),
    'UpdatedAt': updatedAt?.toIso8601String(),
    'UpdatedBy': updatedBy,
    'DateCompletion': dateCompletion?.toIso8601String(),
    'Details': details.map((e) => e.toJson()).toList(),
    'RepairMedia': medias.map((e) => e.toJson()).toList(),
    'StatusName': statusName,
    'ShopName': shopName,
  };

  OrderModel copyWith({
    int? id,
    String? code,
    int? customerId,
    String? customerCode,
    String? customerName,
    String? customerAddress,
    String? phoneNumber,
    int? shopId,
    int? accountId,
    String? description,
    double? estimatedPrice,
    double? totalPrice,
    double?discountAmout,
    double? vatRate,
    double? extraFee,
    int? statusId,
    int? paymentStatus,
    String? status,
    DateTime? desiredTime,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? updatedBy,
    DateTime? dateCompletion,
    List<OrderDetailModel>? details,
    List<RepairMediaModel>? medias,
    String? statusName,
    String? shopName,
  }) {
    return OrderModel(
      id: id ?? this.id,
      code: code ?? this.code,
      customerId: customerId ?? this.customerId,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shopId: shopId ?? this.shopId,
      accountId: accountId ?? this.accountId,
      description: description ?? this.description,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      vatRate: vatRate ?? this.vatRate,
      extraFee: extraFee ?? this.extraFee,
      discountAmout:discountAmout??this.discountAmout,
      statusId: statusId ?? this.statusId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      desiredTime: desiredTime ?? this.desiredTime,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      dateCompletion: dateCompletion ?? this.dateCompletion,
      details: details ?? this.details,
      medias: medias ?? this.medias,
      statusName: statusName ?? this.statusName,
      shopName: shopName ?? this.shopName,
    );
  }
}

/// ===============================
/// Convenience parsers
/// ===============================
OrderModel parseOrderModel(dynamic data) {
  if (data is OrderModel) return data;
  if (data is Map<String, dynamic>) return OrderModel.fromJson(data);
  if (data is Map) return OrderModel.fromJson((data).cast<String, dynamic>());
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return OrderModel.fromJson(decoded);
    if (decoded is Map)
      return OrderModel.fromJson(decoded.cast<String, dynamic>());
  }
  throw ArgumentError('Invalid order payload');
}

List<OrderDetailModel> parseOrderDetailList(dynamic data) {
  if (data is List) {
    return data
        .map((e) {
          try {
            if (e is OrderDetailModel) return e;
            if (e is Map<String, dynamic>) return OrderDetailModel.fromJson(e);
            if (e is Map)
              return OrderDetailModel.fromJson(e.cast<String, dynamic>());
            if (e is String && e.isNotEmpty) {
              final decoded = jsonDecode(e);
              if (decoded is Map)
                return OrderDetailModel.fromJson(
                  decoded.cast<String, dynamic>(),
                );
            }
          } catch (_) {}
          return null;
        })
        .whereType<OrderDetailModel>()
        .toList();
  }
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is List) {
      return decoded
          .map((e) {
            try {
              if (e is Map<String, dynamic>)
                return OrderDetailModel.fromJson(e);
              if (e is Map)
                return OrderDetailModel.fromJson(e.cast<String, dynamic>());
            } catch (_) {}
            return null;
          })
          .whereType<OrderDetailModel>()
          .toList();
    }
  }
  return const <OrderDetailModel>[];
}

class OrderListResponse {
  final int totalRows;
  final List<OrderModel> data;
  final bool isSuccessed;
  final String? message;
  final int pageCount;
  final int pageSize;

  OrderListResponse({
    required this.totalRows,
    required this.data,
    required this.isSuccessed,
    this.message,
    required this.pageCount,
    required this.pageSize,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      totalRows: json['totalRows'] ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((x) => OrderModel.fromJson(x as Map<String, dynamic>))
          .toList(),
      isSuccessed: json['isSuccessed'] ?? false,
      message: json['message'],
      pageCount: json['pageCount'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
    );
  }

  /// ✅ Object rỗng thay vì null
  factory OrderListResponse.empty() {
    return OrderListResponse(
      totalRows: 0,
      data: [],
      isSuccessed: false,
      message: null,
      pageCount: 0,
      pageSize: 0,
    );
  }
}
