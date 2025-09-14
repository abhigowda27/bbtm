import 'dart:async';

import 'package:bbtml_new/screens/bbtm_screens/controllers/wifi.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../widgets/text_field.dart';
import '../../../tabs_page.dart';
import '../../controllers/storage.dart';
import '../../models/switch_model.dart';
import '../../view/routers/add_router.dart';
import '../../view/schedule_on_off_page.dart';
import '../../view/switches/update_switch.dart';
import '../custom/toast.dart';

class SwitchCard extends StatefulWidget {
  final SwitchDetails switchDetails;

  const SwitchCard({required this.switchDetails, super.key});

  @override
  State<SwitchCard> createState() => _SwitchCardState();
}

class _SwitchCardState extends State<SwitchCard> {
  final StorageController _storageController = StorageController();
  bool hide = true;
  bool isExpanded = false;
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).appColors.textSecondary.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(5, 5), // changes position of shadow
            ),
          ],
          color: Theme.of(context).appColors.background,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Switch ID: ",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Flexible(
                child: Text(
                  widget.switchDetails.switchId,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                "Switch Name: ",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Flexible(
                child: Text(
                  widget.switchDetails.switchSSID,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          if (widget.switchDetails.switchTypes.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Selected Switches: ${widget.switchDetails.switchTypes.length}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_outlined
                        : Icons.keyboard_arrow_down_outlined,
                    size: width * 0.06,
                    color: Theme.of(context).appColors.textPrimary,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.switchDetails.switchTypes
                    .asMap()
                    .entries
                    .map((entry) {
                  int index = entry.key;
                  String switchType = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}: ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Expanded(
                          child: Text(
                            switchType,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: Colors.red, size: width * 0.05),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Switch"),
                                content: Text(
                                    "Are you sure you want to delete \"$switchType\"?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      "Delete",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .appColors
                                                  .redButton),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _storageController.deleteOneSwitchType(
                                switchDetails: widget.switchDetails,
                                typeToRemove: switchType,
                              );
                              setState(() {
                                widget.switchDetails.switchTypes
                                    .removeAt(index);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ]
          ],
          if (widget.switchDetails.selectedFan!.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  "Selected fan: ",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Flexible(
                  child: Text(
                    widget.switchDetails.selectedFan!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
          Row(
            children: [
              Text(
                "Switch PassKey : ",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Flexible(
                child: Text(
                  hide
                      ? List.generate(
                          widget.switchDetails.switchPassKey!.length,
                          (index) => "*").join()
                      : widget.switchDetails.switchPassKey!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            ],
          ),
          Row(
            children: [
              Text(
                "Switch Password: ",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Flexible(
                child: Text(
                  hide
                      ? List.generate(
                          widget.switchDetails.switchPassword.length,
                          (index) => "*").join()
                      : widget.switchDetails.switchPassword,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).appColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    tooltip: "Delete Switch",
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (cont) {
                            final formKey = GlobalKey<FormState>();
                            TextEditingController pinController =
                                TextEditingController();

                            return Form(
                              key: formKey,
                              child: AlertDialog(
                                title: Text(
                                  widget.switchDetails.switchSSID,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                content: Text(
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    'Enter the switch pin to proceed'),
                                actions: [
                                  Column(
                                    children: [
                                      CustomTextField(
                                        maxLength: 4,
                                        controller: pinController,
                                        validator: (value) {
                                          if (value!.length <= 3) {
                                            return "Switch Pin cannot be less than 4 letters";
                                          }
                                          if (pinController.text !=
                                              widget.switchDetails.privatePin) {
                                            return "Pin does not match";
                                          }
                                          return null;
                                        },
                                        hintText: "Enter Old Pin",
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('CANCEL'),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (formKey.currentState!
                                                  .validate()) {
                                                if (pinController.text ==
                                                    widget.switchDetails
                                                        .privatePin) {
                                                  _storageController
                                                      .deleteOneSwitch(
                                                          widget.switchDetails);
                                                  Navigator.pushAndRemoveUntil<
                                                      dynamic>(
                                                    context,
                                                    MaterialPageRoute<dynamic>(
                                                      builder: (BuildContext
                                                              context) =>
                                                          const TabsPage(),
                                                    ),
                                                    (route) => false,
                                                  );
                                                } else {
                                                  Navigator.pop(context);
                                                  showToast(context,
                                                      "Pin do not match");
                                                }
                                              }
                                            },
                                            child: const Text('Confirm'),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            );
                          });
                    },
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).appColors.textPrimary,
                    )),
                IconButton(
                    tooltip: "password",
                    onPressed: () {
                      setState(() {
                        hide = !hide;
                      });
                    },
                    icon: hide
                        ? Icon(
                            Icons.visibility_outlined,
                            color: Theme.of(context).appColors.textPrimary,
                          )
                        : Icon(
                            Icons.visibility_off_outlined,
                            color: Theme.of(context).appColors.textPrimary,
                          )),
                IconButton(
                    tooltip: "Refresh Switch",
                    onPressed: () {
                      debugPrint(_connectionStatus);
                      debugPrint(widget.switchDetails.switchSSID);

                      if (!_connectionStatus
                              .contains(widget.switchDetails.switchSSID) &&
                          !widget.switchDetails.switchSSID
                              .contains(_connectionStatus)) {
                        showToast(context,
                            "You should be connected to ${widget.switchDetails.switchSSID} to refresh the switch");
                        return;
                      }
                      showDialog(
                          context: context,
                          builder: (cont) {
                            final formKey = GlobalKey<FormState>();
                            TextEditingController pinController0 =
                                TextEditingController();
                            return Form(
                              key: formKey,
                              child: AlertDialog(
                                title: Text(
                                  widget.switchDetails.switchSSID,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                content: Text(
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    'Enter the switch pin to proceed'),
                                actions: [
                                  Column(
                                    children: [
                                      CustomTextField(
                                        maxLength: 4,
                                        controller: pinController0,
                                        validator: (value) {
                                          if (value!.length <= 3) {
                                            return "Switch Pin cannot be less than 4 letters";
                                          }
                                          if (pinController0.text !=
                                              widget.switchDetails.privatePin) {
                                            return "Pin does not match";
                                          }
                                          return null;
                                        },
                                        hintText: "Enter Switch Pin",
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('CANCEL'),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (formKey.currentState!
                                                  .validate()) {
                                                if (pinController0.text ==
                                                    widget.switchDetails
                                                        .privatePin) {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              UpdatePage(
                                                                  switchDetails:
                                                                      widget
                                                                          .switchDetails)));
                                                } else {
                                                  Navigator.pop(context);
                                                  showToast(context,
                                                      "Pin do not match");
                                                }
                                              }
                                            },
                                            child: const Text('Confirm'),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            );
                          });
                    },
                    icon: Icon(
                      FontAwesomeIcons.penToSquare,
                      color: Theme.of(context).appColors.textPrimary,
                    )),
                IconButton(
                    tooltip: "Add Router",
                    onPressed: () async {
                      if (!_connectionStatus
                              .contains(widget.switchDetails.switchSSID) &&
                          !widget.switchDetails.switchSSID
                              .contains(_connectionStatus)) {
                        showToast(context,
                            "You should be connected to ${widget.switchDetails.switchSSID} to add the Router");
                        return;
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddNewRouterPage(
                                    switchDetails: widget.switchDetails,
                                    isFromSwitch: true,
                                  )));
                    },
                    icon: Transform.rotate(
                      angle: -90 * 3.1415926535897932 / 180,
                      child: SvgPicture.asset(
                        "assets/images/wifi.svg",
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).appColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    )),
                IconButton(
                    tooltip: "timer",
                    onPressed: () {
                      if (!_connectionStatus
                              .contains(widget.switchDetails.switchSSID) &&
                          !widget.switchDetails.switchSSID
                              .contains(_connectionStatus)) {
                        debugPrint(_connectionStatus);
                        showToast(context,
                            "You should be connected to ${widget.switchDetails.switchSSID} to Proceed");
                        return;
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ScheduleOnOffPage(
                                    switchName: widget.switchDetails.switchSSID,
                                    ipAddress: widget.switchDetails.iPAddress,
                                  )));
                    },
                    icon: Icon(
                      Icons.access_alarms_sharp,
                      color: Theme.of(context).appColors.textPrimary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
