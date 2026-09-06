import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Cache em memória para os bytes de imagens Base64 já decodificadas.
/// Evita que `base64Decode` seja executado continuamente na UI thread
/// a cada rebuild de itens em listas ou durante a rolagem.
final Map<String, Uint8List> _base64BytesCache = {};

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? cacheWidth;
  final int? cacheHeight;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth = 500,
    this.cacheHeight = 500,
  });

  Uint8List? _getOrDecodeBase64(String raw) {
    if (_base64BytesCache.containsKey(raw)) {
      return _base64BytesCache[raw];
    }
    try {
      final cleanBase64 = raw.contains(',') ? raw.split(',').last : raw;
      final bytes = base64Decode(cleanBase64.trim());
      // Limitar o cache para não consumir memória desmedida
      if (_base64BytesCache.length > 100) {
        _base64BytesCache.remove(_base64BytesCache.keys.first);
      }
      _base64BytesCache[raw] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('Erro ao decodificar Base64: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    if (imageUrl.isEmpty) {
      imageContent = _buildPlaceholder();
    } else if (imageUrl.startsWith('data:') || (imageUrl.length > 500 && !imageUrl.startsWith('http'))) {
      // Trata imagem Base64
      final bytes = _getOrDecodeBase64(imageUrl);
      if (bytes != null) {
        imageContent = Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } else {
        imageContent = _buildErrorWidget();
      }
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Trata imagem de rede com cache de renderização
      imageContent = Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (imageUrl.startsWith('assets/')) {
      imageContent = Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageContent = _buildPlaceholder();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: Colors.brown.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(
          Icons.cake_outlined,
          color: Colors.brown,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
