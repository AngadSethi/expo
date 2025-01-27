/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <ABI46_0_0React/ABI46_0_0RCTPushNotificationManager.h>

#import <UserNotifications/UserNotifications.h>

#import <ABI46_0_0FBReactNativeSpec/ABI46_0_0FBReactNativeSpec.h>
#import <ABI46_0_0React/ABI46_0_0RCTBridge.h>
#import <ABI46_0_0React/ABI46_0_0RCTConvert.h>
#import <ABI46_0_0React/ABI46_0_0RCTUtils.h>

#import "ABI46_0_0RCTPushNotificationPlugins.h"

NSString *const ABI46_0_0RCTRemoteNotificationReceived = @"RemoteNotificationReceived";

static NSString *const kLocalNotificationReceived = @"LocalNotificationReceived";
static NSString *const kRemoteNotificationsRegistered = @"RemoteNotificationsRegistered";
static NSString *const kRemoteNotificationRegistrationFailed = @"RemoteNotificationRegistrationFailed";

static NSString *const kErrorUnableToRequestPermissions = @"E_UNABLE_TO_REQUEST_PERMISSIONS";

#if !TARGET_OS_UIKITFORMAC
@implementation ABI46_0_0RCTConvert (NSCalendarUnit)

ABI46_0_0RCT_ENUM_CONVERTER(NSCalendarUnit,
                   (@{
                      @"year": @(NSCalendarUnitYear),
                      @"month": @(NSCalendarUnitMonth),
                      @"week": @(NSCalendarUnitWeekOfYear),
                      @"day": @(NSCalendarUnitDay),
                      @"hour": @(NSCalendarUnitHour),
                      @"minute": @(NSCalendarUnitMinute)
                      }),
                   0,
                   integerValue)

@end

@interface ABI46_0_0RCTPushNotificationManager () <ABI46_0_0NativePushNotificationManagerIOSSpec>
@property (nonatomic, strong) NSMutableDictionary *remoteNotificationCallbacks;
@end

@implementation ABI46_0_0RCTConvert (UILocalNotification)

+ (UILocalNotification *)UILocalNotification:(id)json
{
  NSDictionary<NSString *, id> *details = [self NSDictionary:json];
  BOOL isSilent = [ABI46_0_0RCTConvert BOOL:details[@"isSilent"]];
  UILocalNotification *notification = [UILocalNotification new];
  notification.alertTitle = [ABI46_0_0RCTConvert NSString:details[@"alertTitle"]];
  notification.fireDate = [ABI46_0_0RCTConvert NSDate:details[@"fireDate"]] ?: [NSDate date];
  notification.alertBody = [ABI46_0_0RCTConvert NSString:details[@"alertBody"]];
  notification.alertAction = [ABI46_0_0RCTConvert NSString:details[@"alertAction"]];
  notification.userInfo = [ABI46_0_0RCTConvert NSDictionary:details[@"userInfo"]];
  notification.category = [ABI46_0_0RCTConvert NSString:details[@"category"]];
  notification.repeatInterval = [ABI46_0_0RCTConvert NSCalendarUnit:details[@"repeatInterval"]];
  if (details[@"applicationIconBadgeNumber"]) {
    notification.applicationIconBadgeNumber = [ABI46_0_0RCTConvert NSInteger:details[@"applicationIconBadgeNumber"]];
  }
  if (!isSilent) {
    notification.soundName = [ABI46_0_0RCTConvert NSString:details[@"soundName"]] ?: UILocalNotificationDefaultSoundName;
  }
  return notification;
}

ABI46_0_0RCT_ENUM_CONVERTER(UIBackgroundFetchResult, (@{
  @"UIBackgroundFetchResultNewData": @(UIBackgroundFetchResultNewData),
  @"UIBackgroundFetchResultNoData": @(UIBackgroundFetchResultNoData),
  @"UIBackgroundFetchResultFailed": @(UIBackgroundFetchResultFailed),
}), UIBackgroundFetchResultNoData, integerValue)

