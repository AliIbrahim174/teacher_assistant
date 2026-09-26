import 'package:flutter/services.dart';
import 'zoom_token_service.dart';
class ZoomService {
  ZoomService._();

  static final ZoomService instance = ZoomService._();

  static const MethodChannel _channel = MethodChannel(
    'com.alikhedr.mom_teacher_assistant/zoom',
  );

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isInitialized() async {
    try {
      return await _channel.invokeMethod<bool>('isInitialized') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

Future<dynamic> initialize() async {
  try {

    final token =
        ZoomTokenService.generateToken();


    return await _channel.invokeMethod(
      'initialize',
      token,
    );

  } catch (e) {

    return {
      'success': false,
      'exception': e.toString(),
    };

  }
}}
