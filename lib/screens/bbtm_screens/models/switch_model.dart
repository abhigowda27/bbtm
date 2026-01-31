class SwitchDetails {
  late String switchId;
  late String switchSSID;
  late String switchPassword;
  late String? selectedFan;
  late String? switchType;
  late String iPAddress;
  String? switchPassKey;
  late List<String> switchTypes;
  late String privatePin;
  bool? isAutoLock;

  SwitchDetails(
      {required this.switchId,
      this.switchPassKey,
      this.isAutoLock = false,
      required this.switchSSID,
      required this.switchTypes,
      required this.privatePin,
      required this.switchPassword,
      required this.selectedFan,
      required this.iPAddress,
      this.switchType});

  factory SwitchDetails.fromJson(Map<String, dynamic> json) {
    return SwitchDetails(
      switchId: json['SwitchId'] ?? '',
      switchSSID: json['SwitchSSID'] ?? '',
      switchTypes: List<String>.from(json['SwitchTypes'] ?? []),
      privatePin: json['privatePin'] ?? '',
      selectedFan: json['SelectedFan'],
      switchPassword: json['SwitchPassword'] ?? '',
      iPAddress: json['IPAddress'] ?? '',
      switchPassKey: json['SwitchPasskey'],
      switchType: json['switchType'],
      isAutoLock: json["isAutoLock"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['SwitchId'] = switchId;
    data['SwitchSSID'] = switchSSID;
    data['SwitchTypes'] = switchTypes;
    data['SelectedFan'] = selectedFan;
    data['privatePin'] = privatePin;
    data['SwitchPassword'] = switchPassword;
    data['IPAddress'] = iPAddress;
    data['SwitchPasskey'] = switchPassKey;
    data['isAutoLock'] = isAutoLock;
    data['switchType'] = switchType;
    return data;
  }
}
