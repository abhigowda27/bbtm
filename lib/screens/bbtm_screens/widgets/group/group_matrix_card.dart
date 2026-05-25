import 'dart:async';

import 'package:bbtml_new/screens/bbtm_screens/widgets/router/router_list_card.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/router_model.dart';

class GroupMatrixCard extends StatelessWidget {
  final RouterDetails switchDetails;
  final Map<String, dynamic>? status;
  final Function(bool) onToggle;
  final VoidCallback onRefresh;
  const GroupMatrixCard({
    required this.switchDetails,
    required this.status,
    required this.onToggle,
    required this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    bool isOn = status?.values.any((v) => v == "1") ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(5, 5),
          ),
        ],
        color: Theme.of(context).appColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    switchDetails.switchName,
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).appColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: Icon(
                    FontAwesomeIcons.arrowsRotate,
                    color: Theme.of(context).appColors.buttonBackground,
                  ),
                ),
                Switch(
                  onChanged: onToggle,
                  value: isOn,
                  activeThumbColor: Theme.of(context).appColors.greenButton,
                  activeTrackColor: Theme.of(context).appColors.green,
                  inactiveThumbColor: Theme.of(context).appColors.redButton,
                  inactiveTrackColor: Theme.of(context).appColors.red,
                ),
              ],
            ),
          ),
          FutureBuilder<List<String>>(
              future: fetchSwitches(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(
                      color: Theme.of(context).appColors.buttonBackground);
                }
                if (snapshot.hasError) {
                  return const Text("ERROR");
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    bool isSwitchOn =
                        status?["ON${index + 1}"]?.toString() == "1";
                    return RouterListCard(
                      routerDetails: switchDetails,
                      index: index,
                      switchStatus: isSwitchOn,
                      wifiName: "",
                    );
                  },
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                );
              }),
        ],
      ),
    );
  }

  Future<List<String>> fetchSwitches() async {
    return switchDetails.switchTypes;
  }
}
