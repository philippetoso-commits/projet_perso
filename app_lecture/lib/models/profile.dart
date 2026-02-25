import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 1)
class Profile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int avatarId;

  @HiveField(2)
  DateTime createdAt;

  Profile({
    required this.name,
    this.avatarId = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get keyAsId => key as int;
}
