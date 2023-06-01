import 'package:flutter/material.dart';
import 'package:utransport/splash_screen/splash_screen.dart';

import '../screens/rate_driver_screen.dart';


class PayFareAmountDialog extends StatefulWidget {
 // const PayFareAmountDialog({Key? key}) : super(key: key);
  double? fareAmount;
  PayFareAmountDialog({this.fareAmount});
  @override
  State<PayFareAmountDialog> createState() => _PayFareAmountDialogState();
}

class _PayFareAmountDialogState extends State<PayFareAmountDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),

      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20,),
            Text(
              "Fare Amount". toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 30,
              ),
            ),

            SizedBox(height: 20,),
            Divider(
              thickness: 2,
              color: Colors.white,
            ),

            Text(
              "Tsh "+widget.fareAmount.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                  fontWeight: FontWeight.bold
              ),
            ),


            SizedBox(height: 10,),

            Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "This is the total trip fare amount. Please pay it to the driver",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                  ),
                ),
            ),

            SizedBox(height: 10,),

            Padding(
                padding: EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.white
                ),

                onPressed: (){
                  Future.delayed(Duration(milliseconds: 10000),(){
                    Navigator.pop(context, "Cash Paid");
                    Navigator.push(context, MaterialPageRoute(builder: (c) => RateDriverScreen()));
                  });
                },

                child: Row(
                  children: [
                    Text("Pay Cash",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold
                    ),
                    ),

                    Text(
                      "Tsh "+widget.fareAmount.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  ],
                ),
              ),

            ),

            SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }
}