@end
#else
@interface ABI46_0_0RCTPushNotificationManager () <ABI46_0_0NativePushNotificationManagerIOSSpec>
@end
#endif // TARGET_OS_UIKITFORMAC

@implementation ABI46_0_0RCTPushNotificationManager

#if !TARGET_OS_UIKITFORMAC

static NSDictionary *ABI46_0_0RCTFormatLocalNotification(UILocalNotification *notification)
{
  NSMutableDictionary *formattedLocalNotification = [NSMutableDictionary dictionary];
  if (notification.fireDate) {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSString *fireDateString = [formatter stringFromDate:notification.fireDate];
    formattedLocalNotification[@"fireDate"] = fireDateString;
  }
  formattedLocalNotification[@"alertAction"] = ABI46_0_0RCTNullIfNil(notification.alertAction);
  formattedLocalNotification[@"alertBody"] = ABI46_0_0RCTNullIfNil(notification.alertBody);
  formattedLocalNotification[@"applicationIconBadgeNumber"] = @(notification.applicationIconBadgeNumber);
  formattedLocalNotification[@"category"] = ABI46_0_0RCTNullIfNil(notification.category);
  formattedLocalNotification[@"soundName"] = ABI46_0_0RCTNullIfNil(notification.soundName);
  formattedLocalNotification[@"userInfo"] = ABI46_0_0RCTNullIfNil(ABI46_0_0RCTJSONClean(notification.userInfo));
  formattedLocalNotification[@"remote"] = @NO;
  return formattedLocalNotification;
}

static NSDictionary *ABI46_0_0RCTFormatUNNotification(UNNotification *notification)
{
  NSMutableDictionary *formattedNotification = [NSMutableDictionary dictionary];
  UNNotificationContent *content = notification.request.content;

  formattedNotification[@"identifier"] = notification.request.identifier;

  if (notification.date) {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSString *dateString = [formatter stringFromDate:notification.date];
    formattedNotification[@"date"] = dateString;
  }

  formattedNotification[@"title"] = ABI46_0_0RCTNullIfNil(content.title);
  formattedNotification[@"body"] = ABI46_0_0RCTNullIfNil(content.body);
  formattedNotification[@"category"] = ABI46_0_0RCTNullIfNil(content.categoryIdentifier);
  formattedNotification[@"thread-id"] = ABI46_0_0RCTNullIfNil(content.threadIdentifier);
  formattedNotification[@"userInfo"] = ABI46_0_0RCTNullIfNil(ABI46_0_0RCTJSONClean(content.userInfo));

  return formattedNotification;
}

#endif // TARGET_OS_UIKITFORMAC

ABI46_0_0RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

#if !TARGET_OS_UIKITFORMAC
- (void)startObserving
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleLocalNotificationReceived:)
                                               name:kLocalNotificationReceived
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRemoteNotificationReceived:)
                                               name:ABI46_0_0RCTRemoteNotificationReceived
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRemoteNotificationsRegistered:)
                                               name:kRemoteNotificationsRegistered
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRemoteNotificationRegistrationError:)
                                               name:kRemoteNotificationRegistrationFailed
                                             object:nil];
}

- (void)stopObserving
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"localNotificationReceived",
           @"remoteNotificationReceived",
           @"remoteNotificationsRegistered",
           @"remoteNotificationRegistrationError"];
}

