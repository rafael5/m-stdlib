STDFMT  ; m-stdlib — printf-style formatter (subset of Python str.format).
        ;
        ; Two public extrinsics:
        ;   $$f^STDFMT(template,a1,a2,...,a9)   — up to 9 positional
        ;   $$fn^STDFMT(template,.args)         — keyed via local array
        ;
        ; Format spec — a subset of Python str.format:
        ;   {} / {N} / {name}                  — field reference
        ;   {:s} {:d} {:f} {:x} {:X} {:o} {:b} — type
        ;   {:>10} {:<10} {:^10}               — alignment + width
        ;   {:*>10}                            — fill char with align
        ;   {:.3f} {:.4s}                      — precision (rounding for f,
        ;                                        truncate for s)
        ;   {{ }}                              — literal { and }
        ;
        ; Type defaults:
        ;   no type / s   — string, default left-align
        ;   d f x X o b   — numeric, default right-align
        ;   f             — default precision 6 (matches Python)
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDFMT-MISSING-ARG,
        ;   ,U-STDFMT-UNCLOSED-BRACE,
        ;   ,U-STDFMT-UNESCAPED-RBRACE,
        ;   ,U-STDFMT-UNKNOWN-TYPE,
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
f(template,a1,a2,a3,a4,a5,a6,a7,a8,a9)  ; Positional formatter (up to 9 args).
        ; doc: Returns the rendered template. Supplied args fill positions
        ; doc: 0..N-1; unsupplied positions raise $ECODE on lookup.
        ; doc: Example: write $$f^STDFMT("hi {}","world")  ; "hi world"
        new args
        if $data(a1) set args(0)=a1
        if $data(a2) set args(1)=a2
        if $data(a3) set args(2)=a3
        if $data(a4) set args(3)=a4
        if $data(a5) set args(4)=a5
        if $data(a6) set args(5)=a6
        if $data(a7) set args(6)=a7
        if $data(a8) set args(7)=a8
        if $data(a9) set args(8)=a9
        quit $$render(template,.args)
        ;
fn(template,args)       ; Named formatter (lookups in the passed array).
        ; doc: Returns the rendered template. Lookups go to args(name).
        ; doc: Example: set a("n")="x"  write $$fn^STDFMT("{n}",.a)  ; "x"
        quit $$render(template,.args)
        ;
        ; ---------- internal: template walker ----------
        ;
render(template,args)   ; Walk template; expand placeholders.
        ; doc: Internal — handles {{, }}, and {...} placeholders. Sets
        ; doc: $ECODE on malformed templates.
        new out,n,i,c,j,depth,spec,autoIdx
        set out=""
        set autoIdx=0
        set n=$length(template)
        set i=1
        for  quit:i>n  do
        . set c=$extract(template,i)
        . if c="{",$extract(template,i+1)="{" set out=out_"{",i=i+2 quit
        . if c="}",$extract(template,i+1)="}" set out=out_"}",i=i+2 quit
        . if c="{" do  quit
        . . set j=i+1
        . . set depth=1
        . . for  quit:depth=0!(j>n)  do
        . . . if $extract(template,j)="{" set depth=depth+1
        . . . if $extract(template,j)="}" set depth=depth-1
        . . . if depth>0 set j=j+1
        . . if depth'=0 set $ecode=",U-STDFMT-UNCLOSED-BRACE," quit
        . . set spec=$extract(template,i+1,j-1)
        . . set out=out_$$expand(spec,.args,.autoIdx)
        . . set i=j+1
        . if c="}" set $ecode=",U-STDFMT-UNESCAPED-RBRACE," quit
        . set out=out_c
        . set i=i+1
        quit out
        ;
expand(spec,args,autoIdx)       ; Expand a single {...} body to a string.
        ; doc: Internal — splits spec on the first ":", resolves the field
        ; doc: to a value, applies the format spec to that value.
        new colon,field,fmt,val
        set colon=$find(spec,":")
        if colon=0 set field=spec,fmt=""
        else  set field=$extract(spec,1,colon-2),fmt=$extract(spec,colon,$length(spec))
        set val=$$lookup(.args,field,.autoIdx)
        quit $$apply(val,fmt)
        ;
lookup(args,field,autoIdx)      ; Resolve field to argument value.
        ; doc: Internal — empty field auto-numbers; digits is positional
        ; doc: index; otherwise treated as a name.
        new key
        if field="" set key=autoIdx,autoIdx=autoIdx+1
        else  if field?1.N set key=+field
        else  set key=field
        if '$data(args(key)) set $ecode=",U-STDFMT-MISSING-ARG," quit ""
        quit args(key)
        ;
        ; ---------- internal: format spec ----------
        ;
