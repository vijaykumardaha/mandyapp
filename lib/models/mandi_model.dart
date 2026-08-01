class Mandi {
  final int mandiId;
  final String mandiName;

  const Mandi({required this.mandiId, required this.mandiName});

  Mandi.fromJson(Map<String, dynamic> json)
      : mandiId = json['mandi_id'] as int,
        mandiName = json['mandi_name'] as String? ?? '';

  Map<String, dynamic> toJson() => {
        'mandi_id': mandiId,
        'mandi_name': mandiName,
      };
}