+ (void)didRegisterUserNotificationSettings:(__unused UIUserNotificationSettings *)notificationSettings
{
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  NSMutableString *hexString = [NSMutableString string];
  NSUInteger deviceTokenLength = deviceToken.length;
  const unsigned char *bytes = reinterpret_cast<const unsigned char *>(deviceToken.bytes);
  for (NSUInteger i = 0; i < deviceTokenLength; i++) {
    [hexString appendFormat:@"%02x", bytes[i]];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteNotificationsRegistered
                                                      object:self
                                                    userInfo:@{@"deviceToken" : [hexString copy]}];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteNotificationRegistrationFailed
                                                      object:self
                                                    userInfo:@{@"error": error}];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)notification
{
  NSDictionary *userInfo = @{@"notification": notification};
  [[NSNotificationCenter defaultCenter] postNotificationName:ABI46_0_0RCTRemoteNotificationReceived
                                                      object:self
                                                    userInfo:userInfo];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)notification
              fetchCompletionHandler:(ABI46_0_0RCTRemoteNotificationCallback)completionHandler
{
  NSDictionary *userInfo = @{@"notification": notification, @"completionHandler": completionHandler};
  [[NSNotificationCenter defaultCenter] postNotificationName:ABI46_0_0RCTRemoteNotificationReceived
                                                      object:self
                                                    userInfo:userInfo];
}

+ (void)didReceiveLocalNotification:(UILocalNotification *)notification
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kLocalNotificationReceived
                                                      object:self
                                                    userInfo:ABI46_0_0RCTFormatLocalNotification(notification)];
}

- (void)handleLocalNotificationReceived:(NSNotification *)notification
{
  [self sendEventWithName:@"localNotificationReceived" body:notification.userInfo];
}

- (void)handleRemoteNotificationReceived:(NSNotification *)notification
{
  NSMutableDictionary *remoteNotification = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo[@"notification"]];
  ABI46_0_0RCTRemoteNotificationCallback completionHandler = notification.userInfo[@"completionHandler"];
  NSString *notificationId = [[NSUUID UUID] UUIDString];
  remoteNotification[@"notificationId"] = notificationId;
  remoteNotification[@"remote"] = @YES;
  if (completionHandler) {
    if (!self.remoteNotificationCallbacks) {
      // Lazy initialization
      self.remoteNotificationCallbacks = [NSMutableDictionary dictionary];
    }
    self.remoteNotificationCallbacks[notificationId] = completionHandler;
  }

  [self sendEventWithName:@"remoteNotificationReceived" body:remoteNotification];
}

- (void)handleRemoteNotificationsRegistered:(NSNotification *)notification
{
  [self sendEventWithName:@"remoteNotificationsRegistered" body:notification.userInfo];
}

- (void)handleRemoteNotificationRegistrationError:(NSNotification *)notification
{
  NSError *error = notification.userInfo[@"error"];
  NSDictionary *errorDetails = @{
    @"message": error.localizedDescription,
    @"code": @(error.code),
    @"details": error.userInfo,
  };
  [self sendEventWithName:@"remoteNotificationRegistrationError" body:errorDetails];
}

ABI46_0_0RCT_EXPORT_METHOD(onFinishRemoteNotification:(NSString *)notificationId fetchResult:(NSString *)fetchResult) {
  UIBackgroundFetchResult result = [ABI46_0_0RCTConvert UIBackgroundFetchResult:fetchResult];
  ABI46_0_0RCTRemoteNotificationCallback completionHandler = self.remoteNotificationCallbacks[notificationId];
  if (!completionHandler) {
    ABI46_0_0RCTLogError(@"There is no completion handler with notification id: %@", notificationId);
    return;
  }
  completionHandler(result);
  [self.remoteNotificationCallbacks removeObjectForKey:notificationId];
}

/**
 * Update the application icon badge number on the home screen
 */
ABI46_0_0RCT_EXPORT_METHOD(setApplicationIconBadgeNumber:(double)number)
{
  ABI46_0_0RCTSharedApplication().applicationIconBadgeNumber = number;
}

/**
 * Get the current application icon badge number on the home screen
 */
ABI46_0_0RCT_EXPORT_METHOD(getApplicationIconBadgeNumber:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  callback(@[@(ABI46_0_0RCTSharedApplication().applicationIconBadgeNumber)]);
}

