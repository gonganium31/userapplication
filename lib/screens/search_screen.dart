import 'package:flutter/material.dart';
import 'package:utransport/assistants/request_assistant.dart';
import 'package:utransport/global/map_key.dart';
import 'package:utransport/models/predict_places.dart';
import 'package:utransport/widgets/place_prediction_tile.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<PredictedPlaces> placesPredictedList = [];

  findPlaceAutoCompleteSearch(String inputText)async{
  if(inputText.length>1){
    String urlAutoCompleteSearch  = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$inputText&key=$mapKey&components=country:TZ";
    var responseAutoCompleteSearch = await RequestAssistant.receiveRequest(urlAutoCompleteSearch);

    if(responseAutoCompleteSearch == "Error Occured. Failed. No Response.") {
      return;
    }
      if(responseAutoCompleteSearch["status"]=="OK"){
        var placePredictions = responseAutoCompleteSearch["predictions"];
        var placePredictionsList = (placePredictions as List).map((jsonData) => PredictedPlaces.fromJson(jsonData)).toList();

        setState(() {
          placesPredictedList = placePredictionsList;
        });
    }
  }


  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          leading: GestureDetector(
            onTap: (){
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back, color: Colors.white,),
          ),
          title: Text(
              "Search Destination Location",
            style: TextStyle(color: Colors.white),
          ),

          elevation: 0,
        ),

        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                boxShadow:[
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: Offset(0.7,0.7)
                  )
                ]
              ),

              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.adjust_sharp, color: Colors.white,
                        ),

                        SizedBox(height: 18.0,),

                        Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: TextField(
                                onChanged: (value){
                                  findPlaceAutoCompleteSearch(value);
                                },
                                decoration: InputDecoration(
                                  hintText: "Search location here..",
                                  fillColor: Colors.white54,
                                  filled: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                    left: 11,
                                    top: 8,
                                    bottom: 8,
                                  )
                                ),
                              ),
                            ))
                      ],
                    )
                  ],
                ),
              ),
            ),
            (placesPredictedList.length>0)?Expanded(
                child: ListView.separated(
                    itemCount: placesPredictedList.length,
                  physics: ClampingScrollPhysics(),
                  itemBuilder: (context, index){
                      return PlacePredictionTileDesign(
                        predictedPlaces: placesPredictedList[index],
                      );
                  },

                  separatorBuilder: (BuildContext context, int index){
                      return Divider(
                        height: 0,
                        color: Colors.white,
                        thickness: 0,
                      );
                  },
                )
            ) : Container(),
          ],
        ),
      ),
    );
  }
}
