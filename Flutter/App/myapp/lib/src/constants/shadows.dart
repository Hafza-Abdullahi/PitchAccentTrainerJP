import 'package:flutter/material.dart';

import 'colours.dart';

class TshadowStyle {

  //shopcardview shadow properties
  static final shopCardViewShadow = BoxShadow(
    color: tShadowColor.withValues(alpha: 0.05),   //shadow color, barely transparent
    blurRadius: 25,
    spreadRadius: 0,  //shadow radius
    offset: const Offset(0, 1)
  );
}