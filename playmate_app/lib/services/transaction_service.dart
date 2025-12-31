import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import 'api_service.dart';
import '../utils/logger.dart';

/// 거래 관련 API 서비스
class TransactionService {
  /// 인증 토큰 가져오기
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('playmate_auth_token');
    } catch (e) {
      return null;
    }
  }

  /// 거래 목록 조회
  Future<List<Transaction>> getTransactions({
    String? category,
    String? status,
    int? sellerId,
    int? buyerId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      if (sellerId != null) queryParams['sellerId'] = sellerId.toString();
      if (buyerId != null) queryParams['buyerId'] = buyerId.toString();
      queryParams['limit'] = limit.toString();
      queryParams['offset'] = offset.toString();

      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await ApiService.get(
        '/transactions?$queryString',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> transactionsJson = data['data'];
          return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
        } else {
          throw Exception('거래 목록 데이터가 없습니다');
        }
      } else {
        throw Exception('거래 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('거래 목록 조회 오류', tag: 'TransactionService', error: e);
      return [];
    }
  }

  /// 거래 상세 조회
  Future<Transaction?> getTransactionById(int transactionId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/transactions/$transactionId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Transaction.fromJson(data['data']);
        } else {
          throw Exception('거래 데이터가 없습니다');
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('거래 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('거래 상세 조회 오류', tag: 'TransactionService', error: e);
      return null;
    }
  }

  /// 내 거래 목록 조회
  Future<List<Transaction>> getMyTransactions({String type = 'all'}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/transactions/my?type=$type',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> transactionsJson = data['data'];
          return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
        } else {
          throw Exception('내 거래 목록 데이터가 없습니다');
        }
      } else {
        throw Exception('내 거래 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('내 거래 목록 조회 오류', tag: 'TransactionService', error: e);
      return [];
    }
  }

  /// 거래 생성
  Future<Transaction?> createTransaction({
    required String title,
    required String description,
    required String category,
    required int price,
    List<String>? images,
    String? location,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.post(
        '/transactions',
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'title': title,
          'description': description,
          'category': category,
          'price': price,
          'images': images ?? [],
          'location': location,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Transaction.fromJson(data['data']);
        } else {
          throw Exception('거래 생성 실패: ${data['error']}');
        }
      } else {
        throw Exception('거래 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('거래 생성 오류', tag: 'TransactionService', error: e);
      return null;
    }
  }

  /// 거래 수정
  Future<Transaction?> updateTransaction({
    required int transactionId,
    String? title,
    String? description,
    String? category,
    int? price,
    List<String>? images,
    String? location,
    String? status,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (price != null) updateData['price'] = price;
      if (images != null) updateData['images'] = images;
      if (location != null) updateData['location'] = location;
      if (status != null) updateData['status'] = status;

      final response = await ApiService.put(
        '/transactions/$transactionId',
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Transaction.fromJson(data['data']);
        } else {
          throw Exception('거래 수정 실패: ${data['error']}');
        }
      } else {
        throw Exception('거래 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('거래 수정 오류', tag: 'TransactionService', error: e);
      return null;
    }
  }

  /// 거래 삭제
  Future<bool> deleteTransaction(int transactionId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.delete(
        '/transactions/$transactionId',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.error('거래 삭제 오류', tag: 'TransactionService', error: e);
      return false;
    }
  }

  /// 거래 상태 변경
  Future<Transaction?> updateTransactionStatus({
    required int transactionId,
    required String status,
    int? buyerId,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.put(
        '/transactions/$transactionId/status',
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'status': status,
          'buyerId': buyerId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Transaction.fromJson(data['data']);
        } else {
          throw Exception('거래 상태 변경 실패: ${data['error']}');
        }
      } else {
        throw Exception('거래 상태 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('거래 상태 변경 오류', tag: 'TransactionService', error: e);
      return null;
    }
  }
}

