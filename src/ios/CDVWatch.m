/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import <Cordova/CDV.h>
#import "CDVWatch.h"
#import "AppDelegate.h"
#import <objc/runtime.h>


@implementation AppDelegate (WatchSession)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector = @selector(swizzledApplication:didFinishLaunchingWithOptions:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        // ...
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);

        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark - Method Swizzling

- (BOOL)swizzledApplication:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    // Need to boot our watch session manager before anything else
    [WCSessionManager shared];
    return [self swizzledApplication:application didFinishLaunchingWithOptions:launchOptions];
}

@end

@interface WCSessionManager ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, strong) CDVWatch * plugin;

@end

@implementation WCSessionManager

+ (WCSessionManager *) shared {
    static WCSessionManager * shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[WCSessionManager alloc] init];
    });
    return shared;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        _session = [WCSession defaultSession];
        self.session.delegate = self;
        [self.session activateSession];
    }
    return self;
}

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {
    [[NSUserDefaults standardUserDefaults] setObject:applicationContext forKey:@"watch_context"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.plugin)
        [self.plugin session:session didReceiveApplicationContext:applicationContext];
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message {
    [self session:session didReceiveMessage:message replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
        // Empty block
    }];
}

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    if (message[@"local_notifications"]) {
        [self scheduleLocalNotification:message[@"local_notifications"] replyHandler:replyHandler];
    }
    if (self.plugin)
        [self.plugin session:session didReceiveMessage:message replyHandler:replyHandler];
}

- (void) scheduleLocalNotification:(NSDictionary *)notificationInfo replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"SteakMateWatchServices" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;
    }];
    if (notificationInfo[@"events"] && notificationInfo[@"start_date"]) {
        NSDate * start = notificationInfo[@"start_date"];
        NSLog(@"%@",start);
        NSArray * events = notificationInfo[@"events"];
        for (NSDictionary * event in events) {
            if ([event[@"expired"] boolValue]) {
                continue;
            }
            UILocalNotification * notif = [[UILocalNotification alloc] init];
            notif.fireDate = event[@"date"];
            notif.timeZone = [NSTimeZone defaultTimeZone];
            notif.alertBody = event[@"message"];
            notif.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        }
//        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
//            [self displayWatchWarning];
//        }
    } else if (notificationInfo[@"cancel"]) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
    NSMutableDictionary * replyInfo = notificationInfo.mutableCopy;
    replyInfo[@"background_id"] = @(_backgroundTask);
    replyHandler(replyInfo);
    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
    _backgroundTask = UIBackgroundTaskInvalid;
}

@end

@interface CDVWatch () <WCSessionDelegate> {}

@property (nonatomic, strong) WCSessionManager * sessionManager;
@property (nonatomic, strong) NSString * registeredCallbackId;

@end

@implementation CDVWatch

- (void) pluginInitialize {
    self.sessionManager = [WCSessionManager shared];
    self.sessionManager.plugin = self;
}


- (void) registerForWatchEvents:(CDVInvokedUrlCommand*)command {
    // Register a callback to send events to
    self.registeredCallbackId = command.callbackId;
    CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    result.keepCallback = @YES;
    [self.commandDelegate sendPluginResult:result callbackId:self.registeredCallbackId];
}

- (void) sendMessage:(CDVInvokedUrlCommand*)command {
    NSArray * args = command.arguments;
    NSDictionary * context = args[0];
    __block CDVPluginResult * result = nil;
    [self.sessionManager.session sendMessage:context replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:replyMessage];
    } errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"CDV Watch Error: %@", error.description);
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void) session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    // Communicate to the cordova webview instance with the registered callback
    // Looks like the cordova instance can never reply to this message
    CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    result.keepCallback = @YES;
    [self.commandDelegate sendPluginResult:result callbackId:self.registeredCallbackId];
}

- (void) transferUserInfo:(CDVInvokedUrlCommand*)command {
//    NSArray * args = command.arguments;
//    NSDictionary * context = args[0];
//    CDVPluginResult * result = nil;
//    [self.session transferUserInfo:context];
}

- (void) updateApplicationContext:(CDVInvokedUrlCommand*)command {
    NSArray * args = command.arguments;
    NSDictionary * context = args[0];
    CDVPluginResult * result = nil;
    NSError * error = nil;
    BOOL success = [self.sessionManager.session updateApplicationContext:context error:&error];
    if (!success || error) {
        NSLog(@"CDV Watch Error: %@", error.description);
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
}

- (void) session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {
    // Communicate to the cordova webview instance with the registered callback
    CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:applicationContext];
    result.keepCallback = @YES;
    [self.commandDelegate sendPluginResult:result callbackId:self.registeredCallbackId];
}

- (void) getLatestApplicationContext:(CDVInvokedUrlCommand*)command {
    NSDictionary * context = [[NSUserDefaults standardUserDefaults] objectForKey:@"watch_context"];
    if (!context) {
        context = [NSDictionary dictionary];
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:context];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

@end
