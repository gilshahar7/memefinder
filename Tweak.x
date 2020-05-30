#import <libactivator/libactivator.h>
#import <WebKit/WKWebView.h>
#import <WebKit/WKWebViewConfiguration.h>
#import <WebKit/WKPreferences.h>
#import <UIKit/UIKit.h>
#include <RemoteLog.h>

@interface MemeWindow : UIWindow
@end

static MemeWindow *memeWindow;
static UIView *memeView;
static UIVisualEffectView *barView;

@interface MEMEFinderListener : NSObject<LAListener>
-(void)setupWebView:(NSString *)memesearch;
-(void)closeMemeView;
-(void)move:(UIPanGestureRecognizer*)sender;
@end

@implementation MemeWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    RLog(@"event:%@ point:%@", event, NSStringFromCGPoint(point));
    if (memeView.superview == nil) {
      return NO;
    }
    UIView *viewAtPoint = [memeView hitTest:[self convertPoint:point toView:memeView] withEvent:event];
    if (!viewAtPoint || (viewAtPoint == memeView)) return NO;
    else return YES;
	return NO;
}
@end

@implementation MEMEFinderListener
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
  if (memeView.superview == nil) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: @"Input Meme Search"
        message: nil
        preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Meme";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      NSString *somestring = alertController.textFields[0].text;
      [self setupWebView:somestring];
    }]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
  } else {
    [memeView removeFromSuperview];
  }
  [event setHandled:YES];
}

-(void)setupWebView:(NSString *)memesearch {
  if (memeWindow == nil) {
    memeWindow = [[MemeWindow alloc] initWithFrame:CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width,[[UIScreen mainScreen] bounds].size.height)];
    memeWindow.windowLevel = UIWindowLevelAlert;
    UIViewController *viewController = [[UIViewController alloc] init];
    memeWindow.rootViewController = viewController;
    //[memeWindow makeKeyAndVisible];
    memeWindow.hidden = false;

    }
    memeView = [[UIView alloc] initWithFrame:CGRectMake(20,150,[[UIScreen mainScreen] bounds].size.width-40,[[UIScreen mainScreen] bounds].size.height-400)];
    memeView.layer.cornerRadius = 10;
    memeView.layer.masksToBounds = YES;

    memeWindow.rootViewController.view = memeWindow;
    [memeWindow addSubview:memeView];

    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:memeView.frame configuration:theConfiguration];
    webView.layer.masksToBounds = YES;
    NSURL *nsurl = [NSURL URLWithString:[NSString stringWithFormat:@"https://knowyourmeme.com/search?q=%@", memesearch]];
    NSURLRequest *nsrequest = [NSURLRequest requestWithURL:nsurl];
    webView.allowsBackForwardNavigationGestures = TRUE;
    webView.allowsLinkPreview = YES;
    [webView loadRequest:nsrequest];
    [memeView addSubview:webView];

    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];

    barView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    barView.layer.masksToBounds = YES;
    [memeView addSubview:barView];

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton addTarget:self action:@selector(closeMemeView) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setTitle:@"X" forState:UIControlStateNormal];
    [barView.contentView addSubview:closeButton];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,20,20)];
    label.text = @"MemeFinder";
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    [barView.contentView addSubview:label];

    NSDictionary *binding3 = @{@"b" : closeButton, @"l" : label};
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [barView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[b]" options:0 metrics:nil views:binding3]];
    [barView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[l]|" options:0 metrics:nil views:binding3]];
    [barView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[b]|" options:0 metrics:nil views:binding3]];

    webView.translatesAutoresizingMaskIntoConstraints = NO;
    barView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *binding2 = @{@"v" : webView, @"b" : barView};
    [memeView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|" options:0 metrics:nil views:binding2]];
    [memeView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[b]|" options:0 metrics:nil views:binding2]];
    [memeView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[b(==25)][v]|" options:0 metrics:nil views:binding2]];

    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [barView.contentView addGestureRecognizer:panRecognizer];
}

-(void)move:(UIPanGestureRecognizer *)recognizer{
  CGPoint translation = [recognizer translationInView:memeView];
  memeView.center = CGPointMake(memeView.center.x + translation.x, memeView.center.y + translation.y);
  [recognizer setTranslation:CGPointMake(0, 0) inView:memeView];

  if (recognizer.state == UIGestureRecognizerStateEnded) {
    if (memeView.frame.origin.y <= 50) {
      [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        memeView.frame = CGRectMake(memeView.frame.origin.x,50,memeView.frame.size.width,memeView.frame.size.height);
      } completion:nil];
    } else if ((memeView.frame.origin.y >= [[UIScreen mainScreen] bounds].size.height - 50)) {
      [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        memeView.frame = CGRectMake(memeView.frame.origin.x ,[[UIScreen mainScreen] bounds].size.height - 50 ,memeView.frame.size.width,memeView.frame.size.height);
      } completion:nil];
    }
  }
}

-(void)closeMemeView {
  [memeView removeFromSuperview];
}

+(void)load {
  @autoreleasepool {
    [[LAActivator sharedInstance] registerListener:[self new] forName:@"com.gilshahar7.memefinder.toggle"];
  }
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    return @"Show MEMEFinder";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    return @"Open KnowYourMeme in a safari webview";
}
- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}
@end
