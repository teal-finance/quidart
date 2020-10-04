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
  print("Got a refresh token");
  // get an access token
  try {
    await requests.getAccessToken();
  } catch (e) {
    rethrow;
  }
  print(requests.accesToken);
  print("Ok");
}
