import 'package:melodink_client/generated/pb/track.pbgrpc.dart' as pb;

const appHost = "192.168.1.87";
const appPort = 8000;
const appUrl = "http://$appHost:$appPort";

const audioQuality = pb.AudioStreamQuality.MAX;
const audioFormat = pb.AudioStreamFormat.HLS;
