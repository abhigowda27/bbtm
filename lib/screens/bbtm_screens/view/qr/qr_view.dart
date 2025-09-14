import 'dart:convert';

import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import '../../models/switch_model.dart';
import '../../widgets/custom/custom_button.dart';
import '../switches/add_switch.dart';

class QRView extends StatefulWidget {
  const QRView({super.key});

  @override
  State<QRView> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  @override
  void initState() {
    super.initState();
    scanQR();
  }

  SwitchDetails details = SwitchDetails(
      switchId: "Unknown",
      switchSSID: "Unknown",
      switchPassword: "Unknown",
      privatePin: "1234",
      iPAddress: "Unknown",
      switchTypes: [],
      selectedFan: "");

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;
    debugPrint(barcodeScanRes.toString());
    setState(() {
      var jsonR = json.decode(barcodeScanRes);
      details = SwitchDetails(
          switchId: jsonR['LockId'],
          privatePin: "1234",
          switchSSID: jsonR['LockSSID'],
          switchPassword: jsonR['LockPassword'].toString(),
          iPAddress: jsonR['IPAddress'],
          switchTypes: [],
          selectedFan: "");
      /*var jsonR = json.decode(barcodeScanRes);
            debugPrint(jsonR.toString());

            details = SwitchDetails(
                switchId: jsonR['SwitchId'],
                privatePin: jsonR['privatePin'],
                switchSSID: jsonR['SwitchSSID'],
                switchPassword: jsonR['SwitchPassword'],
                iPAddress: jsonR['IPAddress'],
                switchTypes: (jsonR['SwitchTypes'] as List<dynamic>)
                    .map((e) => e.toString())
                    .toList(),
                switchPassKey: jsonR['SwitchPasskey'],
                selectedFan: jsonR['SelectedFan']);*/
    });
  }

  @override
  Widget build(BuildContext context) {
    if (details.switchId == "Unknown") {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).appColors.buttonBackground));
    }
    return GestureDetector(
      // onTap: () => FocusScope.of(context).requestFocus(_model.unfocusNode),
      child: Scaffold(
        appBar: AppBar(title: const Text("QR Details")),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(25.0),
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset:
                            const Offset(5, 5), // changes position of shadow
                      ),
                    ],
                    color: Theme.of(context).appColors.background,
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
                            'Switch ID : ',
                            style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).appColors.textPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            details.switchId,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).appColors.textPrimary,
                                fontWeight: FontWeight.w400),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "Switch Name : ",
                            style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).appColors.textPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            details.switchSSID,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).appColors.textPrimary,
                                fontWeight: FontWeight.w400),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "Switch Password : ",
                            style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).appColors.textPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            details.switchPassword,
                            style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).appColors.textPrimary,
                                fontWeight: FontWeight.w400),
                          )
                        ],
                      ),

                      const Text(
                        "Please NOTE down the password you will need to configure and change the Switch",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      // Text("Start and End Date : 00-00"),
                      // Text("Start and End Time : 00:00-00:00"),
                    ],
                  ),
                ),
              ),
              CustomButton(
                  text: "Next",
                  onPressed: () {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Instructions'),
                        content: const Text(
                            'Below to personalize your configuration you are required to change the switch name and password for security purpose.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Theme.of(context).appColors.primary),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AddNewSwitchesPage(
                                            switchDetails: details,
                                          )));
                            },
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                  color: Theme.of(context).appColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
            ],
          ),
        ),
      ),
    );
  }
}
