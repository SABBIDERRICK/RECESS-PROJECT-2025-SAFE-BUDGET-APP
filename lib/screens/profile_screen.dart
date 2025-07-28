// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:safe_budget/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _changePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Change Password',
                style: TextStyle(color: Colors.white),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      // Password is visible
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter current password'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      // Password is visible
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => isLoading = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null || user.email == null) {
                                throw Exception('No user');
                              }
                              final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: currentPasswordController.text.trim(),
                              );
                              await user.reauthenticateWithCredential(cred);
                              await user.updatePassword(
                                newPasswordController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password updated successfully',
                                    ),
                                  ),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              String msg = 'Failed to update password.';
                              if (e.code == 'wrong-password') {
                                msg = 'Current password is incorrect.';
                              } else if (e.message != null)
                                msg = e.message!;
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(msg)));
                            } finally {
                              setState(() => isLoading = false);
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateNameDialog(BuildContext context) async {
    final nameController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Update Name',
                style: TextStyle(color: Colors.white),
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter your name'
                              : null,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => isLoading = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) throw Exception('No user');
                              await user.updateDisplayName(
                                nameController.text.trim(),
                              );
                              await user.reload();
                              // Update Firestore as well
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .set({
                                    'fullName': nameController.text.trim(),
                                  }, SetOptions(merge: true));
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Name updated successfully'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update name.'),
                                ),
                              );
                            } finally {
                              setState(() => isLoading = false);
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeProfilePicture(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final file = picked;
    final storageRef = FirebaseStorage.instance.ref().child(
      'profile_pictures/${user.uid}.jpg',
    );
    final uploadTask = await storageRef.putData(await file.readAsBytes());
    final url = await storageRef.getDownloadURL();
    await user.updatePhotoURL(url);
    await user.reload();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'photoURL': url,
    }, SetOptions(merge: true));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? 'No email';
    final String uid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: getBaseGradient(), //reusable gradient function
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      String? photoURL;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data();
                        if (data != null && data['photoURL'] != null) {
                          photoURL = data['photoURL'];
                        }
                      }
                      return CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            photoURL != null
                                ? NetworkImage(photoURL)
                                : const AssetImage('assets/images/logo.jpg')
                                    as ImageProvider,
                        backgroundColor: Colors.grey,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _changeProfilePicture(context),
                      child: CircleAvatar(
                        backgroundColor: Colors.green[800],
                        radius: 18,
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // User Info
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .snapshots(),
              builder: (context, snapshot) {
                String fullName = 'No name set';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data();
                  if (data != null && data['fullName'] != null) {
                    fullName = data['fullName'];
                  }
                }
                return Column(
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(email, style: const TextStyle(color: Colors.grey)),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),
            const Divider(color: Colors.white54),

            // Profile Options with ListTileTheme
            ListTileTheme(
              textColor: Colors.white,
              iconColor: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Update Name'),
                    onTap: () => _updateNameDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Change Password'),
                    onTap: () => _changePasswordDialog(context),
                  ),

                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.green[700]),
                    title: Text(
                      'Log Out',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
