STDDATETST      ; Test suite for STDDATE (v0.0.5).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        ;
        ; $ECODE coverage: STDDATE sets $ECODE on malformed input (bad
        ; horolog, bad ISO string, bad duration). Re-enabled here once the
        ; STDASSERT.raises P1 was fixed via ZGOTO unwind (TOOLCHAIN-FINDINGS
        ; row 2026-05-06).
        ;
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---------- fromh: $HOROLOG -> ISO-8601 ----------
        do tFromhEpochDayZero(.pass,.fail)
        do tFromhDayOne(.pass,.fail)
        do tFromhUnixEpoch(.pass,.fail)
        do tFromhSecondsIntoDay(.pass,.fail)
        do tFromhTwoPieceNoFraction(.pass,.fail)
        do tFromhThreePieceMicroseconds(.pass,.fail)
        do tFromhFourPieceUtcSuffix(.pass,.fail)
        do tFromhFourPiecePositiveOffset(.pass,.fail)
        do tFromhFourPieceNegativeOffset(.pass,.fail)
        do tFromhRejectsEmpty(.pass,.fail)
        ;
        ; ---------- toh: ISO-8601 -> $HOROLOG ----------
        do tTohDateOnly(.pass,.fail)
        do tTohDateTime(.pass,.fail)
        do tTohZSuffixYields4Piece(.pass,.fail)
        do tTohPositiveOffset(.pass,.fail)
        do tTohNegativeOffset(.pass,.fail)
        do tTohSubsecondMillis(.pass,.fail)
        do tTohSubsecondMicros(.pass,.fail)
        do tTohRoundTripWithFromh(.pass,.fail)
        do tTohInvalidRaisesEcode(.pass,.fail)
        ;
        ; ---------- leap-year arithmetic (validity only via fromh round-trip) ----------
        do tLeap2000IsLeap(.pass,.fail)
        do tLeap2400IsLeap(.pass,.fail)
        do tLeap2024IsLeap(.pass,.fail)
        ;
        ; ---------- strftime ----------
        do tStrftimeYearFourDigits(.pass,.fail)
        do tStrftimeMonthZeroPad(.pass,.fail)
        do tStrftimeDayZeroPad(.pass,.fail)
        do tStrftimeHourMinuteSecond(.pass,.fail)
        do tStrftimeFullIsoCombo(.pass,.fail)
        do tStrftimeLiteralPercent(.pass,.fail)
        do tStrftimeOffsetZ(.pass,.fail)
        ;
        ; ---------- strptime ----------
        do tStrptimeDateOnly(.pass,.fail)
        do tStrptimeFullIso(.pass,.fail)
        do tStrptimeInvalidRaisesEcode(.pass,.fail)
        ;
        ; ---------- add: ISO-8601 duration ----------
        do tAddOneDay(.pass,.fail)
        do tAddOneDayTwoHourThirtyMinutes(.pass,.fail)
        do tAddOneMonthRollover(.pass,.fail)
        do tAddOneYearOnLeapDayClamps(.pass,.fail)
        do tAddNegativeDuration(.pass,.fail)
        do tAddSecondsCarryDay(.pass,.fail)
        ;
        ; ---------- diff: ISO-8601 duration ----------
        do tDiffEqualHorologsIsZero(.pass,.fail)
        do tDiffOneDayApart(.pass,.fail)
        do tDiffSecondsOnly(.pass,.fail)
        do tDiffNegativeWhenH2Earlier(.pass,.fail)
        ;
        ; ---------- now ----------
        do tNowEndsWithZ(.pass,.fail)
        do tNowContainsCurrentYear(.pass,.fail)
        do tNowSortsLexically(.pass,.fail)
        ;
        ; ---------- round-trip property ----------
        do tRoundTripFromhTohRandomDays(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; =========================================================
        ; fromh — $HOROLOG -> ISO-8601
        ; =========================================================
        ;
tFromhEpochDayZero(pass,fail)   ;@TEST "fromh of (0,0) returns 1840-12-31T00:00:00"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("0,0"),"1840-12-31T00:00:00","$HOROLOG day 0")
        quit
        ;
