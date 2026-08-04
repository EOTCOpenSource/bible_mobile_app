/// Seconds the user must remain on a chapter page (once per visit) to count
/// that chapter toward progress and (once per local calendar day) the streak.
const int kReadingDwellQualifySeconds = 20;

/// One freeze is earned every this many consecutive days.
const int kFreezeEarnEveryDays = 7;

/// Most freezes that can be banked at once. Also the longest gap a return can
/// bridge, so a streak can never survive a week away.
const int kMaxFreezeCredits = 2;
