//
//  AppDelegate.swift
//  LearningApp
//
//  Created by Brian Criscuolo on 6/4/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import UIKit
import MarketingCloudSDK
import SafariServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  let appID = "c1789ddf-7f30-4203-bf6d-902d9d0d9ef6"
  let accessToken = "c1uLm18DgHfoxbT4dc6VRKRo"
  let appEndpoint = URL(string: "https://mcsfwcp0sprjghvyljylgbzt-n1y.device.marketingcloudapis.com/")!
  let mid = "1303591"

  // MobilePush SDK: REQUIRED IMPLEMENTATION
  func configureMarketingCloudSDK() {
    // Use the builder method to configure the SDK for usage. This gives you the maximum flexibility in SDK configuration.
    // The builder lets you configure the SDK parameters at runtime.
    let configuration = PushConfigBuilder(appId: appID)
      .setAccessToken(accessToken)
      .setMarketingCloudServerUrl(appEndpoint)
      .setMid(mid)
      .build()

    SFMCSdk.initializeSdk(
      ConfigBuilder()
        .setPush(config: configuration) { result in
          switch result {
          case .cancelled:
            fatalError("Cancelled")

          case .error:
            fatalError("SDK Start returned error")

          case .timeout:
            fatalError("Timeout")

          case .success:
            // The SDK has been fully configured and is ready for use!

            // Enable logging for debugging. Not recommended for production apps, as significant data
            // about MobilePush will be logged to the console.
#if DEBUG
            SFMCSdk.setLogger(logLevel: .debug)
#endif

            // Set the MarketingCloudSDKURLHandlingDelegate to a class adhering to the protocol.
            // In this example, the AppDelegate class adheres to the protocol (see below)
            // and handles URLs passed back from the SDK.
            // For more information, see https://salesforce-marketingcloud.github.io/MarketingCloudSDK-iOS/sdk-implementation/implementation-urlhandling.html
            SFMCSdk.mp.setURLHandlingDelegate(self)

            // Make sure to dispatch this to the main thread, as UNUserNotificationCenter will present UI.
            DispatchQueue.main.async {
              // Set the UNUserNotificationCenterDelegate to a class adhering to thie protocol.
              // In this exmple, the AppDelegate class adheres to the protocol (see below)
              // and handles Notification Center delegate methods from iOS.
              UNUserNotificationCenter.current().delegate = self

              // Request authorization from the user for push notification alerts.
              UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {(_ granted: Bool, _ error: Error?) -> Void in

              })

              // In any case, your application should register for remote notifications *each time* your application
              // launches to ensure that the push token used by MobilePush (for silent push) is updated if necessary.

              // Registering in this manner does *not* mean that a user will see a notification - it only means
              // that the application will receive a unique push token from iOS.
              UIApplication.shared.registerForRemoteNotifications()
            }
          }
        }
        .build()
    )
  }

  // MobilePush SDK: REQUIRED IMPLEMENTATION
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    self.configureMarketingCloudSDK()
    return true
  }

  // MobilePush SDK: REQUIRED IMPLEMENTATION
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    SFMCSdk.mp.setDeviceToken(deviceToken)
  }


  // MobilePush SDK: REQUIRED IMPLEMENTATION
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print(error)
  }

  // MobilePush SDK: REQUIRED IMPLEMENTATION

  /** This delegate method offers an opportunity for applications with the "remote-notification" background mode to fetch appropriate new data in response to an incoming remote notification. You should call the fetchCompletionHandler as soon as you're finished performing that operation, so the system can accurately estimate its power and data cost.

   This method will be invoked even if the application was launched or resumed because of the remote notification. The respective delegate methods will be invoked first. Note that this behavior is in contrast to application:didReceiveRemoteNotification:, which is not called in those cases, and which will not be invoked if this method is implemented. **/
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    SFMCSdk.mp.setNotificationUserInfo(userInfo)
    completionHandler(.newData)
  }
}

// MobilePush SDK: REQUIRED IMPLEMENTATION
extension AppDelegate: URLHandlingDelegate {
  /**
   This method, if implemented, can be called when a Alert+CloudPage, Alert+OpenDirect, Alert+Inbox or Inbox message is processed by the SDK.
   Implementing this method allows the application to handle the URL from Marketing Cloud data.

   Prior to the MobilePush SDK version 6.0.0, the SDK would automatically handle these URLs and present them using a SFSafariViewController.

   Given security risks inherent in URLs and web pages (Open Redirect vulnerabilities, especially), the responsibility of processing the URL shall be held by the application implementing the MobilePush SDK. This reduces risk to the application by affording full control over processing, presentation and security to the application code itself.

   @param url value NSURL sent with the Location, CloudPage, OpenDirect or Inbox message
   @param type value NSInteger enumeration of the MobilePush source type of this URL
   */
  func sfmc_handleURL(_ url: URL, type: String) {
    // Very simply, send the URL returned from the MobilePush SDK to UIApplication to handle correctly.
    UIApplication.shared.open(url, options: [:],
                              completionHandler: {
      (success) in
      print("Open \(url): \(success)")
    })
  }
}

// MobilePush SDK: REQUIRED IMPLEMENTATION
extension AppDelegate: UNUserNotificationCenterDelegate {

  // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

    // Required: tell the MarketingCloudSDK about the notification. This will collect MobilePush analytics
    // and process the notification on behalf of your application.
    SFMCSdk.mp.setNotificationRequest(response.notification.request)
    completionHandler()
  }

  // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler(.alert)
  }

}
