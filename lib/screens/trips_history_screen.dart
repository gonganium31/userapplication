import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utransport/infoHandler/app_info.dart';
import 'package:utransport/widgets/history_design_ui.dart';
class TripsHistoryScreen extends StatefulWidget {
  const TripsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Trips History",
          style: TextStyle(
            color: Colors.blue
          ),
        ),
        leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            icon: Icon(Icons.close, color: Colors.blue,)
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView.separated(
            itemBuilder: (context, i){
              return Card(
                color: Colors.grey[100],
                shadowColor: Colors.transparent,
                child: HistoryDesignUIScreen(
                  tripsHistoryModel: Provider.of<AppInfo>(context, listen: false).allTripsHistoryInformationList[i],
                ),
              );
            },
            separatorBuilder: (context, i)=> SizedBox(height: 30,),
            itemCount: Provider.of<AppInfo>(context, listen: false).allTripsHistoryInformationList.length,
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
        ),
      ),
    );
  }
}
