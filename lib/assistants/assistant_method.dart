import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:utransport/assistants/request_assistant.dart';
import 'package:utransport/global/global.dart';
import 'package:utransport/models/directions.dart';
import 'package:utransport/models/trips_history_list_model.dart';
import 'package:utransport/models/user_model.dart';

import '../global/map_key.dart';
import '../infoHandler/app_info.dart';
import '../models/directions_details.dart';
import 'package:http/http.dart' as http;

class AssistantsMethods{
  static void readCurrentOnlineUserInfo() async{
    currentUser = firebaseAuth.currentUser;
    DatabaseReference userRef =  FirebaseDatabase.instance.ref().child("users").child(currentUser!.uid);

    userRef.once().then((snap) {
      if(snap.snapshot.value != null){
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  static Future<String> searchAddressForGeographicCoordinate(Position position, context)async{
    String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";
     var requestResponse  = await RequestAssistant.receiveRequest(apiUrl);


     if(requestResponse != "Error Occured. Failed. No Response."){
       humanReadableAddress = requestResponse["results"][1]["formatted_address"];
       Directions userPickUpAddress = Directions();
       userPickUpAddress.locationLatitude = position.latitude;
       userPickUpAddress.locationLongitude = position.longitude;
       userPickUpAddress.locationName = humanReadableAddress;

       Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);


     }
    return humanReadableAddress;

  }

  static Future<DirectionDetailsInfo> obtainOriginToDestinationDirectionDetails(LatLng originPosition, LatLng destinationPosition)async{
    String urlOriginToDestinationDirectionDetails = "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    var responseDirectionApi = await RequestAssistant.receiveRequest(urlOriginToDestinationDirectionDetails);

    // if(responseDirectionApi == "Error Occured. Failed. No Response."){
    //   return;
    //
    // }
    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.e_points = responseDirectionApi["routes"][0]["overview_polyline"]["points"];


    directionDetailsInfo.distance_text = responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distance_value = responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];

    directionDetailsInfo.duration_text = responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.duration_value = responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];


    return directionDetailsInfo;
  }



  static double calculateFareAmountFromOriginalToDestination(DirectionDetailsInfo directionDetailsInfo){
    double timeTraveledFareAmountPerMinute = (directionDetailsInfo.duration_value! / 60) * 0.20;
    double distanceTraveledFareAmountPerKilometer = (directionDetailsInfo.duration_value! / 1000) * 0.20;
    //USD
    double totalFareAmount = (timeTraveledFareAmountPerMinute + distanceTraveledFareAmountPerKilometer)*2000;
    int amount =0;
    if(totalFareAmount.truncate()>=1000 && totalFareAmount.truncate()<2000){
      amount = 1000;
    }else if(totalFareAmount.truncate()>=2000 && totalFareAmount.truncate()<3000){
      amount =2000;
    }else {
      amount = 3000;
    }
    return double.parse(amount.toStringAsFixed(1));
  }


  static sendNotificationToDriverNow(String deviceRegistrationToken, String userRideRequestId, context) async{
    String originAddress = userPickUpAddress;
    String destinationAddress = userDropOffAddress;
    print("token $deviceRegistrationToken ************************");

    Map<String, String> headerNotification = {
      'Content-Type': 'application/json',
      'Authorization': cloudMessagingServerToken,
    };

    Map bodyNotification = {
      "body": "Destionation Address: $destinationAddress."+ "\n" +"Orign Address: $originAddress",
      "title": "New Trip Request"
    };

    Map dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "rideRequestId": userRideRequestId
    };

    Map officialNotificationFormat = {
      "notification": bodyNotification,
      "data": dataMap,
      "priority": "high",
      "to": deviceRegistrationToken
    };

         http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: headerNotification,
        body: jsonEncode(officialNotificationFormat),
    ).then((value) {
      print("Response code &&&&&  ${value.statusCode} response bode ${value.body}   __________________");
    }).whenComplete(() {
         print("notification sent success@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    });
  }

  //retrieve the trips for the online user
static void readTripsKeysForOnlineUser(context){
    FirebaseDatabase.instance.ref().child("All Ride Requests").orderByChild("userName").equalTo(userModelCurrentInfo!.name).once().then((snap) {
      if(snap.snapshot.value != null){
        Map KeysTripsId = snap.snapshot.value as Map;

        //count total number of trips and share it with provider
        int overAllTripsCounter = KeysTripsId.length;
        Provider.of<AppInfo>(context, listen: false).updateOverAllTripsCounter(overAllTripsCounter);

        //share trip keys with provider
        List<String> tripsKeysList = [];
        KeysTripsId.forEach((key, value) {
          tripsKeysList.add(key);
        });

        Provider.of<AppInfo>(context, listen: false).updateOverAllTripsKeys(tripsKeysList);

        //get trips keys data - read trips complete information
        readTripsHistoryInformation(context);

      }
    });
}


static void readTripsHistoryInformation(context){
    var tripsAllKeys = Provider.of<AppInfo>(context, listen: false).historyTripsKeysList;

    for(String eachKey in tripsAllKeys){
      FirebaseDatabase.instance.ref()
          .child("All Ride Requests")
          .child(eachKey)
          .once()
          .then((snap){
            var eachTripHistory  = TripsHistoryModel.fromSnapshot(snap.snapshot);
            if((snap.snapshot.value as Map)["status"] == "ended"){
              //update or add each history to OverAllTrips History list
              Provider.of<AppInfo>(context, listen: false).updateOverAllTripsHistoryInformation(eachTripHistory);
            }
      });
    }
}
}