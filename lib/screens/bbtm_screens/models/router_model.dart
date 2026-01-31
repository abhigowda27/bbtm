class RouterDetails {
  late String switchID;
  late String switchName;
  late String routerName;
  late String routerPassword;
  late String? selectedFan;
  late String? switchType;
  late List<String> switchTypes;
  late String? iPAddress;
  late String? deviceMacId;
  late String switchPasskey;

  RouterDetails(
      {required this.switchID,
      required this.routerName,
      required this.routerPassword,
      required this.iPAddress,
      this.deviceMacId,
      required this.selectedFan,
      required this.switchTypes,
      required this.switchPasskey,
      required this.switchName,
      this.switchType});

  RouterDetails.fromJson(Map<String, dynamic> json) {
    switchID = json['SwitchId'];
    switchName = json['SwitchName'];
    routerName = json['RouterName'];
    routerPassword = json['RouterPassword'];
    selectedFan = json['SelectedFan'];
    switchTypes = List<String>.from(json['SwitchTypes'] ?? []);
    switchPasskey = json['SwitchPassKey'];
    iPAddress = json['IPAddress'];
    deviceMacId = json["macId"];
    switchType = json['switchType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['SwitchId'] = switchID;
    data['SwitchName'] = switchName;
    data['RouterName'] = routerName;
    data['RouterPassword'] = routerPassword;
    data['SwitchTypes'] = switchTypes;
    data['SelectedFan'] = selectedFan;
    data['SwitchPassKey'] = switchPasskey;
    data['IPAddress'] = iPAddress;
    data['macId'] = deviceMacId;
    data['switchType'] = switchType;
    return data;
  }
}