tFromhDayOne(pass,fail) ;@TEST "fromh of (1,0) returns 1841-01-01T00:00:00"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("1,0"),"1841-01-01T00:00:00","day 1")
        quit
        ;
tFromhUnixEpoch(pass,fail)      ;@TEST "fromh of (47117,0) returns 1970-01-01T00:00:00"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,0"),"1970-01-01T00:00:00","Unix epoch day")
        quit
        ;
tFromhSecondsIntoDay(pass,fail) ;@TEST "fromh of (47117,3661) sets HH:MM:SS to 01:01:01"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,3661"),"1970-01-01T01:01:01","3661s = 1h1m1s")
        quit
        ;
tFromhTwoPieceNoFraction(pass,fail)     ;@TEST "fromh emits no .frac on 2-piece input"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,0"),"1970-01-01T00:00:00","no fractional part")
        quit
        ;
tFromhThreePieceMicroseconds(pass,fail) ;@TEST "fromh of 3-piece (D,S,U) appends .uuuuuu"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,0,123456"),"1970-01-01T00:00:00.123456","3-piece us")
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,0,1"),"1970-01-01T00:00:00.000001","6-digit us pad")
        quit
        ;
tFromhFourPieceUtcSuffix(pass,fail)     ;@TEST "fromh of 4-piece with tzoff=0 appends Z"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,0,0,0"),"1970-01-01T00:00:00Z","tzoff=0 -> Z")
        quit
        ;
tFromhFourPiecePositiveOffset(pass,fail)        ;@TEST "fromh of 4-piece with tzoff=+5h appends +05:00"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,0,0,18000"),"1970-01-01T00:00:00+05:00","tzoff=+5h")
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,0,0,19800"),"1970-01-01T00:00:00+05:30","tzoff=+5:30")
        quit
        ;
tFromhFourPieceNegativeOffset(pass,fail)        ;@TEST "fromh of 4-piece with tzoff=-5h appends -05:00"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE("47117,0,0,-18000"),"1970-01-01T00:00:00-05:00","tzoff=-5h")
        quit
        ;