ABI46_0_0RCT_EXPORT_METHOD(requestPermissions:(ABI46_0_0JS::NativePushNotificationManagerIOS::SpecRequestPermissionsPermission &)permissions
                 resolve:(ABI46_0_0RCTPromiseResolveBlock)resolve
                 reject:(ABI46_0_0RCTPromiseRejectBlock)reject)
{
   if (ABI46_0_0RCTRunningInAppExtension()) {
     reject(kErrorUnableToRequestPermissions, nil, ABI46_0_0RCTErrorWithMessage(@"Requesting push notifications is currently unavailable in an app extension"));
     return;
   }

  // Add a listener to make sure that startObserving has been called
  [self addListener:@"remoteNotificationsRegistered"];

  UIUserNotificationType types = UIUserNotificationTypeNone;

  if (permissions.alert()) {
    types |= UIUserNotificationTypeAlert;
  }
  if (permissions.badge()) {
    types |= UIUserNotificationTypeBadge;
  }
  if (permissions.sound()) {
    types |= UIUserNotificationTypeSound;
  }

  [UNUserNotificationCenter.currentNotificationCenter
   requestAuthorizationWithOptions:types
   completionHandler:^(BOOL granted, NSError *_Nullable error) {
    if (error != NULL) {
      reject(@"-1", @"Error - Push authorization request failed.", error);
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [ABI46_0_0RCTSharedApplication() registerForRemoteNotifications];
        [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
           resolve(ABI46_0_0RCTPromiseResolveValueForUNNotificationSettings(settings));
        }];
      });
    }
  }];
}

ABI46_0_0RCT_EXPORT_METHOD(abandonPermissions)
{
  [ABI46_0_0RCTSharedApplication() unregisterForRemoteNotifications];
}

ABI46_0_0RCT_EXPORT_METHOD(checkPermissions:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  if (ABI46_0_0RCTRunningInAppExtension()) {
    callback(@[ABI46_0_0RCTSettingsDictForUNNotificationSettings(NO, NO, NO, NO, NO, NO, UNAuthorizationStatusNotDetermined)]);
    return;
  }

  [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
    callback(@[ABI46_0_0RCTPromiseResolveValueForUNNotificationSettings(settings)]);
  }];
}

static inline NSDictionary *ABI46_0_0RCTPromiseResolveValueForUNNotificationSettings(UNNotificationSettings* _Nonnull settings) {
  return ABI46_0_0RCTSettingsDictForUNNotificationSettings(settings.alertSetting == UNNotificationSettingEnabled,
                                                  settings.badgeSetting == UNNotificationSettingEnabled,
                                                  settings.soundSetting == UNNotificationSettingEnabled,
                                                  settings.criticalAlertSetting == UNNotificationSettingEnabled,
                                                  settings.lockScreenSetting == UNNotificationSettingEnabled,
                                                  settings.notificationCenterSetting == UNNotificationSettingEnabled,
                                                  settings.authorizationStatus);
}

static inline NSDictionary *ABI46_0_0RCTSettingsDictForUNNotificationSettings(BOOL alert, BOOL badge, BOOL sound, BOOL critical, BOOL lockScreen, BOOL notificationCenter, UNAuthorizationStatus authorizationStatus) {
  return @{@"alert": @(alert), @"badge": @(badge), @"sound": @(sound), @"critical": @(critical), @"lockScreen": @(lockScreen), @"notificationCenter": @(notificationCenter), @"authorizationStatus": @(authorizationStatus)};
}

