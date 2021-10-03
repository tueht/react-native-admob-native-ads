//
//  RNGADInterstitialManager.h
//  RNAdMobManager
//
//  Created by Tue Hoang on 03/10/2021.
//  Copyright © 2021 accosine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNGADInterstitialManager : RCTEventEmitter<RCTBridgeModule, GADFullScreenContentDelegate>

+ (RNGADInterstitialManager *)shared;

@property(nonatomic, strong) NSMutableDictionary *interstitialMap;

@end


extern NSString *const EVENT_INTERSTITIAL;
extern NSString *const EVENT_REWARDED;

extern NSString *const ADMOB_EVENT_LOADED;
extern NSString *const ADMOB_EVENT_ERROR;
extern NSString *const ADMOB_EVENT_OPENED;
extern NSString *const ADMOB_EVENT_CLICKED;
extern NSString *const ADMOB_EVENT_LEFT_APPLICATION;
extern NSString *const ADMOB_EVENT_CLOSED;
extern NSString *const ADMOB_EVENT_IMPRESSION;


NS_ASSUME_NONNULL_END
