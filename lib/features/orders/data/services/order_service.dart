import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:huystore/core/services/api_service.dart';
import 'package:huystore/features/home/data/models/order_statistics.dart';
import 'package:huystore/features/orders/data/models/account_model.dart';
import 'package:huystore/features/orders/data/models/bank_account_model.dart';
import 'package:huystore/features/orders/data/models/combo_model.dart';
import 'package:huystore/features/orders/data/models/customer_model.dart';
import 'package:huystore/features/orders/data/models/order_full_model.dart';
import 'package:huystore/features/orders/data/models/order_model.dart'; 
import 'package:huystore/features/orders/data/models/service_model.dart';
import 'package:http/http.dart' as http;

class OrderService extends ApiService { 
  dynamic _unwrapData(dynamic data) {
    final d = data is String ? jsonDecode(data) : data;
    if (d is Map && d.containsKey('data')) return d['data'];
    return d;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected response shape');
  }

  /**
 * 
 */
  Future<OrderStatisticModel> getHomeOrderStatistics() async {
    try {
      final response = await get("orders/gethomeorderstatistics");
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        return OrderStatisticModel.fromJson(data);
      }
      throw Exception("Failed to load order statistics");
    } on DioException catch (e) {
      throw Exception("Failed to load order statistics: ${e.message}");
    }
  }

  Future<OrderListResponse> getOrders({
    List<int>? statusIds,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final query = {
        'Skip': skip,
        'Take': take,
        'Sort': jsonEncode([
          {"field": "Id", "dir": "desc"},
        ]),
      };

      if (statusIds != null && statusIds.isNotEmpty) {
        query["StatusIds"] = statusIds.join(',');
      }

      final response = await get('orders/getlistmobilepaging', query: query);

      if (response.statusCode == 200) {
        final data = response.data;
        return OrderListResponse.fromJson(data);
      }

      // nếu code khác 200 thì trả object rỗng
      return OrderListResponse.empty();
    } catch (e) {
      print('getOrders error: $e');
      return OrderListResponse.empty();
    }
  }

  /**
 * 
 */
  Future<OrderListResponse> searchOrders({
    String searchQuery = "",
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final query = {
        'Skip': skip,
        'Take': take,
        'Sort': jsonEncode([
          {"field": "Id", "dir": "desc"},
        ]),
        'SearchKey': searchQuery,
      };
      final response = await get('orders/getlistmobilepaging', query: query);
      if (response.statusCode == 200 && response.data != null) {
         final data = response.data;
        return OrderListResponse.fromJson(data);
      }
     return OrderListResponse.empty();
    } catch (e) {
      print('searchOrders error: $e');
     return OrderListResponse.empty();
    }
  }

  Future<OrderListResponse> searchOrdersByPhone({
    String phoneNumber = "",
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final query = {
        'Skip': skip,
        'Take': take,
        'Sort': jsonEncode([
          {"field": "Id", "dir": "desc"},
        ]),
        'PhoneNumber': phoneNumber,
      };
      final response = await get(
        'orders/GetListMobileGuestPaging',
        query: query,
      );
      if (response.statusCode == 200 && response.data != null) {
           final data = response.data;
        return OrderListResponse.fromJson(data);
      }
       return OrderListResponse.empty();
    } catch (e) {
      print('searchOrdersByPhone error: $e');
       return OrderListResponse.empty();
    }
  }

  // --------- GET ----------
  /// Lấy chi tiết đơn theo orderId (trả về OrderModel)
  Future<OrderModel> getOrderById(int orderId) async {
    try {
      final Response res = await get("orders/get/$orderId");
      if (res.statusCode == 200 && res.data != null) {
        final body = _asMap(_unwrapData(res.data));
        return OrderModel.fromJson(body);
      }
      throw Exception("Failed to load order, status: ${res.statusCode}");
    } on DioException catch (e) {
      throw Exception("Dio error: ${e.message}");
    }
  }

  /// Lấy chi tiết full theo id + code (QR)
  Future<OrderFullModel> getOrderDetail(int id, String code) async {
    try {
      final Response res = await get("orders/viewfullorder/$id/$code");
      if (res.statusCode == 200 && res.data != null) {
        final body = _asMap(_unwrapData(res.data));
        return OrderFullModel.fromJson(body);
      }
      throw Exception("Failed to load order detail, status: ${res.statusCode}");
    } on DioException catch (e) {
      throw Exception("Dio error: ${e.message}");
    }
  }

  // --------- UPDATE (KHÔNG KÈM FILE) ----------
  /// Cập nhật trạng thái đơn
  Future<Response> updateOrderStatus(
    int orderId,
    int statusId,
    String code,
    int customerId,
  ) async {
    try {
      return await patch(
        "orders/UpdateStatus/$orderId",
        data: {"statusId": statusId, "code": code, "CustomerId": customerId},
      );
    } on DioException catch (e) {
      throw Exception("Update order status failed: ${e.message}");
    }
  }

  /// Cập nhật trạng thái chi tiết
  Future<Response> updateOrderDetailStatus(int detailId, int statusId) async {
    try {
      return await patch(
        "orders/UpdateorderdetailStatus/$detailId",
        data: {"statusId": statusId},
      );
    } on DioException catch (e) {
      throw Exception("Update order detail failed: ${e.message}");
    }
  }

  /// Cập nhật trạng thái step (KHÔNG upload file ở đây)
  Future<Response> updateOrderStepStatus(
    int stepId,
    int statusId, {
    String? note,
  }) async {
    try {
      final payload = {"statusId": statusId, if (note != null) "note": note};
      return await patch("orders/UpdateOrderStep/$stepId", data: payload);
    } on DioException catch (e) {
      throw Exception("Update order step failed: ${e.message}");
    }
  }

  /// (Nếu BE có endpoint này) Cập nhật theo id + code (KHÔNG file)
  Future<Response> updateOrderByIdAndCode({
    required String id,
    required String code,
    required String status,
  }) async {
    try {
      return await post(
        "orders/update",
        data: {"id": id, "code": code, "statusId": status},
      );
    } on DioException catch (e) {
      throw Exception("Update order (id+code) failed: ${e.message}");
    }
  }

  //*tao don nhanh */
  Future<Response> createOrder(Map<String, dynamic> orderData) async {
    try {
      return await post('orders/CreateOrderMobile', data: orderData);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /**
   * 
   */
  Future<Response> updateOrder(int id, Map<String, dynamic> orderData) async {
    try {
      return await put(
        'orders/updatefrommobile/' + id.toString(),
        data: orderData,
      );
    } catch (e) {
      throw Exception('Failed to updatefrommobile order: $e');
    }
  }

  /**
 * F
 */
  Future<Response> updateOrderPaymentStatus(
    int id,
    Map<String, dynamic> orderData,
  ) async {
    try {
      return await put('/orders/updatepaymentstatus/$id', data: orderData);
    } catch (e) {
      throw Exception('Failed to updatefrommobile order: $e');
    }
  }

  /**
 * 
 */
  Future<BankAccountModel> getBankAccountInfo() async {
    try {
      final response = await get('/shops/getbankaccounts');

      if (response.statusCode == 200) {
        final jsonRes = response.data;

        // API trả về: { statusCode: 200, message: null, data: {...} }
        final data = jsonRes['data'];
        return BankAccountModel.fromJson(data);
      } else {
        throw Exception("API lỗi: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Failed to get bank account info: $e');
    }
  }

  // --------- UPLOAD MEDIA (TÁCH RIÊNG) ----------
  /// Upload media (ảnh/video) cho Order/Detail/Step – tách hẳn khỏi update status
  /// fileType: "image" | "video"
  Future<Response> uploadOrderMedia({
    required int orderId,
    int? orderDetailId,
    int? orderStepId,
    required File file,
    required String fileType,
    String? description,
  }) async {
    try {
      final form = FormData.fromMap({
        "orderId": orderId,
        if (orderDetailId != null) "orderDetailId": orderDetailId,
        if (orderStepId != null) "orderStepId": orderStepId,
        "fileType": fileType,
        if (description != null) "description": description,
        "file": await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      return await post(
        "orders/UploadOrderMedia/$orderId/$orderDetailId/$orderStepId",
        data: form,
      );
    } on DioException catch (e) {
      throw Exception("Upload media failed: ${e.message}");
    }
  }

  /// (Tuỳ chọn) Upload riêng cho step nếu BE có route riêng
  // Future<String> uploadStepMedia({
  //   required int stepId,
  //   required File file,
  //   required String fileType,
  //   String? description,
  // }) async {
  //   try {
  //     final form = FormData.fromMap({
  //       "fileType": fileType,
  //       if (description != null) "description": description,
  //       "file": await MultipartFile.fromFile(
  //         file.path,
  //         filename: file.path.split(Platform.pathSeparator).last,
  //       ),
  //     });

  //     final Response res = await post("ordersteps/$stepId/upload", data: form);

  //     if (res.statusCode == 200 && res.data != null) {
  //       final d = _unwrapData(res.data);
  //       if (d is Map && d['fileUrl'] != null) {
  //         return d['fileUrl'] as String;
  //       }
  //       if (d is String) return d;
  //       if (d is Map && d['url'] != null) return d['url'] as String;
  //       return "";
  //     }
  //     throw Exception("Upload step media failed, status: ${res.statusCode}");
  //   } on DioException catch (e) {
  //     throw Exception("Upload step media failed: ${e.message}");
  //   }
  // }

  //#region phan lay danh muc
  Future<List<CustomerModel>> getCustomers({
    required int skip,
    required int take,
    required String searchTerm,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'shopId': -1,
        'skip': skip,
        'take': take,
        'sort': '[{"field":"Id","dir":"desc"}]',
      };
      if (!searchTerm.isEmpty) {
        final filter = {
          "logic": "or",
          "filters": [
            {"field": "FullName", "operator": "contains", "value": searchTerm},
            {
              "field": "PhoneNumber",
              "operator": "contains",
              "value": searchTerm,
            },
            {"field": "Code", "operator": "contains", "value": searchTerm},
          ],
        };

        queryParams = {
          'shopId': -1,
          'skip': skip,
          'take': take,
          'sort': '[{"field":"Id","dir":"desc"}]', // Sắp xếp mặc định
          'filter': jsonEncode(filter),
        };
      }

      final response = await get('Customers/getListPaging', query: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        // 1. Kiểm tra xem responseData có phải là Map không
        if (responseData is Map<String, dynamic> &&
            responseData['isSuccessed'] == true) {
          // 2. Lấy ra danh sách từ key "data"
          final List customerData = responseData['data'];
          if (customerData.isNotEmpty) {
            return customerData
                .map((item) => CustomerModel.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      print("Error fetching customers: $e");
      return [];
    }
  }

  /**
 * 
 */
  Future<List<AccountModel>> getStaffs(int shopId) async {
    try {
      String filterShop = "";
      if (shopId > 0) {
        filterShop = "&shopId=" + shopId.toString();
      }
      final response = await get(
        "diccombo/GetListCombo?table=Accounts" + filterShop,
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data.length > 0) {
        final data = response.data as List;
        return data.map((item) => AccountModel.fromJson(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception("Failed to load staffs: ${e.message}");
    }
  }

  static final Map<String, List<ComboModel>> _cache = {};

  /// Lấy combo từ cache hoặc gọi API qua hàm getCombo có sẵn
  Future<List<ComboModel>> getCombo(
    String table, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(table)) {
      return _cache[table]!;
    }

    final combos = await getComboOrg(table);
    _cache[table] = combos;
    return combos;
  }

  /// Tìm item theo id trong cache
  ComboModel? findById(String table, int id) {
    if (!_cache.containsKey(table)) return null;
    try {
      return _cache[table]!.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<ComboModel>> getComboOrg(String table) async {
    final response = await get("diccombo/getlistcombo?table=$table");
    if (response.statusCode == 200 &&
        response.data != null &&
        response.data.length > 0) {
      final data = response.data as List;
      return data.map((e) => ComboModel.fromJson(e)).toList();
    }
    return [];
  }

  /**
 * 
 */
  Future<List<ServiceModel>> getServices() async {
    try {
      final response = await get("diccombo/getlistcombo?table=Services");
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as List;
        return data.map((item) => ServiceModel.fromJson(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception("Failed to load services: ${e.message}");
    }
  }

  /**
 * 
 */
  Future<Response> checkPhoneExistsAndSendOtp(String phoneNumber) async {
    // final response = await post('guest/sent-otp', data: {'phone': phoneNumber});
    final mockRequestOptions = RequestOptions();
    final successData = {
      'success': true,
      'message': 'Đã gửi mã xác thực thành công.',
      'sessionId': 'session-${DateTime.now().millisecondsSinceEpoch}',
    };

    return Response<Map<String, dynamic>>(
      data: successData,
      requestOptions: mockRequestOptions,
      statusCode: 200,
      statusMessage: 'OK',
    );
  }

  Future<bool> verifyOtpAndLogin(
    String phoneNumber,
    String otp,
    String sessionId,
  ) async {
    return otp == '123456';
  }

  //#end region phan lay danh muc
}

 