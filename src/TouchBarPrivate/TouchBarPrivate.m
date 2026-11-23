#import "TouchBarPrivate.h"
#include <dlfcn.h>

// Private class methods on NSTouchBar (present since macOS 10.14).
@interface NSTouchBar (DisableBarPrivate)
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar
                         placement:(long long)placement
          systemTrayItemIdentifier:(nullable NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar;
@end

static void *DFRHandle(void) {
    static void *handle = NULL;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        handle = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation", RTLD_LAZY);
    });
    return handle;
}

static void HideCloseBox(void) {
    void *handle = DFRHandle();
    if (!handle) return;
    void (*fn)(BOOL) = dlsym(handle, "DFRSystemModalShowsCloseBoxWhenFrontMost");
    if (fn) fn(NO);
}

BOOL TBSystemModalAvailable(void) {
    SEL present = @selector(presentSystemModalTouchBar:placement:systemTrayItemIdentifier:);
    SEL dismiss = @selector(dismissSystemModalTouchBar:);
    return [NSTouchBar respondsToSelector:present] && [NSTouchBar respondsToSelector:dismiss];
}

BOOL TBHasTouchBar(void) {
    void *handle = DFRHandle();
    if (!handle) return NO;
    // DFRGetScreenSize returns a zero size on Macs without a Touch Bar.
    CGSize (*getSize)(void) = dlsym(handle, "DFRGetScreenSize");
    if (!getSize) return NO;
    CGSize size = getSize();
    return size.width > 0 && size.height > 0;
}

void TBPresentSystemModal(NSTouchBar *touchBar) {
    if (!TBSystemModalAvailable()) return;
    HideCloseBox();
    // Placement 1 = full width, hides the Control Strip.
    [NSTouchBar presentSystemModalTouchBar:touchBar placement:1 systemTrayItemIdentifier:nil];
}

void TBDismissSystemModal(NSTouchBar *touchBar) {
    if (!TBSystemModalAvailable()) return;
    [NSTouchBar dismissSystemModalTouchBar:touchBar];
}
