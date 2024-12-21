import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _teacherData;
  Map<String, dynamic>? _adminData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      final userEmail = _user!.email;

      try {
        // Check if user is a student
        final studentSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: userEmail)
            .get();

        if (studentSnapshot.docs.isNotEmpty) {
          setState(() {
            _studentData = studentSnapshot.docs.first.data();
          });
        }

        // Check if user is a teacher
        final teacherSnapshot = await FirebaseFirestore.instance
            .collection('teachers')
            .where('email', isEqualTo: userEmail)
            .get();

        if (teacherSnapshot.docs.isNotEmpty) {
          setState(() {
            _teacherData = teacherSnapshot.docs.first.data();
          });
        }

        // Check if user is an admin
        final adminSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .where('email', isEqualTo: userEmail)
            .get();

        if (adminSnapshot.docs.isNotEmpty) {
          setState(() {
            _adminData = adminSnapshot.docs.first.data();
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildProfileContent();
  }

  Widget _buildProfileContent() {
    if (_user == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_studentData != null) {
      return _buildStudentProfile();
    } else if (_teacherData != null) {
      return _buildTeacherProfile();
    } else if (_adminData != null) {
      return _buildAdminProfile();
    } else {
      return Center(child: Text('No profile data available.'));
    }
  }

  Widget _buildStudentProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Student Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Full Name: ${_studentData?['full_name'] ?? ''}'),
          Text('Email: ${_studentData?['email'] ?? ''}'),
          Text('Phone: ${_studentData?['phone_number'] ?? ''}'),
          Text('Group ID: ${_studentData?['group_id'] ?? ''}'),
        ],
      ),
    );
  }

  Widget _buildTeacherProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Teacher Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Full Name: ${_teacherData?['full_name'] ?? ''}'),
          Text('Email: ${_teacherData?['email'] ?? ''}'),
          Text('Phone: ${_teacherData?['phone_number'] ?? ''}'),
          Text('Subject ID: ${_teacherData?['subject_id'] ?? ''}'),
        ],
      ),
    );
  }

  Widget _buildAdminProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Full Name: ${_adminData?['full_name'] ?? ''}'),
          Text('Email: ${_adminData?['email'] ?? ''}'),
          Text('Phone: ${_adminData?['phone_number'] ?? ''}'),
        ],
      ),
    );
  }
}
