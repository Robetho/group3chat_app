import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_const.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper function kupata data za user
  Future<UserModel?> _getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirebaseConst.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        // Tumia fromMap() kwa kuwa tayari tunajua uid
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching user from Firestore: $e");
      return null;
    }
  }

  // LOGIN
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _getUserData(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code}');
      rethrow;
    } catch (e) {
      print('General Login error: $e');
      rethrow;
    }
  }

  // REGISTER
  Future<UserModel?> register(String email, String password, String name, String phone) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String? uid = credential.user?.uid;

      if (uid != null) {
        // 2. Tengeneza Object ya UserModel
        UserModel newUser = UserModel(
          uid: uid,
          name: name,
          email: email,
          phone: phone,
          profileImage: '',
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          fcmToken: '',
        );

        // 3. Hifadhi kwenye Firestore kwa kutumia toMap()
        await _firestore
            .collection(FirebaseConst.usersCollection)
            .doc(uid)
            .set(newUser.toMap());

        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Register Error: ${e.code}');
      rethrow;
    } catch (e) {
      print('General Register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _getUserData(user.uid);
    }
    return null;
  }

  Future<void> updateUserLastSeen() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection(FirebaseConst.usersCollection)
            .doc(user.uid)
            .update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating last seen: $e');
    }
  }
}
