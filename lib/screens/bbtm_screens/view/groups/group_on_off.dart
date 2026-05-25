import 'dart:async';

import 'package:bbtml_new/common/common_services.dart';
import 'package:bbtml_new/main.dart';
import 'package:bbtml_new/screens/bbtm_screens/widgets/custom/toast.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:bbtml_new/widgets/common_snackbar.dart';
import 'package:flutter/material.dart';

import '../../../../controllers/apis.dart';
import '../../../tabs_page.dart';
import '../../controllers/storage.dart';
import '../../models/router_model.dart';
import '../../widgets/group/group_matrix_card.dart';

class GroupSwitchOnOff extends StatefulWidget {
  final String groupName;
  final String selectedRouter;
  final List<RouterDetails> selectedSwitches;
  final int maximumWattage;
  const GroupSwitchOnOff({
    required this.groupName,
    required this.selectedRouter,
    required this.selectedSwitches,
    super.key,
    required this.maximumWattage,
  });

  @override
  State<GroupSwitchOnOff> createState() => _GroupSwitchOnOffState();
}

class _GroupSwitchOnOffState extends State<GroupSwitchOnOff> {
  final StorageController _storageController = StorageController();
  late bool isSwitchOn = false;
  late Timer _timer;
  final Duration _timerDuration = const Duration(seconds: 30);
  Map<String, Map<String, dynamic>> switchStatuses = {};

  Future<List<RouterDetails>> fetchRouters() async {
    return widget.selectedSwitches;
  }

  int calculateCurrentLoad() {
    int total = 0;

    for (var router in widget.selectedSwitches) {
      final status = switchStatuses[router.switchID];

      if (status == null) continue;

      // Check if ANY switch is ON
      final hasAnyOn = status.entries.any(
        (e) => e.key.startsWith("ON") && e.value.toString() == "1",
      );

      // ✅ Add FULL router wattage
      if (hasAnyOn) {
        total += router.wattage;
      }
    }

    return total;
  }

