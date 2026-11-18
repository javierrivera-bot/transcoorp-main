class CambiarPasswordRequest {
  final String nuevaPassword;
  final String confirmacionPassword;

const CambiarPasswordRequest({
      required this.nuevaPassword,
      required this.confirmacionPassword,
    });

  Map<String, dynamic> toJson() => {
        'nuevaPassword': nuevaPassword,
        'confirmacionPassword': confirmacionPassword,
      };
}