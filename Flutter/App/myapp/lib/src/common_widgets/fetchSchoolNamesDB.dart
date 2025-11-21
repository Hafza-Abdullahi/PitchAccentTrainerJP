import 'package:cloud_firestore/cloud_firestore.dart';

class FetchSchoolNamesDB {
  static Future<List<String>> fetchSchoolNames() async {
    final snapshot = await FirebaseFirestore.instance.collection('RegisteredSchoolNames').get(); //fetch school names
    //save and return as doc
    return snapshot.docs.map((doc) => doc['SchoolName'] as String).toList();
  }
}
