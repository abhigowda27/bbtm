import 'dart:async';

import 'package:bbtml_new/main.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

import '../../../../controllers/apis.dart';
import '../../controllers/wifi.dart';
import '../../models/router_model.dart';
import '../custom/toast.dart';

class GroupFanSwitchCard extends StatefulWidget {
  final RouterDetails switchDetails;

  const GroupFanSwitchCard({
    required this.switchDetails,
    super.key,
  });

  @override
  State<GroupFanSwitchCard> createState() => _GroupFanSwitchCardState();
}

class _GroupFanSwitchCardState extends State<GroupFanSwitchCard> {
  late String selectedControl = "OFF";

  final List<String> controls = [
    "OFF",
    "LOW",
    "MEDIUM",
    "HIGH",
  ];

  late NetworkService _networkService;

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService();
    updateSwitch();
  }

  /// ✅ WiFi validation (NEW STANDARD)
  bool _isConnectedToRouter(String currentWifi) {
    return currentWifi.toLowerCase().contains(
              widget.switchDetails.routerName.toLowerCase(),
            ) ||
        widget.switchDetails.routerName.toLowerCase().contains(
              currentWifi.toLowerCase(),
            );
  }

  /// ✅ Fetch current FAN state
  Future<void> updateSwitch() async {
    try {
      final apiRes = await ApiConnect.hitApiGet(
        "${widget.switchDetails.iPAddress}/Switchstatus",
      );

      final res = Map<String, dynamic>.from(apiRes["data"] ?? {});

      final fanState = (res["FAN"] ?? "").toString().toUpperCase();

      if (!mounted) return;

      setState(() {
        switch (fanState) {
          case "LOW":
            selectedControl = "LOW";
            break;
          case "MED":
          case "MEDIUM":
            selectedControl = "MEDIUM";
            break;
          case "HIGH":
            selectedControl = "HIGH";
            break;
          default:
            selectedControl = "OFF";
        }
      });
    } catch (e) {
      debugPrint("Error fetching switch status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _networkService.wifiNameNotifier,
      builder: (context, wifiName, _) {
        final currentWifi = wifiName ?? "Unknown";

        return Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.blueAccent,
                Colors.lightBlueAccent,
                Colors.greenAccent,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${widget.switchDetails.routerName} - ${widget.switchDetails.selectedFan}",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).appColors.background,
                          ),
                    ),
                  ),

                  /// Refresh
                  IconButton(
                    onPressed: updateSwitch,
                    icon: Icon(
                      FontAwesomeIcons.arrowsRotate,
                      color: Theme.of(context).appColors.background,
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Icon(
                    FontAwesomeIcons.fan,
                    size: 35,
                    color: Colors.deepPurpleAccent,
                  ),
                ],
              ),

              Divider(
                color: Theme.of(context).appColors.background,
              ),

              /// SLIDER
              SleekCircularSlider(
                min: 0,
                max: controls.length.toDouble() - 1,
                initialValue: controls.indexOf(selectedControl).toDouble(),
                appearance: CircularSliderAppearance(
                  size: 150,
                  startAngle: 150,
                  angleRange: 240,
                  customWidths: CustomSliderWidths(
                    trackWidth: 8,
                    progressBarWidth: 12,
                    handlerSize: 12,
                  ),
                  customColors: CustomSliderColors(
                    trackColors: [
                      Colors.blueAccent,
                      Colors.lightBlueAccent,
                      Colors.greenAccent,
                    ],
                    progressBarColors: [
                      Colors.blueAccent,
                      Colors.lightBlueAccent,
                      Colors.greenAccent,
                    ],
                    dotColor: Colors.white,
                  ),
                  infoProperties: InfoProperties(
                    mainLabelStyle:
                        Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).appColors.background,
                            ),
                    modifier: (value) {
                      return controls[value.round()];
                    },
                  ),
                ),
                onChangeEnd: (value) async {
                  final control = controls[value.round()];

                  /// ✅ WiFi check
                  if (!_isConnectedToRouter(currentWifi)) {
                    showToast(
                      context,
                      "Please connect to ${widget.switchDetails.routerName}",
                    );
                    return;
                  }

                  setState(() {
                    selectedControl = control;
                  });

                  await sendFanCommand(control);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Send FAN command
  Future<void> sendFanCommand(String command) async {
    try {
      final response = await ApiConnect.hitApiPost(
        "${widget.switchDetails.iPAddress}/getSwitchcmd",
        {
          "Lock_id": widget.switchDetails.switchID,
          "lock_passkey": widget.switchDetails.switchPasskey,
          "lock_cmd": command,
        },
      );

      final res = response.toString().toLowerCase();

      if (res.contains("ok")) {
        showToast(
          navigatorKey.currentContext!,
          "Fan '$command' executed successfully",
        );
      } else {
        showToast(
          navigatorKey.currentContext!,
          "Failed to execute. Try again.",
        );
      }
    } on DioException catch (e) {
      debugPrint("API Error: $e");
      showToast(navigatorKey.currentContext!, "Network error");
    } catch (e) {
      debugPrint("Unexpected Error: $e");
      showToast(navigatorKey.currentContext!, "Something went wrong");
    }
  }
}
