#import "TouchBarPrivate.h"
#include <dlfcn.h>
#include <objc/runtime.h>
#include <os/log.h>

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

// MARK: - Dimming guard

typedef void (*TBDimIMP)(id, SEL, BOOL);
static TBDimIMP gOriginalDim = NULL;

static void TBCallOriginalDim(id cls, SEL sel, BOOL dimmed, int attempt) {
    @try {
        gOriginalDim(cls, sel, dimmed);
    } @catch (NSException *exception) {
        if (![exception.name isEqualToString:NSGenericException]) @throw;
        os_log_error(OS_LOG_DEFAULT, "DisableBar: caught Touch Bar dimming race (attempt %d): %{public}@",
                     attempt, exception.reason);
        if (attempt < 3) {
            // The rows list settles once the current KVO pass finishes.
            dispatch_async(dispatch_get_main_queue(), ^{ TBCallOriginalDim(cls, sel, dimmed, attempt + 1); });
        }
    }
}

static void TBGuardedDim(id cls, SEL sel, BOOL dimmed) {
    TBCallOriginalDim(cls, sel, dimmed, 1);
}

void TBInstallDimmingGuard(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class rowClass = NSClassFromString(@"NSFunctionRow");
        SEL sel = NSSelectorFromString(@"markActiveFunctionRowsAsDimmed:");
        Method method = rowClass ? class_getClassMethod(rowClass, sel) : NULL;
        // Only patch the exact signature we know: +(void)…:(BOOL).
        if (!method || strcmp(method_getTypeEncoding(method), "v20@0:8B16") != 0) return;
        gOriginalDim = (TBDimIMP)method_setImplementation(method, (IMP)TBGuardedDim);
    });
}
