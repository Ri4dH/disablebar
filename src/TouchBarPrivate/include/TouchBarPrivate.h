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

NS_ASSUME_NONNULL_END
