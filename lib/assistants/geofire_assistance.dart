import '../models/active_nearby_available_driver.dart';

class GeoFireAssistant{
  static List<ActiveNearByAvailableDrivers> activeNearByAvailableDriversList = [];

  static void deleteOfflineDriverFromList(String driverId){
    int indexNumber = activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverId);

    activeNearByAvailableDriversList.removeAt(indexNumber);
  }


  static void updateActiveNearByAvailableDriversLocation(ActiveNearByAvailableDrivers driverWhoMove){
    int indexNumber = activeNearByAvailableDriversList.indexWhere((element)=>element.driverId == driverWhoMove.driverId);
    activeNearByAvailableDriversList[indexNumber].locationLatitude = driverWhoMove.locationLatitude;
    activeNearByAvailableDriversList[indexNumber].locationLongitude = driverWhoMove.locationLongitude;
  }
}