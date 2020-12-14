# Quidart

A requests library for the Quid json web tokens server

## Usage

Initialize:

```dart
import 'package:quidart/quidart.dart';

const quidUri = "http://localhost:8082";
const serverUri = "http://127.0.0.1:5000";
final requests = QuidRequests(
    baseUri: serverUri,
    quidUri: quidUri,
    namespace: "demo",
  );
```

Login and get a refresh and access token:

```dart
import 'package:quidart/src/exceptions.dart';

try {
    await requests.login(
        username: "demouser",
        password: "demouser",
    );
} on QuidException catch (e) {
    if (e.unauthorized) {
        // the login has failed
    }
} catch (e) {
    rethrow;
}
```

Make a get request:

```dart
final uri = "https://myserver.org/path";
final data = await requests.get<Map<String, dynamic>>(uri);
```

Make a post request:

```dart
final data = await requests.post<Map<String, dynamic>>(uri, <Map<String,dynamic>{"foo": "bar"}>);
```
