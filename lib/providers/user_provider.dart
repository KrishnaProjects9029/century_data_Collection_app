import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userServiceProvider).allUsersStream();
});
