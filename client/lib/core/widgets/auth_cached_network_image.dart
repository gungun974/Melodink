import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/api/api.dart';

class AuthCachedNetworkImage extends StatelessWidget {
  final String imageUrl;

  final double? width;

  final double? height;

  final Widget Function(
    BuildContext context,
    String url,
  )? placeholder;

  final Widget Function(
    BuildContext context,
    String url,
    Object error,
  )? errorWidget;

  const AuthCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      httpHeaders: {
        'Cookie': AppApi().generateCookieHeader(),
      },
      height: height,
      width: width,
      imageUrl: imageUrl,
      errorWidget: errorWidget,
    );
  }
}
