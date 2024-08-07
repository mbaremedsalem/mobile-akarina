
// import 'package:bcipay/presentation/customs/custom_new_version.dart';
import 'package:akarina/data/data_providers/exception.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class Services {
  final storage = FlutterSecureStorage();

  Future<bool> getNewToken(BuildContext? context) async {
    bool succeed = false;

    try {
      final response = await NetworkService().getNewAccessToken();
      // print(response);
      await storage.write(key: "token", value: response["access"]);
      await storage.write(key: "refresh", value: response["refresh"]);
      succeed = true;
      return succeed;
    } on Failure {
      Services().logout(context!);
      return succeed;
    }
  }

  void logout(BuildContext context) async {
    await storage.delete(key: "token");
    await storage.delete(key: "refresh");
    await storage.delete(key: "role");
    await storage.delete(key: "firstname");
    await storage.delete(key: "lastname");
    await storage.delete(key: "id");
    await storage.delete(key: "adresse");
    await storage.delete(key: "email");
    await storage.delete(key: "valide_en_agence");
    Navigator.pushNamedAndRemoveUntil(context, "indexLogin", (route) => false);
  }

  static void logoutEndSession(GlobalKey<NavigatorState> navigatorKey) async {
    final storage = FlutterSecureStorage();

    await storage.delete(key: "token");
    await storage.delete(key: "refresh");
    await storage.delete(key: "role");
    await storage.delete(key: "firstname");
    await storage.delete(key: "lastname");
    await storage.delete(key: "id");
    await storage.delete(key: "adresse");
    await storage.delete(key: "email");
    await storage.delete(key: "valide_en_agence");
    navigatorKey.currentState!
        .pushNamedAndRemoveUntil("indexLogin", (route) => false);
  }
}

// class LocationService {
//   Future<l.LocationData?> getLocation() async {
//     l.Location location = new l.Location();
//     bool _serviceEnabled;
//     l.PermissionStatus _permissionGranted;
//     l.LocationData _locationData;

//     _permissionGranted = await location.hasPermission();
//     if (_permissionGranted == l.PermissionStatus.denied) {
//       _permissionGranted = await location.requestPermission();
//     }

//     if (_permissionGranted == l.PermissionStatus.granted) {
//       // throw Exception();
//       _serviceEnabled = await location.serviceEnabled();
//       if (!_serviceEnabled) {
//         _serviceEnabled = await location.requestService();
//         if (!_serviceEnabled) {
//         } else {
//           _locationData = await location.getLocation();
//           return _locationData;
//         }
//       } else {
//         _locationData = await location.getLocation();
//         return _locationData;
//       }
//     }
//     return null;
//   }
// }

class Mylocalstorage {
  FlutterSecureStorage flutterSecureStorage = FlutterSecureStorage();

  setStringValue(String key, String value) async {
    flutterSecureStorage.write(key: key, value: value);
  }

  Future<String?> getStringValue(String key) async {
    return flutterSecureStorage.read(key: key);
  }
}

class ContactPermission {
  Future<Contact?> contactPermissions() async {
    final FlutterContactPicker contactPicker = new FlutterContactPicker();

    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      Contact? contact = await contactPicker.selectContact();
      return contact;
    } else {
      return null;
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }
}

class CameraPermission {
  Future<void> cameraPermissions() async {
    PermissionStatus permissionStatus = await Permission.camera.status;
    if (permissionStatus == PermissionStatus.granted) {
    } else {
      await Permission.camera.request();
    }
  }
}

class StoragePermission {
  Future<void> storagePermissions() async {
    PermissionStatus permissionStatus = await Permission.storage.status;
    if (permissionStatus == PermissionStatus.granted) {
    } else {
      await Permission.storage.request();
    }
  }
}

// void checkVersion(BuildContext context) async {
//   final newVersion = NewVersion(
//     iOSId: 'mr.next.bcipaymr',
//     androidId: 'mr.next.bcipaymr',
//   );
//   try {
//     final _status = await (newVersion.getVersionStatus());
//     if (_status!.canUpdate)
//       newVersion.showUpdateDialog(
//         context: context,
//         versionStatus: _status,
//         allowDismissal: false,
//         dialogTitle: getTranslated(context, "update!")!,
//         dismissButtonText: getTranslated(context, "ignorer"),
//         dialogText: getTranslated(context, "please update"),
//         dismissAction: () {
//           Navigator.pop(context);
//         },
//         updateButtonText: getTranslated(context, "lets update")!,
//       );

//     print("DEVICE : " + _status.localVersion!);
//     print("STORE : " + _status.storeVersion!);
//   } catch (e) {
//     print('error');
//   }
// }



Future<PickedFile> openCamera({bool? rear}) async {
  final picker = ImagePicker();
  // ignore: deprecated_member_use
  final pickedFile = await picker.getImage(
      source: ImageSource.camera,
      preferredCameraDevice:
          (rear ?? false) ? CameraDevice.rear : CameraDevice.front);
  return pickedFile ?? PickedFile('');
}

