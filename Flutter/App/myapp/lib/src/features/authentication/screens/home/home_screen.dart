import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/src/common_widgets/shop_card_view.dart';
import 'package:myapp/src/constants/sizes.dart';
import 'package:myapp/src/features/authentication/screens/home/shop_list.dart';
import '../../../../common_widgets/fetchProfile.dart';
import '../../../../common_widgets/fetchProfile.dart' as fetchProfile show fetchProfileDetails;


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String replaceAmazonTag(String originalUrl, String newTag) {
    return originalUrl.replaceAll(
        RegExp(r'tag=[a-zA-Z0-9-]+'),
        'tag=$newTag'
    );
  }

  Future<String> getUserSchoolName() async {
    try {
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        print("❌ No user email found - user might not be logged in");
        return "Default School";
      }

      print("🔍 Looking for user with email: $userEmail");

      Map<String, String> profile = await fetchProfile.fetchProfileDetails(userEmail);

      if (profile['UserSchoolName'] == null || profile['UserSchoolName']!.isEmpty) {
        print("❌ UserSchoolName is null or empty in profile data");
        print("📋 Full profile data: $profile");
      } else {
        print("✅ Found school name: ${profile['UserSchoolName']}");
      }

      return profile['UserSchoolName'] ?? "Default School";
    } catch (e) {
      print("❌ Error getting user school name: $e");
      return "Default School";
    }
  }

  Future<String> getSchoolTag(String schoolName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('TrackingLinks')
          .where('SchoolNameLink', isEqualTo: schoolName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['AmazonTrackingID'] as String;
      }
      return "tap2shop04-20";
    } catch (e) {
      print("Error getting school tag: $e");
      return "tap2shop04-20";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<String>(
          future: getUserSchoolName(),
          builder: (context, schoolNameSnapshot) {
            if (schoolNameSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (schoolNameSnapshot.hasError) {
              return Center(child: Text('Error: ${schoolNameSnapshot.error}'));
            }

            final String schoolName = schoolNameSnapshot.data ?? "Default School";

            return FutureBuilder<String>(
              future: getSchoolTag(schoolName),
              builder: (context, tagSnapshot) {
                if (tagSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tagSnapshot.hasError) {
                  return Center(child: Text('Error: ${tagSnapshot.error}'));
                }

                final String schoolTag = tagSnapshot.data ?? "tap2shop04-20";

                return SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(tDefaultSize),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // School Info Container with rounded edges
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue[100]!,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue[100]!,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "🎓 Supporting",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                schoolName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green[200]!,
                                  ),
                                ),
                                child: Text(
                                  "ID: $schoolTag",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[800],
                                    fontFamily: 'Monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Shop items with better styling
                        GridView.builder(
                          itemCount: shops.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: 180, // Slightly smaller for better fit
                          ),
                          itemBuilder: (_, index) {
                            String originalUrl = shops[index]["shopUrl"]!;
                            String personalizedUrl = replaceAmazonTag(originalUrl, schoolTag);

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[300]!,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ShopCardView(
                                  imageUrl: shops[index]["imageUrl"]!,
                                  shopUrl: personalizedUrl,
                                    productName: shops[index]["productName"]!,
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}