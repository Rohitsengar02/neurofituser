import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Network or asset photo with a soft gradient while loading or offline.
class NetImg extends StatelessWidget {
  final String src;
  final BoxFit fit;
  final double? width, height;
  final Alignment alignment;
  final Uint8List? bytes;
  final int? cacheWidth;
  const NetImg(this.src,
      {super.key, this.fit = BoxFit.cover, this.width, this.height, this.alignment = Alignment.center, this.bytes, this.cacheWidth});

  Widget _ph() => Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9E5FF), Color(0xFFDCEBFF), Color(0xFFFFE6D6)],
          ),
        ),
        child: const Center(child: Icon(Icons.image_outlined, color: Colors.black26)),
      );

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Image.memory(bytes!, fit: fit, width: width, height: height, alignment: alignment, gaplessPlayback: true);
    }
    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => _ph(),
        frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : _ph(),
      );
    }
    return Image.asset(src, fit: fit, width: width, height: height, alignment: alignment, cacheWidth: cacheWidth, errorBuilder: (_, _, _) => _ph());
  }
}