ABI46_0_0RCT_EXPORT_METHOD(presentLocalNotification:(ABI46_0_0JS::NativePushNotificationManagerIOS::Notification &)notification)
{
  NSMutableDictionary *notificationDict = [NSMutableDictionary new];
  notificationDict[@"alertTitle"] = notification.alertTitle();
  notificationDict[@"alertBody"] = notification.alertBody();
  notificationDict[@"alertAction"] = notification.alertAction();
  notificationDict[@"userInfo"] = notification.userInfo();
  notificationDict[@"category"] = notification.category();
  notificationDict[@"repeatInterval"] = notification.repeatInterval();
  if (notification.fireDate()) {
    notificationDict[@"fireDate"] = @(*notification.fireDate());
  }
  if (notification.applicationIconBadgeNumber()) {
    notificationDict[@"applicationIconBadgeNumber"] = @(*notification.applicationIconBadgeNumber());
  }
  if (notification.isSilent()) {
    notificationDict[@"isSilent"] = @(*notification.isSilent());
    if ([notificationDict[@"isSilent"] isEqualToNumber:@(NO)]) {
      notificationDict[@"soundName"] = notification.soundName();
    }
  }
  [ABI46_0_0RCTSharedApplication() presentLocalNotificationNow:[ABI46_0_0RCTConvert UILocalNotification:notificationDict]];
}

ABI46_0_0RCT_EXPORT_METHOD(scheduleLocalNotification:(ABI46_0_0JS::NativePushNotificationManagerIOS::Notification &)notification)
{
  NSMutableDictionary *notificationDict = [NSMutableDictionary new];
  notificationDict[@"alertTitle"] = notification.alertTitle();
  notificationDict[@"alertBody"] = notification.alertBody();
  notificationDict[@"alertAction"] = notification.alertAction();
  notificationDict[@"userInfo"] = notification.userInfo();
  notificationDict[@"category"] = notification.category();
  notificationDict[@"repeatInterval"] = notification.repeatInterval();
  if (notification.fireDate()) {
    notificationDict[@"fireDate"] = @(*notification.fireDate());
  }
  if (notification.applicationIconBadgeNumber()) {
    notificationDict[@"applicationIconBadgeNumber"] = @(*notification.applicationIconBadgeNumber());
  }
  if (notification.isSilent()) {
    notificationDict[@"isSilent"] = @(*notification.isSilent());
    if ([notificationDict[@"isSilent"] isEqualToNumber:@(NO)]) {
      notificationDict[@"soundName"] = notification.soundName();
    }
  }
  [ABI46_0_0RCTSharedApplication() scheduleLocalNotification:[ABI46_0_0RCTConvert UILocalNotification:notificationDict]];
}

ABI46_0_0RCT_EXPORT_METHOD(cancelAllLocalNotifications)
{
  [ABI46_0_0RCTSharedApplication() cancelAllLocalNotifications];
}

ABI46_0_0RCT_EXPORT_METHOD(cancelLocalNotifications:(NSDictionary<NSString *, id> *)userInfo)
{
  for (UILocalNotification *notification in ABI46_0_0RCTSharedApplication().scheduledLocalNotifications) {
    __block BOOL matchesAll = YES;
    NSDictionary<NSString *, id> *notificationInfo = notification.userInfo;
    // Note: we do this with a loop instead of just `isEqualToDictionary:`
    // because we only require that all specified userInfo values match the
    // notificationInfo values - notificationInfo may contain additional values
    // which we don't care about.
    [userInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
      if (![notificationInfo[key] isEqual:obj]) {
        matchesAll = NO;
        *stop = YES;
      }
    }];
    if (matchesAll) {
      [ABI46_0_0RCTSharedApplication() cancelLocalNotification:notification];
    }
  }
}

ABI46_0_0RCT_EXPORT_METHOD(getInitialNotification:(ABI46_0_0RCTPromiseResolveBlock)resolve
                  reject:(__unused ABI46_0_0RCTPromiseRejectBlock)reject)
{
  NSMutableDictionary<NSString *, id> *initialNotification =
    [self.bridge.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] mutableCopy];

  UILocalNotification *initialLocalNotification =
    self.bridge.launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];

  if (initialNotification) {
    initialNotification[@"remote"] = @YES;
    resolve(initialNotification);
  } else if (initialLocalNotification) {
    resolve(ABI46_0_0RCTFormatLocalNotification(initialLocalNotification));
  } else {
    resolve((id)kCFNull);
  }
}

