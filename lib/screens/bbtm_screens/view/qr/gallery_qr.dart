import 'dart:convert';

import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scan/scan.dart';

import '../../models/switch_model.dart';
import '../../widgets/custom/custom_button.dart';
import '../switches/add_switch.dart';

class GalleryQRPage extends StatefulWidget {
  const GalleryQRPage({super.key});

  @override
  State<GalleryQRPage> createState() => _GalleryQRPageState();
}

class _GalleryQRPageState extends State<GalleryQRPage> {
  SwitchDetails details = SwitchDetails(
    switchId: "Unknown",
    switchSSID: "Unknown",
    switchPassword: "Unknown",
    selectedFan: "",
    switchTypes: [],
    privatePin: "1234",
    iPAddress: "Unknown",
  );

  @override
  void initState() {
    super.initState();
    scanQR();
  }

  Future<void> scanQR() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        String? barcodeScanRes = await Scan.parse(pickedFile.path);
        if (barcodeScanRes != null) {
          setState(() {
            var jsonR = json.decode(barcodeScanRes);
            debugPrint(jsonR);
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
        } else {
          // Handle null result from QR parsing
          // You can show an error message or take appropriate action
          debugPrint("QR code not found in the selected image.");
        }
      } catch (e) {
        debugPrint("$e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    if (details.switchId == "Unknown") {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).appColors.buttonBackground));
    }
    return Scaffold(
      appBar: AppBar(title: const Text("QR Details")),
      body: SafeArea(
        top: true,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * .8,
                  height: 180,
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400,
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(5, 5),
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
                              "Switch ID : ",
                              style: TextStyle(
                                  fontSize: width * 0.045,
                                  color:
                                      Theme.of(context).appColors.textPrimary,
                                  fontWeight: FontWeight.bold),
                            ),
                            Wrap(
                              children: [
                                Text(
                                  details.switchId,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: width * 0.045,
                                      color: Theme.of(context)
                                          .appColors
                                          .textPrimary,
                                      fontWeight: FontWeight.w400),
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "Switch Name : ",
                              style: TextStyle(
                                  fontSize: width * 0.045,
                                  color:
                                      Theme.of(context).appColors.textPrimary,
                                  fontWeight: FontWeight.bold),
                            ),
                            Wrap(
                              children: [
                                Text(
                                  details.switchSSID,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: width * 0.045,
                                      color: Theme.of(context)
                                          .appColors
                                          .textPrimary,
                                      fontWeight: FontWeight.w400),
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "Switch Password : ",
                              style: TextStyle(
                                  fontSize: width * 0.045,
                                  color:
                                      Theme.of(context).appColors.textPrimary,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              details.switchPassword,
                              style: TextStyle(
                                  fontSize: width * 0.045,
                                  color:
                                      Theme.of(context).appColors.textPrimary,
                                  fontWeight: FontWeight.w400),
                            )
                          ],
                        ),

                        const Expanded(
                          child: Text(
                            "Please NOTE down the password you will need to configure and change the Switch",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        // Text("Start and End Date : 00-00"),
                        // Text("Start and End Time : 00:00-00:00"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: CustomButton(
                  width: 200,
                  text: "Next",
                  onPressed: () {
                    // debugPrint('Button pressed ...');
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Instructions'),
                        content: const Text(
                            'Below to personalize your configuration you are required to change the Switch name and password for security purpose.'),
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
                  }),
            )
          ],
        ),
      ),
    );
  }
}
