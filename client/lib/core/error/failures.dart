import 'package:rust_core/result.dart' as base;
import 'package:thiserror/thiserror.dart';

export 'package:rust_core/result.dart' hide Result;
export 'package:rust_core/panic.dart';
export 'package:rust_core/typedefs.dart';

sealed class Error extends ThisError<Error> {
  const Error([super.stringifiable]);
}

// General failures
class UnknowFailure extends Error {
  UnknowFailure() : super(() => "An unknown error occurred.");
}

class ServerFailure extends Error {
  ServerFailure() : super(() => "The server respond with an unknown error.");
}

class NoInternetFailure extends Error {
  NoInternetFailure() : super(() => "Failed to reach the Internet.");
}

// Playlist
class PlaylistNotFoundFailure extends Error {
  PlaylistNotFoundFailure() : super(() => "Failded to find Playlist.");
}

typedef Result<S> = base.Result<S, Error>;
