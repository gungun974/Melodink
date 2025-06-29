import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';

import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/file_system.dart';

class ImageCacheManager {
  late CacheManager _cacheManager;

  Future<void> initCacheManager() async {
    final path = (await getMelodinkInstanceSupportDirectory()).path;
    _cacheManager = CacheManager(Config(
      'melodinkImageCache',
      stalePeriod: const Duration(hours: 1),
      maxNrOfCacheObjects: 10000,
      fileSystem: NewFileSystem('melodinkImageCache'),
      repo: JsonCacheInfoRepository(path: '$path/melodinkImageCache.json'),
    ));
  }

  ImageCacheManager._internal();

  factory ImageCacheManager() {
    return _instance;
  }

  static final ImageCacheManager _instance = ImageCacheManager._internal();

  CacheManager get cacheManager => _cacheManager;

  static Future<void> initCache() {
    return ImageCacheManager().initCacheManager();
  }

  static Future<File> getImage(Uri uri) {
    return ImageCacheManager()
        .cacheManager
        .getSingleFile(uri.toString(), headers: {
      "Cookie": AppApi().generateCookieHeader(),
    });
  }

  static Future<void> preCache(Uri uri, BuildContext context) async {
    precacheImage(
      FileImage(await getImage(uri)),
      context,
    );
  }

  static Future<void> clearCache(Uri uri) {
    return ImageCacheManager().cacheManager.removeFile(uri.toString());
  }
}

class AuthCachedNetworkImage extends ConsumerStatefulWidget {
  final String imageUrl;

  final double? width;

  final double? height;

  final BoxFit? fit;

  final AlignmentGeometry? alignment;

  final bool gaplessPlayback;

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
    this.fit,
    this.alignment,
    this.placeholder,
    this.errorWidget,
    this.gaplessPlayback = false,
  });

  @override
  ConsumerState<AuthCachedNetworkImage> createState() =>
      _AuthCachedNetworkImageState();
}

class _AuthCachedNetworkImageState
    extends ConsumerState<AuthCachedNetworkImage> {
  final GlobalKey imageKey = GlobalKey();

  Future<File>? networkImageFuture;

  FileImage? previousNetworkImage;

  @override
  void initState() {
    super.initState();
    Uri? uri = Uri.tryParse(widget.imageUrl);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (!NetworkInfo().isServerRecheable()) {
        return;
      }

      networkImageFuture = ImageCacheManager.getImage(uri);
    }
  }

  @override
  void didUpdateWidget(covariant AuthCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    Uri? uri = Uri.tryParse(widget.imageUrl);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (!NetworkInfo().isServerRecheable()) {
        return;
      }

      if (oldWidget.imageUrl != widget.imageUrl) {
        networkImageFuture = ImageCacheManager.getImage(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Uri? uri = Uri.tryParse(widget.imageUrl);

    final isServerReachable = ref.read(isServerReachableProvider);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (!isServerReachable) {
        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: widget.errorWidget?.call(context, uri.toString(), Error()),
        );
      }

      final localErrorWidget = widget.errorWidget;

      return FutureBuilder(
          future: networkImageFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              previousNetworkImage = FileImage(snapshot.data!);
            } else {
              if (!widget.gaplessPlayback) {
                previousNetworkImage = null;
              }
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: widget.height,
                width: widget.width,
                child:
                    widget.errorWidget?.call(context, uri.toString(), Error()),
              );
            }

            if (previousNetworkImage != null) {
              return Image(
                key: imageKey,
                image: previousNetworkImage!,
                height: widget.height,
                width: widget.width,
                fit: widget.fit ?? BoxFit.fitHeight,
                alignment: widget.alignment ?? Alignment.bottomCenter,
                errorBuilder: localErrorWidget != null
                    ? (BuildContext context, Object error,
                        StackTrace? stackTrace) {
                        return SizedBox(
                          height: widget.height,
                          width: widget.width,
                          child:
                              localErrorWidget(context, uri.toString(), error),
                        );
                      }
                    : null,
                gaplessPlayback: widget.gaplessPlayback,
                filterQuality: FilterQuality.high,
              );
            }

            return Container(
              height: widget.height,
              width: widget.width,
              color: Colors.transparent,
            );
          });
    }

    final localErrorWidget = widget.errorWidget;

    previousNetworkImage = FileImage(File(widget.imageUrl));

    return Image(
      key: imageKey,
      image: previousNetworkImage!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit ?? BoxFit.fitHeight,
      alignment: widget.alignment ?? Alignment.bottomCenter,
      errorBuilder: localErrorWidget != null
          ? (BuildContext context, Object error, StackTrace? stackTrace) {
              return SizedBox(
                height: widget.height,
                width: widget.width,
                child: localErrorWidget(context, uri.toString(), error),
              );
            }
          : null,
      gaplessPlayback: widget.gaplessPlayback,
      filterQuality: FilterQuality.high,
    );
  }
}
