//
//  RNGADInterstitialManager.m
//  RNAdMobManager
//
//  Created by Tue Hoang on 03/10/2021.
//  Copyright © 2021 accosine. All rights reserved.
//

#import "RNGADInterstitialManager.h"

NSString *const EVENT_INTERSTITIAL = @"admob_interstitial_event";
NSString *const EVENT_TYPE_LOADED = @"loaded";
NSString *const EVENT_TYPE_ERROR = @"error";
NSString *const EVENT_TYPE_OPENED = @"opened";
NSString *const EVENT_TYPE_CLICKED = @"clicked";
NSString *const EVENT_TYPE_IMPRESSION = @"impression";
NSString *const EVENT_TYPE_APPLICATION = @"left_application";
NSString *const EVENT_TYPE_CLOSED = @"closed";

NSString *const AD_ERROR_DOMAIN = @"RNGADErrorDomain";

@implementation RNGADInterstitialManager {
    bool hasListeners;
}

#pragma mark -
#pragma mark Module Setup

RCT_EXPORT_MODULE();

- (NSDictionary *)constantsToExport
{
    return @{
        @"EVENT_INTERSTITIAL": EVENT_INTERSTITIAL,
        @"EVENT_TYPE_LOADED": EVENT_TYPE_LOADED,
        @"EVENT_TYPE_ERROR": EVENT_TYPE_ERROR,
        @"EVENT_TYPE_OPENED": EVENT_TYPE_OPENED,
        @"EVENT_TYPE_CLICKED": EVENT_TYPE_CLICKED,
        @"EVENT_TYPE_IMPRESSION": EVENT_TYPE_IMPRESSION,
        @"EVENT_TYPE_APPLICATION": EVENT_TYPE_APPLICATION,
        @"EVENT_TYPE_CLOSED": EVENT_TYPE_CLOSED,
        @"AD_ERROR_DOMAIN": AD_ERROR_DOMAIN
    };
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (void)dealloc {
    [_interstitialMap removeAllObjects];
}

- (id)init {
    self = [super init];
    if (self) {
        self.interstitialMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(NSArray<NSString *> *)supportedEvents {
    return @[EVENT_INTERSTITIAL];
}

-(void)setAd:(GADInterstitialAd *)ad for:(NSString *)requestId {
    _interstitialMap[requestId] = ad;
}

-(GADInterstitialAd *)adForRequestId:(NSString *)requestId {
    return _interstitialMap[requestId];
}

-(void)startObserving {
    hasListeners = TRUE;
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    hasListeners = NO;
}

- (void)sendAdEvent:(NSString *)event
          requestId:(NSString *)requestId
               type:(NSString *)type
           adUnitId:(NSString *)adUnitId
              error:(nullable NSDictionary *)error
               data:(nullable NSDictionary *)data {
    NSMutableDictionary *body = [@{
        @"type": type,
    } mutableCopy];

    if (error != nil) {
        body[@"error"] = error;
    }

    if (data != nil) {
        body[@"data"] = data;
    }

    NSMutableDictionary *payload = [@{
            @"eventName": type,
            @"requestId": requestId,
            @"adUnitId": adUnitId,
            @"body": body,
    } mutableCopy];

    if (hasListeners) {
        [self sendEventWithName:event body:payload];
    }
}

- (void)sendInterstitialEvent:(NSString *)type
                    requestId:(NSString *)requestId
                     adUnitId:(NSString *)adUnitId
                        error:(nullable NSDictionary *)error {
  [self sendAdEvent:EVENT_INTERSTITIAL requestId:requestId type:type adUnitId:adUnitId error:error data:nil];
}

+ (NSDictionary *)getCodeAndMessageFromAdError:(NSError *)error {
    NSString *code = @"unknown";
    NSString *message = @"An unknown error occurred.";

    if (error.code == GADErrorInvalidRequest) {
        code = @"invalid-request";
        message = @"The ad request was invalid; for instance, the ad unit ID was incorrect.";
    } else if (error.code == GADErrorNoFill) {
        code = @"no-fill";
        message = @"The ad request was successful, but no ad was returned due to lack of ad inventory.";
    } else if (error.code == GADErrorNetworkError) {
        code = @"network-error";
        message = @"The ad request was unsuccessful due to network connectivity.";
    } else if (error.code == GADErrorInternalError) {
        code = @"internal-error";
        message = @"Something happened internally; for instance, an invalid response was received from the ad server.";
    }

    return @{
        @"code": code,
        @"message": message,
    };
}

+ (GADRequest *)buildAdRequest:(NSDictionary *)adRequestOptions {
    GADRequest *request = [GADRequest request];
    NSMutableDictionary *extras = [@{} mutableCopy];

    if (adRequestOptions[@"requestNonPersonalizedAdsOnly"] && [adRequestOptions[@"requestNonPersonalizedAdsOnly"] boolValue]) {
        extras[@"npa"] = @"1";
    }

    if (adRequestOptions[@"networkExtras"]) {
        for (NSString *key in adRequestOptions[@"networkExtras"]) {
            NSString *value = adRequestOptions[@"networkExtras"][key];
            extras[key] = value;
        }
    }

    GADExtras *networkExtras = [[GADExtras alloc] init];
    networkExtras.additionalParameters = extras;
    [request registerAdNetworkExtras:networkExtras];

    if (adRequestOptions[@"keywords"]) {
        request.keywords = adRequestOptions[@"keywords"];
    }

    if (adRequestOptions[@"contentUrl"]) {
        request.contentURL = adRequestOptions[@"contentUrl"];
    }

    if (adRequestOptions[@"requestAgent"]) {
        request.requestAgent = adRequestOptions[@"requestAgent"];
    }

    return request;
}

+ (void)rejectPromiseWithUserInfo:(RCTPromiseRejectBlock)reject userInfo:(NSMutableDictionary *)userInfo {
    NSError *error = [NSError errorWithDomain:AD_ERROR_DOMAIN code:666 userInfo:userInfo];
    reject(userInfo[@"code"], userInfo[@"message"], error);
}

#pragma mark -
#pragma mark GADInterstitialDelegate Methods

- (NSString*)requestIdForAd:(GADInterstitialAd*)ad {
    NSArray *keys = [_interstitialMap allKeysForObject:ad];
    if (keys.count > 0) {
        return keys[0];
    }
    return nil;
}

/// Tells the delegate that an impression has been recorded for the ad.
- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad {
    GADInterstitialAd *inAd = (GADInterstitialAd *)ad;
    NSString *requestId = [self requestIdForAd:ad];
    if (requestId) {
        [self sendInterstitialEvent:EVENT_TYPE_IMPRESSION requestId:requestId adUnitId:inAd.adUnitID error:nil];
    }
}

/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    GADInterstitialAd *inAd = (GADInterstitialAd *)ad;
    NSString *requestId = [self requestIdForAd:ad];
    if (requestId) {
        [self sendInterstitialEvent:EVENT_TYPE_ERROR requestId:requestId adUnitId:inAd.adUnitID error:[RNGADInterstitialManager getCodeAndMessageFromAdError:error]];
    }
}

/// Tells the delegate that the ad presented full screen content.
-(void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    GADInterstitialAd *inAd = (GADInterstitialAd *)ad;
    NSString *requestId = [self requestIdForAd:ad];
    if (requestId) {
        [self sendInterstitialEvent:EVENT_TYPE_OPENED requestId:requestId adUnitId:inAd.adUnitID error:nil];
    }
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    GADInterstitialAd *inAd = (GADInterstitialAd *)ad;
    NSString *requestId = [self requestIdForAd:ad];
    if (requestId) {
        [self sendInterstitialEvent:EVENT_TYPE_CLOSED requestId:requestId adUnitId:inAd.adUnitID error:nil];
        [_interstitialMap removeObjectForKey:requestId];
    }
}

#pragma mark -
#pragma mark RN Firebase AdMob Methods


RCT_EXPORT_METHOD(interstitialLoad:(nonnull NSString *)requestId :(NSString *)adUnitId :(NSDictionary *)adRequestOptions :(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    if ([self adForRequestId:requestId]) {
        resolve(@1);
        return;
    }
    GADRequest *request = [RNGADInterstitialManager buildAdRequest:adRequestOptions];
    if (@available(iOS 13.0, *)) {
        request.scene = [UIApplication sharedApplication].delegate.window.windowScene;
    }
    [GADInterstitialAd loadWithAdUnitID:adUnitId
                                  request:request
                        completionHandler:^(GADInterstitialAd *ad, NSError *error) {
        if (error) {
            NSDictionary *meta = [RNGADInterstitialManager getCodeAndMessageFromAdError:error];
            reject(meta[@"code"], meta[@"message"], nil);
            return;
        }
        [self setAd:ad for:requestId];
        ad.fullScreenContentDelegate = self;
        resolve(@1);
      }];
}

RCT_EXPORT_METHOD(interstitialShow:(nonnull NSString *)requestId :(NSDictionary *)showOptions :(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    GADInterstitialAd *interstitial = [self adForRequestId:requestId];
    if (interstitial) {
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [interstitial presentFromRootViewController:rootViewController];
        resolve(@1);
    } else {
        [RNGADInterstitialManager rejectPromiseWithUserInfo:reject userInfo:[@{
            @"code": @"not-ready",
            @"message": @"Interstitial ad attempted to show but was not ready.",
        } mutableCopy]];
    }
}

@end
