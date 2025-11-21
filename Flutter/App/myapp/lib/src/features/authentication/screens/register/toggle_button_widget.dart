import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/src/constants/sizes.dart';
import 'package:myapp/src/features/authentication/screens/register/register_form_user_widget.dart';
import 'package:myapp/src/features/authentication/screens/register/register_form_school_widget.dart';

import '../../../../constants/text_strings.dart';

class ToggleButtonWidget extends StatefulWidget {
  final double deviceHeight; //not to be changed
  const ToggleButtonWidget({
    super.key,
    //takes in only device height
    required this.deviceHeight,
  });

  //override and manage state
  @override
  State<ToggleButtonWidget> createState() => _ToggleButtonWidgetState();
}

class _ToggleButtonWidgetState extends State<ToggleButtonWidget> {
  List<bool> isSelected = [true, false]; // default is a Customer

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleButtons(
          isSelected: isSelected,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < isSelected.length; i++) {
                isSelected[i] = i == index;
              }
            });
          },

          //styling
          renderBorder: true,
          borderWidth: 2,
          borderColor: Colors.black12,
          selectedBorderColor: Colors.black12,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(6),

          selectedColor: Colors.white, // Text color when selected
          fillColor: Colors.blue,       // Background when selected
          color: Colors.teal,           // Text color when not selected

          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("I am a customer"),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("I am a school"),
            ),
          ],
        ),

        const SizedBox(
          height: tFormHeight,
        ), //padding

        isSelected[0]
            ? const RegisterFormUser()
            : const RegisterFormSchool(),
      ],
    );


  }
}
