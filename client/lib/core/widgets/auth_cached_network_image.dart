import 'dart:io';

import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';

import 'dart:async';
import 'dart:ui' as ui;

import 'package:melodink_client/core/helpers/split_hash_to_path.dart';

String createUrlHash(String url) {
  final bytes = utf8.encode(url);

  final digest = md5.convert(bytes);

  return digest.toString();
}

@immutable
class AppImageCacheProvider extends ImageProvider<AppImageCacheProvider> {
  AppImageCacheProvider(this.url, {this.scale = 1.0})
      : dio = AppApi().dio,
        cacheId = splitHashToPath(createUrlHash(url.toString()));

  final Uri url;

  final String cacheId;

  final double scale;

  final Dio dio;

  @override
  Future<AppImageCacheProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AppImageCacheProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      AppImageCacheProvider key, ImageDecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url.toString(),
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AppImageCacheProvider>('Image key', key),
      ],
    );
  }

  static clearCache(Uri url) async {
    final cacheId = splitHashToPath(createUrlHash(url.toString()));

    final cacheLocation = File(
      "${(await getMelodinkInstanceCacheDirectory()).path}/imacheCache/$cacheId",
    );

    if (await cacheLocation.exists()) {
      await cacheLocation.delete();
    }

    await AppImageCacheProvider(url).evict();
  }

  Future<ui.Codec> _loadAsync(
    AppImageCacheProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    try {
      assert(key == this);

      final cacheLocation = File(
        "${(await getMelodinkInstanceCacheDirectory()).path}/imacheCache/$cacheId",
      );

      if (await cacheLocation.exists()) {
        final time = await cacheLocation.lastModified();

        final currentTime = DateTime.now();

        final difference = currentTime.difference(time);

        if (difference.inHours <= 1) {
          try {
            final buffer = await ui.ImmutableBuffer.fromUint8List(
                await cacheLocation.readAsBytes());

            return await decode(buffer);
          } catch (_) {
            await cacheLocation.delete();
          }
        }
      }

      final response = await dio.getUri<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(
            seconds: 10,
          ),
        ),
        onReceiveProgress: (count, total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: count,
            expectedTotalBytes: total > 0 ? total : null,
          ));
        },
      );

      if (response.statusCode != 200) {
        throw NetworkImageLoadException(
          uri: url,
          statusCode: response.statusCode!,
        );
      }

      final bytes = Uint8List.fromList(response.data as List<int>);

      if (bytes.lengthInBytes == 0) {
        throw NetworkImageLoadException(
          uri: url,
          statusCode: response.statusCode!,
        );
      }

      await cacheLocation.create(recursive: true);

      RandomAccessFile raf = await cacheLocation.open(mode: FileMode.write);

      await raf.writeFrom(bytes);

      await raf.close();

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      unawaited(chunkEvents.close());
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AppImageCacheProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AppImageCacheProvider')}("$url", scale: $scale)';
}

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
    Uri? uri = Uri.tryParse(imageUrl);

    ImageProvider imageProvider;

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      imageProvider = AppImageCacheProvider(uri);
    } else {
      imageProvider = FileImage(File(imageUrl));
    }

    final localErrorWidget = errorWidget;

    return Image(
      image: imageProvider,
      height: height,
      width: width,
      fit: BoxFit.fitHeight,
      errorBuilder: localErrorWidget != null
          ? (BuildContext context, Object error, StackTrace? stackTrace) {
              return SizedBox(
                height: height,
                width: width,
                child: localErrorWidget(context, uri.toString(), error),
              );
            }
          : null,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
    );
  }
}
