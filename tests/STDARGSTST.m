STDARGSTST      ; Test suite for STDARGS (v0.0.7).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---- handle / lifecycle ----
        do tNewReturnsInteger(.pass,.fail)
        do tNewIsolatesParsers(.pass,.fail)
        do tFreeRemovesState(.pass,.fail)
        ;
        ; ---- flag actions (long form) ----
        do tStoreTrueLongFlag(.pass,.fail)
        do tStoreTrueAbsentDefaultsZero(.pass,.fail)
        do tStoreTakesNextToken(.pass,.fail)
        do tCountLongFlag(.pass,.fail)
        do tAppendLongFlag(.pass,.fail)
        ;
        ; ---- short flags ----
        do tStoreTrueShortFlag(.pass,.fail)
        do tStoreShortFlagTakesNextToken(.pass,.fail)
        do tGroupedShortCountFlags(.pass,.fail)
        ;
        ; ---- positional ----
        do tSinglePositional(.pass,.fail)
        do tTwoPositionalsInOrder(.pass,.fail)
        do tFlagsBeforePositional(.pass,.fail)
        do tFlagsAfterPositional(.pass,.fail)
        ;
        ; ---- -- terminator ----
        do tDashDashTerminator(.pass,.fail)
        do tDashDashAllowsLeadingDashTokens(.pass,.fail)
        ;
        ; ---- sub-commands ----
        do tSubcommandDispatchesToSubparser(.pass,.fail)
        do tSubcommandRecordsName(.pass,.fail)
        ;
        ; ---- error paths ----
        do tUnknownLongFlagRaises(.pass,.fail)
        do tUnknownShortFlagRaises(.pass,.fail)
        do tMissingValueRaises(.pass,.fail)
        do tMissingPositionalRaises(.pass,.fail)
        do tUnknownSubcommandRaises(.pass,.fail)
        do tUnknownActionRaises(.pass,.fail)
        ;
        ; ---- help ----
        do tHelpContainsProgAndDescription(.pass,.fail)
        do tHelpListsLongAndShortFlags(.pass,.fail)
        do tHelpListsPositionals(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- handle / lifecycle ----------
        ;
tNewReturnsInteger(pass,fail)   ;@TEST "$$new() returns a positive integer handle"
        new p
        set p=$$new^STDARGS("demo","a demo")
        do true^STDASSERT(.pass,.fail,p>0,"handle is positive")
        do free^STDARGS(p)
        quit
        ;
tNewIsolatesParsers(pass,fail)  ;@TEST "$$new() returns distinct handles each call"
        new p1,p2
        set p1=$$new^STDARGS("a","")
        set p2=$$new^STDARGS("b","")
        do ne^STDASSERT(.pass,.fail,p1,p2,"distinct handles")
        do free^STDARGS(p1)
        do free^STDARGS(p2)
        quit
        ;
tFreeRemovesState(pass,fail)    ;@TEST "free() removes the parser's state"
        new p
        set p=$$new^STDARGS("a","")
        do free^STDARGS(p)
        do false^STDASSERT(.pass,.fail,$data(^STDLIB($job,"stdargs",p)),"state removed after free")
        quit
        ;
        ; ---------- flag actions (long form) ----------
        ;
tStoreTrueLongFlag(pass,fail)   ;@TEST "store_true sets dest=1 when long flag present"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do parse^STDARGS(p,"--verbose",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("verbose")),1,"verbose=1")
        do free^STDARGS(p)
        quit
        ;
tStoreTrueAbsentDefaultsZero(pass,fail) ;@TEST "store_true defaults to 0 when flag absent"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do parse^STDARGS(p,"",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("verbose")),0,"verbose=0")
        do free^STDARGS(p)
        quit
        ;
tStoreTakesNextToken(pass,fail) ;@TEST "store action consumes the next token as value"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--name","-n","store","name")
        do parse^STDARGS(p,"--name alice",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("name")),"alice","name=alice")
        do free^STDARGS(p)
        quit
        ;
tCountLongFlag(pass,fail)       ;@TEST "count action increments dest per occurrence"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","count","verbose")
        do parse^STDARGS(p,"--verbose --verbose --verbose",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("verbose")),3,"verbose=3")
        do free^STDARGS(p)
        quit
        ;
tAppendLongFlag(pass,fail)      ;@TEST "append action accumulates values into ns(dest,k)"
        new p,ns,joined
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--include","-I","append","include")
        do parse^STDARGS(p,"--include a --include b --include c",.ns)
        set joined=$get(ns("include",1))_","_$get(ns("include",2))_","_$get(ns("include",3))
        do eq^STDASSERT(.pass,.fail,joined,"a,b,c","include=[a,b,c]")
        do free^STDARGS(p)
        quit
        ;
        ; ---------- short flags ----------
        ;