tFromhRejectsEmpty(pass,fail)   ;@TEST "fromh of empty input raises U-STDDATE-BAD-HOROLOG"
        do raises^STDASSERT(.pass,.fail,"new x set x=$$fromh^STDDATE("""")","U-STDDATE-BAD-HOROLOG","empty horolog")
        quit
        ;
        ; =========================================================
        ; toh — ISO-8601 -> $HOROLOG
        ; =========================================================
        ;
tTohDateOnly(pass,fail) ;@TEST "toh of YYYY-MM-DD returns days,0"
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01"),"47117,0","unix epoch date")
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1840-12-31"),"0,0","horolog day 0 date")
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1841-01-01"),"1,0","horolog day 1 date")
        quit
        ;
tTohDateTime(pass,fail) ;@TEST "toh of YYYY-MM-DDTHH:MM:SS returns days,seconds"
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01T01:01:01"),"47117,3661","epoch + 1h1m1s")
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01T23:59:59"),"47117,86399","last second of day")
        quit
        ;
tTohZSuffixYields4Piece(pass,fail)      ;@TEST "toh of ...Z returns 4-piece D,S,0,0"
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01T00:00:00Z"),"47117,0,0,0","Z -> 4-piece")
        quit
        ;
tTohPositiveOffset(pass,fail)   ;@TEST "toh of +HH:MM returns 4-piece with tzoff in seconds"
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01T00:00:00+05:00"),"47117,0,0,18000","+05:00 = 18000s")
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01T00:00:00+05:30"),"47117,0,0,19800","+05:30 = 19800s")
        quit
        ;
tTohNegativeOffset(pass,fail)   ;@TEST "toh of -HH:MM returns 4-piece with negative tzoff"
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01T00:00:00-05:00"),"47117,0,0,-18000","-05:00")
        quit
        ;
tTohSubsecondMillis(pass,fail)  ;@TEST "toh of .SSS appends microseconds (3->6 digit pad)"
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01T00:00:00.123"),"47117,0,123000",".123 -> 123000us")
        quit
        ;
tTohSubsecondMicros(pass,fail)  ;@TEST "toh of .SSSSSS preserves microseconds"
        do eq^STDASSERT(.pass,.fail,$$toh^STDDATE("1970-01-01T00:00:00.123456"),"47117,0,123456",".123456 us")
        quit
        ;
tTohRoundTripWithFromh(pass,fail)       ;@TEST "fromh(toh(x)) == x for canonical strings"
        new s
        for s="1840-12-31T00:00:00","1970-01-01T00:00:00","2026-05-05T17:42:31","2000-02-29T12:00:00" do
        . do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE($$toh^STDDATE(s)),s,"round-trip "_s)
        quit
        ;
tTohInvalidRaisesEcode(pass,fail)       ;@TEST "toh of malformed string raises U-STDDATE-BAD-ISO"
        do raises^STDASSERT(.pass,.fail,"new x set x=$$toh^STDDATE(""not-a-date"")","U-STDDATE-BAD-ISO","garbage")
        do raises^STDASSERT(.pass,.fail,"new x set x=$$toh^STDDATE(""2026-13-01"")","U-STDDATE-BAD-ISO","month 13")
        do raises^STDASSERT(.pass,.fail,"new x set x=$$toh^STDDATE(""2026-02-30"")","U-STDDATE-BAD-ISO","Feb 30")
        do raises^STDASSERT(.pass,.fail,"new x set x=$$toh^STDDATE(""1900-02-29"")","U-STDDATE-BAD-ISO","1900 not leap")
        quit
        ;
        ; =========================================================
        ; leap-year arithmetic
        ; =========================================================
        ;
tLeap2000IsLeap(pass,fail)      ;@TEST "year 2000 (div by 400) accepts Feb 29"
        ; Feb 29 2000 must round-trip through toh/fromh.
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE($$toh^STDDATE("2000-02-29")),"2000-02-29T00:00:00","2000 leap")
        quit
        ;
tLeap1900IsNotLeap(pass,fail)   ;@TEST "year 1900 (div by 100, not 400) rejects Feb 29"
        do raises^STDASSERT(.pass,.fail,"new x set x=$$toh^STDDATE(""1900-02-29"")","U-STDDATE-BAD-ISO","1900-02-29 invalid")
        quit
        ;
tLeap2400IsLeap(pass,fail)      ;@TEST "year 2400 (div by 400) accepts Feb 29"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE($$toh^STDDATE("2400-02-29")),"2400-02-29T00:00:00","2400 leap")
        quit
        ;
tLeap2024IsLeap(pass,fail)      ;@TEST "year 2024 (div by 4) accepts Feb 29"
        do eq^STDASSERT(.pass,.fail,$$fromh^STDDATE($$toh^STDDATE("2024-02-29")),"2024-02-29T00:00:00","2024 leap")
        quit
        ;
tLeap2023IsNotLeap(pass,fail)   ;@TEST "year 2023 (not div 4) rejects Feb 29"
        do raises^STDASSERT(.pass,.fail,"new x set x=$$toh^STDDATE(""2023-02-29"")","U-STDDATE-BAD-ISO","2023-02-29 invalid")
        quit
        ;
        ; =========================================================
        ; strftime
        ; =========================================================
        ;
tStrftimeYearFourDigits(pass,fail)      ;@TEST "%Y emits 4-digit year"
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,0","%Y"),"1970","unix epoch year")
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("0,0","%Y"),"1840","horolog day 0")
        quit
        ;
tStrftimeMonthZeroPad(pass,fail)        ;@TEST "%m zero-pads the month"
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,0","%m"),"01","Jan -> 01")
        quit
        ;
tStrftimeDayZeroPad(pass,fail)  ;@TEST "%d zero-pads the day"
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,0","%d"),"01","day 1 -> 01")
        quit
        ;
tStrftimeHourMinuteSecond(pass,fail)    ;@TEST "%H/%M/%S produce zero-padded time fields"
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,3661","%H"),"01","1h")
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,3661","%M"),"01","1m")
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,3661","%S"),"01","1s")
        quit
        ;
tStrftimeFullIsoCombo(pass,fail)        ;@TEST "%Y-%m-%dT%H:%M:%S composes into ISO-8601"
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,3661","%Y-%m-%dT%H:%M:%S"),"1970-01-01T01:01:01","full ISO compose")
        quit
        ;
tStrftimeLiteralPercent(pass,fail)      ;@TEST "%% emits a single literal percent"
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,0","%%Y=%Y"),"%Y=1970","%% literal")
        quit
        ;
tStrftimeOffsetZ(pass,fail)     ;@TEST "%z emits +HHMM / -HHMM (or empty if no tz piece)"
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,0,0,18000","%z"),"+0500","+05:00")
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,0,0,-18000","%z"),"-0500","-05:00")
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,0,0,0","%z"),"+0000","UTC")
        do eq^STDASSERT(.pass,.fail,$$strftime^STDDATE("47117,0","%z"),"","2-piece -> empty")
        quit
        ;
        ; =========================================================
        ; strptime
        ; =========================================================
        ;
tStrptimeDateOnly(pass,fail)    ;@TEST "strptime parses %Y-%m-%d to days,0"
        do eq^STDASSERT(.pass,.fail,$$strptime^STDDATE("1970-01-01","%Y-%m-%d"),"47117,0","date only")
        quit
        ;
tStrptimeFullIso(pass,fail)     ;@TEST "strptime parses %Y-%m-%dT%H:%M:%S to days,seconds"
        do eq^STDASSERT(.pass,.fail,$$strptime^STDDATE("1970-01-01T01:01:01","%Y-%m-%dT%H:%M:%S"),"47117,3661","full ISO")
        quit
        ;
tStrptimeInvalidRaisesEcode(pass,fail)  ;@TEST "strptime mismatch raises U-STDDATE-BAD-ISO"
        do raises^STDASSERT(.pass,.fail,"new x set x=$$strptime^STDDATE(""nope"",""%Y-%m-%d"")","U-STDDATE-BAD-ISO","mismatch")
        quit
        ;
        ; =========================================================
        ; add — ISO-8601 duration
        ; =========================================================
        ;
tAddOneDay(pass,fail)   ;@TEST "add P1D advances the day counter by one"
        do eq^STDASSERT(.pass,.fail,$$add^STDDATE("47117,0","P1D"),"47118,0","+1 day")
        quit
        ;
tAddOneDayTwoHourThirtyMinutes(pass,fail)       ;@TEST "add P1DT2H30M shifts day + time-of-day"
        do eq^STDASSERT(.pass,.fail,$$add^STDDATE("47117,0","P1DT2H30M"),"47118,9000","+1d2h30m = +9000s on day+1")
        quit
        ;
tAddOneMonthRollover(pass,fail) ;@TEST "add P1M advances calendar month"
        ; 1970-01-15 + 1M = 1970-02-15. day 47131, seconds 0.
        do eq^STDASSERT(.pass,.fail,$$add^STDDATE($$toh^STDDATE("1970-01-15"),"P1M"),$$toh^STDDATE("1970-02-15"),"+1 month")
        quit
        ;
tAddOneYearOnLeapDayClamps(pass,fail)   ;@TEST "add P1Y on Feb 29 clamps to Feb 28 in non-leap year"
        ; 2024-02-29 + 1Y = 2025-02-28 (Python convention; Feb 29 doesn't exist in 2025).
        do eq^STDASSERT(.pass,.fail,$$add^STDDATE($$toh^STDDATE("2024-02-29"),"P1Y"),$$toh^STDDATE("2025-02-28"),"clamp leap day")
        quit
        ;
tAddNegativeDuration(pass,fail) ;@TEST "add -P1D subtracts one day"
        do eq^STDASSERT(.pass,.fail,$$add^STDDATE("47117,0","-P1D"),"47116,0","-1 day")
        quit
        ;
tAddSecondsCarryDay(pass,fail)  ;@TEST "add PT86400S carries into the day field"
        do eq^STDASSERT(.pass,.fail,$$add^STDDATE("47117,0","PT86400S"),"47118,0","86400s = +1 day")
        do eq^STDASSERT(.pass,.fail,$$add^STDDATE("47117,3600","PT82800S"),"47118,0","3600+82800=86400 carry")
        quit
        ;
        ; =========================================================
        ; diff — ISO-8601 duration
        ; =========================================================
        ;
tDiffEqualHorologsIsZero(pass,fail)     ;@TEST "diff of equal horologs returns PT0S"
        do eq^STDASSERT(.pass,.fail,$$diff^STDDATE("47117,0","47117,0"),"PT0S","0 diff")
        quit
        ;
tDiffOneDayApart(pass,fail)     ;@TEST "diff of (47117,0) -> (47118,0) returns P1D"
        do eq^STDASSERT(.pass,.fail,$$diff^STDDATE("47117,0","47118,0"),"P1D","+1 day")
        quit
        ;
tDiffSecondsOnly(pass,fail)     ;@TEST "diff of seconds-only difference returns PTnS form"
        do eq^STDASSERT(.pass,.fail,$$diff^STDDATE("47117,0","47117,1"),"PT1S","1s")
        do eq^STDASSERT(.pass,.fail,$$diff^STDDATE("47117,0","47117,3661"),"PT1H1M1S","3661s = 1h1m1s")
        quit
        ;
tDiffNegativeWhenH2Earlier(pass,fail)   ;@TEST "diff returns -P prefix when h2 < h1"
        do eq^STDASSERT(.pass,.fail,$$diff^STDDATE("47118,0","47117,0"),"-P1D","-1 day")
        quit
        ;
        ; =========================================================
        ; now — current ISO-8601 UTC
        ; =========================================================
        ;
tNowEndsWithZ(pass,fail)        ;@TEST "now() returns ISO-8601 UTC ending with Z"
        new n set n=$$now^STDDATE()
        do eq^STDASSERT(.pass,.fail,$extract(n,$length(n)),"Z","trailing Z")
        quit
        ;
tNowContainsCurrentYear(pass,fail)      ;@TEST "now() includes the current year"
        ; Sanity-only: the year is between 2024 and 2100.
        new n,y
        set n=$$now^STDDATE()
        set y=+$extract(n,1,4)
        do true^STDASSERT(.pass,.fail,(y>2024)&(y<2100),"year in plausible range")
        quit
        ;
tNowSortsLexically(pass,fail)   ;@TEST "two now() calls sort in generation order"
        new a,b
        set a=$$now^STDDATE()
        hang 0.005
        set b=$$now^STDDATE()
        do true^STDASSERT(.pass,.fail,b]]a,"b sorts at-or-after a")
        quit
        ;
        ; =========================================================
        ; round-trip property
        ; =========================================================
        ;
tRoundTripFromhTohRandomDays(pass,fail) ;@TEST "fromh/toh round-trip across 200 random days"
        ; Pick 200 random horologs in 0..36500 (covers ~100y from epoch);
        ; round-trip each through fromh -> toh and confirm equality.
        new i,d,s,h,iso,h2,bad
        set bad=0
        for i=1:1:200 do
        . set d=$random(36500)
        . set s=$random(86400)
        . set h=d_","_s
        . set iso=$$fromh^STDDATE(h)
        . set h2=$$toh^STDDATE(iso)
        . if h2'=h set bad=$increment(bad)
        do eq^STDASSERT(.pass,.fail,bad,0,"no round-trip failures over 200 samples")
        quit
