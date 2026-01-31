import 'dart:convert';

import 'package:bbtml_new/main.dart';
import 'package:bbtml_new/screens/bbtm_screens/models/appliance_model.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:bbtml_new/widgets/mandatory_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../constants.dart';
import '../../../../controllers/apis.dart';
import '../../../../widgets/text_field.dart';
import '../../../tabs_page.dart';
import '../../controllers/storage.dart';
import '../../models/switch_model.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/custom/toast.dart';

class AddNewSwitchesPage extends StatefulWidget {
  const AddNewSwitchesPage({super.key, required this.switchDetails});
  final SwitchDetails switchDetails;
  @override
  State<AddNewSwitchesPage> createState() => _AddNewSwitchesPageState();
}

class _AddNewSwitchesPageState extends State<AddNewSwitchesPage> {
  final StorageController _storageController = StorageController();
  final TextEditingController _switchId = TextEditingController();
  final TextEditingController _passKey = TextEditingController();
  final TextEditingController _ssid = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _privatePin = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? _addFan = "No";
  final TextEditingController _fanNameController = TextEditingController();
  String? _selectedSwitchType;
  String? selectedFan;
  final List<String> _switchesWithFan = [
    'Switch 1',
    'Switch 2',
    'Switch 3',
    'Switch 4',
  ];

  final List<String> _switchesWithoutFan = [
    'Switch 1',
    'Switch 2',
    'Switch 3',
    'Switch 4',
    'Switch 5',
  ];

  List<String> _availableSwitchTypes = [];
  bool loading = false;
  List<Map<String, TextEditingController>> selectedSwitches = [];

  @override
  void initState() {
    super.initState();
    initValues();
    _loadAppliances();
    // _updateAvailableSwitchTypes();
  }

  List<Appliance> _appliances = [];
  Appliance? _selectedAppliance;

  Future<void> _loadAppliances() async {
    final jsonString =
        await rootBundle.loadString('assets/json/appliances_data.json');

    final Map<String, dynamic> jsonData = json.decode(jsonString);

    setState(() {
      _appliances = (jsonData['appliances'] as List)
          .map((e) => Appliance.fromJson(e))
          .toList();
    });
  }

  void initValues() {
    _switchId.text = widget.switchDetails.switchId;
    _ssid.text = widget.switchDetails.switchSSID;
    _password.text = widget.switchDetails.switchPassword;
    _passKey.text = widget.switchDetails.switchPassKey!;
    _privatePin.text = widget.switchDetails.privatePin;

    // For fan
    if (widget.switchDetails.selectedFan!.isNotEmpty) {
      _addFan = "Yes";
      _fanNameController.text = widget.switchDetails.selectedFan!;
    } else {
      _addFan = "No";
    }

    // Prefill switch types (rename switches)
    selectedSwitches = widget.switchDetails.switchTypes
        .map((type) => {
              'type': TextEditingController(text: type),
            })
        .toList();
  }

