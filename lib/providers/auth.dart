import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Auth with ChangeNotifier {
  String? token;
  DateTime? expiryDate;
  String? userId;
  Timer? authTimer;

  bool get isAuth {
    return token != null;
  }

  String? get UserId {
    return userId;
  }

  String? get Token {
    if (expiryDate != null &&
        expiryDate!.isAfter(DateTime.now()) &&
        token != null) {
      return token;
    }
    return null;
  }

  // Future<void> _authenticate(
  //     String email, String password, String urlSegment) async {
  //   final url =
  //       'https://identitytoolkit.googleapis.com/v1/$urlSegment?key=AIzaSyDcvUZP1LZ0BdIiRf6T3VOMNalQmJh5eWk';
  //   final response = await http.post(Uri.parse(url),
  //       body: json.encode({
  //         'email': email,
  //         'password': password,
  //         'returnSecureToken': true,
  //       }));
  // }

  Future<void> signup(String email, String password) async {
    const url =
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyDcvUZP1LZ0BdIiRf6T3VOMNalQmJh5eWk';
    try {
      final response = await http.post(Uri.parse(url),
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }));
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      token = responseData['idToken'];
      userId = responseData['localId'];
      expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );
    } catch (error) {
      throw error;
    }
  }

  Future<void> login(String email, String password) async {
    const url =
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyDcvUZP1LZ0BdIiRf6T3VOMNalQmJh5eWk';
    try {
      final response = await http.post(Uri.parse(url),
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }));
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }

      token = responseData['idToken'];
      userId = responseData['localId'];
      expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );
      autologout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': token,
        'userId': userId,
        'expiryDate': expiryDate!.toIso8601String(),
      });
      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

  Future<bool> tryautologin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData') ?? '') as Map<String, dynamic>;
    var expiryDate = DateTime.parse(extractedUserData['expiryDate']);
    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    token = extractedUserData['token'];
    userId = extractedUserData['userId'];
    expiryDate = expiryDate;
    notifyListeners();
    autologout();
    return true;
  }

  Future<void> logout() async {
    token = null;
    userId = null;
    expiryDate = null;
    if (authTimer != null) {
      authTimer!.cancel();
      authTimer = null;
    }

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void autologout() {
    if (authTimer != null) {
      authTimer?.cancel();
    }
    final timetoexpiry = expiryDate!.difference(DateTime.now()).inSeconds;
    authTimer = Timer(Duration(seconds: timetoexpiry), logout);
  }
}
