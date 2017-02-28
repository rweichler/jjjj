if ffi.arch == 'arm64' then
    ffi.cdef'typedef double CGFloat;'
else
    ffi.cdef'typedef float CGFloat;'
end

ffi.cdef[[
struct CGPoint {
    CGFloat x;
    CGFloat y;
};
struct CGSize {
    CGFloat width;
    CGFloat height;
};
struct CGRect {
    struct CGPoint origin;
    struct CGSize size;
};
int UIApplicationMain(int argc, char **argv, id principalClassName, id appDelegateClassName);
typedef uint32_t uid_t;
typedef uint32_t gid_t;
int setuid(uid_t uid);
int setgid(gid_t gid);
uid_t getuid();
gid_t getgid();

typedef void (*alert_callback_t)();
typedef void (*alert_input_callback_t)(const char *response);
void alert_display(const char *title, const char *msg, const char *cancel, const char *ok, alert_callback_t callback);
void alert_input(const char *title, const char *msg, const char *cancel, const char *ok, alert_input_callback_t callback);
void pipeit(const char *cmd, void (*callback)(const char *, int));
void run_async(void (*callback)());
void animateit(float duration, float delay, int options, void (*animations)(), void (*completion)(bool));


typedef void *CFNotificationCenterRef;
void CFNotificationCenterPostNotification(CFNotificationCenterRef center, id name, const void *object, id userInfo, bool deliverImmediately);
CFNotificationCenterRef CFNotificationCenterGetDarwinNotifyCenter(void);
]]
UITableViewRowAnimationFade     = 0
UITableViewRowAnimationRight    = 1
UITableViewRowAnimationLeft     = 2
UITableViewRowAnimationTop      = 3
UITableViewRowAnimationBottom   = 4
UITableViewRowAnimationNone     = 5
UITableViewRowAnimationMiddle   = 6
UITableViewRowAnimationAutomatic = 100

NSUTF8StringEncoding = 4

NSURLSessionTaskStateRunning   = 0
NSURLSessionTaskStateSuspended = 1
NSURLSessionTaskStateCanceling = 2
NSURLSessionTaskStateCompleted = 3

UIViewAnimationOptionLayoutSubviews            = bit.lshift(1, 0)
UIViewAnimationOptionAllowUserInteraction      = bit.lshift(1, 1)
UIViewAnimationOptionBeginFromCurrentState     = bit.lshift(1, 2)
UIViewAnimationOptionRepeat                    = bit.lshift(1, 3)
UIViewAnimationOptionAutoreverse               = bit.lshift(1, 4)
UIViewAnimationOptionOverrideInheritedDuration = bit.lshift(1, 5)
UIViewAnimationOptionOverrideInheritedCurve    = bit.lshift(1, 6)
UIViewAnimationOptionAllowAnimatedContent      = bit.lshift(1, 7)
UIViewAnimationOptionShowHideTransitionViews   = bit.lshift(1, 8)
UIViewAnimationOptionOverrideInheritedOptions  = bit.lshift(1, 9)

UIViewAnimationOptionCurveEaseInOut            = bit.lshift(0, 16)
UIViewAnimationOptionCurveEaseIn               = bit.lshift(1, 16)
UIViewAnimationOptionCurveEaseOut              = bit.lshift(2, 16)
UIViewAnimationOptionCurveLinear               = bit.lshift(3, 16)

UIViewAnimationOptionTransitionNone            = bit.lshift(0, 20)
UIViewAnimationOptionTransitionFlipFromLeft    = bit.lshift(1, 20)
UIViewAnimationOptionTransitionFlipFromRight   = bit.lshift(2, 20)
UIViewAnimationOptionTransitionCurlUp          = bit.lshift(3, 20)
UIViewAnimationOptionTransitionCurlDown        = bit.lshift(4, 20)
UIViewAnimationOptionTransitionCrossDissolve   = bit.lshift(5, 20)
UIViewAnimationOptionTransitionFlipFromTop     = bit.lshift(6, 20)
UIViewAnimationOptionTransitionFlipFromBottom  = bit.lshift(7, 20)

NSTextAlignmentLeft      = 0    -- Visually left aligned
NSTextAlignmentCenter    = 1    -- Visually centered
NSTextAlignmentRight     = 2    -- Visually right aligned
NSTextAlignmentJustified = 3    -- Fully-justified. The last line in a paragraph is natural-aligned.
NSTextAlignmentNatural   = 4    -- Indicates the default alignment for script

UIProgressViewStyleDefault      = 0
UIBarButtonItemStylePlain       = 0

UIControlEventTouchDown         = bit.lshift(1, 0)
UIControlEventTouchDownRepeat   = bit.lshift(1, 1)
UIControlEventTouchDragInside   = bit.lshift(1, 2)
UIControlEventTouchDragOutside  = bit.lshift(1, 3)
UIControlEventTouchDragEnter    = bit.lshift(1, 4)
UIControlEventTouchDragExit     = bit.lshift(1, 5)
UIControlEventTouchUpInside     = bit.lshift(1, 6)
UIControlEventTouchUpOutside    = bit.lshift(1, 7)
UIControlEventTouchCancel       = bit.lshift(1, 8)

UIControlStateNormal            = 0
UIControlStateHighlighted       = bit.lshift(1, 0)
UIControlStateDisabled          = bit.lshift(1, 1)
UIControlStateSelected          = bit.lshift(1, 2)
UIControlStateFocused           = bit.lshift(1, 3)
UIControlStateApplication       = 0x00FF0000
UIControlStateReserved          = 0xFF000000

function CGRectMake(x, y, w, h)
    local rect = ffi.new('struct CGRect')
    rect.origin.x = x
    rect.origin.y = y
    rect.size.width = w
    rect.size.height = h
    return rect
end

ffi.metatype('struct CGRect', {
    __tostring = function(t)
        return '<CGRect ('..t.origin.x..', '..t.origin.y..', '..t.size.width..', '..t.size.height..')>'
    end,
})
