class UserAlbum {
  final List businessPhones;
  final String displayName;
  final String givenName;
  final String jobTitle;
  final String mail;
  final String mobilePhone;
  final String officeLocation;
  final String preferredLanguage;
  final String surname;
  final String userPrincipalName;
  final String id;

  const UserAlbum({
    required this.businessPhones,
    required this.displayName,
    required this.givenName,
    required this.jobTitle,
    required this.mail,
    required this.mobilePhone,
    required this.officeLocation,
    required this.preferredLanguage,
    required this.surname,
    required this.userPrincipalName,
    required this.id,
  });

  factory UserAlbum.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'businessPhones:': List businessPhones,
        'displayName': String displayName,
        'givenName': String givenName,
        'jobTitle': String jobTitle,
        'mail': String mail,
        'mobilePhone': String mobilePhone,
        'officeLocation': String officeLocation,
        'preferredLanguage': String preferredLanguage,
        'surname': String surname,
        'userPrincipalName': String userPrincipalName,
        'id': String id,
      } =>
        UserAlbum(
          businessPhones: businessPhones,
          displayName: displayName,
          givenName: givenName,
          jobTitle: jobTitle,
          mail: mail,
          mobilePhone: mobilePhone,
          officeLocation: officeLocation,
          preferredLanguage: preferredLanguage,
          surname: surname,
          userPrincipalName: userPrincipalName,
          id: id,
        ),
      _ => throw const FormatException('Failed to load user album'),
    };
  }
}