  void _updateAvailableSwitchTypes() {
    setState(() {
      _availableSwitchTypes = _addFan == "Yes"
          ? List.from(_switchesWithFan)
          : List.from(_switchesWithoutFan);
      selectedSwitches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final height = screenSize.height;
    return Scaffold(
      appBar: AppBar(title: const Text("Add Device")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              richTxt(text: "Switch ID"),
              CustomTextField(
                controller: _switchId,
                validator: (value) {
                  if (value!.isEmpty) return "Switch ID cannot be empty";
                  return null;
                },
                hintText: "SwitchID",
              ),
              richTxt(text: "Switch Name"),
              CustomTextField(
                controller: _ssid,
                validator: (value) {
                  if (value!.isEmpty) return "SSID cannot be empty";
                  return null;
                },
                hintText: "New Switch Name",
              ),
              richTxt(text: "Select Switch Type"),
              GestureDetector(
                onTap: () => _showApplianceBottomSheet(),
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: TextEditingController(
                      text: _selectedAppliance?.name ?? "",
                    ),
                    validator: (_) {
                      if (_selectedAppliance == null) {
                        return "Please select an appliance";
                      }
                      return null;
                    },
                    hintText: "Select Appliance",
                    suffixIcon: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
              ),
              richTxt(text: "Switch Password"),
              CustomTextField(
                controller: _password,
                validator: (value) {
                  if (value!.length <= 7) {
                    return "Switch Password cannot be less than 8 letters";
                  }
                  return null;
                },
                hintText: "New Password",
              ),
              richTxt(text: "PIN"),
              CustomTextField(
                maxLength: 4,
                controller: _privatePin,
                validator: (value) {
                  if (value!.length <= 3) {
                    return "Switch Pin cannot be less than 4 letters";
                  }
                  return null;
                },
                hintText: "New Pin",
              ),
              richTxt(text: "Switch Passkey"),
              CustomTextField(
                validator: (value) {
                  if (value!.isEmpty) {
                    return "PassKey Cannot be empty";
                  }
                  if (value.length <= 7) {
                    return "PassKey Cannot be less than 8 letters";
                  }
                  return null;
                },
                controller: _passKey,
                hintText: "New Passkey",
              ),
              SizedBox(height: height * 0.03),
              const Text(
                "Do you want to add a fan?",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text("Yes"),
                      textColor: Theme.of(context).appColors.textSecondary,
                      leading: Radio<String>(
                        value: "Yes",
                        groupValue: _addFan,
                        onChanged: (value) {
                          setState(() {
                            _addFan = value;
                            _updateAvailableSwitchTypes();
                            _fanNameController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      textColor: Theme.of(context).appColors.textSecondary,
                      title: const Text("No"),
                      leading: Radio<String>(
                        value: "No",
                        groupValue: _addFan,
                        onChanged: (value) {
                          setState(() {
                            _addFan = value;
                            _fanNameController.clear();
                            _updateAvailableSwitchTypes();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_addFan == "Yes") ...[
                SizedBox(height: height * 0.02),
                CustomTextField(
                  controller: _fanNameController,
                  validator: (value) {
                    if (_addFan == "Yes" && (value == null || value.isEmpty)) {
                      return "Fan name cannot be empty";
                    }
                    return null;
                  },
                  hintText: "Fan Name",
                ),
              ],
              richTxt(text: "Select Switches"),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      value: _selectedSwitchType,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSwitchType = newValue;
                        });
                      },
                      validator: (value) {
                        if ((_addFan == "No") && selectedSwitches.isEmpty) {
                          return "Please select a switches";
                        }
                        return null;
                      },
                      items: _availableSwitchTypes.map((switchType) {
                        return DropdownMenuItem<String>(
                          value: switchType,
                          child: Text(switchType),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintStyle: Theme.of(context).textTheme.bodyLarge,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        hintText: "Select Switches and Rename Them if Needed",
                        labelStyle: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () {
                      if (_selectedSwitchType != null) {
                        setState(() {
                          selectedSwitches.add({
                            'type': TextEditingController(
                                text: _selectedSwitchType),
                          });
                          _availableSwitchTypes.remove(_selectedSwitchType);
                          _selectedSwitchType = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              if (selectedSwitches.isNotEmpty) ...[
                Column(
                  children: selectedSwitches.map((switchMap) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: switchMap['type']!,
                              hintText: "Rename Switch",
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () {
                              setState(() {
                                _availableSwitchTypes
                                    .add(switchMap['type']!.text);
                                selectedSwitches.remove(switchMap);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).appColors.background,
        child: Center(
          child: loading
              ? Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                  child: Container(
                    width: 300,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.shade600,
                          Colors.purple.shade300,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 1,
                          color: Theme.of(context).appColors.textSecondary,
                          offset: const Offset(0, 2),
                        )
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: const AlignmentDirectional(0, 0),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).appColors.primary,
                    ),
                  ),
                )
              : CustomButton(
                  text: "Submit",
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        loading = true;
                      });
                      bool exists = await _storageController.isSwitchNameExists(
                          _ssid.text, _switchId.text);
                      if (exists) {
                        showDialog(
                          context: navigatorKey.currentContext!,
                          builder: (cont) {
                            return AlertDialog(
                              title: const Text('Update Switch'),
                              content: const Text(
                                  'SwitchId is already Exist, Do you want to update the existing switch'),
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
                                    List<String> renamedSwitches =
                                        selectedSwitches.map((switchMap) {
                                      return switchMap['type']!.text;
                                    }).toList();
                                    String? fanName = _addFan == "Yes"
                                        ? _fanNameController.text
                                        : null;
                                    SwitchDetails switchDetails = SwitchDetails(
                                      privatePin: _privatePin.text,
                                      switchId: _switchId.text,
                                      switchSSID: _ssid.text,
                                      switchPassKey: _passKey.text,
                                      switchPassword: _password.text,
                                      iPAddress: Constants.routerIP,
                                      switchTypes: renamedSwitches,
                                      selectedFan: fanName ?? "",
                                    );
                                    Navigator.pop(context);
                                    try {
                                      await ApiConnect.hitApiGet(
                                        "${Constants.routerIP}/",
                                      );
                                      await ApiConnect.hitApiPost(
                                          "${Constants.routerIP}/settings", {
                                        "Lock_id": _switchId.text,
                                        "lock_name": _ssid.text,
                                        "lock_pass": _password.text
                                      });
                                      await ApiConnect.hitApiGet(
                                        "${Constants.routerIP}/",
                                      );
                                      ApiConnect.hitApiPost(
                                          "${Constants.routerIP}/getSecretKey",
                                          {
                                            "Lock_id": _switchId.text,
                                            "lock_passkey": _passKey.text
                                          });
                                      _storageController.updateSwitchIfIdExist(
                                          _switchId.text,
                                          _ssid.text,
                                          switchDetails);
                                      Navigator.pushAndRemoveUntil<dynamic>(
                                        navigatorKey.currentContext!,
                                        MaterialPageRoute<dynamic>(
                                          builder: (BuildContext context) =>
                                              const TabsPage(),
                                        ),
                                        (route) => false,
                                      );
                                    } catch (e) {
                                      debugPrint("Error inside updating");
                                      debugPrint("$e");
                                      showToast(navigatorKey.currentContext!,
                                          "Error: ${e.toString()}");
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
                        List<String> renamedSwitches =
                            selectedSwitches.map((switchMap) {
                          return switchMap['type']!.text;
                        }).toList();
                        String? fanName =
                            _addFan == "Yes" ? _fanNameController.text : null;
                        SwitchDetails switchDetails = SwitchDetails(
                          privatePin: _privatePin.text,
                          switchId: _switchId.text,
                          switchSSID: _ssid.text,
                          switchPassKey: _passKey.text,
                          switchPassword: _password.text,
                          iPAddress: Constants.routerIP,
                          switchTypes: renamedSwitches,
                          switchType: _selectedAppliance?.code,
                          selectedFan: fanName ?? "",
                        );
                        try {
                          await ApiConnect.hitApiGet(
                            "${Constants.routerIP}/",
                          );
                          await ApiConnect.hitApiPost(
                              "${Constants.routerIP}/settings", {
                            "Lock_id": _switchId.text,
                            "lock_name": _ssid.text,
                            "lock_pass": _password.text
                          });
                          ApiConnect.hitApiGet(
                            "${Constants.routerIP}/",
                          );
                          ApiConnect.hitApiPost(
                              "${Constants.routerIP}/getSecretKey", {
                            "Lock_id": _switchId.text,
                            "lock_passkey": _passKey.text
                          });
                          _storageController.addSwitches(switchDetails);
                          Navigator.pushAndRemoveUntil<dynamic>(
                            navigatorKey.currentContext!,
                            MaterialPageRoute<dynamic>(
                              builder: (BuildContext context) =>
                                  const TabsPage(),
                            ),
                            (route) => false,
                          );
                        } catch (e, s) {
                          debugPrint("$e $s");
                          ApiConnect.hitApiGet(
                            "${Constants.routerIP}/",
                          );
                          ApiConnect.hitApiPost(
                              "${Constants.routerIP}/getSecretKey", {
                            "Lock_id": switchDetails.switchId,
                            "lock_passkey": _passKey.text
                          });
                          _storageController.addSwitches(switchDetails);
                          setState(() {
                            loading = false;
                          });
                          Navigator.pushAndRemoveUntil<dynamic>(
                            navigatorKey.currentContext!,
                            MaterialPageRoute<dynamic>(
                              builder: (BuildContext context) =>
                                  const TabsPage(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    }
                  }),
        ),
      ),
    );
  }

  void _showApplianceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.grey.shade500,
                automaticallyImplyLeading: false,
                title: Column(
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Text(
                      "Select Switch Type",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.separated(
                      separatorBuilder: (_, index) {
                        return const SizedBox(height: 10);
                      },
                      padding: const EdgeInsets.all(16),
                      itemCount: _appliances.length,
                      itemBuilder: (_, index) {
                        final appliance = _appliances[index];
                        return ListTile(
                          tileColor: Theme.of(context)
                              .appColors
                              .primary
                              .withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: _selectedAppliance?.id == appliance.id
                                  ? Theme.of(context).appColors.buttonBackground
                                  : Theme.of(context)
                                      .appColors
                                      .grey
                                      .withOpacity(0.5),
                            ),
                          ),
                          leading: Image.asset(
                            Constants().applianceIconAsset(appliance.code),
                            height: 50,
                            width: 50,
                            fit: BoxFit.contain,
                          ),
                          titleTextStyle:
                              Theme.of(context).textTheme.titleMedium,
                          subtitleTextStyle:
                              Theme.of(context).textTheme.titleSmall,
                          title: Text(appliance.name),
                          subtitle: Text(appliance.category),
                          trailing: _selectedAppliance?.id == appliance.id
                              ? const Icon(Icons.check_circle_rounded,
                                  color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedAppliance = appliance;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
