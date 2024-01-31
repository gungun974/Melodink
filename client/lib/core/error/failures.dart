import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  @override
  List<Object> get props => [];
}

// Failures message

const String SERVER_FAILURE_MESSAGE = 'server_failure_message';
const String NO_INTERNET_FAILURE_MESSAGE = 'no_internet_failure_message';

// General failures
class ServerFailure extends Failure {}

class NoInternetFailure extends Failure {}
