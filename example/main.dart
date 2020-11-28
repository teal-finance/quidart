import 'package:quidart/quidart.dart';
import 'package:quidart/src/exceptions.dart';

Future<void> main() async {
  final requests =
      QuidRequests(serverUri: "http://localhost:8082", namespace: "demo");
  // get a a refresh token
  try {
    await requests.getRefreshToken(
      username: "demouser",
      password: "demouser",
    );
  } on QuidException catch (e) {
    if (e.unauthorized) {
      print(e.message);
      return;
    }
  } catch (e) {
    rethrow;
  }

  // get an access token
  try {
    await requests.getAccessToken();
  } catch (e) {
    rethrow;
  }
  print("Access token");
  print(requests.accessToken);
  print("Making request");
  const uri = "http://127.0.0.1:5000";
  final data = await requests.get(uri);
  print(data);
}
