import 'package:flutter/material.dart';
import 'package:myapp/src/constants/colours.dart';

import '../constants/sizes.dart';

class RoundedImage extends StatelessWidget {
  const RoundedImage({ //constructor, initialize fields
    super.key,
    required this.imageUrl, //mandatory field
    this.width = 150,
    this.height = 160,
    this.border,
    this.onPressed,
    this.padding,
    this.applyImageRadius = false,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.isNetworkImage = false, this.margin, required this.borderColor, required this.borderRadius, //for img that are urls, required

  });

  // This can be null if no child/double etc is provided.

  final double? width;
  final double? height;
  final BoxBorder? border;
  final BoxFit? fit;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? borderColor;

  //cant be null
  final String imageUrl;
  final bool applyImageRadius;
  final bool isNetworkImage;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(   //widget to detect gestures
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          border: border,
          color: backgroundColor ?? tTransparent, //default value is transparent
          borderRadius: BorderRadius.circular(borderRadius)
        ),
        child: ClipRRect(   //widget to clip img to a rounded shape
          borderRadius: applyImageRadius ? BorderRadius.circular(borderRadius) : BorderRadius.zero,

          //if image is from network, loads from url, otherwise from asset
          child: Image(fit: fit, image: isNetworkImage ? NetworkImage(imageUrl) : AssetImage(imageUrl) as ImageProvider),
        ),
      ),
    );
  }
}