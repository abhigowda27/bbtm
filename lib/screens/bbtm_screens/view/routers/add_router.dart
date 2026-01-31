import 'dart:async';

import 'package:bbtml_new/main.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:bbtml_new/widgets/mandatory_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../../../../constants.dart';
import '../../../../controllers/apis.dart';
import '../../../../widgets/text_field.dart';
import '../../../tabs_page.dart';
import '../../controllers/storage.dart';
import '../../controllers/wifi.dart';
import '../../models/router_model.dart';
import '../../models/switch_model.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/custom/toast.dart';

class AddNewRouterPage extends StatefulWidget {
  final SwitchDetails? switchDetails;
  final bool isFromSwitch;
  final String selectedWifiName;
  const AddNewRouterPage(
      {super.key,
      required this.isFromSwitch,
      this.switchDetails,
      required this.selectedWifiName});

  @override
  State<AddNewRouterPage> createState() => _AddNewRouterPageState();
}

class _AddNewRouterPageState extends State<AddNewRouterPage> {
  final StorageController _storage = StorageController();
  late String switchID;
  late String switchName;
  String? selectedFan;
  String? switchType;
  String? passKey;
  late List<String> switchList;
  final TextEditingController _ssid = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
  late NetworkService _networkService;

  @override
  void initState() {
    super.initState();
    _ssid.text = widget.selectedWifiName;
    _networkService = NetworkService();
    _initNetworkInfo();
    connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
    if (widget.isFromSwitch) {
      setState(() {
        switchID = widget.switchDetails!.switchId;
        switchName = widget.switchDetails!.switchSSID;
        passKey = widget.switchDetails!.switchPassKey!;
        switchList = widget.switchDetails!.switchTypes;
        selectedFan = widget.switchDetails!.selectedFan;
        switchType = widget.switchDetails!.switchType;
      });
    } else {
      getSwitchDetails();
    }
  }

  Future<void> getSwitchDetails() async {
    List<SwitchDetails> switches = await _storage.readSwitches();
    for (var element in switches) {
      if (_connectionStatus.contains(element.switchSSID) ||
          element.switchSSID.contains(_connectionStatus)) {
        setState(() {
          passKey = element.switchPassKey!;
          switchID = element.switchId;
          switchName = element.switchSSID;
          switchList = element.switchTypes;
          selectedFan = element.selectedFan;
          switchType = element.switchType;
        });
        break;
      }
    }
  }

