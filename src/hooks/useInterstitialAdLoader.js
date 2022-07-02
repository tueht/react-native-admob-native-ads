import {useCallback, useEffect, useRef} from 'react';
import {NativeModules, NativeEventEmitter} from 'react-native';
import {getConfigs, DEAFAULT_TIME_BETWEEN_ADS} from '../AdManager';

export const ADS_PLACEMENT = {
	HOME: 1,
	DETAILS: 2,
};

let lastShownTime = null;

const useInterstitialAdLoader = (placementId, adUnitId, autoLoad = true, options = {}) => {
	const callbackRef = useRef();
	const {timeBetweenInterstitial = DEAFAULT_TIME_BETWEEN_ADS} = getConfigs();

	const loadAd = useCallback(() => {
		return NativeModules.RNGADInterstitialManager.interstitialLoad(
			placementId,
			adUnitId,
			options,
		);
	}, [adUnitId, options, placementId]);

	useEffect(() => {
		const onAdsEvent = event => {
			const {type} = event.body;
			if (event.requestId === placementId && type === 'closed' && callbackRef.current) {
				callbackRef.current();
				callbackRef.current = null;
				loadAd();
			}
		};
		const eventEmitter = new NativeEventEmitter(NativeModules.RNGADInterstitialManager);
		const subscription = eventEmitter.addListener('admob_interstitial_event', onAdsEvent);
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
		(callbackAfterClosed, force = false) => {
			if (force || !lastShownTime || lastShownTime < Date.now() - timeBetweenInterstitial) {
				NativeModules.RNGADInterstitialManager.interstitialShow(placementId, {})
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
		[placementId],
	);

	return [showAd, loadAd];
};

export default useInterstitialAdLoader;
