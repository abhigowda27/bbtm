import 'dart:async';

import 'package:bbtml_new/screens/bbtm_screens/widgets/fingerprint_card.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../controllers/storage.dart';
import '../../controllers/wifi.dart';
import '../../models/switch_model.dart';

class FingersPage extends StatefulWidget {
  const FingersPage({super.key});

  @override
  State<FingersPage> createState() => _FingersPageState();
}

class _FingersPageState extends State<FingersPage> {
  final StorageController _storageController = StorageController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
  late NetworkService _networkService;
  @override
  void initState() {
    super.initState();
    _networkService = NetworkService();
    _initNetworkInfo();
    connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  String _connectionStatus = 'Unknown';
  Future<void> _updateConnectionStatus(
          List<ConnectivityResult> results) async =>
      _initNetworkInfo();

  Future<void> _initNetworkInfo() async {
    String? wifiName = await _networkService.initNetworkInfo();
    setState(() => _connectionStatus = wifiName ?? "Unknown");
  }

  Future<List<SwitchDetails>> fetchLocks() async {
    return _storageController.readSwitchesByType("DOOR_LOCK");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fingerprints")),
      body: FutureBuilder(
          future: fetchLocks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(
                  color: Theme.of(context).appColors.buttonBackground);
            }
            if (snapshot.hasError) {
              debugPrint("${snapshot.error}");
              debugPrint("StackTrace: ${snapshot.stackTrace}");

              return const Text("ERROR");
            }
            return ListView.separated(
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(
                    height: 16,
                  );
                },
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return FingerprintCard(
                    switchDetails: snapshot.data![index],
                    wifiName: _connectionStatus,
                  );
                });
          }),
    );
  }
}