ABI46_0_0RCT_EXPORT_METHOD(getScheduledLocalNotifications:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  NSArray<UILocalNotification *> *scheduledLocalNotifications = ABI46_0_0RCTSharedApplication().scheduledLocalNotifications;
  NSMutableArray<NSDictionary *> *formattedScheduledLocalNotifications = [NSMutableArray new];
  for (UILocalNotification *notification in scheduledLocalNotifications) {
    [formattedScheduledLocalNotifications addObject:ABI46_0_0RCTFormatLocalNotification(notification)];
  }
  callback(@[formattedScheduledLocalNotifications]);
}

ABI46_0_0RCT_EXPORT_METHOD(removeAllDeliveredNotifications)
{
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center removeAllDeliveredNotifications];
}

ABI46_0_0RCT_EXPORT_METHOD(removeDeliveredNotifications:(NSArray<NSString *> *)identifiers)
{
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center removeDeliveredNotificationsWithIdentifiers:identifiers];
}

ABI46_0_0RCT_EXPORT_METHOD(getDeliveredNotifications:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *_Nonnull notifications) {
    NSMutableArray<NSDictionary *> *formattedNotifications = [NSMutableArray new];

    for (UNNotification *notification in notifications) {
      [formattedNotifications addObject:ABI46_0_0RCTFormatUNNotification(notification)];
    }
    callback(@[formattedNotifications]);
  }];
}

ABI46_0_0RCT_EXPORT_METHOD(getAuthorizationStatus:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings)  {
    callback(@[@(settings.authorizationStatus)]);
  }];
}

#else // TARGET_OS_UIKITFORMAC

ABI46_0_0RCT_EXPORT_METHOD(onFinishRemoteNotification:(NSString *)notificationId fetchResult:(NSString *)fetchResult)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(setApplicationIconBadgeNumber:(double)number)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(getApplicationIconBadgeNumber:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(requestPermissions:(ABI46_0_0JS::NativePushNotificationManagerIOS::SpecRequestPermissionsPermission &)permissions
                 resolve:(ABI46_0_0RCTPromiseResolveBlock)resolve
                 reject:(ABI46_0_0RCTPromiseRejectBlock)reject)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(abandonPermissions)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(checkPermissions:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(presentLocalNotification:(ABI46_0_0JS::NativePushNotificationManagerIOS::Notification &)notification)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(scheduleLocalNotification:(ABI46_0_0JS::NativePushNotificationManagerIOS::Notification &)notification)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(cancelAllLocalNotifications)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(cancelLocalNotifications:(NSDictionary<NSString *, id> *)userInfo)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(getInitialNotification:(ABI46_0_0RCTPromiseResolveBlock)resolve
                  reject:(__unused ABI46_0_0RCTPromiseRejectBlock)reject)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(getScheduledLocalNotifications:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(removeAllDeliveredNotifications)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(removeDeliveredNotifications:(NSArray<NSString *> *)identifiers)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(getDeliveredNotifications:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

ABI46_0_0RCT_EXPORT_METHOD(getAuthorizationStatus:(ABI46_0_0RCTResponseSenderBlock)callback)
{
  ABI46_0_0RCTLogError(@"Not implemented: %@", NSStringFromSelector(_cmd));
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[];
}

#endif // TARGET_OS_UIKITFORMAC

- (std::shared_ptr<ABI46_0_0facebook::ABI46_0_0React::TurboModule>)getTurboModule:(const ABI46_0_0facebook::ABI46_0_0React::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<ABI46_0_0facebook::ABI46_0_0React::NativePushNotificationManagerIOSSpecJSI>(params);
}

@end

Class ABI46_0_0RCTPushNotificationManagerCls(void) {
  return ABI46_0_0RCTPushNotificationManager.class;
}
