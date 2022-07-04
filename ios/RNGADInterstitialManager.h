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

@property(nonatomic, strong) NSMutableDictionary *interstitialMap;

@end

NS_ASSUME_NONNULL_END
