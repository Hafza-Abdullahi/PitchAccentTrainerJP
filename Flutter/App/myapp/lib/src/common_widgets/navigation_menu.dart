import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:myapp/src/features/authentication/screens/account/account_screen.dart';
import 'package:myapp/src/features/authentication/screens/home/home_screen.dart';
import 'package:myapp/src/features/authentication/screens/settings/panel.dart';

import '../constants/global_variables.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController()); // Create instance of nav controller

    return Scaffold(
      bottomNavigationBar: Obx(
            () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value, // Current selected index
          onDestinationSelected: (index) => controller.selectedIndex.value = index, // Update index on tap
          destinations: controller.destinations, // Use dynamic destinations from controller
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]), // Show current screen
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  // Simple ternary approach
  List<Widget> get screens => myGlobal_AccountType == "School User"
      ? [HomeScreen(), PanelScreen(), AccountScreen()]
      : [HomeScreen(), AccountScreen()];

  List<NavigationDestination> get destinations => myGlobal_AccountType == "School User"
      ? const [
    NavigationDestination(icon: Icon(Iconsax.home), label: "Home"),
    NavigationDestination(icon: Icon(Iconsax.setting_2), label: "Settings"),
    NavigationDestination(icon: Icon(Iconsax.profile_circle), label: "Account"),
  ]
      : const [
    NavigationDestination(icon: Icon(Iconsax.home), label: "Home"),
    NavigationDestination(icon: Icon(Iconsax.profile_circle), label: "Account"),
  ];

  // Optional: Add index validation to prevent errors
  @override
  void onInit() {
    super.onInit();
    ever(selectedIndex, (_) {
      // Ensure selected index doesn't exceed available screens
      if (selectedIndex.value >= screens.length) {
        selectedIndex.value = screens.length - 1; // Set to last valid index
      }
    });
  }
}