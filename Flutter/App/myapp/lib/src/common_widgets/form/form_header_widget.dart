import 'package:flutter/cupertino.dart';
import 'package:myapp/src/constants/sizes.dart';

class FormHeaderWidget extends StatelessWidget {
  const FormHeaderWidget({
    super.key,
    //takes in 4 arguments so this header can be used across multiple forms
    required this.deviceHeight,
    required this.image,
    required this.title,
    required this.subTitle,
  });

  final double deviceHeight; //not to be changed
  final String image, title, subTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, //align to start
      children: [
        Image(
          image: AssetImage(image), //shopping img
          height: deviceHeight * 0.18, //img covers 0.15 of the screen
        ),
        Text(
          title,
          style: TextStyle(fontSize: tHeading1, fontWeight: FontWeight.bold),
        ), // Title size),  //title to be filled
        Text(
          subTitle,
          style: TextStyle(fontSize: tHeading2),
        ), // Title size)    //subtitle also to be filled
      ],
    );
  }
}
