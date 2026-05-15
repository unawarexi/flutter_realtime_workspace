class ReferralModel {
  final String inviteCode;
  final DateTime? inviteCodeExpiry;

  const ReferralModel({
    required this.inviteCode,
    this.inviteCodeExpiry,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
        inviteCode: json['inviteCode'] as String,
        inviteCodeExpiry: json['inviteCodeExpiry'] != null
            ? DateTime.tryParse(json['inviteCodeExpiry'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'inviteCode': inviteCode,
        if (inviteCodeExpiry != null)
          'inviteCodeExpiry': inviteCodeExpiry!.toIso8601String(),
      };
}
