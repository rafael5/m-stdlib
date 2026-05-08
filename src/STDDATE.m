STDDATE ; m-stdlib — ISO-8601 datetime + arithmetic (v0.0.5).
        ;
        ; Public extrinsics:
        ;   $$now^STDDATE()                  — current ISO-8601 UTC ("...Z")
        ;   $$fromh^STDDATE(h)               — $HOROLOG -> ISO-8601 string
        ;   $$toh^STDDATE(iso)               — ISO-8601 -> $HOROLOG form
        ;   $$strftime^STDDATE(h,fmt)        — format horolog per fmt
        ;   $$strptime^STDDATE(text,fmt)     — parse text per fmt -> horolog
        ;   $$add^STDDATE(h,dur)             — h + ISO-8601 duration -> horolog
        ;   $$diff^STDDATE(h1,h2)            — h2-h1 -> ISO-8601 duration
        ;
        ; Horolog forms accepted/emitted:
        ;   2-piece: D,S         ($HOROLOG)
        ;   3-piece: D,S,U       (with microseconds)
        ;   4-piece: D,S,U,T     (with microseconds and tz offset in seconds)
        ;
        ; Calendar: proleptic Gregorian. Day 0 = 1840-12-31 (M $HOROLOG epoch);
        ; Unix epoch (1970-01-01) = day 47117. Civil <-> day-count conversions
        ; use Howard Hinnant's "days_from_civil" algorithm — works for any
        ; year in proleptic Gregorian.
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDDATE-BAD-HOROLOG,
        ;   ,U-STDDATE-BAD-ISO,
        ;   ,U-STDDATE-BAD-DUR,
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
now()   ; Return current time as ISO-8601 UTC with millisecond precision.
        ; doc: @returns       string  ISO-8601 UTC: "YYYY-MM-DDTHH:MM:SS.sssZ"
        ; doc: @example       write $$now^STDDATE()           ; ISO-8601 UTC, e.g. 2026-05-05T17:42:31.123Z
        ; doc: @example       write $length($$now^STDDATE())  ; 24
        ; doc: @since         v0.0.5
        ; doc: @stable        stable
        ; doc: @see           $$fromh^STDDATE, $$strftime^STDDATE
        ; doc: Always trailing Z. Source: $ZHOROLOG (microsecond + tz pieces).
        new dh,d,s,u,t,utcD,utcS,y,m,dd,hh,mm,ss,ms
        ; m-lint: disable-next-line=M-MOD-022
        set dh=$zhorolog
        set d=$piece(dh,",",1),s=$piece(dh,",",2)
        set u=$piece(dh,",",3),t=$piece(dh,",",4)
        ; convert local -> UTC by subtracting tzoff seconds
        set s=s-t
        set utcD=d+(s\86400),utcS=s#86400
        if utcS<0 set utcS=utcS+86400,utcD=utcD-1
        do civilFromDays(utcD-47117,.y,.m,.dd)
        set hh=utcS\3600,mm=(utcS#3600)\60,ss=utcS#60
        set ms=u\1000
        quit $$padL(y,4,"0")_"-"_$$padL(m,2,"0")_"-"_$$padL(dd,2,"0")_"T"_$$padL(hh,2,"0")_":"_$$padL(mm,2,"0")_":"_$$padL(ss,2,"0")_"."_$$padL(ms,3,"0")_"Z"
        ;
fromh(h)        ; Format a $HOROLOG (2/3/4-piece) as ISO-8601.
        ; doc: @param h       horolog  comma-piece form: D,S | D,S,U | D,S,U,T
        ; doc: @returns       string   ISO-8601 rendering (precision matches piece-count)
        ; doc: @raises        U-STDDATE-BAD-HOROLOG  `h` is not a 2/3/4-piece comma string
        ; doc: @example       write $$fromh^STDDATE("47117,0")  ; "1970-01-01T00:00:00"
        ; doc: @since         v0.0.5
        ; doc: @stable        stable
        ; doc: @see           $$toh^STDDATE, $$strftime^STDDATE
        ; doc: 2-piece D,S        -> "YYYY-MM-DDTHH:MM:SS"
        ; doc: 3-piece D,S,U      -> "...HH:MM:SS.uuuuuu" when U>0
        ; doc: 4-piece D,S,U,T    -> "..." + "Z" or "+HH:MM" / "-HH:MM"
        new np,d,s,u,t,iso
        set np=$length(h,",")
        if (np<2)!(np>4) set $ecode=",U-STDDATE-BAD-HOROLOG," quit ""
        set d=+$piece(h,",",1),s=+$piece(h,",",2)
        set u=$select(np>2:+$piece(h,",",3),1:0)
        set iso=$$fmtDate(d)_"T"_$$fmtTime(s)
        if u>0 set iso=iso_"."_$$padL(u,6,"0")
        if np>3 set t=+$piece(h,",",4),iso=iso_$$fmtTzColon(t)
        quit iso
        ;
toh(iso)        ; Parse an ISO-8601 string into $HOROLOG form.
        ; doc: @param iso     string   ISO-8601: date, date+time, or date+time+tz
        ; doc: @returns       horolog  2/3/4-piece comma string; "" on parse failure
        ; doc: @raises        U-STDDATE-BAD-ISO  malformed input or invalid date
        ; doc: @example       write $$toh^STDDATE("1970-01-01")  ; "47117,0"
        ; doc: @since         v0.0.5
        ; doc: @stable        stable
        ; doc: @see           $$fromh^STDDATE, $$strptime^STDDATE
        ; doc: 2-piece D,S for date or date+time without subsec/tz;
        ; doc: 3-piece D,S,U if subseconds present; 4-piece D,S,U,T if tz.
        ; doc: "Z" -> tzoff=0. "+HH:MM"/"-HH:MM" -> tzoff in seconds.
        new len,y,m,d,hh,mm,ss,us,tz,rest,horolog,sec
        set len=$length(iso)
        if len<10 set $ecode=",U-STDDATE-BAD-ISO," quit ""
        set y=$extract(iso,1,4),m=$extract(iso,6,7),d=$extract(iso,9,10)
        if '$$validDate(+y,+m,+d) set $ecode=",U-STDDATE-BAD-ISO," quit ""
        set horolog=$$civilToDays(+y,+m,+d)+47117
        if len=10 quit horolog_",0"
        if len<19 set $ecode=",U-STDDATE-BAD-ISO," quit ""
        set hh=$extract(iso,12,13),mm=$extract(iso,15,16),ss=$extract(iso,18,19)
        if (+hh>23)!(+mm>59)!(+ss>59) set $ecode=",U-STDDATE-BAD-ISO," quit ""
        set rest=$extract(iso,20,len),us=0,tz=""
        if $extract(rest,1)="." do parseFrac(.rest,.us)
        if $ecode'="" quit ""
        if rest="Z" set tz=0
        if (rest'="Z")&(rest'="") do parseTz(rest,.tz)
        if $ecode'="" quit ""
        set sec=(hh*3600)+(mm*60)+ss
        if (us=0)&(tz="") quit horolog_","_sec
        if tz="" quit horolog_","_sec_","_us
        quit horolog_","_sec_","_us_","_tz
        ;
parseFrac(rest,us)      ; Parse leading ".ddd..." in rest into us. Mutates rest.
        ; doc: @internal
        ; doc: Moves rest past the fractional. Up to 6 digits kept.
        new fe,frac
        set fe=2
        for  quit:fe>$length(rest)  quit:'($extract(rest,fe)?1N)  set fe=fe+1
        set frac=$extract(rest,2,fe-1)
        if $length(frac)<1 set $ecode=",U-STDDATE-BAD-ISO," quit
        set us=+$extract(frac_"000000",1,6)
        set rest=$extract(rest,fe,$length(rest))
        quit
        ;
parseTz(rest,tz)        ; Parse a +HH:MM / -HH:MM suffix into tz seconds.
        ; doc: @internal
        ; doc: Sets $ECODE on malformed offset.
        new sgn,th,tm
        set sgn=$extract(rest,1)
        if (sgn'="+")&(sgn'="-") set $ecode=",U-STDDATE-BAD-ISO," quit
        if ($length(rest)'=6)!($extract(rest,4)'=":") set $ecode=",U-STDDATE-BAD-ISO," quit
        set th=$extract(rest,2,3),tm=$extract(rest,5,6)
        if (th_tm)'?4N set $ecode=",U-STDDATE-BAD-ISO," quit
        set tz=(th*3600)+(tm*60)
        if sgn="-" set tz=-tz
        quit
        ;
strftime(h,fmt) ; Format a horolog per a strftime-style format string.
        ; doc: @param h       horolog  comma-piece form: D,S | D,S,U | D,S,U,T
        ; doc: @param fmt     string   format string with %Y %m %d %H %M %S %j %z %% directives
        ; doc: @returns       string   the rendered date/time
        ; doc: @raises        U-STDDATE-BAD-HOROLOG  `h` is not a 2/3/4-piece comma string
        ; doc: @example       write $$strftime^STDDATE("47117,0","%Y-%m-%d")  ; "1970-01-01"
        ; doc: @since         v0.0.5
        ; doc: @stable        stable
        ; doc: @see           $$strptime^STDDATE, $$fromh^STDDATE
        ; doc: Unknown directives pass through as "%X". %z emits +HHMM/-HHMM
        ; doc: (no colon) or "" if h has no tz piece.
        new np,d,s,u,t,y,m,dd,hh,mm,ss,out,i,c,nc
        set np=$length(h,",")
        if (np<2)!(np>4) set $ecode=",U-STDDATE-BAD-HOROLOG," quit ""
        set d=+$piece(h,",",1),s=+$piece(h,",",2)
        do civilFromDays(d-47117,.y,.m,.dd)
        set hh=s\3600,mm=(s#3600)\60,ss=s#60
        set out="",i=1
        for  quit:i>$length(fmt)  do
        . set c=$extract(fmt,i)
        . if c'="%" set out=out_c,i=i+1 quit
        . set nc=$extract(fmt,i+1),i=i+2
        . if nc="Y" set out=out_$$padL(y,4,"0") quit
        . if nc="m" set out=out_$$padL(m,2,"0") quit
        . if nc="d" set out=out_$$padL(dd,2,"0") quit
        . if nc="H" set out=out_$$padL(hh,2,"0") quit
        . if nc="M" set out=out_$$padL(mm,2,"0") quit
        . if nc="S" set out=out_$$padL(ss,2,"0") quit
        . if nc="j" set out=out_$$padL($$dayOfYear(y,m,dd),3,"0") quit
        . if nc="z" set out=out_$select(np<4:"",1:$$fmtTzCompact(+$piece(h,",",4))) quit
        . if nc="%" set out=out_"%" quit
        . set out=out_"%"_nc
        quit out
        ;
strptime(text,fmt)      ; Parse text per format string into a horolog.
        ; doc: @param text    string   the input text to parse
        ; doc: @param fmt     string   format string with %Y %m %d %H %M %S directives
        ; doc: @returns       horolog  2-piece D,S; "" on parse failure
        ; doc: @raises        U-STDDATE-BAD-ISO  parse mismatch or invalid date components
        ; doc: @example       write $$strptime^STDDATE("1970-01-01","%Y-%m-%d")  ; "47117,0"
        ; doc: @since         v0.0.5
        ; doc: @stable        stable
        ; doc: @see           $$strftime^STDDATE, $$toh^STDDATE
        ; doc: Literal characters in fmt must match `text` exactly; only the
        ; doc: documented directives are honoured.
        new ti,fi,c,nc,n,wid,y,m,d,hh,mm,ss
        set y=1970,m=1,d=1,hh=0,mm=0,ss=0
        set ti=1,fi=1
        for  quit:fi>$length(fmt)  quit:$ecode'=""  do
        . set c=$extract(fmt,fi)
        . if c'="%" do  quit
        . . if $extract(text,ti)'=c set $ecode=",U-STDDATE-BAD-ISO," quit
        . . set ti=ti+1,fi=fi+1
        . set nc=$extract(fmt,fi+1),fi=fi+2
        . set wid=$select(nc="Y":4,1:2)
        . set n=$extract(text,ti,ti+wid-1)
        . if ($length(n)'=wid)!(n'?1.N) set $ecode=",U-STDDATE-BAD-ISO," quit
        . set ti=ti+wid
        . if nc="Y" set y=+n quit
        . if nc="m" set m=+n quit
        . if nc="d" set d=+n quit
        . if nc="H" set hh=+n quit
        . if nc="M" set mm=+n quit
        . if nc="S" set ss=+n quit
        . set $ecode=",U-STDDATE-BAD-ISO,"
        if $ecode'="" quit ""
        if ti'>$length(text) set $ecode=",U-STDDATE-BAD-ISO," quit ""
        if '$$validDate(y,m,d) set $ecode=",U-STDDATE-BAD-ISO," quit ""
        quit ($$civilToDays(y,m,d)+47117)_","_((hh*3600)+(mm*60)+ss)
        ;
add(h,dur)      ; Add an ISO-8601 duration to a horolog. Negative prefix "-P..." accepted.
        ; doc: @param h       horolog  comma-piece form: D,S | D,S,U | D,S,U,T
        ; doc: @param dur     string   ISO-8601 duration ("P1Y", "PT2H30M", "-P1D", etc.)
        ; doc: @returns       horolog  2-piece D,S after addition; "" on error
        ; doc: @raises        U-STDDATE-BAD-DUR      `dur` is not a valid ISO-8601 duration
        ; doc: @raises        U-STDDATE-BAD-HOROLOG  `h` is not a 2/3/4-piece comma string
        ; doc: @example       write $$add^STDDATE("47117,0","P1DT2H30M")  ; "47118,9000"
        ; doc: @since         v0.0.5
        ; doc: @stable        stable
        ; doc: @see           $$diff^STDDATE
        ; doc: Calendar arithmetic for Y/M (with day-clamp on shorter months);
        ; doc: raw day arithmetic for W/D; second-arithmetic for H/M/S.
        new neg,p,years,months,weeks,days,hours,mins,secs,inT,num,i,c
        new np,d,s,y,m,dd,sec,dim
        set neg=0,p=dur
        if $extract(p,1)="-" set neg=1,p=$extract(p,2,$length(p))
        if $extract(p,1)'="P" set $ecode=",U-STDDATE-BAD-DUR," quit ""
        set p=$extract(p,2,$length(p))
        set years=0,months=0,weeks=0,days=0,hours=0,mins=0,secs=0
        set inT=0,num="",i=1
        for  quit:i>$length(p)  do  quit:$ecode'=""
        . set c=$extract(p,i),i=i+1
        . if c="T" set inT=1,num="" quit
        . if (c?1N)!(c=".") set num=num_c quit
        . if c="Y" set years=+num,num="" quit
        . if c="W" set weeks=+num,num="" quit
        . if c="D" set days=+num,num="" quit
        . if c="H" set hours=+num,num="" quit
        . if c="S" set secs=+num,num="" quit
        . if c="M" do  quit
        . . if 'inT set months=+num,num="" quit
        . . set mins=+num,num=""
        . set $ecode=",U-STDDATE-BAD-DUR,"
        if $ecode'="" quit ""
        if neg set years=-years,months=-months,weeks=-weeks,days=-days
        if neg set hours=-hours,mins=-mins,secs=-secs
        set np=$length(h,",")
        if (np<2)!(np>4) set $ecode=",U-STDDATE-BAD-HOROLOG," quit ""
        set d=+$piece(h,",",1),s=+$piece(h,",",2)
        do civilFromDays(d-47117,.y,.m,.dd)
        set y=y+years,m=m+months
        for  quit:m>0  set m=m+12,y=y-1
        for  quit:m<13  set m=m-12,y=y+1
        set dim=$$daysInMonth(y,m)
        if dd>dim set dd=dim
        set d=$$civilToDays(y,m,dd)+47117
        set d=d+(weeks*7)+days
        set sec=s+(hours*3600)+(mins*60)+secs
        set d=d+(sec\86400),sec=sec#86400
        if sec<0 set sec=sec+86400,d=d-1
        quit d_","_sec
        ;
diff(h1,h2)     ; Return h2 - h1 as an ISO-8601 duration.
        ; doc: @param h1      horolog  start time (2-piece D,S minimum)
        ; doc: @param h2      horolog  end time (2-piece D,S minimum)
        ; doc: @returns       string   ISO-8601 duration; "PT0S" if zero; "-P..." if h2 < h1
        ; doc: @example       write $$diff^STDDATE("47117,0","47118,0")  ; "P1D"
        ; doc: @since         v0.0.5
        ; doc: @stable        stable
        ; doc: @see           $$add^STDDATE
        ; doc: Days carry into hours/minutes/seconds; never emits Y or M
        ; doc: (variable-length).
        new d1,s1,d2,s2,total,neg,days,hours,mins,secs,out
        set d1=+$piece(h1,",",1),s1=+$piece(h1,",",2)
        set d2=+$piece(h2,",",1),s2=+$piece(h2,",",2)
        set total=((d2-d1)*86400)+(s2-s1)
        if total=0 quit "PT0S"
        set neg=0
        if total<0 set neg=1,total=-total
        set days=total\86400,total=total#86400
        set hours=total\3600,total=total#3600
        set mins=total\60,secs=total#60
        set out="P"
        if days>0 set out=out_days_"D"
        if (hours>0)!(mins>0)!(secs>0) do
        . set out=out_"T"
        . if hours>0 set out=out_hours_"H"
        . if mins>0 set out=out_mins_"M"
        . if secs>0 set out=out_secs_"S"
        if neg set out="-"_out
        quit out
        ;
        ; ---------- internal helpers ----------
        ;
civilFromDays(z,y,m,d)  ; Howard Hinnant: days since 1970-01-01 -> (y,m,d).
        ; doc: @internal
        ; doc: Proleptic Gregorian conversion. y,m,d returned by-ref.
        new era,doe,yoe,doy,mp
        set z=z+719468
        set era=z\146097
        if (z<0)&((z#146097)'=0) set era=era-1
        set doe=z-(era*146097)
        set yoe=(doe-(doe\1460)+(doe\36524)-(doe\146096))\365
        set y=yoe+(era*400)
        set doy=doe-((365*yoe)+(yoe\4)-(yoe\100))
        set mp=((5*doy)+2)\153
        set d=doy-(((153*mp)+2)\5)+1
        if mp<10 set m=mp+3
        else  set m=mp-9
        if m<3 set y=y+1
        quit
        ;
civilToDays(y,m,d)      ; Howard Hinnant inverse: (y,m,d) -> days since 1970-01-01.
        ; doc: @internal
        ; doc: Does not validate input. Pair with $$validDate first.
        new yy,era,yoe,doy,doe
        set yy=$select(m<3:y-1,1:y)
        set era=yy\400
        if (yy<0)&((yy#400)'=0) set era=era-1
        set yoe=yy-(era*400)
        if m>2 set doy=((153*(m-3))+2)\5+d-1
        else  set doy=((153*(m+9))+2)\5+d-1
        set doe=(yoe*365)+(yoe\4)-(yoe\100)+doy
        quit (era*146097)+doe-719468
        ;
isLeap(y)       ; Return 1 if y is a leap year in the proleptic Gregorian calendar.
        ; doc: @internal
        ; doc: Div-4-not-100-or-400 rule.
        if (y#400)=0 quit 1
        if (y#100)=0 quit 0
        if (y#4)=0 quit 1
        quit 0
        ;
daysInMonth(y,m)        ; Return the number of days in (y,m).
        ; doc: @internal
        ; doc: Apr/Jun/Sep/Nov=30; Feb=28 or 29; else 31.
        if (m=4)!(m=6)!(m=9)!(m=11) quit 30
        if m=2 quit $select($$isLeap(y):29,1:28)
        quit 31
        ;
validDate(y,m,d)        ; Return 1 if (y,m,d) is a valid civil date; else 0.
        ; doc: @internal
        ; doc: Month 1..12 and day 1..daysInMonth.
        if (m<1)!(m>12) quit 0
        if (d<1)!(d>$$daysInMonth(y,m)) quit 0
        quit 1
        ;
dayOfYear(y,m,d)        ; Return the day-of-year (1..366) for (y,m,d).
        ; doc: @internal
        ; doc: Used by strftime %j.
        new t,mi
        set t=d
        for mi=1:1:m-1 set t=t+$$daysInMonth(y,mi)
        quit t
        ;
fmtDate(d)      ; Format horolog days as YYYY-MM-DD.
        ; doc: @internal
        ; doc: d is days since 1840-12-31 (M $HOROLOG epoch).
        new y,mo,da
        do civilFromDays(d-47117,.y,.mo,.da)
        quit $$padL(y,4,"0")_"-"_$$padL(mo,2,"0")_"-"_$$padL(da,2,"0")
        ;
fmtTime(s)      ; Format seconds-into-day as HH:MM:SS.
        ; doc: @internal
        ; doc: s in 0..86399.
        quit $$padL(s\3600,2,"0")_":"_$$padL((s#3600)\60,2,"0")_":"_$$padL(s#60,2,"0")
        ;
fmtTzColon(t)   ; Format tz offset (seconds) as Z / +HH:MM / -HH:MM.
        ; doc: @internal
        ; doc: Used by fromh's 4-piece path.
        new sgn,a
        if t=0 quit "Z"
        set sgn=$select(t<0:"-",1:"+")
        set a=$select(t<0:-t,1:t)
        quit sgn_$$padL(a\3600,2,"0")_":"_$$padL((a\60)#60,2,"0")
        ;
fmtTzCompact(t) ; Format tz offset as +HHMM / -HHMM (no colon, no Z).
        ; doc: @internal
        ; doc: Used by strftime %z (POSIX-compatible).
        new sgn,a
        set sgn=$select(t<0:"-",1:"+")
        set a=$select(t<0:-t,1:t)
        quit sgn_$$padL(a\3600,2,"0")_$$padL((a\60)#60,2,"0")
        ;
padL(s,n,ch)    ; Left-pad string s with ch up to length n.
        ; doc: @internal
        ; doc: Used everywhere zero-padding is needed.
        new r set r=s
        for  quit:$length(r)'<n  set r=ch_r
        quit r
