/**
 * PPKReactBridge.m
 * PPKReactBridge
 *
 * Copyright (c) 2017 by Uepaa AG, Zürich, Switzerland.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#import "PPKReactBridge.h"
#import <P2PKit/P2PKit.h>

@interface PPKReactBridge() <PPKControllerDelegate> {
    BOOL hasListeners_;
}
@end


@implementation PPKReactBridge

RCT_EXPORT_MODULE()

#pragma mark - API

RCT_EXPORT_METHOD(enable:(NSString*)appKey) {

    dispatch_async(dispatch_get_main_queue(), ^{

        @try {
            [PPKController enableWithConfiguration:appKey observer:self];
        } @catch (NSException *exception) {
            [self invokePluginResultErrorWithString:[NSString stringWithFormat:@"Failed to enable p2pkit with exception %@", exception.description]];
        }
    });
}

RCT_EXPORT_METHOD(disable) {

    dispatch_async(dispatch_get_main_queue(), ^{

        [PPKController disable];
        [self invokePluginResultWithMethodName:@"onDisabled" parms:nil];
    });
}

RCT_EXPORT_METHOD(getMyPeerId)  {


    dispatch_async(dispatch_get_main_queue(), ^{

        if (![PPKController isEnabled]) {
            [self invokePluginResultErrorWithString:@"p2pkit is not enabled"];
            return;
        }

        [self invokePluginResultWithMethodName:@"onGetMyPeerId" parms:@{@"myPeerId":[PPKController myPeerID]}];
    });
}

RCT_EXPORT_METHOD(startDiscovery:(NSString*)discoveryInfoBase64 options:(NSDictionary *)options)  {

    dispatch_async(dispatch_get_main_queue(), ^{

        bool stateRestoration = NO;

        if ([options objectForKey:@"stateRestoration"]) {
            stateRestoration = options[@"stateRestoration"];
        }

        if (![PPKController isEnabled]) {
            [self invokePluginResultErrorWithString:@"p2pkit is not enabled"];
            return;
        }

        if (!discoveryInfoBase64) {
            [self invokePluginResultErrorWithString:@"could not extract discovery info"];
            return;
        }

        NSData *discoveryInfo = [[NSData alloc] initWithBase64EncodedString:discoveryInfoBase64 options:0];

        if (!discoveryInfo) {
            [self invokePluginResultErrorWithString:@"could not convert base64 discovery info to data"];
            return;
        }

        @try {
            [PPKController startDiscoveryWithDiscoveryInfo:discoveryInfo stateRestoration:stateRestoration];
        } @catch (NSException *exception) {
            [self invokePluginResultErrorWithString:[NSString stringWithFormat:@"Failed to start discovery with exception %@", exception.description]];
        }
    });
}

RCT_EXPORT_METHOD(stopDiscovery)  {

    dispatch_async(dispatch_get_main_queue(), ^{

        if (![PPKController isEnabled]) {
            [self invokePluginResultErrorWithString:@"p2pkit is not enabled"];
            return;
        }

        [PPKController stopDiscovery];
    });
}

RCT_EXPORT_METHOD(enableProximityRanging)  {

    dispatch_async(dispatch_get_main_queue(), ^{

        if (![PPKController isEnabled]) {
            [self invokePluginResultErrorWithString:@"p2pkit is not enabled"];
            return;
        }

        [PPKController enableProximityRanging];
    });
}

RCT_EXPORT_METHOD(pushNewDiscoveryInfo:(NSString*)discoveryInfoBase64)  {

    dispatch_async(dispatch_get_main_queue(), ^{

        if (![PPKController isEnabled] || [PPKController discoveryState] == PPKDiscoveryStateStopped) {
            [self invokePluginResultErrorWithString:@"p2pkit is not enabled or discovery is not running"];
            return;
        }

        if (!discoveryInfoBase64) {
            [self invokePluginResultErrorWithString:@"could not extract discovery info"];
            return;
        }

        NSData *discoveryInfo = [[NSData alloc] initWithBase64EncodedString:discoveryInfoBase64 options:0];

        if (!discoveryInfo) {
            [self invokePluginResultErrorWithString:@"could not convert base64 discovery info to data"];
            return;
        }

        @try {
            [PPKController pushNewDiscoveryInfo:discoveryInfo];
        } @catch (NSException *exception) {
            [self invokePluginResultErrorWithString:[NSString stringWithFormat:@"Failed to update discovery info with exception %@", exception.description]];
        }
    });
}

RCT_EXPORT_METHOD(getDiscoveryPowerMode)  {

    dispatch_async(dispatch_get_main_queue(), ^{

        if (![PPKController isEnabled] || [PPKController discoveryState] == PPKDiscoveryStateStopped) {
            [self invokePluginResultErrorWithString:@"p2pkit is not enabled or discovery is not running"];
            return;
        }

        [self invokePluginResultWithMethodName:@"onGetDiscoveryPowerMode" parms:@{@"discoveryPowerMode":@"NOT_AVAILABLE_ON_IOS"}];
    });
}

RCT_EXPORT_METHOD(setDiscoveryPowerMode:(NSString*)discoveryPowerMode)  {

    dispatch_async(dispatch_get_main_queue(), ^{

        [self invokePluginResultErrorWithString:@"Power modes are not available on iOS"];
    });
}

#pragma mark - PPKControllerDelegate

-(void)PPKControllerInitialized {

    [self invokePluginResultWithMethodName:@"onEnabled" parms:nil];
}

-(void)PPKControllerFailedWithError:(PPKErrorCode)error {

    [self invokePluginResultWithMethodName:@"onError" parms:@{@"platform":@"ios", @"errorCode":[NSNumber numberWithInt:error]}];
}

-(void)discoveryStateChanged:(PPKDiscoveryState)state {

    [self invokePluginResultWithMethodName:@"onDiscoveryStateChanged" parms:@{@"platform":@"ios", @"state":[NSNumber numberWithInt:state]}];
}

-(void)peerDiscovered:(PPKPeer *)peer {

    [self invokePluginResultWithMethodName:@"onPeerDiscovered" parms:[self createDictionaryFromPeer:peer]];
}

-(void)peerLost:(PPKPeer *)peer {

    [self invokePluginResultWithMethodName:@"onPeerLost" parms:[self createDictionaryFromPeer:peer]];
}

-(void)discoveryInfoUpdatedForPeer:(PPKPeer *)peer {

    [self invokePluginResultWithMethodName:@"onPeerUpdatedDiscoveryInfo" parms:[self createDictionaryFromPeer:peer]];
}

-(void)proximityStrengthChangedForPeer:(PPKPeer *)peer {

    [self invokePluginResultWithMethodName:@"onProximityStrengthChanged" parms:[self createDictionaryFromPeer:peer]];
}

#pragma mark - Helpers

-(void)invokePluginResultErrorWithString:(NSString*)errorString {

    if (!errorString) {
        return;
    }

    [self invokePluginResultWithMethodName:@"onException" parms:@{@"platform":@"ios",@"message":errorString}];
}

-(void)invokePluginResultWithMethodName:(NSString*)name parms:(NSDictionary*)parms {

    dispatch_async(dispatch_get_main_queue(), ^{

        if (!hasListeners_) {
            [PPKController disable];
            return;
        }

        if (!name) {
            return;
        }

        NSMutableDictionary *statusMessage = [NSMutableDictionary new];
        [statusMessage setObject:name forKey:@"methodName"];
        if(parms) [statusMessage setObject:parms forKey:@"parms"];

        [self sendEventWithName:@"callback" body:statusMessage];
    });
}

-(NSDictionary*)createDictionaryFromPeer:(PPKPeer*)peer {

    NSString *peerID = peer.peerID;
    NSString *discoveryInfo = [peer.discoveryInfo base64EncodedStringWithOptions:0];
    NSString *proximityStrength = [NSString stringWithFormat:@"%.0li", (long)peer.proximityStrength];

    return @{@"peerID":peerID, @"discoveryInfo":discoveryInfo, @"proximityStrength":proximityStrength};
}

#pragma mark - RCTEventEmitter override

-(void)startObserving {
    hasListeners_ = YES;
    [super startObserving];
}


-(void)stopObserving {
    hasListeners_ = NO;
    [super stopObserving];
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"callback"];
}

-(void)dealloc {
  if ([PPKController isEnabled]) {
    [PPKController disable];
  }
}
@end
