import 'package:flutter/material.dart';
import 'package:utransport/global/global.dart';
import 'package:utransport/screens/login_screen.dart';
import 'package:utransport/screens/profile_screen.dart';
import 'package:utransport/screens/trips_history_screen.dart';

import '../splash_screen/splash_screen.dart';


class DrawerScreen extends StatefulWidget {
  const DrawerScreen({Key? key}) : super(key: key);

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      child: Drawer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, 50, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue,
                      shape: BoxShape.circle
                    ),

                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20,),
                  
                  
                  Text(
                    userModelCurrentInfo!.name!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  SizedBox(height: 10,),

                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (c)=> ProfileScreen()));
                    },
                    child: Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue
                      ),
                    ),
                  ),


                  SizedBox(height: 30,),
                  
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (c)=> TripsHistoryScreen()));
                    },
                      child: Text("Your Trip", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)
                  ),

                  SizedBox(height: 15,),

                  Text("Notifications", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),

                  SizedBox(height: 15,),

                  Text("Helps", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),

                  SizedBox(height: 15,),

                  Text("About", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),

                  SizedBox(height: 15,),
                ],
              ),


              GestureDetector(
                onTap: (){
                  firebaseAuth.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                },
                child: Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