  void connectToWiFi() async {
    debugPrint("========== WIFI CONNECTION START ==========");

    try {
      // 1. Check WiFi Enabled
      bool isEnabled = await WiFiForIoTPlugin.isEnabled();
      debugPrint("WiFi Enabled: $isEnabled");

      if (!isEnabled) {
        debugPrint("WiFi is OFF. Trying to enable...");
        dynamic enabled = await WiFiForIoTPlugin.setEnabled(
            true); // Note: Returns dynamic (bool on Android)
        debugPrint("WiFi enabling result: $enabled");
      }

      // 2. Check Current Connection
      String? currentSSID = await WiFiForIoTPlugin.getSSID();
      debugPrint("Current Connected SSID: $currentSSID");

      // Normalize target
      String targetSSID = _ssid.text.trim().toLowerCase();
      String? password = _password.text.trim();
      if (password.isEmpty) {
        debugPrint("⚠️ No password provided—ensure network is open!");
      } else {
        debugPrint(
            "Password: '$password' (length: ${password.length} – verify exact match, e.g., no extra '0')");
      }

      // Early exit if already connected
      if (currentSSID?.toLowerCase() == targetSSID) {
        debugPrint("Already connected to target WiFi: $targetSSID");
        return;
      }

      // 3. Scan & Validate Target
      List<WiFiAccessPoint> networks =
          await WiFiScan.instance.getScannedResults();
      debugPrint("Available Networks (${networks.length}):");
      bool targetFound = false;
      for (var net in networks) {
        debugPrint(
            " → SSID: ${net.ssid} | BSSID: ${net.bssid} | Level: ${net.level}");
        if (net.ssid.toLowerCase() == targetSSID) {
          targetFound = true;
        }
      }
      if (!targetFound) {
        debugPrint(
            "❌ Target SSID '$targetSSID' not found in scan. Check spelling, range, or if hidden.");
        return;
      }

      // // 4. Force Disconnect from Current (Key for switch)
      // if (currentSSID != null && currentSSID.toLowerCase() != targetSSID) {
      //   debugPrint("Disconnecting from current SSID: $currentSSID");
      //   bool disconnected = await WiFiForIoTPlugin.disconnect();
      //   debugPrint("Disconnect result: $disconnected");
      //   if (disconnected) {
      //     await Future.delayed(const Duration(seconds: 5));
      //     currentSSID = await WiFiForIoTPlugin.getSSID();
      //     debugPrint("SSID after disconnect wait: $currentSSID (should be null)");
      //   } else {
      //     debugPrint("❌ Disconnect failed—ensure CHANGE_WIFI_STATE permission.");
      //     return;
      //   }
      // }

      // 5. Security Type
      NetworkSecurity securityType =
          password.isEmpty ? NetworkSecurity.NONE : NetworkSecurity.WPA;

      // 6. Connect
      debugPrint("Attempting connection to SSID: $targetSSID");
      debugPrint("Using password: $password");

      bool? result = await WiFiForIoTPlugin.connect(
        targetSSID,
        password: password,
        security: securityType,
        withInternet: false,
        timeoutInSeconds: 30, // Plugin default, but explicit
      );
      debugPrint("connect() returned: $result");

      if (result != true) {
        debugPrint("❌ Connection initiation failed.");
        return;
      }

      // 7. Force WiFi Usage
      bool forced = await WiFiForIoTPlugin.forceWifiUsage(true);
      debugPrint("Forced WiFi usage: $forced");

      // 8. Poll for Connection (Enhanced: 45s total, 1s intervals post-connect)
      int maxWaitSeconds = 45;
      int intervalSeconds = 1;
      bool isConnected = false;
      String? newSSID;

      // Initial post-connect wait (3s)
      await Future.delayed(const Duration(seconds: 3));
      debugPrint("Starting polling...");

      for (int i = 0; i < maxWaitSeconds; i += intervalSeconds) {
        newSSID = await WiFiForIoTPlugin.getSSID();
        bool connected = await WiFiForIoTPlugin.isConnected();
        debugPrint(
            "After ${i + intervalSeconds}s: SSID='$newSSID' | isConnected=$connected");

        if (newSSID?.toLowerCase() == targetSSID && connected) {
          isConnected = true;
          break;
        }
        await Future.delayed(Duration(seconds: intervalSeconds));
      }

      debugPrint(
          "Final: Connected to target WiFi: $isConnected (SSID: $newSSID)");
      if (isConnected) {
        debugPrint("✅ Success! Connected to $targetSSID.");
        // Optional: Register for persistence if needed
        // await WiFiForIoTPlugin.registerWifiNetwork(targetSSID, password: password, security: securityType);
      } else {
        debugPrint(
            "❌ Failed. Common causes: Wrong password, approval prompt dismissed, or OS band preference.");
        // Cleanup
        await WiFiForIoTPlugin.disconnect();
        await WiFiForIoTPlugin.removeWifiNetwork(targetSSID);
      }
    } catch (e, stack) {
      debugPrint("❌ ERROR while connecting to WiFi: $e");
      debugPrint("STACK TRACE: $stack");
    }

    debugPrint("========== WIFI CONNECTION END ==========");
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

  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final height = screenSize.height;
    return Scaffold(
        appBar: AppBar(title: const Text("Add Router")),
        body: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                richTxt(text: "Router Name"),
                CustomTextField(
                  controller: _ssid,
                  validator: (value) {
                    if (value!.isEmpty) return "SSID cannot be empty";
                    return null;
                  },
                  hintText: "New Router Name",
                ),
                SizedBox(
                  height: height * 0.01,
                ),
                richTxt(text: "Router Password"),
                CustomTextField(
                  controller: _password,
                  validator: (value) {
                    if (value!.length <= 7) {
                      return "Router Password cannot be less than 8 letters";
                    }
                    return null;
                  },
                  hintText: "New Router Password",
                ),
                // ElevatedButton(
                //     onPressed: connectToWiFi, child: Text(";lkjhgf")),
                const Spacer(),
                loading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 0, 16, 16),
                          child: InkWell(
                            splashColor:
                                Theme.of(context).appColors.textSecondary,
                            // onTap: onPressed,
                            child: Container(
                              width: 200,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).appColors.textSecondary,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 1,
                                    color: Theme.of(context)
                                        .appColors
                                        .textSecondary,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      Theme.of(context).appColors.textSecondary,
                                  width: 1,
                                ),
                              ),
                              alignment: const AlignmentDirectional(0, 0),
                              child: CircularProgressIndicator(
                                color: Theme.of(context).appColors.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: CustomButton(
                          width: 200,
                          text: "Submit",
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                setState(() {
                                  loading = true;
                                });
                                if (!widget.isFromSwitch) {
                                  await getSwitchDetails();
                                }
                                debugPrint("inside submit $passKey");
                                if (passKey == null) {
                                  showToast(navigatorKey
                                      .currentContext!,
                                      "No switch found with switch $_connectionStatus");
                                  setState(() {
                                    loading = false;
                                  });
                                  return;
                                }
                                String? existedRouter = await _storage
                                    .getRouterNameIfSwitchIDExists(switchID);
                                if (existedRouter == _ssid.text) {
                                  showToast(navigatorKey.currentContext!,
                                      "SwitchId is already Exist with this router");
                                  setState(() {
                                    loading = false;
                                  });
                                  return;
                                }
                                if (existedRouter != null) {
                                  showDialog(
                                    context: navigatorKey.currentContext!,
                                    builder: (cont) {
                                      return AlertDialog(
                                        title: const Text('Update Router'),
                                        content: const Text(
                                            'SwitchId is already Exist, Do you want to update the existing router'),
                                        actions: [
                                          OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                loading = false;
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              'CANCEL',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .appColors
                                                      .primary),
                                            ),
                                          ),
                                          OutlinedButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              try {
                                                await ApiConnect.hitApiGet(
                                                    "${Constants.routerIP}/");
                                                var res =
                                                    await ApiConnect.hitApiPost(
                                                        "${Constants.routerIP}/getWifiParem",
                                                        {
                                                      "router_ssid": _ssid.text,
                                                      "router_password":
                                                          _password.text,
                                                      "switch_passkey": passKey,
                                                    });
                                                String ipAddress =
                                                    res['IPAddress'];
                                                if (ipAddress
                                                    .contains("0.0.0.0")) {
                                                  showToast(navigatorKey
                                                      .currentContext!,
                                                      "Unable to connect to IP. Try again.");
                                                  return;
                                                }
                                                RouterDetails routerDetails =
                                                    RouterDetails(
                                                        switchType: switchType,
                                                        switchID: switchID,
                                                        switchName: switchName,
                                                        routerName: _ssid.text,
                                                        routerPassword:
                                                            _password.text,
                                                        deviceMacId: res['MAC'],
                                                        switchPasskey: passKey!,
                                                        iPAddress:
                                                            res['IPAddress'],
                                                        switchTypes: switchList,
                                                        selectedFan:
                                                            selectedFan);
                                                await _storage.updateRouter(
                                                    routerDetails);
                                                Navigator.pushAndRemoveUntil<
                                                    dynamic>(
                                                  navigatorKey
                                                      .currentContext!,
                                                  MaterialPageRoute<dynamic>(
                                                    builder: (BuildContext
                                                            context) =>
                                                        const TabsPage(),
                                                  ),
                                                  (route) => false,
                                                );
                                              } catch (e) {
                                                debugPrint(
                                                    "Error inside updating");
                                                debugPrint("$e");
                                                showToast(navigatorKey
                                                    .currentContext!, "Error");
                                              }
                                            },
                                            child: Text(
                                              'OK',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .appColors
                                                      .primary),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                } else {
                                  showToast(navigatorKey
                                      .currentContext!,
                                      "You are connected to $_connectionStatus");
                                  await ApiConnect.hitApiGet(
                                    "${Constants.routerIP}/",
                                  );
                                  var res = await ApiConnect.hitApiPost(
                                      "${Constants.routerIP}/getWifiParem", {
                                    "router_ssid": _ssid.text,
                                    "router_password": _password.text,
                                    "switch_passkey": passKey,
                                  });
                                  String iPAddress = res['IPAddress'];
                                  if (iPAddress.contains("0.0.0.0")) {
                                    showToast(navigatorKey
                                        .currentContext!,
                                        "Unable to connect IP. Try Again., ${iPAddress.contains("0.0.0.0")}");
                                    setState(() {
                                      loading = false;
                                    });
                                    return;
                                  }
                                  setState(() {
                                    loading = false;
                                  });
                                  if (res["MAC"] == null) {
                                    showToast(navigatorKey
                                        .currentContext!,
                                        "MAC id is Null please, check with operator");
                                  }
                                  RouterDetails routerDetails = RouterDetails(
                                      switchType: switchType,
                                      switchID: switchID,
                                      switchName: switchName,
                                      routerName: _ssid.text,
                                      routerPassword: _password.text,
                                      switchPasskey: passKey!,
                                      iPAddress: res['IPAddress'],
                                      deviceMacId: res['MAC'],
                                      switchTypes: switchList,
                                      selectedFan: selectedFan);
                                  setState(() {
                                    loading = true;
                                  });
                                  _storage.addRouters(routerDetails);
                                  setState(() {
                                    loading = false;
                                  });
                                  Navigator.pushAndRemoveUntil<dynamic>(
                                    navigatorKey
                                        .currentContext!,
                                    MaterialPageRoute<dynamic>(
                                      builder: (BuildContext context) =>
                                          const TabsPage(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                debugPrint(e.toString());
                                showToast(
                                    navigatorKey
                                        .currentContext!, "Please connect to correct wifi");
                                setState(() {
                                  loading = false;
                                });
                              }
                            }
                          },
                        ),
                      )
              ],
            ),
          ),
        ));
  }
}