  void showCertLogPopup(String certLog) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("🔒 Security Certificate Details"),
        content: SingleChildScrollView(
          child: Text(certLog),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> loadInitialStatus(RouterDetails switchDetails) async {
    try {
      Map<String, dynamic> apiRes =
          await ApiConnect.hitApiGet("${switchDetails.iPAddress}/Switchstatus");

      final res = Map<String, dynamic>.from(apiRes["data"]);

      switchStatuses[switchDetails.switchID] = res;
      if (res["cert_log"] != null) {
        showCertLogPopup(res["cert_log"]);
      }
      setState(() {});
    } catch (e) {
      debugPrint("Error loading status");
    }
  }

  Future<void> toggleSwitch(RouterDetails switchDetails, bool value) async {
    final totalSwitches = switchDetails.switchTypes.length;

    int currentLoad = calculateCurrentLoad();
    final data = switchStatuses[switchDetails.switchID];
    final switchValues = data?.entries
        .where((e) => e.key.startsWith("ON"))
        .map((e) => e.value.toString())
        .toList();

    final isAlreadyFullyOn = switchValues != null &&
        switchValues.isNotEmpty &&
        switchValues.every((v) => v == "1");

    final additionalLoad = isAlreadyFullyOn ? 0 : switchDetails.wattage;

    if (value && !isAlreadyFullyOn) {
      if (currentLoad + additionalLoad > widget.maximumWattage) {
        showToast(
          context,
          "Max wattage will be exceeded! Cannot turn ON ${switchDetails.switchName}",
        );
        return;
      }
    }

    try {
      for (int i = 1; i <= totalSwitches; i++) {
        await ApiConnect.hitApiPost(
          "${switchDetails.iPAddress}/getSwitchcmd$i",
          {
            "Lock_id": switchDetails.switchID,
            "lock_passkey": switchDetails.switchPasskey,
            "lock_cmd$i": value ? "ON$i" : "OFF$i",
          },
        );
      }

      // ✅ Update central state
      switchStatuses[switchDetails.switchID] = {
        for (int i = 1; i <= totalSwitches; i++) "ON$i": value ? "1" : "0"
      };

      setState(() {});

      if (value) {
        commonSnackBar(navigatorKey.currentContext!,
            "${switchDetails.switchName} turned ON Successfully");
      } else {
        commonSnackBar(navigatorKey.currentContext!,
            "${switchDetails.switchName} turned OFF Successfully");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (var sw in widget.selectedSwitches) {
      loadInitialStatus(sw);
    }
    _loadSwitchState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer(_timerDuration, _navigateToNextPage);
  }

  void _resetTimer() {
    _timer.cancel();
    debugPrint("starts reloading");
    _startTimer();
  }

  Future<void> _loadSwitchState() async {
    bool state = await _storageController.loadGroupSwitchState();
    setState(() {
      isSwitchOn = state;
    });
  }

  Future<void> _saveGroupSwitchState(bool value) async {
    setState(() {
      isSwitchOn = value;
    });
    await _storageController.saveGroupSwitchState(value);
  }

  void _navigateToNextPage() {
    if (mounted) {
      Navigator.pushAndRemoveUntil<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => const TabsPage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    return GestureDetector(
      onTap: _resetTimer,
      child: Scaffold(
        appBar: AppBar(title: const Text("GROUP SWITCH")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 7,
                      offset: const Offset(5, 5),
                    ),
                  ],
                  color: Theme.of(context)
                      .appColors
                      .primary
                      .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.groupName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FutureBuilder<List<RouterDetails>>(
                      future: fetchRouters(),
                      builder: (context, routerSnapshot) {
                        if (routerSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(
                              color:
                                  Theme.of(context).appColors.buttonBackground);
                        }
                        if (routerSnapshot.hasError) {
                          return const Text("ERROR");
                        }
                        final List<RouterDetails> routers =
                            routerSnapshot.data ?? [];
                        return Switch(
                          onChanged: (value) async {
                            if (value) {
                              int currentLoad = calculateCurrentLoad();
                              int additionalLoad = 0;

                              for (var switchDetails in routers) {
                                final status =
                                    switchStatuses[switchDetails.switchID];

                                final switchValues = status?.entries
                                    .where((e) => e.key.startsWith("ON"))
                                    .map((e) => e.value.toString())
                                    .toList();

                                final totalSwitches =
                                    switchDetails.switchTypes.length;

                                final switchesToTurnOn = switchValues
                                        ?.where((v) => v != "1")
                                        .length ??
                                    totalSwitches;

                                if (switchesToTurnOn > 0 && totalSwitches > 0) {
                                  final perSwitchWatt =
                                      switchDetails.wattage / totalSwitches;
                                  additionalLoad +=
                                      (perSwitchWatt * switchesToTurnOn)
                                          .round();
                                }
                              }

                              if (currentLoad + additionalLoad >
                                  widget.maximumWattage) {
                                showToast(
                                  context,
                                  "Max wattage exceeded! Cannot turn ON group",
                                );
                                return;
                              }
                            }

                            // ✅ Only executes if safe
                            await _saveGroupSwitchState(value);
//  Execute all ON/OFF commands first
                            for (var switchDetails in routers) {
                              var totalSwitches =
                                  switchDetails.switchTypes.length;

                              try {
                                for (int i = 1; i <= totalSwitches; i++) {
                                  await ApiConnect.hitApiPost(
                                    "${switchDetails.iPAddress}/getSwitchcmd$i",
                                    {
                                      "Lock_id": switchDetails.switchID,
                                      "lock_passkey":
                                          switchDetails.switchPasskey,
                                      "lock_cmd$i": value ? "ON$i" : "OFF$i",
                                    },
                                  ).timeout(const Duration(seconds: 5));
                                }
                              } catch (e) {
                                debugPrint(
                                    'API call failed for ${switchDetails.switchName}');
                              }
                            }

                            for (var switchDetails in routers) {
                              await loadInitialStatus(switchDetails);
                            }

                            setState(() {
                              isSwitchOn = value;
                            });

                            commonSnackBar(
                              navigatorKey.currentContext!,
                              value
                                  ? "Group turned ON successfully"
                                  : "Group turned OFF successfully",
                            );
                          },
                          value: isSwitchOn,
                          activeThumbColor:
                              Theme.of(context).appColors.greenButton,
                          activeTrackColor: Theme.of(context).appColors.green,
                          inactiveThumbColor:
                              Theme.of(context).appColors.redButton,
                          inactiveTrackColor: Theme.of(context).appColors.red,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Text(
                  "Maximum Wattage ${CommonServices().formatWatt(widget.maximumWattage)}"),
              FutureBuilder<List<RouterDetails>>(
                future: fetchRouters(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(
                        color: Theme.of(context).appColors.buttonBackground);
                  }
                  if (snapshot.hasError) {
                    return const Text("ERROR");
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      if (snapshot.data![index].switchTypes.isNotEmpty) {
                        final switchItem = widget.selectedSwitches[index];

                        return GroupMatrixCard(
                          switchDetails: snapshot.data![index],
                          status: switchStatuses[switchItem.switchID],
                          onToggle: (value) => toggleSwitch(switchItem, value),
                          onRefresh: () => loadInitialStatus(switchItem),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: 15);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
