class SavedPaymentMethod {
  final String method;
  final String detail;
  final DateTime createdAt;

  const SavedPaymentMethod({
    required this.method,
    required this.detail,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'detail': detail,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      method: (json['method'] ?? '').toString(),
      detail: (json['detail'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPaymentMethod &&
          runtimeType == other.runtimeType &&
          method == other.method &&
          detail == other.detail;

  @override
  int get hashCode => method.hashCode ^ detail.hashCode;
}
