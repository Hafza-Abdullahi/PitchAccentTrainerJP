import 'package:flutter/material.dart';
import 'package:myapp/src/constants/colours.dart';

import '../constants/sizes.dart';

class RoundedContainer extends StatelessWidget{
  const RoundedContainer({  //constructor, initialize fields
    super.key,
    this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.showBorder = false,
    this.radius = tShopCardRadius,
    this.backgroundColor = tCardBgColourWhite,
    this.borderColor = tCardBorderColorLight

});

  // This can be null if no child/double etc is provided.
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  //cant be null
  final bool showBorder;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;


  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder ? Border.all(color: borderColor) : null,
      ), // BoxDecoration
      child: child,
    ); // Container
  }
}
