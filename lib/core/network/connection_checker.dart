import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract interface class InternetConnectionChecker {
  Future<bool> get isConnected;
}

class InternetConnectionCheckerImpl implements InternetConnectionChecker {
  final InternetConnection internetConnection;

  InternetConnectionCheckerImpl({required this.internetConnection});

  @override
  Future<bool> get isConnected async =>
      await internetConnection.hasInternetAccess;
}
