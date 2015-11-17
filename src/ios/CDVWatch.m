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
#import <WatchConnectivity/WatchConnectivity.h>
#import "CDVWatch.h"

@interface CDVWatch () {}

@property (nonatomic, strong) WCSession * session;

@end

@implementation CDVWatch

- (void) pluginInitialize {
    if ([WCSession isSupported]) {
        self.session = [WCSession defaultSession];
        self.session.delegate = self;
        [self.session activateSession];
    }
}

- (void) sendMessage:(CDVInvokedUrlCommand*)command {
    NSArray * args = command.arguments;
    NSDictionary * context = args[0];
    __block CDVPluginResult * result = nil;
    [self.session sendMessage:context replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:replyMessage];
    } errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"CDV Watch Error: %@", error.description);
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
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
    BOOL success = [self.session updateApplicationContext:context error:&error];
    if (!success || error) {
        NSLog(@"CDV Watch Error: %@", error.description);
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
}

@end
