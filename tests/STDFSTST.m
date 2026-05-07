STDFSTST        ; Test suite for STDFS (v0.2.x — Pri 2, Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tBasenameSimple(.pass,.fail)
        do tBasenameTrailingSlash(.pass,.fail)
        do tBasenameNoSlash(.pass,.fail)
        do tBasenameRoot(.pass,.fail)
        do tBasenameEmpty(.pass,.fail)
        do tDirnameSimple(.pass,.fail)
        do tDirnameNoSlash(.pass,.fail)
        do tDirnameRoot(.pass,.fail)
        do tDirnameTrailingSlash(.pass,.fail)
        do tDirnameEmpty(.pass,.fail)
        do tJoinSimple(.pass,.fail)
        do tJoinAbsoluteRight(.pass,.fail)
        do tJoinTrailingSlashLeft(.pass,.fail)
        do tJoinEmptyLeft(.pass,.fail)
        do tJoinEmptyRight(.pass,.fail)
        do tWriteThenReadRoundTrip(.pass,.fail)
        do tWriteThenReadEmpty(.pass,.fail)
        do tWriteThenReadMultiline(.pass,.fail)
        do tAppendExtendsFile(.pass,.fail)
        do tAppendCreatesIfMissing(.pass,.fail)
        do tExistsTrueAfterWrite(.pass,.fail)
        do tExistsFalseAfterRemove(.pass,.fail)
        do tExistsFalseForMissingPath(.pass,.fail)
        do tRemoveDeletesFile(.pass,.fail)
        do tReadMissingRaises(.pass,.fail)
        do tWriteLinesRoundTrip(.pass,.fail)
        do tReadLinesPopulatesArray(.pass,.fail)
        do tSizeMatchesContentLength(.pass,.fail)
        do tSizeOfMissingIsMinusOne(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- helpers ----
sandboxPath(suffix)     ; Build a unique path under /tmp for this test process.
        ; doc: $JOB is unique per process; suffix lets each test pick its own file.
        quit "/tmp/m-stdlib-fstest-"_$job_"-"_suffix
        ;
        ; ---- basename ----
tBasenameSimple(pass,fail)      ;@TEST "basename('/etc/hosts')='hosts'"
        do eq^STDASSERT(.pass,.fail,$$basename^STDFS("/etc/hosts"),"hosts","strip leading dirs")
        do eq^STDASSERT(.pass,.fail,$$basename^STDFS("/a/b/c/file.txt"),"file.txt","deep nesting")
        quit
        ;
tBasenameTrailingSlash(pass,fail)       ;@TEST "basename('/foo/bar/')='bar'"
        do eq^STDASSERT(.pass,.fail,$$basename^STDFS("/foo/bar/"),"bar","trailing slash stripped")
        quit
        ;
tBasenameNoSlash(pass,fail)     ;@TEST "basename('plain')='plain'"
        do eq^STDASSERT(.pass,.fail,$$basename^STDFS("plain"),"plain","no slash returned verbatim")
        quit
        ;
tBasenameRoot(pass,fail)        ;@TEST "basename('/')='/'"
        do eq^STDASSERT(.pass,.fail,$$basename^STDFS("/"),"/","root path is its own basename")
        quit
        ;
tBasenameEmpty(pass,fail)       ;@TEST "basename('')=''"
        do eq^STDASSERT(.pass,.fail,$$basename^STDFS(""),"","empty path is empty basename")
        quit
        ;
        ; ---- dirname ----
tDirnameSimple(pass,fail)       ;@TEST "dirname('/etc/hosts')='/etc'"
        do eq^STDASSERT(.pass,.fail,$$dirname^STDFS("/etc/hosts"),"/etc","strip last component")
        do eq^STDASSERT(.pass,.fail,$$dirname^STDFS("/a/b/c/file.txt"),"/a/b/c","deep nesting")
        quit
        ;
tDirnameNoSlash(pass,fail)      ;@TEST "dirname('plain')='.'"
        do eq^STDASSERT(.pass,.fail,$$dirname^STDFS("plain"),".","no-slash dirname is dot")
        quit
        ;
tDirnameRoot(pass,fail) ;@TEST "dirname('/')='/'"
        do eq^STDASSERT(.pass,.fail,$$dirname^STDFS("/"),"/","root's parent is root")
        quit
        ;
tDirnameTrailingSlash(pass,fail)        ;@TEST "dirname('/foo/bar/')='/foo'"
        do eq^STDASSERT(.pass,.fail,$$dirname^STDFS("/foo/bar/"),"/foo","trailing slash treated as basename")
        quit
        ;
tDirnameEmpty(pass,fail)        ;@TEST "dirname('')='.'"
        do eq^STDASSERT(.pass,.fail,$$dirname^STDFS(""),".","empty path dirname is dot")
        quit
        ;
        ; ---- join ----
tJoinSimple(pass,fail)  ;@TEST "join('/a','b')='/a/b'"
        do eq^STDASSERT(.pass,.fail,$$join^STDFS("/a","b"),"/a/b","two components")
        do eq^STDASSERT(.pass,.fail,$$join^STDFS("/a/b","c.txt"),"/a/b/c.txt","nested")
        quit
        ;
tJoinAbsoluteRight(pass,fail)   ;@TEST "join('/a','/b')='/b' — absolute right wins"
        do eq^STDASSERT(.pass,.fail,$$join^STDFS("/a","/b"),"/b","absolute right replaces left")
        quit
        ;
tJoinTrailingSlashLeft(pass,fail)       ;@TEST "join('/a/','b')='/a/b' — no double slash"
        do eq^STDASSERT(.pass,.fail,$$join^STDFS("/a/","b"),"/a/b","trailing slash collapsed")
        quit
        ;
tJoinEmptyLeft(pass,fail)       ;@TEST "join('','b')='b'"
        do eq^STDASSERT(.pass,.fail,$$join^STDFS("","b"),"b","empty left dropped")
        quit
        ;
tJoinEmptyRight(pass,fail)      ;@TEST "join('/a','')='/a'"
        do eq^STDASSERT(.pass,.fail,$$join^STDFS("/a",""),"/a","empty right dropped")
        quit
        ;
        ; ---- read / write round-trip ----
tWriteThenReadRoundTrip(pass,fail)      ;@TEST "writeFile then readFile returns the same string"
        new path,content,got
        set path=$$sandboxPath("rw1")
        set content="hello, world"
        do writeFile^STDFS(path,content)
        set got=$$readFile^STDFS(path)
        do eq^STDASSERT(.pass,.fail,got,content,"round-trip single line")
        do remove^STDFS(path)
        quit
        ;
tWriteThenReadEmpty(pass,fail)  ;@TEST "writeFile('') then readFile returns ''"
        new path,got
        set path=$$sandboxPath("rw-empty")
        do writeFile^STDFS(path,"")
        set got=$$readFile^STDFS(path)
        do eq^STDASSERT(.pass,.fail,got,"","empty round-trip")
        do remove^STDFS(path)
        quit
        ;
tWriteThenReadMultiline(pass,fail)      ;@TEST "writeFile multiline then readFile preserves lines"
        new path,content,got
        set path=$$sandboxPath("rw-multi")
        set content="line1"_$char(10)_"line2"_$char(10)_"line3"
        do writeFile^STDFS(path,content)
        set got=$$readFile^STDFS(path)
        do eq^STDASSERT(.pass,.fail,got,content,"three-line round-trip")
        do remove^STDFS(path)
        quit
        ;
tAppendExtendsFile(pass,fail)   ;@TEST "append() concatenates onto an existing file"
        new path,got
        set path=$$sandboxPath("append")
        do writeFile^STDFS(path,"head")
        do append^STDFS(path,"-tail")
        set got=$$readFile^STDFS(path)
        do eq^STDASSERT(.pass,.fail,got,"head-tail","append concatenates")
        do remove^STDFS(path)
        quit
        ;
tAppendCreatesIfMissing(pass,fail)      ;@TEST "append() creates the file if it doesn't exist"
        new path,got
        set path=$$sandboxPath("append-create")
        if $$exists^STDFS(path) do remove^STDFS(path)
        do append^STDFS(path,"only")
        set got=$$readFile^STDFS(path)
        do eq^STDASSERT(.pass,.fail,got,"only","append creates new file")
        do remove^STDFS(path)
        quit
        ;
        ; ---- exists / remove / size ----
tExistsTrueAfterWrite(pass,fail)        ;@TEST "exists() is 1 immediately after writeFile()"
        new path
        set path=$$sandboxPath("exists-after")
        do writeFile^STDFS(path,"x")
        do true^STDASSERT(.pass,.fail,$$exists^STDFS(path),"exists after writeFile")
        do remove^STDFS(path)
        quit
        ;
tExistsFalseAfterRemove(pass,fail)      ;@TEST "exists() is 0 after remove()"
        new path
        set path=$$sandboxPath("exists-removed")
        do writeFile^STDFS(path,"x")
        do remove^STDFS(path)
        do false^STDASSERT(.pass,.fail,$$exists^STDFS(path),"missing after remove")
        quit
        ;
tExistsFalseForMissingPath(pass,fail)   ;@TEST "exists() is 0 for a never-written path"
        new path
        set path=$$sandboxPath("never-written")
        do false^STDASSERT(.pass,.fail,$$exists^STDFS(path),"never-written path missing")
        quit
        ;
tRemoveDeletesFile(pass,fail)   ;@TEST "remove() makes exists() return 0"
        new path
        set path=$$sandboxPath("delete-me")
        do writeFile^STDFS(path,"bye")
        do true^STDASSERT(.pass,.fail,$$exists^STDFS(path),"present before remove")
        do remove^STDFS(path)
        do false^STDASSERT(.pass,.fail,$$exists^STDFS(path),"absent after remove")
        quit
        ;
tReadMissingRaises(pass,fail)   ;@TEST "readFile of a missing path sets $ECODE=,U-STDFS-OPEN-FAIL,"
        new path,code
        set path=$$sandboxPath("definitely-missing")
        if $$exists^STDFS(path) do remove^STDFS(path)
        set code="set x=$$readFile^STDFS("""_path_""")"
        do raises^STDASSERT(.pass,.fail,code,"U-STDFS-OPEN-FAIL","missing-file open fails")
        quit
        ;
tWriteLinesRoundTrip(pass,fail) ;@TEST "writeLines / readLines round-trips an array"
        new path,lines,got,n
        set path=$$sandboxPath("wlines")
        set lines(1)="alpha",lines(2)="beta",lines(3)="gamma"
        do writeLines^STDFS(path,.lines)
        do readLines^STDFS(path,.got)
        do eq^STDASSERT(.pass,.fail,$get(got(1)),"alpha","line 1")
        do eq^STDASSERT(.pass,.fail,$get(got(2)),"beta","line 2")
        do eq^STDASSERT(.pass,.fail,$get(got(3)),"gamma","line 3")
        set n=0,n=$order(got(""),-1)
        do eq^STDASSERT(.pass,.fail,n,3,"three lines total")
        do remove^STDFS(path)
        quit
        ;
tReadLinesPopulatesArray(pass,fail)     ;@TEST "readLines populates 1..N from a writeFile output"
        new path,content,got,n
        set path=$$sandboxPath("rlines")
        set content="one"_$char(10)_"two"_$char(10)_"three"
        do writeFile^STDFS(path,content)
        do readLines^STDFS(path,.got)
        do eq^STDASSERT(.pass,.fail,$get(got(1)),"one","line 1")
        do eq^STDASSERT(.pass,.fail,$get(got(2)),"two","line 2")
        do eq^STDASSERT(.pass,.fail,$get(got(3)),"three","line 3")
        set n=$order(got(""),-1)
        do eq^STDASSERT(.pass,.fail,n,3,"three lines parsed")
        do remove^STDFS(path)
        quit
        ;
tSizeMatchesContentLength(pass,fail)    ;@TEST "size() returns the on-disk byte count"
        ; writeFile always emits a trailing LF (YDB SEQ stream-mode close
        ; finalises the last record with LF), so on-disk size is data+1.
        ; This matches the POSIX text-file convention and is documented
        ; explicitly in the module doc.
        new path,content
        set path=$$sandboxPath("size")
        set content="0123456789abcdef"  ; 16 bytes data
        do writeFile^STDFS(path,content)
        do eq^STDASSERT(.pass,.fail,$$size^STDFS(path),17,"16-byte data + LF on disk")
        do remove^STDFS(path)
        quit
        ;
tSizeOfMissingIsMinusOne(pass,fail)     ;@TEST "size() of a missing path returns -1"
        new path
        set path=$$sandboxPath("size-missing")
        if $$exists^STDFS(path) do remove^STDFS(path)
        do eq^STDASSERT(.pass,.fail,$$size^STDFS(path),-1,"missing path size is -1")
        quit
