// mirror: make the built-in screen mirror another display, or stop mirroring.
//   mirror list                 online displays: id, name, size, main/built-in/mirror state
//   mirror on <name part>       the built-in screen mirrors the display whose name contains <name part>
//                               (case-insensitive), so that display becomes the main one
//   mirror off                  the built-in screen stops mirroring
//   mirror main <name part>     extended, not mirrored: the named display becomes the main one (at the origin),
//                               the others to its right; "mirror main builtin" puts the built-in screen back
// Public CoreGraphics API; changes last for this login session only (kCGConfigureForSession).
// Build: clang -fobjc-arc -O2 -framework Foundation -framework AppKit -framework CoreGraphics mirror.m -o mirror
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

static NSString *name_of(CGDirectDisplayID d) {
    for (NSScreen *s in NSScreen.screens)
        if ([s.deviceDescription[@"NSScreenNumber"] unsignedIntValue] == d) return s.localizedName;
    return CGDisplayIsBuiltin(d) ? @"Built-in" : @"?";   // a display hidden in a mirror set has no NSScreen
}

static uint32_t online(CGDirectDisplayID *ids) {
    uint32_t n = 0; CGGetOnlineDisplayList(16, ids, &n); return n;
}

static CGDirectDisplayID builtin(void) {
    CGDirectDisplayID ids[16]; uint32_t n = online(ids);
    for (uint32_t i = 0; i < n; i++) if (CGDisplayIsBuiltin(ids[i])) return ids[i];
    return kCGNullDirectDisplay;
}

static int configure(CGDirectDisplayID display, CGDirectDisplayID master) {
    CGDisplayConfigRef cfg;
    CGError e = CGBeginDisplayConfiguration(&cfg);
    if (e == kCGErrorSuccess) e = CGConfigureDisplayMirrorOfDisplay(cfg, display, master);
    if (e == kCGErrorSuccess) e = CGCompleteDisplayConfiguration(cfg, kCGConfigureForSession);
    else CGCancelDisplayConfiguration(cfg);
    if (e != kCGErrorSuccess) { fprintf(stderr, "mirror: display configuration failed (CGError %d)\n", e); return 1; }
    return 0;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        [NSApplication sharedApplication];   // a window-server connection, for NSScreen names
        NSString *cmd = argc > 1 ? @(argv[1]) : @"list";
        CGDirectDisplayID ids[16]; uint32_t n = online(ids);
        if ([cmd isEqualToString:@"list"]) {
            for (uint32_t i = 0; i < n; i++) {
                CGDisplayModeRef m = CGDisplayCopyDisplayMode(ids[i]);
                printf("%u\t%s\t%zux%zu%s%s%s\n", ids[i], name_of(ids[i]).UTF8String,
                       m ? CGDisplayModeGetWidth(m) : 0, m ? CGDisplayModeGetHeight(m) : 0,
                       CGDisplayIsMain(ids[i]) ? "\tmain" : "", CGDisplayIsBuiltin(ids[i]) ? "\tbuilt-in" : "",
                       CGDisplayMirrorsDisplay(ids[i]) ? [NSString stringWithFormat:@"\tmirrors %u", CGDisplayMirrorsDisplay(ids[i])].UTF8String : "");
                if (m) CGDisplayModeRelease(m);
            }
            return 0;
        }
        CGDirectDisplayID screen = builtin();
        if (!screen) { fprintf(stderr, "mirror: no built-in screen\n"); return 1; }
        if ([cmd isEqualToString:@"off"])   // macOS refuses to unmirror a screen that is not mirroring
            return CGDisplayMirrorsDisplay(screen) ? configure(screen, kCGNullDirectDisplay) : 0;
        if ([cmd isEqualToString:@"main"] && argc > 2) {
            // Extended (not mirrored): put the named display (or "builtin") at the origin, which makes it the
            // main display, and line the others up to its right.
            NSString *want = @(argv[2]);
            CGDirectDisplayID target = kCGNullDirectDisplay;
            if ([want caseInsensitiveCompare:@"builtin"] == NSOrderedSame) target = screen;
            else for (uint32_t i = 0; i < n; i++)
                if (ids[i] != screen && [name_of(ids[i]) rangeOfString:want options:NSCaseInsensitiveSearch].location != NSNotFound) target = ids[i];
            if (!target) { fprintf(stderr, "mirror: no online display named like \"%s\"\n", argv[2]); return 1; }
            CGDisplayConfigRef cfg;
            CGError e = CGBeginDisplayConfiguration(&cfg);
            if (e != kCGErrorSuccess) { fprintf(stderr, "mirror: display configuration failed (CGError %d)\n", e); return 1; }
            if (CGDisplayMirrorsDisplay(screen)) CGConfigureDisplayMirrorOfDisplay(cfg, screen, kCGNullDirectDisplay);
            int32_t x = (int32_t)CGDisplayBounds(target).size.width;
            if (e == kCGErrorSuccess) e = CGConfigureDisplayOrigin(cfg, target, 0, 0);
            for (uint32_t i = 0; i < n && e == kCGErrorSuccess; i++) {
                if (ids[i] == target || CGDisplayMirrorsDisplay(ids[i])) continue;
                e = CGConfigureDisplayOrigin(cfg, ids[i], x, 0);
                x += (int32_t)CGDisplayBounds(ids[i]).size.width;
            }
            if (e == kCGErrorSuccess) e = CGCompleteDisplayConfiguration(cfg, kCGConfigureForSession);
            else CGCancelDisplayConfiguration(cfg);
            if (e != kCGErrorSuccess) { fprintf(stderr, "mirror: display configuration failed (CGError %d)\n", e); return 1; }
            return 0;
        }
        if ([cmd isEqualToString:@"on"] && argc > 2) {
            NSString *want = @(argv[2]);
            for (uint32_t i = 0; i < n; i++) {
                if (ids[i] == screen) continue;
                if ([name_of(ids[i]) rangeOfString:want options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    if (CGDisplayMirrorsDisplay(screen) == ids[i]) return 0;   // already
                    return configure(screen, ids[i]);
                }
            }
            fprintf(stderr, "mirror: no online display named like \"%s\"\n", argv[2]);
            return 1;
        }
        fprintf(stderr, "usage: mirror list | on <name part> | off | main <name part>|builtin\n");
        return 2;
    }
}
