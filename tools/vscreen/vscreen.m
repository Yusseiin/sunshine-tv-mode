// Virtual 16:9 Screen: an invisible background app (no Dock icon, no window) that keeps a virtual 16:9
// display connected while it runs; quitting it (SIGTERM, or `open` again with --quit) removes the display.
// It replaces BetterDisplay for Sunshine's TV mode. Mirroring is done separately by tools/mirror.
// Uses CoreGraphics' CGVirtualDisplay classes (private API, the same ones DeskPad and BetterDisplay use).
// Arguments: [width height [refresh]]   (default 1920 1080 60)
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <signal.h>

@interface CGVirtualDisplayDescriptor : NSObject
@property (retain, nonatomic) dispatch_queue_t queue;
@property (retain, nonatomic) NSString *name;
@property (nonatomic) unsigned int maxPixelsWide, maxPixelsHigh;
@property (nonatomic) CGSize sizeInMillimeters;
@property (nonatomic) unsigned int productID, vendorID, serialNum;
@property (copy, nonatomic) void (^terminationHandler)(id, id);
@end
@interface CGVirtualDisplayMode : NSObject
- (instancetype)initWithWidth:(unsigned int)width height:(unsigned int)height refreshRate:(double)refreshRate;
@end
@interface CGVirtualDisplaySettings : NSObject
@property (nonatomic) unsigned int hiDPI;
@property (retain, nonatomic) NSArray *modes;
@end
@interface CGVirtualDisplay : NSObject
- (instancetype)initWithDescriptor:(CGVirtualDisplayDescriptor *)descriptor;
- (BOOL)applySettings:(CGVirtualDisplaySettings *)settings;
@property (readonly, nonatomic) CGDirectDisplayID displayID;
@end

static CGVirtualDisplay *g_display;   // kept alive for the life of the app

static void say(NSString *s) { fprintf(stderr, "vscreen: %s\n", s.UTF8String); }

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end
@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)n {
    NSArray<NSString *> *a = NSProcessInfo.processInfo.arguments;
    unsigned w = 1920, h = 1080; double hz = 60;
    if (a.count > 2 && a[1].intValue > 0 && a[2].intValue > 0) { w = (unsigned)a[1].intValue; h = (unsigned)a[2].intValue; }
    if (a.count > 3 && a[3].doubleValue > 0) hz = a[3].doubleValue;

    // Every app seen to make a usable virtual display (BetterDisplay, DeskPad, screen-streaming hosts)
    // holds Screen Recording permission; ask for it (macOS shows its prompt once) and log the state.
    BOOL capture = CGPreflightScreenCaptureAccess();
    say(capture ? @"screen recording permission: granted" : @"screen recording permission: not granted (requesting)");
    if (!capture) CGRequestScreenCaptureAccess();

    Class D = NSClassFromString(@"CGVirtualDisplayDescriptor"), V = NSClassFromString(@"CGVirtualDisplay"),
          S = NSClassFromString(@"CGVirtualDisplaySettings"), M = NSClassFromString(@"CGVirtualDisplayMode");
    if (!D || !V || !S || !M) { say(@"CGVirtualDisplay is not available"); exit(1); }

    CGVirtualDisplayDescriptor *d = [[D alloc] init];
    d.queue = dispatch_get_main_queue();
    d.name = @"Virtual 16:9";
    d.maxPixelsWide = w; d.maxPixelsHigh = h;
    d.sizeInMillimeters = CGSizeMake(1210, 680);   // a 55" 16:9 panel
    d.vendorID = 0x1EA7; d.productID = 0x1609;
    // Newer macOS versions also describe the display's colours; zeros leave a display that never comes
    // online. sRGB / Rec. 709 primaries with a D65 white point.
    NSDictionary<NSString *, NSValue *> *colours = @{
        @"redPrimary": [NSValue valueWithPoint:NSMakePoint(0.640, 0.330)],
        @"greenPrimary": [NSValue valueWithPoint:NSMakePoint(0.300, 0.600)],
        @"bluePrimary": [NSValue valueWithPoint:NSMakePoint(0.150, 0.060)],
        @"whitePoint": [NSValue valueWithPoint:NSMakePoint(0.3127, 0.3290)],
    };
    for (NSString *k in colours)
        if ([d respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [k substringToIndex:1].uppercaseString, [k substringFromIndex:1]])])
            [d setValue:colours[k] forKey:k];
    d.terminationHandler = ^(id x, id y) { say(@"the system ended the virtual display"); exit(0); };
    // The window server refuses a display with the vendor/product/serial of one it still remembers
    // ("already exists!"), and can keep one after its process ended; a fixed serial then keeps failing
    // until the next login. So each launch takes a serial of its own (its pid), with a few retries.
    // (Approach from manaflow-ai/cmux scripts/create-virtual-display.m.)
    for (unsigned attempt = 0; attempt < 4 && !g_display; attempt++) {
        unsigned serial = ((unsigned)getpid() & 0x00FFFFFF) | (attempt << 24);
        d.serialNum = serial ? serial : 1;
        if ([d respondsToSelector:@selector(setSerialNumber:)]) [d setValue:@(d.serialNum) forKey:@"serialNumber"];
        g_display = [[V alloc] initWithDescriptor:d];
    }
    if (!g_display) { say(@"could not create the virtual display"); exit(1); }

    CGVirtualDisplaySettings *s = [[S alloc] init];
    s.hiDPI = 0;
    s.modes = @[[[M alloc] initWithWidth:w height:h refreshRate:hz]];
    if (![g_display applySettings:s]) { say(@"could not apply the display mode"); exit(1); }
    say([NSString stringWithFormat:@"virtual display %u, %ux%u@%.0f", g_display.displayID, w, h, hz]);
}
@end

int main(int argc, const char **argv) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;
        // SIGTERM ends the app (and with it the display) cleanly on the main queue.
        signal(SIGTERM, SIG_IGN);
        dispatch_source_t t = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGTERM, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(t, ^{ say(@"stopping"); exit(0); });
        dispatch_resume(t);
        [app run];
    }
    return 0;
}
