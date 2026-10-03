import UIKit
import Flutter
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCcTubNsHkaESRHsEh9Y2h11sYpWIM1shU")

    // Nécessaire pour que les notifications (FCM et flutter_local_notifications)
    // s'affichent et soient cliquables quand l'app est au premier plan.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

    GeneratedPluginRegistrant.register(with: self)

    // Demande le jeton APNs à Apple ; Firebase l'échange ensuite contre le jeton FCM.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
