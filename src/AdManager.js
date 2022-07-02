import {NativeModules} from 'react-native';
import {AdOptions} from './utils';

const RNAdmobNativeAdsManager = NativeModules.RNAdmobNativeAdsManager;

const DEAFAULT_TIME_BETWEEN_ADS = 80000;

let adConfigs = {
	timeBetweenInterstitial: DEAFAULT_TIME_BETWEEN_ADS,
};

async function setRequestConfiguration(config) {
	return RNAdmobNativeAdsManager.setRequestConfiguration(config);
}

async function isTestDevice() {
	return RNAdmobNativeAdsManager.isTestDevice();
}

function registerRepository(config) {
	config.mediaAspectRatio = AdOptions.mediaAspectRatio[config.mediaAspectRatio || 'unknown'];
	config.adChoicesPlacement =
		AdOptions.adChoicesPlacement[config.adChoicesPlacement || 'topRight'];
	return RNAdmobNativeAdsManager.registerRepository(config);
}

function unRegisterRepository(name) {
	return RNAdmobNativeAdsManager.unRegisterRepository(name);
}

async function hasAd(name) {
	return RNAdmobNativeAdsManager.hasAd(name);
}

async function resetCache() {
	return RNAdmobNativeAdsManager.resetCache();
}

const getConfigs = () => {
	return adConfigs;
};

const setConfigs = configs => {
	adConfigs = {
		...adConfigs,
		...configs,
	};
};

export default {
	setRequestConfiguration,
	isTestDevice,
	registerRepository,
	hasAd,
	unRegisterRepository,
	resetCache,
	getConfigs,
	setConfigs,
	DEAFAULT_TIME_BETWEEN_ADS,
};
