import 'dart:async';

import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../controllers/storage.dart';
import '../../controllers/wifi.dart';
import '../../models/mac_model.dart';
import '../../models/switch_model.dart';
import '../../widgets/custom/toast.dart';
import '../../widgets/mac_card.dart';
import 'add_mac.dart';

class MacsPage extends StatefulWidget {
  const MacsPage({super.key});

  @override
  State<MacsPage> createState() => _MacsPageState();
}

class _MacsPageState extends State<MacsPage> {
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

  Future<List<MacsDetails>> fetchContacts() async {
    return _storageController.readMacs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
          child: Icon(
            FontAwesomeIcons.plus,
            color: Theme.of(context).appColors.background,
          ),
          onPressed: () async {
            List<SwitchDetails> switches =
                await _storageController.readSwitches();
            String localConnectStatus = _connectionStatus;
            for (var element in switches) {
              debugPrint(element.switchSSID);
              debugPrint(localConnectStatus);
              if (localConnectStatus == element.switchSSID) {
                debugPrint(element.switchSSID);
                debugPrint(">>>>>>>>>>>>>");
                debugPrint(">>>>>>>>>>>>>");
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NewMacInstallationPage(
                              switchDetails: element,
                            )));
                return;
              }
            }
            debugPrint(_connectionStatus);
            showToast(context, "You may not be connected to AP Mode.");
            return;
          }),
      key: scaffoldKey,
      appBar: AppBar(title: const Text("MAC")),
      body: FutureBuilder(
          future: fetchContacts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(
                  color: Theme.of(context).appColors.buttonBackground);
            }
            if (snapshot.hasError) {
              debugPrint("${snapshot.error}");
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
                  return MacCard(macsDetails: snapshot.data![index]);
                });
          }),
    );
  }
}
