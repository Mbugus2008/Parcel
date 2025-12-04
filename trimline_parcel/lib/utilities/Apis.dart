// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import './logger.dart';

class ApiClient extends ChangeNotifier {
  final LoggerService logger = Get.find();

  /// Get base URL from AppConfig (supports different environments)
  String get baseUrl => AppConfig().apiBaseUrl;

  /// Get client identifier from AppConfig
  String get clientIdentifier => AppConfig().clientIdentifier;

  Future<http.Response> postdata(String url, String? data) async {
    http.Response? r = http.Response("", 200);
    try {
      String urls = '$baseUrl$url';
      logger.info(urls);
      logger.info("out: $data");

      final rawHeader = {
        'Content-Type': 'application/json',
        'X-Client-Identifier': clientIdentifier,
      };
      logger.info(rawHeader.toString());

      r = await http
          .post(Uri.parse(urls), body: data, headers: rawHeader)
          .timeout(Duration(seconds: AppConfig().apiTimeoutSeconds));
      logger.info('url: $url, status code: ${r.statusCode}');
      logger.info('url: ${url}body: ${r.body}');

      if (r.statusCode != 200) {
        logger.error(r.statusCode.toString());
        logger.error(r.body);
      }
    } on TimeoutException catch (e, stackTrace) {
      logger.error("API timeout", error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      logger.error("API failed", error: e, stackTrace: stackTrace);
      rethrow;
    }
    return await Future.value(r);
  }
}

class ApiService extends GetxService {
  Future<ApiService> init() async {
    // Initialize your API service here
    print('ApiService initialized');
    return this;
  }

  // ... other API methods
}

// class AesDecryption {
//   static final key = encrypt.Key.fromUtf8('kOFq5NYMkfiYPayzs3GntbP2mCT+39WLDcnuLJ5Rsrg='); // 32 bytes
//   static final iv = encrypt.IV.fromUtf8('1234567890abcdef'); // 16 bytes

//   static String decrypt(String encryptedBase64) {
//     final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
//     final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
//     final decrypted = encrypter.decrypt(encrypted, iv: iv);
//     return decrypted; // This is the original plaintext
//   }
// }
