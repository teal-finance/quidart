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
  String accesToken;

  String _refreshToken;

  /// Get an access token from the server
  Future<void> getAccessToken() async {
    final payload = <String, dynamic>{
      "namespace": this.namespace,
      "refresh_token": this._refreshToken,
    };
    final uri = serverUri + "/token/access/" + timeouts["accessToken"];
    try {
      final response =
          await _dio.post<Map<String, dynamic>>(uri, data: payload);
      final data = Map<String, String>.from(response.data);
      this.accesToken = data["token"];
    } 
    //on DioError catch (e) {
    //  rethrow;
    //} 
    catch (e) {
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
        "namespace": this.namespace,
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
}
