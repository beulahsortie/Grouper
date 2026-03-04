// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';  // This will be the generated file

@Envied(path: '.env')  // Path to your .env file
abstract class Env {
    @EnviedField(varName: 'API_BASE_URL', obfuscate: true)
    static final String apiBaseUrl = _Env.apiBaseUrl;
    

}