class SwitchDetails {
  late String switchId;
  late String switchSSID;
  late String switchPassword;

  late String? selectedFan;
  late String iPAddress;
  String? switchPassKey;
  late List<String> switchTypes;
  late String privatePin;

  SwitchDetails({
    required this.switchId,
    this.switchPassKey,
    required this.switchSSID,
    required this.switchTypes,
    required this.privatePin,
    required this.switchPassword,
    required this.selectedFan,
    required this.iPAddress,
  });

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
    return data;
  }

  String toSwitchQR() {
    return "SWITCH,$switchId,$switchSSID,$switchPassKey,$switchPassword,$selectedFan,$switchTypes";
  }
}
