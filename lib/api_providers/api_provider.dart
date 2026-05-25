import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:bbtml_new/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../common/get_device_id.dart';
import '../common/globals.dart' as globals;
import '../controllers/shared_preference.dart';

class ApiProvider {
  final deviceId = DeviceUtils.getDeviceId();
  late String authCookie;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Constants.apiEndPoint,
    headers: {
      'Content-Type': 'application/json',
      "deviceid": globals.deviceId ?? ''
    },
  ));

  Future<bool> validateAssetCertificate(BuildContext context) async {
    try {
      debugPrint(globals.currentCertificatePath);
      final certData = await rootBundle.loadString(
        globals.currentCertificatePath,
      );

      final cert = X509Utils.x509CertificateFromPem(certData);

      final subject = cert.tbsCertificate?.subject.toString() ?? "N/A";

      final issuer = cert.tbsCertificate?.issuer.toString() ?? "N/A";

      final startDate = cert.tbsCertificate?.validity.notBefore;

      final endDate = cert.tbsCertificate?.validity.notAfter;

      bool isValid = true;

      // Expiry Check
      if (endDate != null && DateTime.now().isAfter(endDate)) {
        isValid = false;
      }

      // Not Yet Valid Check
      if (startDate != null && DateTime.now().isBefore(startDate)) {
        isValid = false;
      }

      debugPrint("Subject: $subject");
      debugPrint("Issuer: $issuer");
      debugPrint("Start Date: $startDate");
      debugPrint("End Date: $endDate");
      final formattedStartDate = startDate != null
          ? DateFormat('dd MMM yyyy, hh:mm a').format(startDate.toLocal())
          : "N/A";

      final formattedEndDate = endDate != null
          ? DateFormat('dd MMM yyyy, hh:mm a').format(endDate.toLocal())
          : "N/A";
      // Show Dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              title: Text(
                isValid ? "Certificate is Valid" : "Certificate is Invalid",
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Subject:\n$subject"),
                  const SizedBox(height: 10),
                  Text("Issuer:\n$issuer"),
                  const SizedBox(height: 10),
                  Text("Valid From:\n$formattedStartDate"),
                  const SizedBox(height: 10),
                  Text("Valid Till:\n$formattedEndDate"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }

      return isValid;
    } catch (e) {
      debugPrint("Certificate Validation Failed: $e");

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text("Certificate Error"),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }

      return false;
    }
  }

  Future<dynamic> login(Map<String, dynamic> payload) async {
    debugPrint("Payload Passing to Api=====> $payload");
    debugPrint(">>>>>>>>>${_dio.options.headers}");
    try {
      final response = await _dio
          .post(
            '/api/auth/login',
            data: payload,
          )
          .timeout(const Duration(seconds: 5));
      final setCookie = response.headers.map['set-cookie']?.first;
      if (setCookie != null) {
        authCookie = setCookie.split(';').first;
        debugPrint("Saved Cookie: $authCookie");
        await SharedPreferenceServices().saveAuthCookie(authCookie);
      }
      debugPrint("Api Response=====> $response");
      debugPrint("Api ResponseData=====> ${response.data}");
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Login failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('error: $e');
    }
  }

  Future<dynamic> addSwitch(Map<String, dynamic> payload) async {
    debugPrint("Payload Passing to Api=====> ${jsonEncode(payload)}");
    String? savedCookie = SharedPreferenceServices().getAuthCookie();
    debugPrint("Header Passing to Api=====>$savedCookie");
    try {
      final response = await _dio
          .post(
            '/api/devices/add',
            data: payload,
            options: Options(
              headers: {
                'Cookie': savedCookie,
              },
            ),
          )
          .timeout(const Duration(seconds: 5));
      debugPrint("Api Response=====> $response");

      debugPrint("Api ResponseData=====> ${response.data}");
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Add Switch failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('error: $e');
    }
  }

  Future<dynamic> getSwitchList() async {
    String? savedCookie = SharedPreferenceServices().getAuthCookie();
    debugPrint("Header Passing to Api=====>$savedCookie");
    try {
      final response = await _dio
          .get(
            '/api/devices/list',
            data: {},
            options: Options(
              headers: {
                'Cookie': savedCookie,
              },
            ),
          )
          .timeout(const Duration(seconds: 5));
      debugPrint("Api Response=====> $response");

      debugPrint("Api ResponseData=====> ${response.data}");
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Add Switch failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> triggerSwitch(Map<String, dynamic> payload) async {
    debugPrint("Payload Passing to Api=====> ${jsonEncode(payload)}");
    String? savedCookie = SharedPreferenceServices().getAuthCookie();
    debugPrint("Header Passing to Api=====>$savedCookie");
    try {
      final response = await _dio
          .post(
            '/api/devices/trigger-switch',
            data: payload,
            options: Options(
              headers: {
                'Cookie': savedCookie,
              },
            ),
          )
          .timeout(const Duration(seconds: 5));
      debugPrint("Api Response=====> $response");
      debugPrint("Api ResponseData=====> ${response.data}");
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("${e.response}");
        throw Exception('trigger-switch failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('error: $e');
    }
  }

  Future<dynamic> deleteSwitch(Map<String, dynamic> payload) async {
    debugPrint("Payload Passing to Api=====> $payload");
    String? savedCookie = SharedPreferenceServices().getAuthCookie();
    debugPrint("Header Passing to Api=====>$savedCookie");
    try {
      final response = await _dio
          .delete(
            '/api/devices/delete',
            data: payload,
            options: Options(
              headers: {
                'Cookie': savedCookie,
              },
            ),
          )
          .timeout(const Duration(seconds: 5));
      debugPrint("Api Response=====> $response");
      debugPrint("Api ResponseData=====> ${response.data}");
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("${e.response}");
        throw Exception('delete-switch failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('error: $e');
    }
  }

  Future<dynamic> sendOtp(Map<String, dynamic> payload) async {
    debugPrint("Payload Passing to Api=====> $payload");
    debugPrint("Header Passing to Api=====>${_dio.options.headers}");
    try {
      final response = await _dio
          .post(
            '/api/auth/send-otp',
            data: payload,
          )
          .timeout(const Duration(seconds: 5));
      final setCookie = response.headers.map['set-cookie']?.first;
      if (setCookie != null) {
        authCookie = setCookie.split(';').first;
        debugPrint("Saved Cookie: $authCookie");
        await SharedPreferenceServices().saveOtpCookie(authCookie);
      }
      debugPrint("Api Response=====> $response");
      debugPrint("Api ResponseData=====> ${response.data}");
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Otp send failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('error: $e');
    }
  }

  Future<dynamic> verifyOtp(Map<String, dynamic> payload) async {
    debugPrint("Payload Passing to Api=====> $payload");
    String? savedCookie = SharedPreferenceServices().getOtpCookie();
    debugPrint("Header Passing to Api=====>$savedCookie");

    try {
      final response = await _dio
          .post(
            '/api/auth/verify-otp',
            data: payload,
            options: Options(
              headers: {
                'Cookie': savedCookie,
              },
            ),
          )
          .timeout(const Duration(seconds: 5));
      final setCookie = response.headers.map['set-cookie']?.first;
      if (setCookie != null) {
        authCookie = setCookie.split(';').first;
        debugPrint("Saved Cookie: $authCookie");
        await SharedPreferenceServices().saveAuthCookie(authCookie);
      }
      debugPrint("Api Response=====> $response");
      debugPrint("Api ResponseData=====> ${response.data}");
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Otp verification failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('error: $e');
    }
  }

  Future<dynamic> logout() async {
    debugPrint(">>>>>>>>>${_dio.options.headers}");
    try {
      final response = await _dio.post(
        '/api/auth/logout',
        data: {},
      ).timeout(const Duration(seconds: 5));
      debugPrint("Api Response=====> $response");
      debugPrint("Api ResponseData=====> ${response.data}");
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Logout failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('error: $e');
    }
  }

  Future<dynamic> getSwitchStatus(Map<String, dynamic> payload) async {
    String? savedCookie = SharedPreferenceServices().getAuthCookie();
    debugPrint("Header Passing to Api=====>$savedCookie");
    debugPrint("payload Passing to Api=====>$payload");
    try {
      final response = await _dio
          .post(
            '/api/devices/details',
            options: Options(headers: {
              'Cookie': savedCookie,
            }, validateStatus: (status) => true),
            data: payload,
          )
          .timeout(const Duration(seconds: 50));
      debugPrint("Get Switch Status Api Response=====> $response");

      debugPrint("Get Switch Status Api ResponseData=====> ${response.data}");
      return response.data;
    } catch (e) {
      debugPrint("======$e");
      throw Exception(e.toString());
    }
  }
}
