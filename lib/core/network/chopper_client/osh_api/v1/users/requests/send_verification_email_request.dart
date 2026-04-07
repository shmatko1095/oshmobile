final class SendVerificationEmailRequest {
  const SendVerificationEmailRequest({
    required this.email,
  });

  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
      };
}
