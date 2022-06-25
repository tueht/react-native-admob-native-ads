import { useCallback, useEffect, useRef } from 'react';
import { NativeModules, NativeEventEmitter } from 'react-native';

export const ADS_PLACEMENT = {
    HOME: 1,
    DETAILS: 2
};

let lastShownTime = null;
const TIME_BETWEEN_ADS = 80000;

const useInterstitialAdLoader = (
    placementId,
    adUnitId,
    autoLoad = true,
    options = {}
) => {
    const callbackRef = useRef();

    const loadAd = useCallback(() => {
        return NativeModules.RNGADInterstitialManager.interstitialLoad(
            placementId,
            adUnitId,
            options
        ).catch(error => {
            console.log('error loading', error);
        });
    }, [adUnitId, options, placementId]);

    useEffect(() => {
        const onAdsEvent = event => {
            const { type } = event.body;
            if (
                event.requestId === placementId &&
                type === 'closed' &&
                callbackRef.current
            ) {
                callbackRef.current();
                callbackRef.current = null;
                loadAd();
            }
        };
        const eventEmitter = new NativeEventEmitter(
            NativeModules.RNGADInterstitialManager
        );
        const subscription = eventEmitter.addListener(
            'admob_interstitial_event',
            onAdsEvent
        );
        return () => {
            subscription.remove();
        };
    }, [loadAd, placementId]);

    useEffect(() => {
        if (autoLoad) {
            loadAd();
        }
    }, [autoLoad, loadAd]);

    const showAd = useCallback(
        callbackAfterClosed => {
            if (
                !lastShownTime ||
                lastShownTime < Date.now() - TIME_BETWEEN_ADS
            ) {
                NativeModules.RNGADInterstitialManager.interstitialShow(
                    placementId,
                    {}
                )
                    .then(() => {
                        callbackRef.current = callbackAfterClosed;
                        lastShownTime = Date.now();
                    })
                    .catch(e => {
                        callbackAfterClosed && callbackAfterClosed();
                    });
            } else {
                callbackAfterClosed && callbackAfterClosed();
            }
        },
        [placementId, autoLoad]
    );

    return [showAd, loadAd];
};

export default useInterstitialAdLoader;
