import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get base => dotenv.env['API_BASE'] ?? 'http://10.0.0.125:5026';
}