tStoreTrueShortFlag(pass,fail)  ;@TEST "store_true honours short flag form"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do parse^STDARGS(p,"-v",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("verbose")),1,"verbose=1")
        do free^STDARGS(p)
        quit
        ;
tStoreShortFlagTakesNextToken(pass,fail)        ;@TEST "store action with short flag consumes next token"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--name","-n","store","name")
        do parse^STDARGS(p,"-n bob",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("name")),"bob","name=bob")
        do free^STDARGS(p)
        quit
        ;
tGroupedShortCountFlags(pass,fail)      ;@TEST "grouped short count flags expand: -vvv = three increments"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","count","verbose")
        do parse^STDARGS(p,"-vvv",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("verbose")),3,"verbose=3 from -vvv")
        do free^STDARGS(p)
        quit
        ;
        ; ---------- positional ----------
        ;
tSinglePositional(pass,fail)    ;@TEST "single positional fills its dest"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addpos^STDARGS(p,"path","path")
        do parse^STDARGS(p,"/etc/hosts",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("path")),"/etc/hosts","path=/etc/hosts")
        do free^STDARGS(p)
        quit
        ;
tTwoPositionalsInOrder(pass,fail)       ;@TEST "two positionals fill in declaration order"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addpos^STDARGS(p,"src","src")
        do addpos^STDARGS(p,"dst","dst")
        do parse^STDARGS(p,"a.txt b.txt",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("src")),"a.txt","src=a.txt")
        do eq^STDASSERT(.pass,.fail,$get(ns("dst")),"b.txt","dst=b.txt")
        do free^STDARGS(p)
        quit
        ;
tFlagsBeforePositional(pass,fail)       ;@TEST "flags before positionals parse correctly"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do addpos^STDARGS(p,"path","path")
        do parse^STDARGS(p,"--verbose /etc/hosts",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("verbose")),1,"verbose=1")
        do eq^STDASSERT(.pass,.fail,$get(ns("path")),"/etc/hosts","path=/etc/hosts")
        do free^STDARGS(p)
        quit
        ;
tFlagsAfterPositional(pass,fail)        ;@TEST "flags after positionals also parse"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do addpos^STDARGS(p,"path","path")
        do parse^STDARGS(p,"/etc/hosts --verbose",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("verbose")),1,"verbose=1")
        do eq^STDASSERT(.pass,.fail,$get(ns("path")),"/etc/hosts","path=/etc/hosts")
        do free^STDARGS(p)
        quit
        ;
        ; ---------- -- terminator ----------
        ;
tDashDashTerminator(pass,fail)  ;@TEST "-- ends flag parsing; rest is positional"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do addpos^STDARGS(p,"path","path")
        do parse^STDARGS(p,"-- --verbose",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("verbose")),0,"verbose=0 (consumed as positional)")
        do eq^STDASSERT(.pass,.fail,$get(ns("path")),"--verbose","path=--verbose")
        do free^STDARGS(p)
        quit
        ;
tDashDashAllowsLeadingDashTokens(pass,fail)     ;@TEST "tokens after -- are taken verbatim even with leading -"
        new p,ns
        set p=$$new^STDARGS("demo","")
        do addpos^STDARGS(p,"path","path")
        do parse^STDARGS(p,"-- -strange-name",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("path")),"-strange-name","path=-strange-name")
        do free^STDARGS(p)
        quit
        ;
        ; ---------- sub-commands ----------
        ;
tSubcommandDispatchesToSubparser(pass,fail)     ;@TEST "subcommand routes remaining tokens to its sub-parser"
        new p,sub,ns
        set p=$$new^STDARGS("demo","")
        set sub=$$new^STDARGS("demo add","")
        do addflag^STDARGS(sub,"--name","-n","store","name")
        do addsub^STDARGS(p,"add",sub)
        do parse^STDARGS(p,"add --name alice",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("name")),"alice","sub-parser populated ns")
        do free^STDARGS(p)
        do free^STDARGS(sub)
        quit
        ;
tSubcommandRecordsName(pass,fail)       ;@TEST "the subcommand name is recorded under ns(""__sub__"")"
        new p,sub,ns
        set p=$$new^STDARGS("demo","")
        set sub=$$new^STDARGS("demo add","")
        do addsub^STDARGS(p,"add",sub)
        do parse^STDARGS(p,"add",.ns)
        do eq^STDASSERT(.pass,.fail,$get(ns("__sub__")),"add","subcommand=add")
        do free^STDARGS(p)
        do free^STDARGS(sub)
        quit
        ;
        ; ---------- error paths ----------
        ;
