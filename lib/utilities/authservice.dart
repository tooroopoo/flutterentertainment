import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/deal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/appuser.dart';

import 'package:rxdart/rxdart.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  var userisBrand=false;
  AppUser appUser=AppUser(brandname: 'username',
    dealsbybusiness: [],
    isBrand: false,
    description: 'account description',
    outletlist: [],);

  CollectionReference users = FirebaseFirestore.instance.collection('users');
  // Firebase user a realtime stream

// Firebase user one-time fetch
//bool isLoggedIn(){
//  return _auth.currentUser!=null;
//}

Stream<User> get user => FirebaseAuth.instance.authStateChanges();


  /// Sign in with Google
   Future<UserCredential> signInWithGoogle() async {
            print('sign in with google ----');
          // Trigger the authentication flow
          final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

          // Obtain the auth details from the request
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

          // Create a new credential
          final GoogleAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
        UserCredential result = await _auth.signInWithCredential(credential);




        if (result.additionalUserInfo.isNewUser==true){
          addUserData(result);
        }



          // Once signed in, return the UserCredential
          return result;
}

Future<UserCredential> signInWithEmail(String email, String password) async{
try{
  UserCredential authResult = await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );



  return authResult;
}on FirebaseAuthException catch (e) {
  print('firebaseauthexception');
  print(e);

} catch (e) {
  print('sign in error');
  print(e);
}

}

Future<UserCredential> registerWithEmail(String email, String password) async{
  try {
  UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password
  );


  if (userCredential.additionalUserInfo.isNewUser==true){
    addUserData(userCredential);
  }


  return userCredential;
} on FirebaseAuthException catch (e) {
  if (e.code == 'weak-password') {
    print('The password provided is too weak.');
  } else if (e.code == 'email-already-in-use') {
    print('The account already exists for that email.');
  }
} catch (e) {
  print(e);
}
}

  
  void addUserData(UserCredential user) async{


      await FirebaseFirestore.instance
            .collection('users')
            .doc(user.user.uid)
            .set({
        'brandname':user.user.displayName,

        
          'role':'public'
          
          

        });

  }

  // Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<bool> addDeal(Deal deal) async{
    await FirebaseFirestore.instance.collection('deals').add({

      'createdAt': Timestamp.now(),
      'userId': _auth.currentUser.uid,
      'dealname':deal.dealname,
      'dealdetails':deal.dealdetails,
      'location':deal.location,
      'imageUrl':deal.imageUrl
    }) .then((value){
      print('added deal!!!!!!!!!!!!!');
      return true;
    })
        .catchError((error)  {
          print(error);
          print('not added');
          return false;
    });
  }


Stream<QuerySnapshot> getBrandDeal(String id) {

  Stream<QuerySnapshot> q= _db.collection('deals').where('userId',isEqualTo: id ).snapshots();
  print(q);
  print('==============in getbranddeal=====================');
  return q;
}


Future<AppUser> getAppUserData() async{
  print('_______________________________________________in authservice getappuserdata__________________________________________________________');
     if (_auth.currentUser!=null){
       print('_______________________________________________in authservice USER IS LOGGED IN__________________________________________________________');
       var snapshot=await _db.collection('users').doc(_auth.currentUser.uid).get();
       print(snapshot);
       var data=snapshot.data();
       var isbrand=data['role']=='brand';
       String brandname=data['brandname'];
       String description=data['description'];
       var outlistlist=data['outletlist'];
       var dealsbybusiness=data['dealsbybusiness'];
       AppUser thisuser=AppUser(
           description: description,
           isBrand: isbrand,
           brandname: brandname,
           outletlist: [],
           dealsbybusiness:[]

       );

       return thisuser;
     }else{
       print('_______________________________________________NO USER LOGGED IN __________________________________________________________');
       return AppUser(brandname: 'username',
         dealsbybusiness: [],
         description: 'account description',
         isBrand: false,
         outletlist: [],);
     }
}



}