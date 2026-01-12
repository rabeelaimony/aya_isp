class FinancialItem {
  final String username;
  final String typecard;
  final String burnType;
  final String bd; // beginning date as string
  final String paidMount;
  final String lastBalance;
  final String? newTraffic;
  final String bex;
  final String nex;

  FinancialItem({
    required this.username,
    required this.typecard,
    required this.burnType,
    required this.bd,
    required this.paidMount,
    required this.lastBalance,
    this.newTraffic,
    required this.bex,
    required this.nex,
  });

  factory FinancialItem.fromJson(Map<String, dynamic> json) {
    return FinancialItem(
      username: json['username']?.toString() ?? '',
      typecard: json['typecard']?.toString() ?? '',
      burnType: json['BurnType']?.toString() ?? json['burnType']?.toString() ?? '',
      bd: json['bd']?.toString() ?? '',
      paidMount: json['paid_mount']?.toString() ?? json['paid_amount']?.toString() ?? '',
      lastBalance: json['lastbalance']?.toString() ?? '',
      newTraffic: json['new_traffic']?.toString(),
      bex: json['bex']?.toString() ?? '',
      nex: json['nex']?.toString() ?? '',
    );
  }
}
