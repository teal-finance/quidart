import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import "./exceptions.dart";

final Dio _dio = Dio();

/// The main requests class
class QuidRequests {
  /// Provide an uri for the Quid server
  QuidRequests(
      {@required this.serverUri,
      @required this.namespace,
      this.timeouts = const <String, String>{
        "accessToken": "20m",
        "refreshToken": "24h"
      }});

  /// The Quid server uri
  final String serverUri;

  /// The namespace
  final String namespace;

  /// The tokens time to live
  final Map<String, String> timeouts;

  /// The access token
  String accessToken;

  String _refreshToken;

  /// Get request
  Future<Map<String, dynamic>> get(String uri) async {
    await _checkTokens();
    return _requestWithRetry(
      uri: uri,
      method: "get",
    );
  }

  /// Post request
  Future<Map<String, dynamic>> post(
      String uri, Map<String, dynamic> payload) async {
    await _checkTokens();
    return _requestWithRetry(
      uri: uri,
      method: "post",
      payload: payload,
    );
  }

  Future<Map<String, dynamic>> _requestWithRetry(
      {String uri,
      String method,
      Map<String, dynamic> payload,
      int retry = 0}) async {
    Map<String, dynamic> resp;
    try {
      if (method == "get") {
        final response = await _dio.get<Map<String, dynamic>>(
          uri,
          options: Options(
            headers: <String, dynamic>{"Authorization": "Bearer $accessToken"},
          ),
        );
        resp = response.data;
      } else {
        final response = await _dio.post<Map<String, dynamic>>(
          uri,
          data: payload,
          options: Options(
            headers: <String, dynamic>{"Authorization": "Bearer $accessToken"},
          ),
        );
        resp = response.data;
      }
    } on DioError catch (e) {
      if (e?.response?.statusCode == 401) {
        if (retry > 2) {
          throw const QuidException.tooManyRetries();
        }
        return _requestWithRetry(
            uri: uri, method: method, payload: payload, retry: retry + 1);
      }
    } catch (e) {
      rethrow;
    }
    return resp;
  }

  /// Get an access token from the server
  Future<void> getAccessToken() async {
    final payload = <String, dynamic>{
      "namespace": namespace,
      "refresh_token": _refreshToken,
    };
    final uri = serverUri + "/token/access/" + timeouts["accessToken"];
    try {
      final response =
          await _dio.post<Map<String, dynamic>>(uri, data: payload);
      final data = Map<String, String>.from(response.data);
      accessToken = data["token"];
    } on DioError catch (e) {
      if (e?.response?.statusCode == 401) {
        throw const QuidException.unauthorized();
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a refresh token from the server
  Future<void> getRefreshToken(
      {@required String username,
      @required String password,
      String refreshTokenTtl = "24h"}) async {
    try {
      final uri = serverUri + "/token/refresh/" + refreshTokenTtl;
      final payload = <String, String>{
        "namespace": namespace,
        "username": username,
        "password": password,
      };
      //print("Posting payload $payload");
      final response =
          await _dio.post<Map<String, dynamic>>(uri, data: payload);
      final data = Map<String, String>.from(response.data);
      _refreshToken = data["token"];
      //print("RT $_refreshToken");
    } on DioError catch (e) {
      if (e.response != null) {
        // check if unauthorized
        if (e.response.statusCode == 401) {
          throw const QuidException.unauthorized();
        }
        rethrow;
      } else {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _checkTokens() async {
    if (_refreshToken == null) {
      throw const QuidException.hasToLogin();
    }
    if (accessToken == null) {
      try {
        await getAccessToken();
      } on QuidException catch (e) {
        if (e?.unauthorized == true) {
          throw const QuidException.hasToLogin();
        } else {
          rethrow;
        }
      }
    }
  }
}
