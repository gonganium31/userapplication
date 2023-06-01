import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:utransport/models/directions_details.dart';

import '../models/user_model.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

String cloudMessagingServerToken = "key=AAAA37Dp8J0:APA91bGmMK6qLKiNHH4LM3NKKb7WcS5nq7ZyzfV10yyP8tbfId-jgmS270vibQ72fJubhtaUP6WD3DY1uy-y5Fg-KfqmUL6qliXbZ59_LYTrI6PCYDzuUQADuUGI3wBGnOwqCWyvmh7D";

DirectionDetailsInfo? tripDirectionDetailsInfo;

String userDropOffAddress = "";
String userPickUpAddress = "";

List driversList = [];

//DatabaseReference? referenceRequest;

String driverTransDetails = "";
String driverName = "";
String driverPhone = "";
String driverRatings = "";

double countRatingStars = 0.0;
String titleStarsRating = "";


