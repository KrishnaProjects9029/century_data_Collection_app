import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/connectivity_manager.dart';

final connectivityManagerProvider =
    Provider<ConnectivityManager>((ref) {
  final manager = ConnectivityManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityManagerProvider).onConnectivityChanged;
});
