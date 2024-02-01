import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:melodink_client/config.dart';

ClientChannelBase createGrpcClient() {
  return ClientChannel(
    appHost,
    port: appPort,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
    ),
  );
}
