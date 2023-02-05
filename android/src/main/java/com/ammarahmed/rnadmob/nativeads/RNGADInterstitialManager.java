package com.ammarahmed.rnadmob.nativeads;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.Map;
import java.util.HashMap;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;



public class RNGADInterstitialManager extends ReactContextBaseJavaModule {
    public final static HashMap<String, InterstitialAd> mInterstitialMap = new HashMap<>();
    public static String showingRequestId;

    private void sendEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    @ReactMethod
    public void addListener(String eventName) {
    }

    @ReactMethod
    public void removeListeners(Integer count) {
    }

    private void sendAdEvent(String evenName, String requestId, String adUnitId, @Nullable WritableMap error, @Nullable WritableMap data) {
        ReactContext context = getReactApplicationContext();
        WritableMap params = Arguments.createMap();
        WritableMap body = Arguments.createMap();
        body.putString("type", evenName);
        params.putString("eventName", evenName);
        params.putString("requestId", requestId);
        params.putString("adUnitId", adUnitId);
        if (error != null) {
            params.putMap("error", error);
        }
        if (data != null) {
            params.putMap("data", data);
        }
        params.putMap("body", body);

        sendEvent(context, "admob_interstitial_event", params);
    }

    private final FullScreenContentCallback adCallback = new FullScreenContentCallback() {
        @Override
        public void onAdDismissedFullScreenContent() {
            InterstitialAd ad = mInterstitialMap.get(showingRequestId.toString());
            if (ad != null) {
                sendAdEvent("closed", showingRequestId, ad.getAdUnitId(), null, null);
            }
        }

        @Override
        public void onAdFailedToShowFullScreenContent(AdError adError) {
            InterstitialAd ad = mInterstitialMap.get(showingRequestId.toString());
            if (ad != null) {
                WritableMap error = Arguments.createMap();
                error.putInt("code", adError.getCode());
                error.putString("message", adError.getMessage());
                sendAdEvent("error", showingRequestId, ad.getAdUnitId(), error, null);
            }
        }

        @Override
        public void onAdShowedFullScreenContent() {
            if (showingRequestId != null) {
                InterstitialAd ad = mInterstitialMap.get(showingRequestId.toString());
                if (ad != null) {
                    sendAdEvent("opened", showingRequestId, ad.getAdUnitId(), null, null);
                }
                mInterstitialMap.remove(showingRequestId.toString());
            }
        }

        @Override
        public void onAdClicked() {
            InterstitialAd ad = mInterstitialMap.get(showingRequestId.toString());
            if (ad != null) {
                sendAdEvent("clicked", showingRequestId, ad.getAdUnitId(), null, null);
            }
        }

        @Override
        public void onAdImpression() {
            InterstitialAd ad = mInterstitialMap.get(showingRequestId.toString());
            if (ad != null) {
                sendAdEvent("impression", showingRequestId, ad.getAdUnitId(), null, null);
            }
        }
    };

    public RNGADInterstitialManager(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNGADInterstitialManager";
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("EVENT_INTERSTITIAL", "admob_interstitial_event");
        constants.put("ADMOB_EVENT_LOADED", "loaded");
        constants.put("ADMOB_EVENT_ERROR", "error");
        constants.put("ADMOB_EVENT_OPENED", "opened");
        constants.put("ADMOB_EVENT_CLICKED", "clicked");
        constants.put("ADMOB_EVENT_IMPRESSION", "impression");
        constants.put("ADMOB_EVENT_LEFT_APPLICATION", "left_application");
        constants.put("ADMOB_EVENT_CLOSED", "closed");
        return constants;
    }

    @ReactMethod
    public void interstitialLoad(String requestId, String adUnitId, ReadableMap adRequestOptions, Promise promise) {
        AdRequest adRequest = new AdRequest.Builder().build();
        final Activity activity = getCurrentActivity();
        if (activity != null) {
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    InterstitialAd.load(activity, adUnitId, adRequest,
                            new InterstitialAdLoadCallback() {
                                @Override
                                public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
                                    interstitialAd.setFullScreenContentCallback(adCallback);
                                    mInterstitialMap.put(requestId.toString(), interstitialAd);
                                    promise.resolve(1);
                                }

                                @Override
                                public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                                    promise.reject("InterstitialAd", loadAdError.getMessage());
                                }
                            });
                }
            });
        } else {
            promise.reject("InterstitialAd", "No active activity");
        }
    }

    @ReactMethod
    public void interstitialShow(String requestId,  ReadableMap showOptions, Promise promise) {
        InterstitialAd interstitialAd = mInterstitialMap.get(requestId.toString());
        final Activity activity = getCurrentActivity();
        if (activity != null && interstitialAd != null) {
            showingRequestId = requestId;
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    interstitialAd.show(activity);
                }
            });
            promise.resolve(1);
        } else {
            promise.reject("InterstitialAd", "No ads or active activity");
        }
    }
}
