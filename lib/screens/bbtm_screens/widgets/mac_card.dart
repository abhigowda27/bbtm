import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants.dart';
import '../../../controllers/apis.dart';
import '../../tabs_page.dart';
import '../controllers/storage.dart';
import '../controllers/wifi.dart';
import '../models/mac_model.dart';
import 'custom/toast.dart';

class MacCard extends StatefulWidget {
  final MacsDetails macsDetails;

  const MacCard({
    required this.macsDetails,
    super.key,
  });

  @override
  State<MacCard> createState() => _MacCardState();
}

class _MacCardState extends State<MacCard> {
  final StorageController _storageController = StorageController();
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
    //isSwitched = widget.macsDetails.isPresentInESP;
    _loadMacState();
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMacState() async {
    isSwitched = await _storageController.getMacState(widget.macsDetails);
    setState(() {});
  }

  Future<void> _saveMacState(bool value) async {
    final updatedMac = MacsDetails(
      id: widget.macsDetails.id,
      switchDetails: widget.macsDetails.switchDetails,
      name: widget.macsDetails.name,
      isPresentInESP: value,
    );
    await _storageController.saveMacState(updatedMac);
  }

  String _connectionStatus = 'Unknown';
  Future<void> _updateConnectionStatus(
          List<ConnectivityResult> results) async =>
      _initNetworkInfo();

  Future<void> _initNetworkInfo() async {
    String? wifiName = await _networkService.initNetworkInfo();
    if (!mounted) return;
    setState(() => _connectionStatus = wifiName ?? "Unknown");
  }

  bool isSwitched = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).appColors.textSecondary.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(2, 2),
            ),
          ],
          color: Theme.of(context).appColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Switch ID : ",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Flexible(
                  child: Text(
                    widget.macsDetails.switchDetails.switchId,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              ],
            ),
            Row(
              children: [
                Text(
                  "Switch Name : ",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Flexible(
                  child: Text(
                    widget.macsDetails.switchDetails.switchSSID,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              ],
            ),
            Row(
              children: [
                Text(
                  "Mac ID : ",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Flexible(
                  child: Text(
                    widget.macsDetails.id,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              ],
            ),
            Row(
              children: [
                Text(
                  "Mac Name : ",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Flexible(
                  child: Text(
                    widget.macsDetails.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              ],
            ),
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).appColors.primary,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: widget.macsDetails.id,
                        ));
                        showToast(context, "Mac Id copied");
                      },
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).appColors.textPrimary,
                      )),
                  const SizedBox(
                    width: 10,
                  ),
                  IconButton(
                      onPressed: () async {
                        String localConnectStatus = _connectionStatus;
                        debugPrint("localConnectStatus");
                        debugPrint(localConnectStatus);
                        if (localConnectStatus !=
                            widget.macsDetails.switchDetails.switchSSID) {
                          showFlutterToast(
                              "You should be connected to ${widget.macsDetails.switchDetails.switchSSID} to delete the MAC");

                          AppSettings.openAppSettings(
                              type: AppSettingsType.wifi);
                          return;
                        }
                        showDialog(
                            context: context,
                            builder: (cont) {
                              return AlertDialog(
                                title: const Text('BBT Switch'),
                                content:
                                    const Text('This will delete the Switch'),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('CANCEL'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      _storageController
                                          .deleteOneMacs(widget.macsDetails);
                                      Navigator.pushAndRemoveUntil<dynamic>(
                                        context,
                                        MaterialPageRoute<dynamic>(
                                          builder: (BuildContext context) =>
                                              const TabsPage(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            });
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).appColors.textPrimary,
                      )),
                  const SizedBox(
                    width: 10,
                  ),
                  Switch(
                    onChanged: (value) async {
                      await _storageController
                          .deleteMacState(widget.macsDetails);
                      String localConnectStatus = _connectionStatus;
                      debugPrint("localConnectStatus");
                      debugPrint(localConnectStatus);
                      // if (localConnectStatus !=
                      //     widget.macsDetails.switchDetails.switchSSID) {
                      //   final scaffold = ScaffoldMessenger.of(context);
                      //   scaffold.showSnackBar(
                      //     SnackBar(
                      //       content: Text(
                      //           "You should be connected to ${widget.macsDetails.switchDetails.switchSSID} to refresh the MAC settings"),
                      //     ),
                      //   );
                      //   return;
                      // }
                      setState(() {
                        isSwitched = value;
                      });
                      if (value) {
                        await ApiConnect.hitApiPost(
                            "${Constants.routerIP}/macid",
                            {"MacID": widget.macsDetails.id});
                        await ApiConnect.hitApiPost(
                            "${Constants.routerIP}/MacOnOff",
                            {"MacCheck": "ON"});
                      } else {
                        await ApiConnect.hitApiPost(
                            "${Constants.routerIP}/MacOnOff",
                            {"MacCheck": "OFF"});
                        await ApiConnect.hitApiPost(
                            "${Constants.routerIP}/deletemac",
                            {"MacID": widget.macsDetails.id.toLowerCase()});
                      }
                      await _saveMacState(isSwitched);
                    },
                    value: isSwitched,
                    activeColor: Theme.of(context).appColors.primary,
                    activeTrackColor: Theme.of(context).appColors.textSecondary,
                    inactiveThumbColor: Theme.of(context).appColors.primary,
                    inactiveTrackColor: Theme.of(context).appColors.background,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
