// services/expresspay_channel.dart
import 'package:flutter/services.dart';

class ExpressPayChannel {
  static const MethodChannel _channel =
      MethodChannel('com.yourcompany.expresspay');

  static Future<String?> startExpressPay(Map<String, String> params) async {
    try {
      final result = await _channel.invokeMethod('startExpressPay', params);
      if (result is String) {
        return result;
      }
      return null;
    } on PlatformException catch (e) {
      return e.message;
    }
  }
}