tUnknownLongFlagRaises(pass,fail)       ;@TEST "unknown long flag raises U-STDARGS-UNKNOWN-FLAG"
        new p
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do raises^STDASSERT(.pass,.fail,"new ns do parse^STDARGS("_p_",""--bogus"",.ns)","U-STDARGS-UNKNOWN-FLAG","--bogus rejected")
        do free^STDARGS(p)
        quit
        ;
tUnknownShortFlagRaises(pass,fail)      ;@TEST "unknown short flag raises U-STDARGS-UNKNOWN-FLAG"
        new p
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do raises^STDASSERT(.pass,.fail,"new ns do parse^STDARGS("_p_",""-x"",.ns)","U-STDARGS-UNKNOWN-FLAG","-x rejected")
        do free^STDARGS(p)
        quit
        ;
tMissingValueRaises(pass,fail)  ;@TEST "store flag without value raises U-STDARGS-MISSING-VALUE"
        new p
        set p=$$new^STDARGS("demo","")
        do addflag^STDARGS(p,"--name","-n","store","name")
        do raises^STDASSERT(.pass,.fail,"new ns do parse^STDARGS("_p_",""--name"",.ns)","U-STDARGS-MISSING-VALUE","--name needs value")
        do free^STDARGS(p)
        quit
        ;
tMissingPositionalRaises(pass,fail)     ;@TEST "missing required positional raises U-STDARGS-MISSING-POSITIONAL"
        new p
        set p=$$new^STDARGS("demo","")
        do addpos^STDARGS(p,"path","path")
        do raises^STDASSERT(.pass,.fail,"new ns do parse^STDARGS("_p_","""",.ns)","U-STDARGS-MISSING-POSITIONAL","path required")
        do free^STDARGS(p)
        quit
        ;
tUnknownSubcommandRaises(pass,fail)     ;@TEST "first token unrecognised against subcommands raises U-STDARGS-UNKNOWN-SUBCOMMAND"
        new p,sub
        set p=$$new^STDARGS("demo","")
        set sub=$$new^STDARGS("demo add","")
        do addsub^STDARGS(p,"add",sub)
        do raises^STDASSERT(.pass,.fail,"new ns do parse^STDARGS("_p_",""nuke"",.ns)","U-STDARGS-UNKNOWN-SUBCOMMAND","nuke rejected")
        do free^STDARGS(p)
        do free^STDARGS(sub)
        quit
        ;
tUnknownActionRaises(pass,fail) ;@TEST "addflag with unknown action raises U-STDARGS-UNKNOWN-ACTION"
        new p
        set p=$$new^STDARGS("demo","")
        do raises^STDASSERT(.pass,.fail,"do addflag^STDARGS("_p_",""--x"",""-x"",""bogus"",""x"")","U-STDARGS-UNKNOWN-ACTION","bogus action rejected")
        do free^STDARGS(p)
        quit
        ;
        ; ---------- help ----------
        ;
tHelpContainsProgAndDescription(pass,fail)      ;@TEST "$$help() contains the prog name and description"
        new p,h
        set p=$$new^STDARGS("widget","frob the widget")
        set h=$$help^STDARGS(p)
        do contains^STDASSERT(.pass,.fail,h,"widget","help mentions prog")
        do contains^STDASSERT(.pass,.fail,h,"frob the widget","help mentions description")
        do free^STDARGS(p)
        quit
        ;
tHelpListsLongAndShortFlags(pass,fail)  ;@TEST "$$help() lists each flag's long and short forms"
        new p,h
        set p=$$new^STDARGS("widget","")
        do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        do addflag^STDARGS(p,"--name","-n","store","name")
        set h=$$help^STDARGS(p)
        do contains^STDASSERT(.pass,.fail,h,"--verbose","help has --verbose")
        do contains^STDASSERT(.pass,.fail,h,"-v","help has -v")
        do contains^STDASSERT(.pass,.fail,h,"--name","help has --name")
        do contains^STDASSERT(.pass,.fail,h,"-n","help has -n")
        do free^STDARGS(p)
        quit
        ;
tHelpListsPositionals(pass,fail)        ;@TEST "$$help() lists each positional by name"
        new p,h
        set p=$$new^STDARGS("widget","")
        do addpos^STDARGS(p,"src","src")
        do addpos^STDARGS(p,"dst","dst")
        set h=$$help^STDARGS(p)
        do contains^STDASSERT(.pass,.fail,h,"src","help has src")
        do contains^STDASSERT(.pass,.fail,h,"dst","help has dst")
        do free^STDARGS(p)
        quit
