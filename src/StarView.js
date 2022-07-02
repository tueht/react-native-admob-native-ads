import React, {useCallback} from 'react';
import {View, StyleSheet, Image} from 'react-native';

const fullStarImage = require('../assets/star-full.webp');
const haftStarImage = require('../assets/star-haft.webp');
const emptyStarImage = require('../assets/star-empty.webp');

export default function StarView({
	style,
	stars,
	size = 15,
	fullIconColor = '#ffd27d',
	halfIconColor = '#ffd27d',
	emptyIconColor = '#f0f0f0',
	passRef,
	StarComponent,
	...passThroughProps
}) {
	const renderIcon = useCallback(
		(key, variant) => {
			let img = emptyStarImage;
			let tintColor = emptyIconColor;
			if (variant === 'haft') {
				img = haftStarImage;
				tintColor = halfIconColor;
			} else if (variant === 'full') {
				img = fullStarImage;
				tintColor = fullIconColor;
			}

			if (StarComponent && React.isValidElement(StarComponent)) {
				return <StarComponent size={size} tintColor={tintColor} variant={variant} />;
			}

			return (
				<Image
					key={key}
					source={img}
					resizeMode="contain"
					style={{width: size, height: size, tintColor}}
				/>
			);
		},
		[StarComponent, size, emptyIconColor, halfIconColor, fullIconColor],
	);

	const renderIcons = useCallback(
		(_stars, icons = [], emptyStars = 5) => {
			if (typeof stars !== 'number') return null;

			if (_stars > 5) {
				_stars = 5;
			}
			if (_stars >= 1) {
				// 1 - 5
				icons.push(renderIcon(`star-full${_stars}`, 'full'));
				return renderIcons(_stars - 1, icons, emptyStars - 1);
			} else if (_stars >= 0.5) {
				// 0 - 1
				icons.push(renderIcon(`star-half${_stars}`, 'haft'));
				return renderIcons(_stars - 1, icons, emptyStars - 1);
			}
			if (emptyStars > 0) {
				icons.push(renderIcon(`star-empty${_stars}`, 'empty'));
				return renderIcons(_stars, icons, emptyStars - 1);
			}
			// 0
			return icons;
		},
		[renderIcon],
	);

	if (typeof stars !== 'number' || typeof size !== 'number') return null;

	return (
		<View ref={passRef} style={[styles.row, style]} {...passThroughProps}>
			{renderIcons(stars)}
		</View>
	);
}

const styles = StyleSheet.create({
	row: {
		flexDirection: 'row',
		marginTop: 1,
	},
});
