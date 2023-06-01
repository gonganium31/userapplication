import 'dart:async';
//import 'dart:js_util';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:utransport/assistants/assistant_method.dart';
import 'package:utransport/assistants/geofire_assistance.dart';
import 'package:utransport/global/global.dart';
import 'package:utransport/global/map_key.dart';
import 'package:utransport/infoHandler/app_info.dart';
import 'package:utransport/models/active_nearby_available_driver.dart';
import 'package:utransport/screens/drawe_screen.dart';
import 'package:utransport/screens/precise_pickup_location.dart';
import 'package:utransport/screens/rate_driver_screen.dart';
import 'package:utransport/screens/search_screen.dart';
import 'package:utransport/splash_screen/splash_screen.dart';
import 'package:utransport/widgets/progress_dialog.dart';

import '../models/directions.dart';
import '../widgets/pay_fare_amount.dart';
// import 'package:utransport/global/global.dart';

Future<void> _makePhoneCall(String url)async{
  if(await canLaunch(url)){
    await launch(url);
  }else{
    throw "Could not launch $url";
  }
}




class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-6.203201663291594, 35.79840304553662),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scaffordState = GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight = 220;
  double waitingResponsefromDriverContainerHeight = 0;
  double assignedInfoDriverContainerHeight = 0;
  double suggestedRidesContainerHeight = 0;
  double searchingForDriverContainerHeight = 0;

  Position? userCurrentPosition;
  var geolocation = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap=0;

  List<LatLng> plineCoOrdinatedList = [];
  Set<Polyline> polylineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  String userName = "";
  String userEmail = "";

  bool openNavigationDrawer = true;
  bool activeNearbyDriverKeysLoaded = false;
  BitmapDescriptor? activeNearbyIcon;
  bool requestPositionInfo = true;

  String selectedVehicleType = "";
  String driverRideStatus = "Driver is coming";
  DatabaseReference? referenceRideRequest;
  List<ActiveNearByAvailableDrivers> onlineNearByAvailableDriversList = [];
  StreamSubscription<DatabaseEvent>? tripRidesRequestInfoStreamSubscription;
  String userRideRequestStatus = "";



  locateUserPosition()async{
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng LatLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: LatLngPosition, zoom: 15);
    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));


    String humanReadableAddress = await AssistantsMethods.searchAddressForGeographicCoordinate(userCurrentPosition!, context);
    print("This is address = " + humanReadableAddress);
    print("LatLang =  ${LatLngPosition}" );


    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

    initializeGeoFireListener();
    AssistantsMethods.readTripsKeysForOnlineUser(context);
  }

  initializeGeoFireListener(){
    Geofire.initialize("activeDrivers");

    Geofire.queryAtLocation(userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!
        .listen((map) {
      print(map);
      if(map != null){
        var callBack  = map["callBack"];

        switch(callBack){
          case Geofire.onKeyEntered:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude = map["longitude"];
            activeNearByAvailableDrivers.driverId = map["key"];

            GeoFireAssistant.activeNearByAvailableDriversList.add(activeNearByAvailableDrivers);
            if(activeNearbyDriverKeysLoaded == true){
              displayActiveDriversOnUserMap();
            }
            break;
        //whenever driver become non-active/online
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map["key"]);
            displayActiveDriversOnUserMap();

            break;

        //whenever driver moves - update driver location
          case Geofire.onKeyMoved:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude = map["longitude"];
            activeNearByAvailableDrivers.driverId = map["key"];

            GeoFireAssistant.activeNearByAvailableDriversList.add(activeNearByAvailableDrivers);
            displayActiveDriversOnUserMap();

            break;

        //shows active drivers
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            displayActiveDriversOnUserMap();
            break;
        }
      }
      setState(() {

      });
    });
  }

  displayActiveDriversOnUserMap(){
    setState(() {
      markersSet.clear();
      circlesSet.clear();


      Set<Marker> driversMarkerSet = Set<Marker>();

      for(ActiveNearByAvailableDrivers eachDriver in GeoFireAssistant.activeNearByAvailableDriversList){
        LatLng eachDriverActivePosition = LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );

        driversMarkerSet.add(marker);
      }

      setState(() {
        markersSet = driversMarkerSet;
      });
    });
  }


  createActiveNearByDriverIconMarker(){
    if(activeNearbyIcon == null){
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(0.1, 0.1));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/bajaj.png").then((value) {
        activeNearbyIcon = value;
      });
    }
  }


  Future<void> drawPolylineFromOriginalToDestination()async {
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(originPosition!.locationLatitude!, originPosition!.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!, destinationPosition!.locationLongitude!);


    showDialog(context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait.......",),
    );

    var directionDetailsInfo = await AssistantsMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;

    });

    Navigator.pop(context);
    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResultList = pPoints.decodePolyline(directionDetailsInfo.e_points!);

    plineCoOrdinatedList.clear();

    if(decodePolyLinePointsResultList.isNotEmpty){
      decodePolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        plineCoOrdinatedList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: plineCoOrdinatedList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    }
    else if(originLatLng.latitude > destinationLatLng.latitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    }
    else{
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: MarkerId("originID"),
      infoWindow: InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker = Marker(
      markerId: MarkerId("destinationID"),
      infoWindow: InfoWindow(title: destinationPosition.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      markersSet.add(originMarker);
      markersSet.add(destinationMarker);
    });


    Circle originCircle = Circle(
      circleId: CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );


    Circle destinationCircle = Circle(
      circleId: CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });
  }

  showSearchingForDriversContainer(){
    setState(() {
      searchingForDriverContainerHeight = 200;
    });
  }

  void showSuggestedRidesContainer(){

    setState(() {
      suggestedRidesContainerHeight = 400;
      bottomPaddingOfMap = 400;
    });

  }


  checkIfLocationPermissionAllowed() async{
    _locationPermission = await Geolocator.requestPermission();
    if(_locationPermission == LocationPermission.denied){
      _locationPermission = await Geolocator.requestPermission();
    }

  }

  saveRideRequestInfomation(String selectedVehicleType){
    //1. save the requestRide Information
    referenceRideRequest = FirebaseDatabase.instance.ref().child("All Ride Requests").push();

    var originLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      //"key: value"
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };

    Map destinationLocationMap = {
      //"key: value"
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };


    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);

    tripRidesRequestInfoStreamSubscription = referenceRideRequest!.onValue.listen((eventSnap)async {
      if(eventSnap.snapshot.value == null){
        return;
      }
      if((eventSnap.snapshot.value as Map)["trans_details"] != null){
        setState(() {
          driverTransDetails = (eventSnap.snapshot.value as Map)["trans_details"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverPhone"] != null){
        setState(() {
          driverPhone = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverName"] != null){
        setState(() {
          driverName = (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["ratings"] != null){
        setState(() {
          driverRatings = (eventSnap.snapshot.value as Map)["ratings"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["status"] != null){
        setState(() {
          userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverLocation"] != null){

        double driverCurrentPositionLat = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverCurrentPositionLng = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["longitude"].toString());

        LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        //status == accepted
        if(userRideRequestStatus == "accepted"){
          updateArrivalTimeToUserPickLocation(driverCurrentPositionLatLng);
        }


        //status == arrived
        if(userRideRequestStatus == "arrived"){
          setState(() {
            driverRideStatus = "Driver has arrived";
          });
        }

        //status == onTrip
        if(userRideRequestStatus == "ontrip"){
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }

        if(userRideRequestStatus == "ended"){
          if((eventSnap.snapshot.value as Map)["fareAmount"] != null){
            double fareAmount = double.parse((eventSnap.snapshot.value as Map)["fareAmount"].toString());

            var response = await showDialog(
                context: context,
                builder: (BuildContext context) => PayFareAmountDialog(
                  fareAmount: fareAmount,
                )
            );

            if(response == "Cash Paid"){
              //user can rate the driver now
              if((eventSnap.snapshot.value as Map)["driverId"] != null){
                String assignedDriverId = (eventSnap.snapshot.value as Map)["driverId"].toString();
                Navigator.push(context, MaterialPageRoute(builder: (c)=> RateDriverScreen(
                  assignedDriverId: assignedDriverId,
                )));


                referenceRideRequest!.onDisconnect();
                tripRidesRequestInfoStreamSubscription!.cancel();

              }
            }
          }
        }
      }
    });

    onlineNearByAvailableDriversList = GeoFireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);
  }

  searchNearestOnlineDrivers(String selectedVehicleType) async{
    if(onlineNearByAvailableDriversList.length == 0){

      referenceRideRequest!.remove();

      setState(() {
        polylineSet.clear();
        markersSet.clear();
        circlesSet.clear();
        plineCoOrdinatedList.clear();
      });

      Fluttertoast.showToast(msg: "No online nearest Driver Available");
      Fluttertoast.showToast(msg: "Search again. \n Restart App");


      Future.delayed(Duration(milliseconds: 4000), (){
        referenceRideRequest!.remove();
        Navigator.push(context, MaterialPageRoute(builder: (c)=>SplashScreen()));
      });

      return;
    }

    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    print("Driver List: " + driversList.toString());

    for(int i = 0; i < driversList.length; i++){
      if(driversList[i]["trans_details"]["type"] == selectedVehicleType){
        AssistantsMethods.sendNotificationToDriverNow(driversList[i]["token"], referenceRideRequest!.key!,
            context);
      }
    }

    Fluttertoast.showToast(msg: "Notification sent successfully");

    showSearchingForDriversContainer();

    await FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).child("driverId").onValue.listen((eventRideRequestSnapshot) {
      print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
      if(eventRideRequestSnapshot.snapshot.value != null){
        if(eventRideRequestSnapshot.snapshot.value != "waiting"){
          showUIForAssignedDriverInfo();
        }
      }
    });

  }

  updateArrivalTimeToUserPickLocation(driverCurrentPositionLatLng) async{
    if(requestPositionInfo == true){
      requestPositionInfo = false;
      LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      var directionDetailsInfo = await AssistantsMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng, userPickUpPosition,
      );

      if(directionDetailsInfo == null){
        return;
      }
      setState(() {
        driverRideStatus = "Driver is coming: " + directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }

  }


  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async{
    if(requestPositionInfo == true){
      requestPositionInfo = false;


      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
        dropOffLocation!.locationLatitude!,
        dropOffLocation.locationLongitude!,
      );
      var directionDetailsInfo = await AssistantsMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        userDestinationPosition,
      );

      if(directionDetailsInfo == null){
        return;
      }

      setState(() {
        driverRideStatus = "Going Towards Destination: " + directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }
  }

  showUIForAssignedDriverInfo(){
    setState(() {
      waitingResponsefromDriverContainerHeight = 0;
      searchLocationContainerHeight = 0;
      assignedInfoDriverContainerHeight = 200;
      suggestedRidesContainerHeight = 0;
      bottomPaddingOfMap = 200;
    });
  }


  retrieveOnlineDriversInformation(List onlineNearestDriversList)async{
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");

    for(int i = 0; i < onlineNearestDriversList.length; i++){
      await ref.child(onlineNearestDriversList[i].driverId.toString()).once().then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;

        driversList.add(driverKeyInfo);
        print("driver Key information = " + driversList.toString());
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfLocationPermissionAllowed();
  }




  @override
  Widget build(BuildContext context) {

    createActiveNearByDriverIconMarker();
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: _scaffordState,
        drawer: DrawerScreen(),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _kGooglePlex,
              polylines: polylineSet,
              markers: markersSet,
              circles: circlesSet,
              onMapCreated: (GoogleMapController controller){
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;

                setState(() {
                  bottomPaddingOfMap = 200;

                });
                locateUserPosition();

              },
            ),

            Positioned(
              top: 50,
              left: 20,
              child: Container(
                child: GestureDetector(
                  onTap: (){
                    _scaffordState.currentState!.openDrawer();
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.menu,
                      color: Colors.lightBlue,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 50, 10, 10),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, color: Colors.blue,),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("From",
                                              style: TextStyle(
                                                color: Colors.blue, fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            Text(Provider.of<AppInfo>(context).userPickUpLocation != null
                                                ? Provider.of<AppInfo>(context).userPickUpLocation!.locationName!:
                                            "Not Getting Address", style: TextStyle(color: Colors.grey.shade700))
                                          ],
                                        )
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 5,),

                                  Divider(
                                    height: 1,
                                    thickness: 2,
                                    color: Colors.blue,
                                  ),

                                  SizedBox(height: 5,),

                                  Padding(
                                    padding: EdgeInsets.all(5),
                                    child: GestureDetector(
                                      onTap: () async{
                                        var responseFromSearchScreen = await Navigator.push(context, MaterialPageRoute(builder: (c)=> const SearchScreen()));
                                        if(responseFromSearchScreen == "obtainedDropoff"){
                                          setState(() {
                                            openNavigationDrawer = false;
                                          });
                                        }

                                        await drawPolylineFromOriginalToDestination();
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, color: Colors.blue,),
                                          SizedBox(width: 10,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("To",
                                                style: TextStyle(
                                                  color: Colors.blue, fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              Text(Provider.of<AppInfo>(context).userDropOffLocation != null
                                                  ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName!:
                                              "Where to", style: TextStyle(color: Colors.grey.shade700),)
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(height: 5,),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (c)=> PrecisePickUpScreen()));
                                  },
                                  child: Text(
                                    "Change Pickup Location",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),

                                SizedBox(width: 10,),

                                ElevatedButton(
                                  onPressed: (){
                                    if(Provider.of<AppInfo>(context, listen:  false).userDropOffLocation != null){
                                      showSuggestedRidesContainer();
                                    }else{
                                      Fluttertoast.showToast(msg: "Please select destination location");
                                    }
                                  },
                                  child: Text(
                                    "Show fare",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
            ),

            //ui for suggested rides
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: suggestedRidesContainerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    ),
                  ),

                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Icon(
                                Icons.star, color: Colors.white,
                              ),
                            ),

                            SizedBox(width: 15,),

                            Text(
                              Provider.of<AppInfo>(context).userPickUpLocation != null
                                  ? Provider.of<AppInfo>(context).userPickUpLocation!.locationName!
                                  : "Not Getting Address",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 20,),

                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Icon(
                                Icons.star, color: Colors.grey,
                              ),
                            ),

                            SizedBox(width: 15,),

                            Text(
                              Provider.of<AppInfo>(context).userDropOffLocation != null
                                  ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName!
                                  : "Where to?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 20,),

                        Text(
                          "Suggested Rides",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 20,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: (){
                                setState(() {
                                  selectedVehicleType = "Bajaj";
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedVehicleType == "Bajaj" ? Colors.blue : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(25.0),
                                  child: Column(
                                    children: [
                                      Image.asset("images/bajaj.png", scale: 10,),

                                      SizedBox(height: 8,),

                                      Text(
                                        "Bajaj",
                                        style: TextStyle(
                                            color: selectedVehicleType == "Bajaj" ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),


                                      SizedBox(height: 2,),

                                      Text(
                                        tripDirectionDetailsInfo != null ? "Tsh ${((AssistantsMethods.calculateFareAmountFromOriginalToDestination(tripDirectionDetailsInfo!) * 2) * 107).toStringAsFixed(1)}"
                                            : "null",
                                        style: TextStyle(
                                            color: selectedVehicleType == "Bajaj" ? Colors.white : Colors.black
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: (){
                                setState(() {
                                  selectedVehicleType = "BodaBoda";
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedVehicleType == "BodaBoda" ? Colors.blue : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(25.0),
                                  child: Column(
                                    children: [
                                      Image.asset("images/bikebike.png", scale: 22,),

                                      SizedBox(height: 8,),

                                      Text(
                                        "Boda Boda",
                                        style: TextStyle(
                                            color: selectedVehicleType == "BodaBoda" ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),


                                      SizedBox(height: 2,),

                                      Text(
                                        tripDirectionDetailsInfo != null ? "Tsh ${((AssistantsMethods.calculateFareAmountFromOriginalToDestination(tripDirectionDetailsInfo!) * 0.8) * 107).toStringAsFixed(1)}"
                                            : "null",
                                        style: TextStyle(
                                            color:  selectedVehicleType == "BodaBoda" ? Colors.white : Colors.black
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 35,),

                        Expanded(
                          child: GestureDetector(
                            onTap: (){
                              if(selectedVehicleType != ""){
                                saveRideRequestInfomation(selectedVehicleType);
                              }else{
                                Fluttertoast.showToast(msg: "Please select a vehicle from \n suggested rides.");
                              }
                            },

                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: Center(
                                child: Text(
                                  "Request a Ride",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
            ),

            //Request for a ride
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: searchingForDriverContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      LinearProgressIndicator(
                        color: Colors.blue,
                      ),

                      SizedBox(height: 10,),

                      Center(
                        child: Text(
                          "Searching for a driver....",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),

                      SizedBox(height: 20,),

                      GestureDetector(
                        onTap: (){
                          referenceRideRequest!.remove();
                          setState(() {
                            searchingForDriverContainerHeight = 0;
                            suggestedRidesContainerHeight = 0;
                          });

                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(width: 1,color: Colors.grey)
                          ),

                          child: Icon(
                            Icons.close,
                            size: 25,
                          ),
                        ),
                      ),

                      SizedBox(height: 15,),

                      Container(
                        width: double.infinity,
                        child: Text(
                          "Cancel",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      )

                    ],
                  ),
                ),
              ),
            ),


            //UI for display assigned driver information
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: assignedInfoDriverContainerHeight,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)
                  ),

                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(driverRideStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5,),
                        Divider(
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  child: Icon(Icons.person, color: Colors.white,),
                                ),
                                SizedBox(width: 10,),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driverName, style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    ),

                                    Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.orange,),
                                        SizedBox(width: 5,),
                                        Text("Ratings",//driverRatings == null ? "0.00" : double.parse(driverRatings).toStringAsFixed(2),
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Image.asset("images/bajaj.png", scale: 10,),
                                Text(driverTransDetails, style: TextStyle(
                                  fontSize: 20,
                                ),
                                ),
                              ],
                            )
                          ],
                        ),


                        SizedBox(height: 1,),
                        Divider(
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                        ElevatedButton.icon(
                          onPressed: (){
                            _makePhoneCall("Tel: ${driverPhone}");
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                          ),
                          icon: Icon(Icons.phone),
                          label: Text("Call Driver"),
                        )
                      ],
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),

    );
  }
}
