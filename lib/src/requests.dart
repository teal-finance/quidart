import 'package:dio/dio.dart';
//import 'package:emodebug/emodebug.dart';

import 'package:meta/meta.dart';
import "./exceptions.dart";

final Dio _dio = Dio();

/// The main requests class
class QuidRequests {
  /// Provide an uri for the Quid server
  QuidRequests(
      {@required this.quidUri,
      @required this.namespace,
      this.baseUri,
      this.timeouts = const <String, String>{
        "accessToken": "20m",
        "refreshToken": "24h"
      },
      this.verbose = false}) {
    /*if (verbose) {
      _ = EmoDebug(zone: "quidrequests", deactivatePrint: !verbose)
        ..constructor("QuidRequests initialized");
    }*/
  }

  /// The Quid server uri
  final String quidUri;

  /// The api server uri
  final String baseUri;

  /// The namespace
  final String namespace;

  /// The tokens time to live
  final Map<String, String> timeouts;

  /// Verbosity
  final bool verbose;

  //EmoDebug _;

  String _accessToken;

  /// The refresh token
  String refreshToken;

  /// Make a get request
  Future<T> get<T>(String uri) async {
    await _checkTokens();
    final url = baseUri == null ? uri : baseUri + uri;
    //_.requestGet("Get request $url");
    final v = await _requestWithRetry<T>(
      uri: url,
      method: "get",
    );
    return v;
  }

  /// Post request
  Future<T> post<T>(String uri, Map<String, dynamic> payload) async {
    await _checkTokens();
    final url = baseUri == null ? uri : baseUri + uri;
    return _requestWithRetry<T>(
      uri: url,
      method: "post",
      payload: payload,
    );
  }

  /// Login and get refreh token and access token
  Future<void> login(
      {@required String username,
      @required String password,
      String refreshTokenTtl}) async {
    var ttl = refreshTokenTtl;
    if (refreshTokenTtl == null) {
      ttl = timeouts["refreshToken"];
    }
    await getRefreshToken(
        username: username, password: password, refreshTokenTtl: ttl);
    await getAccessToken();
  }

  /// Get an access token from the server
  Future<void> getAccessToken() async {
    //_.key("Getting access token");
    final payload = <String, dynamic>{
      "namespace": namespace,
      "refresh_token": refreshToken,
    };
    final uri = quidUri + "/token/access/" + timeouts["accessToken"];
    try {
      final response =
          await _dio.post<Map<String, dynamic>>(uri, data: payload);
      final data = Map<String, String>.from(response.data);
      _accessToken = data["token"];
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
    //_.key("Getting refresh token");
    try {
      final uri = quidUri + "/token/refresh/" + refreshTokenTtl;
      final payload = <String, String>{
        "namespace": namespace,
        "username": username,
        "password": password,
      };
      //print("Posting payload $payload");
      final response =
          await _dio.post<Map<String, dynamic>>(uri, data: payload);
      final data = Map<String, String>.from(response.data);
      refreshToken = data["token"];
      //print("RT $refreshToken");
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

  Future<T> _requestWithRetry<T>(
      {String uri,
      String method,
      Map<String, dynamic> payload,
      int retry = 0}) async {
    //print("Request $method $uri");
    T resp;
    try {
      if (method == "get") {
        final response = await _dio.get<T>(
          uri,
          options: Options(
            headers: <String, dynamic>{"Authorization": "Bearer $_accessToken"},
          ),
        );
        resp = response.data;
      } else {
        final response = await _dio.post<T>(
          uri,
          data: payload,
          options: Options(
            headers: <String, dynamic>{"Authorization": "Bearer $_accessToken"},
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

  Future<void> _checkTokens() async {
    if (refreshToken == null) {
      throw const QuidException.hasToLogin();
    }
    if (_accessToken == null) {
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
