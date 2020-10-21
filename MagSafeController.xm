@interface UIView (MagSafeController)
- (void)setCentersHorizontally:(bool)arg1;
@end

@interface UIImage (MagSafeController)
-(UIImage *)_flatImageWithColor:(UIColor *)color;
@end

@interface CSCoverSheetViewControllerBase : UIViewController
@end
@interface CSChargingViewController : CSCoverSheetViewControllerBase
@end

@interface SBUILegibilityLabel
	@property (getter=isHidden, nonatomic) bool hidden;
@end

@interface CSAccessory : NSObject
@property (nonatomic, retain) UIColor *primaryColor;
@property (nonatomic, retain) UIColor *secondaryColor;
@property (nonatomic) double alignmentPercent;
@end

NSString *const domainString = @"com.tomaszpoliszuk.magsafecontroller";
NSUserDefaults *tweakSettings;

static bool enableTweak;

static bool useNative;

static int selectedColor;
static int selectedLowPowerModeColor;

static int blurBackground;

static int boltScale;
static int ringScale;

static double lineWidth;

static int labelFontSize;

static double ringScaledWidth;

static double boltScaledWidth;
static double boltScaledHeight;

static double boltSizeWidth = 84;
static double boltSizeHeight = 124;

static double animationDuration = 2.75;

CAMediaTimingFunction * timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

void TweakSettingsChanged() {
	tweakSettings = [[NSUserDefaults alloc] initWithSuiteName:domainString];

	enableTweak = [([tweakSettings objectForKey:@"enableTweak"] ?: @(YES)) boolValue];

	if (@available(iOS 14.1, *)) {
		useNative = [([tweakSettings objectForKey:@"useNative"] ?: @(YES)) boolValue];
	}

	selectedColor = [([tweakSettings valueForKey:@"selectedColor"] ?: @(0)) integerValue];
	selectedLowPowerModeColor = [([tweakSettings valueForKey:@"selectedLowPowerModeColor"] ?: @(1)) integerValue];

	blurBackground = [([tweakSettings valueForKey:@"blurBackground"] ?: @(2)) integerValue];

	boltScale = [([tweakSettings valueForKey:@"boltScale"] ?: @(100)) integerValue];
	ringScale = [([tweakSettings valueForKey:@"ringScale"] ?: @(100)) integerValue];
	labelFontSize = [([tweakSettings valueForKey:@"labelFontSize"] ?: @(24)) integerValue];

	lineWidth = [([tweakSettings valueForKey:@"lineWidth"] ?: @(24)) integerValue];
}

%group native

%hook CSPowerChangeObserver
- (bool)isConnectedToWirelessInternalChargingAccessory {
	bool origValue = %orig;
	if ( enableTweak ) {
		return YES;
	}
	return origValue;
}
- (void)setIsConnectedToWirelessInternalChargingAccessory:(bool)arg1 {
	if ( enableTweak ) {
		arg1 = YES;
	}
	%orig;
}
%end

%hook CSAccessoryConfiguration

- (CGSize)boltSize {
	CGSize origValue = %orig;
	if ( enableTweak ) {
		boltScaledWidth = boltSizeWidth * boltScale / 100;
		boltScaledHeight = boltSizeHeight * boltScale / 100;

		if ( boltScaledWidth > 0 ) {
			origValue.width = boltScaledWidth;
		}
		if ( boltScaledHeight > 0 ) {
			origValue.height = boltScaledHeight;
		}
	}
	return origValue;
}
- (double)ringDiameter {
	double origValue = %orig;
	if ( enableTweak ) {
		ringScaledWidth = 3 * ringScale;
		if ( ringScaledWidth > 0 ) {
			return ringScaledWidth;
		}
	}
	return origValue;
}
- (double)splashRingDiameter {
	double origValue = %orig;
	if ( enableTweak ) {
		ringScaledWidth = 3 * ringScale;
		if ( ringScaledWidth > 0 ) {
			return ringScaledWidth*2.25;
		}
	}
	return origValue;
}
- (double)lineWidth {
	double origValue = %orig;
	if ( enableTweak ) {
		return lineWidth;
	}
	return origValue;
}

