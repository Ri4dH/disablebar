#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Presents `touchBar` above every app's Touch Bar, covering the whole strip
/// (including the Control Strip and the Esc region).
void TBPresentSystemModal(NSTouchBar *touchBar);

/// Removes a Touch Bar previously shown with `TBPresentSystemModal`.
void TBDismissSystemModal(NSTouchBar *touchBar);

/// Returns YES when the private system-modal API is available on this macOS.
BOOL TBSystemModalAvailable(void);

/// Returns YES if this Mac has a Touch Bar.
BOOL TBHasTouchBar(void);

/// Works around an AppKit race: when the Touch Bar wakes from its idle dim
/// while another window (e.g. Sparkle's update window) has its own Touch Bar
/// next to our system-modal one, +[NSFunctionRow markActiveFunctionRowsAsDimmed:]
/// can throw "Collection was mutated while being enumerated" and crash the
/// app. This wraps that method, and retries it on the next run-loop pass.
void TBInstallDimmingGuard(void);

NS_ASSUME_NONNULL_END
