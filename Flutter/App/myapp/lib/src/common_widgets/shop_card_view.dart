import 'package:flutter/material.dart';
import 'package:myapp/src/common_widgets/RoundedImage.dart';
import 'package:myapp/src/common_widgets/rounded_container.dart';
import 'package:myapp/src/constants/colours.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/image_strings.dart';
import '../constants/shadows.dart';
import '../constants/sizes.dart';
import '../constants/text_strings.dart';

class ShopCardView extends StatelessWidget {
  final String shopUrl; //url for link
  final String imageUrl; //url for link
  final String productName;
  //url for link
  const ShopCardView(
      {super.key,
      required this.shopUrl,
      required this.imageUrl, required this.productName}); //required url

  //func to open url
  void _openShop() async {
    final Uri url = Uri.parse(shopUrl); // shop url parsed
    print('Attempting to launch: $url'); //debug line

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    //main container with shadow
    return GestureDetector(
      onTap: _openShop, //opens link when tapped
      child: Container(
          width: 200,
          height: 150,
          padding: const EdgeInsets.all(1),
          //padding of 1

          decoration: BoxDecoration(
            //boxdec class is useful for shadows and roundedness
            boxShadow: [TshadowStyle.shopCardViewShadow],
            borderRadius: BorderRadius.circular(tShopCardRadius), //round edge
          ),
          child: Column(
            children: [
              RoundedContainer(
                  height: 100,
                  padding: const EdgeInsets.all(tPaddingSmall),
                  backgroundColor: tBackgroundColor,

                  /*--------- stack for img and buttons ----------*/
                  child: Stack(
                    children: [
                      RoundedImage(
                        imageUrl: imageUrl,
                        borderRadius: tShopCardRadius,
                        borderColor: null,
                      )
                    ],
                  )),
              //text for img
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  children: [
                  Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16.0),
                ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}