apply(val,fmt)  ; Apply a format spec to val.
        ; doc: Internal — fmt is the substring after ":" (empty if none).
        new parsed,s,defaultAlign
        do parseSpec(fmt,.parsed)
        set s=$$convert(val,parsed("type"),parsed("precision"))
        if (parsed("type")="s")!(parsed("type")="") do
        . if parsed("precision")'="" set s=$extract(s,1,+parsed("precision"))
        if parsed("align")="" do
        . set defaultAlign=$select((parsed("type")="s")!(parsed("type")=""):"<",1:">")
        . set parsed("align")=defaultAlign
        quit $$pad(s,parsed("width"),parsed("align"),parsed("fill"))
        ;
parseSpec(fmt,parsed)   ; Parse a format spec into parsed("...") subscripts.
        ; doc: Internal — fmt is the substring after ":" (no leading colon).
        ; doc: Sets fill / align / width / precision / type subscripts.
        new pos,n,c
        set parsed("fill")=" ",parsed("align")=""
        set parsed("width")="",parsed("precision")="",parsed("type")=""
        if fmt="" quit
        set pos=1,n=$length(fmt)
        ; fill+align (two chars where char-2 is align)
        if n>=2 do
        . set c=$extract(fmt,2)
        . if c="<"!(c=">")!(c="^") do
        . . set parsed("fill")=$extract(fmt,1)
        . . set parsed("align")=c
        . . set pos=3
        ; bare align (when no fill+align matched)
        if parsed("align")="",pos<=n do
        . set c=$extract(fmt,pos)
        . if c="<"!(c=">")!(c="^") set parsed("align")=c,pos=pos+1
        ; width — run of digits
        for  quit:(pos>n)!($extract(fmt,pos)'?1N)  do
        . set parsed("width")=parsed("width")_$extract(fmt,pos)
        . set pos=pos+1
        ; .precision
        if pos<=n,$extract(fmt,pos)="." do
        . set pos=pos+1
        . for  quit:(pos>n)!($extract(fmt,pos)'?1N)  do
        . . set parsed("precision")=parsed("precision")_$extract(fmt,pos)
        . . set pos=pos+1
        ; type — single trailing char
        if pos<=n set parsed("type")=$extract(fmt,pos)
        quit
        ;
convert(val,type,precision)     ; Convert val to its rendered string per type.
        ; doc: Internal — pre-padding. Sets $ECODE on unknown type.
        if type="" quit val
        if type="s" quit val
        if type="d" quit val\1
        if type="f" quit $fnumber(val,"",$select(precision="":6,1:+precision))
        if type="x" quit $$toBase(+val,16,"0123456789abcdef")
        if type="X" quit $$toBase(+val,16,"0123456789ABCDEF")
        if type="o" quit $$toBase(+val,8,"01234567")
        if type="b" quit $$toBase(+val,2,"01")
        set $ecode=",U-STDFMT-UNKNOWN-TYPE,"
        quit ""
        ;
toBase(n,base,alpha)    ; Convert integer n to a string in base via alpha.
        ; doc: Internal — handles negatives via leading '-'.
        new sign,abs,digits,d
        if n=0 quit "0"
        set sign=$select(n<0:"-",1:"")
        set abs=$select(n<0:-n,1:n)
        set digits=""
        for  quit:abs=0  do
        . set d=abs#base
        . set digits=$extract(alpha,d+1)_digits
        . set abs=abs\base
        quit sign_digits
        ;
pad(s,width,align,fill) ; Apply width/align/fill to s.
        ; doc: Internal — when |s| >= width, returns s unchanged.
        new w,sLen,padding,lpad,rpad
        if width="" quit s
        set w=+width
        set sLen=$length(s)
        if sLen>=w quit s
        set padding=w-sLen
        if align="<" quit s_$$repeat(fill,padding)
        if align=">" quit $$repeat(fill,padding)_s
        if align'="^" quit s
        set lpad=padding\2
        set rpad=padding-lpad
        quit $$repeat(fill,lpad)_s_$$repeat(fill,rpad)
        ;
repeat(c,n)     ; Return char c repeated n times.
        ; doc: Internal — simple loop; works for any char (not just space).
        new out,i
        set out=""
        for i=1:1:n set out=out_c
        quit out
