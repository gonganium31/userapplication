import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utransport/assistants/request_assistant.dart';
import 'package:utransport/global/map_key.dart';
import 'package:utransport/infoHandler/app_info.dart';
import 'package:utransport/models/directions.dart';
import 'package:utransport/widgets/progress_dialog.dart';

import '../global/global.dart';
import '../models/predict_places.dart';




class PlacePredictionTileDesign extends StatefulWidget {
  final PredictedPlaces? predictedPlaces;

  PlacePredictionTileDesign({this.predictedPlaces});
  //const PlacePredictionTileDesign({Key? key}) : super(key: key);

  @override
  State<PlacePredictionTileDesign> createState() => _PlacePredictionTileDesignState();
}

class _PlacePredictionTileDesignState extends State<PlacePredictionTileDesign> {

  getPlaceDirectionDetails(String? placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context)=>ProgressDialog(
          message: "Setting up Drop-off. Please wait....",
        )
    );


    String placeDirectionDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var responseApi = await RequestAssistant.receiveRequest(placeDirectionDetailsUrl);
    Navigator.pop(context);


    if(responseApi == "Error Occured. Failed. No Response."){
      return;

    }
    if(responseApi["status"]=="OK"){
      Directions directions = Directions();
      directions.locationName = responseApi["result"]["name"];
      directions.locationId = placeId;
      directions.locationLatitude = responseApi["result"]["geometry"]["location"]["lat"];
      directions.locationLongitude = responseApi["result"]["geometry"]["location"]["lng"];


      Provider.of<AppInfo>(context, listen: false).updateDropOffLocationAddress(directions);

      setState(() {
        userDropOffAddress = directions.locationName!;
      });

      Navigator.pop(context, "obtainedDropoff");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: (){
          getPlaceDirectionDetails(widget.predictedPlaces!.place_id, context);
        },
        child: Padding(
            padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(Icons.add_location, color: Colors.white,
              ),

              SizedBox(width: 10,),

              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.predictedPlaces!.main_text!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white
                        ),
                      ),


                      Text(
                        widget.predictedPlaces!.secondary_text!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                        ),
                      ),

                    ],
                  )
              )
            ],
          ),
        )
    );
  }
}
