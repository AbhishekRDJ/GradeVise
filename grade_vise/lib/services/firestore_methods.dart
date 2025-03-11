import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grade_vise/utils/show_error.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createUser(
    BuildContext context,
    String uid,
    String fname,
    String email,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        "uid": uid,
        'name': fname,
        'email': email,
        "photoURL": "",
        'createdAt': DateTime.now(),
        'role': "",
      });
    } catch (e) {
      if (context.mounted) {
        showSnakbar(context, e.toString());
      }
    }
  }

  Future<void> createClassroom(
    String name,
    String section,
    String subject,
    String room,
  ) async {
    try {
      String classroomId = Uuid().v1();

      await FirebaseFirestore.instance.collection('classrooms').doc().set({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'name': name,
        'section': section,
        'subject': subject,
        'room': room,
        'classroomId': classroomId,
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
