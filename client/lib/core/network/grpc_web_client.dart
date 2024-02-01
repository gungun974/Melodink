import 'package:grpc/grpc_connection_interface.dart';
import 'package:grpc/grpc_web.dart';
import 'package:melodink_client/config.dart';

ClientChannelBase createGrpcClient() {
  return GrpcWebClientChannel.xhr(Uri.parse(appUrl));
}
