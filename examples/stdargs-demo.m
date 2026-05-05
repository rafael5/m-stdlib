stdargsdemo     ; m-stdlib STDARGS demo CLI — `widget` tool.
        ; m-lint: disable-file=M-MOD-020
        ;
        ; Runs the parser against $ZCMDLINE so the file doubles as a
        ; manual validation harness. Two sub-commands ("add", "list")
        ; exercise: long flags, short flags, grouped count flags
        ; (-vvv), store-with-value, store_true, append, positionals,
        ; sub-command dispatch, and --help.
        ;
        ; Try:
        ;   yottadb -run ^stdargsdemo  list -vv --tag urgent --tag stale
        ;   yottadb -run ^stdargsdemo  add --name widget /tmp/out
        ;   yottadb -run ^stdargsdemo  --help
        ;
        do main($zcmdline)
        quit
        ;
main(argline)   ; Parse argline against the widget CLI; print result.
        new root,addP,listP,ns
        set root=$$build()
        do parse^STDARGS(root,argline,.ns)
        if $get(ns("__sub__"))="add" do
        . write "add: name=",$get(ns("name")),"  out=",$get(ns("out")),!
        if $get(ns("__sub__"))="list" do
        . write "list: verbose=",$get(ns("verbose")),!
        . new tag set tag=""
        . for  set tag=$order(ns("tags",tag)) quit:tag=""  do
        . . write "  tag=",ns("tags",tag),!
        do free^STDARGS(root)
        quit
        ;
build() ; Build the parser graph; return the root handle.
        new root,addP,listP
        set root=$$new^STDARGS("widget","frob a widget")
        ; sub: add
        set addP=$$new^STDARGS("widget add","add a widget")
        do addflag^STDARGS(addP,"--name","-n","store","name")
        do addpos^STDARGS(addP,"out","out")
        do addsub^STDARGS(root,"add",addP)
        ; sub: list
        set listP=$$new^STDARGS("widget list","list widgets")
        do addflag^STDARGS(listP,"--verbose","-v","count","verbose")
        do addflag^STDARGS(listP,"--tag","-t","append","tags")
        do addsub^STDARGS(root,"list",listP)
        quit root