String? validatorInputNumber(
    BuildContext context, String? value, String? pays) {
  String pattern = r'^[0-9]*$';
  RegExp regExp = new RegExp(pattern);

  if (value!.isEmpty) {
    return getTranslated(context, "telobligatoire");
  } else if (pays == 'Mauritania') {
    if (value.startsWith('2') ||
        value.startsWith('3') ||
        value.startsWith('4')) {
      if (value.length == 8) {
        if (regExp.hasMatch(value)) {
          return null;
        } else {
          return getTranslated(context, "telnonvalide");
        }
      } else {
        return getTranslated(context, "telnonvalide");
      }
    } else
      return getTranslated(context, "telnonvalide");
  } else if (pays == 'Guinee') {
    if (value.startsWith('61') ||
        value.startsWith('62') ||
        value.startsWith('65') ||
        value.startsWith('66')) {
      if (value.length == 9) {
        if (regExp.hasMatch(value)) {
          return null;
        } else {
          return getTranslated(context, "telnonvalide");
        }
      } else {
        return getTranslated(context, "telnonvalide");
      }
    } else
      return getTranslated(context, "telnonvalide");
  }
  return getTranslated(context, "telnonvalide");
}

String? validatorInputNni(BuildContext context, String? value, String? pays) {
  if (pays == 'Mauritania') {
    if (value!.isEmpty) {
      return getTranslated(context, "nnicourtMR");
    } else {
      if (value.length == 10) {
        return null;
      }
      return getTranslated(context, "nnicourtMR");
    }
  }
  if (pays == 'Guinee') {
    if (value!.isEmpty) {
      return getTranslated(context, "nnicourtGN");
    } else {
      if (value.length == 15) {
        return null;
      }
      return getTranslated(context, "nnicourtGN");
    }
  }
  return getTranslated(context, "nnicourtGN");
}

int? maxLengthNumber(String? pays) {
  if (pays == 'Mauritania') {
    return 8;
  }
  if (pays == 'Guinee') {
    return 9;
  }
  return null;
}

int? maxLengthNni(String? pays) {
  if (pays == 'Mauritania') {
    return 10;
  }
  if (pays == 'Guinee') {
    return 15;
  }
  return null;
}

String baseParPays(String pays) {
  // print(pays);
  switch (pays) {
    case 'Mauritania':
      return "https://api.bcipaymr.com/";
    // return "https://bcipay-mr-dev.nw.r.appspot.com/";;
    case 'Guinee':
      return "https://bcipaygn-dev.nw.r.appspot.com/";
    case 'Mali':
      return "https://icash-379023.ey.r.appspot.com/";
    case 'Senegal':
      return "https://icash-379023.ey.r.appspot.com/";
    default:
      return "https://bcipay-mr-dev.nw.r.appspot.com/";
  }
}

// String baseParPays(String pays) {
//   // print(pays);
//   switch (pays) {
//     case 'Mauritania':
//       return return "https://api.bcipaymr.com/";
//     case 'Guinee':
//       return "https://bcipaygn-dev.nw.r.appspot.com/";
//     case 'Mali':
//       return "https://icash-379023.ey.r.appspot.com/";
//     case 'Senegal':
//       return "https://icash-379023.ey.r.appspot.com/";
//     default:
//       return "https://bcipay-mr-dev.nw.r.appspot.com/";
//   }
// }

String currencyParPay(String pays) {
  // print(pays);
  switch (pays) {
    case 'Mauritania':
      return "Mru";
    case 'Guinee':
      return "GNF";
    // case 'Mali':
    //   return "";
    // case 'Senegal':
    //   return "";
    default:
      return "Mru";
  }
}

Future<void> launchCall(String pays) async {
  try {
    if (pays == 'Mauritania') {
      await launchUrl(Uri.parse('tel:28584000'));
    } else if (pays == 'Guinee') {
      await launchUrl(Uri.parse('tel:140'));
    } else {
      await launchUrl(Uri.parse('tel:28584000'));
    }
  } catch (e) {
    throw 'Could not launch the call';
  }
}

String phoneNumber(String? pays) {
  // print(pays);
  switch (pays) {
    case 'Mauritania':
      return "28 58 40 00";
    case 'Guinee':
      return "140";
    // case 'Mali':
    //   return "";
    // case 'Senegal':
    //   return "";
    default:
      return "28 58 40 00";
  }
}

Future<void> launchWhatsapp(String pays) async {
  try {
    if (pays == 'Mauritania') {
      await launchUrl(Uri.parse("whatsapp://send?phone=+22228584000"));
    } else if (pays == 'Guinee') {
      await launchUrl(Uri.parse("whatsapp://send?phone=+224610140140"));
    } else {
      await launchUrl(Uri.parse("whatsapp://send?phone=+22228584000"));
    }
  } catch (e) {
    throw 'Could not launch the call';
  }
}

String whatsappNumber(String? pays) {
  // print(pays);
  switch (pays) {
    case 'Mauritania':
      return "28 58 40 00";
    case 'Guinee':
      return "610 140 140";
    // case 'Mali':
    //   return "";
    // case 'Senegal':
    //   return "";
    default:
      return "28 58 40 00";
  }
}

Future<void> launchMail(String pays) async {
  try {
    if (pays == 'Mauritania') {
      await launchUrl(
          Uri.parse("mailto:contact@bcipay.mr?subj20pluginect=''&body=''"));
    } else if (pays == 'Guinee') {
      await launchUrl(Uri.parse(
          "mailto:supportclient@bci-banque.com?subj20pluginect=''&body=''"));
    } else {
      await launchUrl(
          Uri.parse("mailto:contact@bcipay.mr?subj20pluginect=''&body=''"));
    }
  } catch (e) {
    throw 'Could not launch the call';
  }
}

String mailText(String? pays) {
  // print(pays);
  switch (pays) {
    case 'Mauritania':
      return "contact@bcipay.mr";
    case 'Guinee':
      return "supportclient@bci-banque.com";
    // case 'Mali':
    //   return "";
    // case 'Senegal':
    //   return "";
    default:
      return "contact@bcipay.mr";
  }
}
