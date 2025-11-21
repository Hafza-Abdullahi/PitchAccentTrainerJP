import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, String>> fetchProfileDetails(String email) async {
print("🔍 Searching for: $email");

// Search in BOTH collections automatically
final normalUsersQuery = await FirebaseFirestore.instance
    .collection('NormalUsers')
    .where('UserEmail', isEqualTo: email)
    .limit(1)
    .get();

if (normalUsersQuery.docs.isNotEmpty) {
final userDoc = normalUsersQuery.docs.first;
print("✅ Found in NormalUsers");
return {
'UserFullName': userDoc['UserFullName'] ?? '',
'UserSchoolName': userDoc['UserSchoolName'] ?? '',
'UserEmail': userDoc['UserEmail'] ?? '',
};
}

final schoolUsersQuery = await FirebaseFirestore.instance
    .collection('SchoolUsers')
    .where('schoolEmail', isEqualTo: email)
    .limit(1)
    .get();

if (schoolUsersQuery.docs.isNotEmpty) {
final userDoc = schoolUsersQuery.docs.first;
print("✅ Found in SchoolUsers");
return {
'UserFullName': userDoc['schoolFullName'] ?? '',
'UserSchoolName': userDoc['schoolFullName'] ?? '', // School users ARE the school
'UserEmail': userDoc['schoolEmail'] ?? '',
};
}

print("❌ Not found in any collection");
throw Exception("User not found");
}