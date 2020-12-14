import 'package:quidart/quidart.dart';
import 'package:quidart/src/exceptions.dart';

const quidUri = "http://localhost:8082";
const serverUri = "http://127.0.0.1:5000";

Future<void> main() async {
  final requests = QuidRequests(
    baseUri: serverUri,
    quidUri: quidUri,
    namespace: "demo",
  );
  // login
  try {
    await requests.login(
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
  print("Access token ok");
  print("Making request");
  const uri = serverUri;
  final data = await requests.get<Map<String, dynamic>>(uri);
  print(data);
}
