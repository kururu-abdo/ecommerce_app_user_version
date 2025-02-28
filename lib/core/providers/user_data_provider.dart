import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:user_app/core/models/orders_model.dart';
import 'package:user_app/core/models/user_model.dart';
import 'firebase_service.dart';

class UserDataProvider with ChangeNotifier {
  UserDataProvider() {
    fetchUserData();
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FireStoreService().instance;
  UserModel _userData = UserModel();
  UserModel get userData => _userData;
  ShippingAddress? _shippingAddress;
  ShippingAddress? get shippingAddress => _shippingAddress;
  set userData(UserModel value) {
    _userData = value;
    notifyListeners();
  }

  

  Future<UserModel> fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final uid = user.uid;
        if (!user.isAnonymous) {
          final snapshot = await _fireStore.collection('users').doc(uid).get();
          _userData = UserModel.fromJson(snapshot.data()!);
          //clenning user shippingAddress here if user loggleIn with a new account
          _shippingAddress = ShippingAddress(
            addressLine1: '',
            addressLine2: '',
            city: '',
            state: '',
            postalCode: '',
            country: '',
            latitude: '',
            longitude: '',
            formattedAddress: '',
          );
          final data = snapshot.data();
          if (data != null && data['shippingAddress'] != null) {
            final shippingAddress = data['shippingAddress'];
            _shippingAddress = ShippingAddress.fromJson(shippingAddress);
          }
        }
        notifyListeners();
        return _userData;
      }
      return UserModel();
    } catch (e) {
      return UserModel();
    }
  }

  Future<void> uploadUserData(UserModel userModel) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        userModel.id = user.uid;
        var date = DateTime.now().toString();
        var dateparse = DateTime.parse(date);
        var formattedDate =
            '${dateparse.day}-${dateparse.month}-${dateparse.year}';
        userModel.joinedAt = formattedDate;
        userModel.createdAt = Timestamp.now();
        await _fireStore
            .collection('users')
            .doc(userModel.id)
            .set(userModel.toJson())
            .then((_) async {
          await fetchUserData();
        });
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserData(UserModel userModel) async {
    try {
      final user = _auth.currentUser;
      userModel.id = user!.uid;
      await _fireStore
          .collection('users')
          .doc(userModel.id)
          .update(userModel.toJson());
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
