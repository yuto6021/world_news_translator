class User {
  final int id;
  final String email;
  final String displayName;
  final String passwordHash; // 保存されたハッシュ
  final String salt; // ランダムソルト
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int,
        email: map['email'] as String,
        displayName: map['display_name'] as String,
        passwordHash: map['password_hash'] as String,
        salt: map['salt'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