%end

%end

%group simulated

%hook CSChargingViewController
- (void)viewDidLoad {
	%orig;

	UIColor *elementsColor = [UIColor systemGreenColor];

	bool lowPowerMode = [[NSProcessInfo processInfo] isLowPowerModeEnabled];

	if ( selectedColor == 1 ) {
		elementsColor = [UIColor systemYellowColor];
	} else if ( selectedColor == 2 ) {
		elementsColor = [UIColor systemRedColor];
	}
	if ( lowPowerMode ) {
		if ( selectedLowPowerModeColor == 1 ) {
			elementsColor = [UIColor systemYellowColor];
		} else if ( selectedLowPowerModeColor == 2 ) {
			elementsColor = [UIColor systemRedColor];
		}
	}

	ringScaledWidth = 3 * ringScale;

	boltScaledWidth = boltSizeWidth * boltScale / 100;
	boltScaledHeight = boltSizeHeight * boltScale / 100;

	NSNumber *currentBatteryLevel = [NSNumber numberWithFloat:[UIDevice currentDevice].batteryLevel];

	UIView * splashCircle = [[UIView alloc] init];
	splashCircle.backgroundColor = [UIColor whiteColor];
	splashCircle.frame = CGRectMake(0, 0, ringScaledWidth, ringScaledWidth);
	splashCircle.center = self.view.center;
	splashCircle.layer.cornerRadius = ringScaledWidth/2;
	[self.view addSubview:splashCircle];
	splashCircle.layer.zPosition = 1;

	CAKeyframeAnimation *splashCircleAnimation			= [CAKeyframeAnimation animation];
	splashCircleAnimation.keyPath 						= @"transform.scale";
	splashCircleAnimation.values						= @[ @0, @1, @1.5, @2, @3, @3, @3, @3, @3, @3 ];
	splashCircleAnimation.duration						= animationDuration;
	splashCircleAnimation.timingFunctions				= @[ timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction ];

	CAKeyframeAnimation *splashCircleAnimationOpacity	= [CAKeyframeAnimation animation];
	splashCircleAnimationOpacity.keyPath 				= @"opacity";
	splashCircleAnimationOpacity.values					= @[ @0.25, @0.25, @0.25, @0.125, @0, @0, @0, @0, @0, @0 ];
	splashCircleAnimationOpacity.duration				= animationDuration;
	splashCircleAnimationOpacity.timingFunctions		= @[ timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction ];

	CAAnimationGroup *splashCircleAnimationGroup = [[CAAnimationGroup alloc] init];
	splashCircleAnimationGroup.animations = @[ splashCircleAnimation, splashCircleAnimationOpacity ];
	splashCircleAnimationGroup.duration = animationDuration;

	[splashCircle.layer addAnimation:splashCircleAnimationGroup forKey:@"splashCircleAnimationGroup"];
	splashCircle.layer.opacity = 0;

	UIView *boltView = [[UIView alloc] initWithFrame:CGRectMake( CGRectGetMidX(self.view.frame)-boltScaledWidth/2, CGRectGetMidY(self.view.frame)-boltScaledHeight/2, boltScaledWidth, boltScaledHeight )];
	UIImage *boltImage = [[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MagSafeControllerSettings.bundle/icons/Bolt.png"] _flatImageWithColor:elementsColor];
	UIImageView *boltImageView = [[UIImageView alloc] initWithImage:boltImage];
	boltImageView.frame = boltView.bounds;

	CAKeyframeAnimation *boltZoomAnimation			= [CAKeyframeAnimation animation];
	boltZoomAnimation.keyPath 						= @"transform.scale";
	boltZoomAnimation.values						= @[ @0, @0, @1, @1, @1, @1, @1, @1, @1, @0 ];
	boltZoomAnimation.timingFunctions				= @[ timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction ];

	CAKeyframeAnimation *boltOpacityAnimation		= [CAKeyframeAnimation animation];
	boltOpacityAnimation.keyPath 					= @"opacity";
	boltOpacityAnimation.values						= @[ @0, @0, @1, @1, @1, @1, @1, @1, @1, @0 ];
	boltOpacityAnimation.timingFunctions			= @[ timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction, timingFunction ];

	CAAnimationGroup *boltAnimationGroup = [[CAAnimationGroup alloc] init];
	boltAnimationGroup.animations = @[ boltZoomAnimation, boltOpacityAnimation ];
	boltAnimationGroup.duration = animationDuration;

	[boltView addSubview:boltImageView];
	[self.view addSubview:boltView];
	boltView.layer.zPosition = 1;
	[boltView.layer addAnimation:boltAnimationGroup forKey:@"boltZoomAnimation"];
	boltView.layer.opacity = 0;

	CAShapeLayer *chargingRingBackground	= [CAShapeLayer layer];
	chargingRingBackground.path				= [UIBezierPath bezierPathWithArcCenter:CGPointMake((ringScaledWidth/2), (ringScaledWidth/2)) radius:(ringScaledWidth/2) startAngle:(-M_PI/2) endAngle:(M_PI * 2 - M_PI_2) clockwise:YES].CGPath;
	chargingRingBackground.position			= CGPointMake(CGRectGetMidX(self.view.frame)-(ringScaledWidth/2), CGRectGetMidY(self.view.frame)-(ringScaledWidth/2));
	chargingRingBackground.fillColor		= [UIColor clearColor].CGColor;
	chargingRingBackground.strokeColor		= [UIColor systemGrayColor].CGColor;
	chargingRingBackground.lineWidth		= lineWidth;
	chargingRingBackground.lineCap			= kCALineCapRound;
	chargingRingBackground.lineJoin			= kCALineJoinRound;

	CAShapeLayer *chargingRingProgress		= [CAShapeLayer layer];
	chargingRingProgress.path				= [UIBezierPath bezierPathWithArcCenter:CGPointMake((ringScaledWidth/2), (ringScaledWidth/2)) radius:(ringScaledWidth/2) startAngle:(-M_PI/2) endAngle:(M_PI * 2 - M_PI_2) clockwise:YES].CGPath;
	chargingRingProgress.position			= CGPointMake(CGRectGetMidX(self.view.frame)-(ringScaledWidth/2), CGRectGetMidY(self.view.frame)-(ringScaledWidth/2));
	chargingRingProgress.fillColor			= [UIColor clearColor].CGColor;
	chargingRingProgress.strokeColor		= elementsColor.CGColor;
	chargingRingProgress.lineWidth			= lineWidth;
	chargingRingProgress.lineCap			= kCALineCapRound;
	chargingRingProgress.lineJoin			= kCALineJoinRound;

	CAKeyframeAnimation *chargingRingProgressAnimation							= [CAKeyframeAnimation animation];
	chargingRingProgressAnimation.keyPath 										= @"strokeEnd";
	chargingRingProgressAnimation.values										= @[ @0, @0, currentBatteryLevel, currentBatteryLevel, @1 ];
	chargingRingProgressAnimation.timingFunctions								= @[ timingFunction, timingFunction, timingFunction, timingFunction ];

	CAKeyframeAnimation *chargingRingProgressOutAnimation						= [CAKeyframeAnimation animation];
	chargingRingProgressOutAnimation.keyPath 									= @"strokeStart";
	chargingRingProgressOutAnimation.values										= @[ @0, @0, @0, @0, @1 ];
	chargingRingProgressOutAnimation.timingFunctions							= @[ timingFunction, timingFunction, timingFunction, timingFunction ];

	CAKeyframeAnimation *chargingRingProgressLineWidthAnimation					= [CAKeyframeAnimation animation];
	chargingRingProgressLineWidthAnimation.keyPath								= @"lineWidth";
	chargingRingProgressLineWidthAnimation.values								= @[ @0, [NSNumber numberWithFloat:lineWidth], [NSNumber numberWithFloat:lineWidth], [NSNumber numberWithFloat:lineWidth], [NSNumber numberWithFloat:lineWidth/2] ];
	chargingRingProgressLineWidthAnimation.timingFunctions						= @[ timingFunction, timingFunction, timingFunction, timingFunction ];

	CAKeyframeAnimation *chargingRingProgressBackgroundLineWidthAnimation		= [CAKeyframeAnimation animation];
	chargingRingProgressBackgroundLineWidthAnimation.keyPath					= @"lineWidth";
	chargingRingProgressBackgroundLineWidthAnimation.values						= @[ @0, [NSNumber numberWithFloat:lineWidth], [NSNumber numberWithFloat:lineWidth], [NSNumber numberWithFloat:lineWidth], [NSNumber numberWithFloat:lineWidth/2] ];
	chargingRingProgressBackgroundLineWidthAnimation.timingFunctions			= @[ timingFunction, timingFunction, timingFunction, timingFunction ];

	CAKeyframeAnimation *chargingRingBackgroundOutAnimation						= [CAKeyframeAnimation animation];
	chargingRingBackgroundOutAnimation.keyPath 									= @"strokeEnd";
	chargingRingBackgroundOutAnimation.values									= @[ @1, @1, @1, @1, @1 ];
	chargingRingBackgroundOutAnimation.timingFunctions							= @[ timingFunction, timingFunction, timingFunction, timingFunction ];

	CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
	group.animations = @[ chargingRingProgressAnimation, chargingRingProgressOutAnimation, chargingRingProgressLineWidthAnimation ];
	group.duration = animationDuration;

	CAAnimationGroup *chargingRingBackgroundGroup = [[CAAnimationGroup alloc] init];
	chargingRingBackgroundGroup.animations = @[ chargingRingBackgroundOutAnimation, chargingRingProgressOutAnimation, chargingRingProgressBackgroundLineWidthAnimation ];
	chargingRingBackgroundGroup.duration = animationDuration;

	[self.view.layer addSublayer:chargingRingBackground];
	[self.view.layer addSublayer:chargingRingProgress];

	chargingRingBackground.zPosition = 1;
	chargingRingProgress.zPosition = 1;

	[chargingRingProgress addAnimation:group forKey:@"chargingRingProgress"];
	[chargingRingBackground addAnimation:chargingRingBackgroundGroup forKey:@"chargingRingBackground"];

	chargingRingProgress.strokeStart = 1;
	chargingRingProgress.strokeEnd = 1;
	chargingRingProgress.lineWidth = lineWidth/2;
	chargingRingBackground.strokeStart = 1;
	chargingRingBackground.strokeEnd = 1;
	chargingRingBackground.lineWidth = lineWidth/2;

	UILabel *labelElement = [[UILabel alloc] initWithFrame:CGRectMake( CGRectGetMidX(self.view.frame)-ringScaledWidth/2, CGRectGetMidY(self.view.frame)+ringScaledWidth/2+lineWidth, ringScaledWidth , labelFontSize*1.5 )];
	[labelElement setCentersHorizontally:YES];
	[labelElement setFont:[UIFont systemFontOfSize:labelFontSize weight:normal]];
	[self.view addSubview:labelElement];
	labelElement.layer.zPosition = 1;
	labelElement.text = [NSString stringWithFormat:@"%.f%% Charged", floor([[UIDevice currentDevice] batteryLevel] * 100)];

	UIVisualEffect *blurEffect;
	blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
	if ( blurBackground == 1 ) {
		blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	}
	UIVisualEffectView *visualEffectView;
	visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	visualEffectView.frame = self.view.bounds;
	[self.view addSubview:visualEffectView];
}
%end

%hook _CSSingleBatteryChargingView
-(void)_layoutBattery {
	%orig;
	MSHookIvar<UIView *>(self, "_batteryContainerView").hidden = YES;
	MSHookIvar<UIView *>(self, "_batteryBlurView").hidden = YES;
	MSHookIvar<UIView *>(self, "_batteryFillView").hidden = YES;
	MSHookIvar<UILabel *>(self, "_chargePercentLabel").hidden = YES;
}
%end

%end

%ctor {
	TweakSettingsChanged();
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)TweakSettingsChanged,
		CFSTR("com.tomaszpoliszuk.magsafecontroller.settingschanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately
	);
	
	if ( enableTweak ) {
		if ( useNative ) {
			%init(native);
		} else {
			%init(simulated);
		}
	}
}
