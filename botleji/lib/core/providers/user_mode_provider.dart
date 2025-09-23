import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserMode {
  collector,
  household
}

final userModeProvider = StateProvider<UserMode>((ref) => UserMode.household); 