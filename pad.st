#!/usr/bin/env gst

PackageLoader fileInPackage: 'GTK'.
PackageLoader fileInPackage: 'Iconv'.
FileStream fileIn: 'memo.st'.

Object subclass: PettitWorkspace [
    | rootbox northbox southbox buttonbox sw1 sw2 textview textbuf list doitBtn printitBtn newBtn window binder currentMemo |

    doit [
        ^Behavior evalString: textbuf selectedText to: self.
    ]
    printit [
	| result iter start end |
	iter := textbuf iterOfSelectedText second.
	result := ' ', self doit printString.
	textbuf insertInteractive: iter text: result
	    len: result size defaultEditable: true.
	start := textbuf getIterAtOffset: (iter getOffset - result size).
	end   := textbuf getIterAtOffset: (iter getOffset).
	textbuf selectRange: start bound: end.
	textview grabFocus.
    ]

    createNewMemo [
	| memo |
	memo := binder createMemo.
	self updateList.
	self changeCurrentMemo: memo.
    ]

    delete: aWiget event: aGdkEvent [
	self updateCurrentMemo.
	binder save.

        GTK.Gtk mainQuit.
	Transcript show: 'Bye!'; cr.
        ^false
    ]

    show [
        window := GTK.GtkWindow new: GTK.Gtk gtkWindowToplevel.
        window setTitle: 'MemoPad-st ver.0.0.3'.
        window connectSignal: 'delete_event' 
            to: self selector: #delete:event: userData: nil.

        window setBorderWidth: 10.

        rootbox := GTK.GtkVBox new: false spacing: 0.
        window add: rootbox.

	northbox := GTK.GtkHBox new: false spacing: 1.
	southbox := GTK.GtkHBox new: false spacing: 1.
	rootbox add: northbox.
	rootbox add: southbox.
	northbox setBorderWidth: 1.

	"binder := self createBinder: '/media/cofs3/tools/memopad/memoForTest'."
	"binder := self createBinder: '/media/cofs3/tools/memopad/memo'. "
	binder := self createBinder: '../../../tools/memopad/memo'.
	list := self createMemoList: binder.

        sw1 := GTK.GtkScrolledWindow withChild: list.
        sw1 setPolicy: GTK.Gtk gtkPolicyAutomatic
	    vscrollbarPolicy: GTK.Gtk gtkPolicyAlways.

        textview := GTK.GtkTextView new.
	textview setWrapMode: GTK.Gtk gtkWrapChar.
        textbuf  := textview getBuffer.
        sw2 := GTK.GtkScrolledWindow withChild: textview.
        sw2 setPolicy: GTK.Gtk gtkPolicyAutomatic
	    vscrollbarPolicy: GTK.Gtk gtkPolicyAutomatic.

        northbox packStart: sw1 expand: true fill: true padding: 1.
	sw1 show.
	list show.

        newBtn := GTK.GtkButton newWithLabel: 'new'.
        newBtn connectSignal: 'clicked'
            to: self selector: #createNewMemo userData: nil.
        northbox packStart: newBtn expand: false fill: true padding: 1.
        newBtn show.


        southbox packStart: sw2 expand: true fill: true padding: 1.
        sw2 show.
        textview show.

	buttonbox := GTK.GtkVBox new: false spacing: 1.
        southbox packStart: buttonbox expand: false fill: true padding: 1.

        doitBtn := GTK.GtkButton newWithLabel: 'Doit'.
        doitBtn connectSignal: 'clicked'
            to: self selector: #doit userData: nil.
        buttonbox packStart: doitBtn expand: false fill: true padding: 1.
        doitBtn show.

        printitBtn := GTK.GtkButton newWithLabel: 'Printit'.
        printitBtn connectSignal: 'clicked'
            to: self selector: #printit userData: nil.
        buttonbox packStart: printitBtn expand: false fill: true padding: 1.
        printitBtn show.

	northbox setSizeRequest: 500 height: 200.
	southbox setSizeRequest: 500 height: 300.

	northbox show.
	southbox show.
	buttonbox show.
	rootbox show.
        window show.
    ]

    createBinder: directoryPath  [
	| binder |
	binder := MemoBinder new.
	binder setPath: directoryPath asString.
	binder load.
	^binder
    ]

    createMemoList: binder [
	| header listModel listView|

	"Model"
	listModel := GTK.GtkListStore new: 3
				      varargs: { GTK.GValue gTypeString.   "date"
						 GTK.GValue gTypeString.   "title"
						 GTK.GValue gTypeString. }."id (hidden)"
	binder memoTbl do: [ :memo |
	    | iter |
	    iter := GTK.GtkTreeIter new.
	    listModel append: iter.
	    listModel setOop: iter column: 0 value: (memo timestamp printStringYyyyMmDd , ' ', memo timestamp printStringHhMm) asUnicodeString asByteArray.
	    listModel setOop: iter column: 1 value: (memo title) asByteArray.
	    listModel setOop: iter column: 2 value: (memo id) asByteArray. "hidden row"
	].

	"View"
	listView := GTK.GtkTreeView new.
	header := #('Date' 'Title').
	header keysAndValuesDo: [ :i :value |
	    | rend col |
	    rend := GTK.GtkCellRendererText new.
	    col  := GTK.GtkTreeViewColumn new.
	    col setTitle: value;
		packStart: rend expand: true;
		addAttribute: rend attribute: 'text' column: i-1.
	    listView insertColumn: col position: -1
	].

	listView setModel: listModel.
	listView getSelection 
            connectSignal: 'changed' 
            to: [
		| iter |
	        iter := GTK.GtkTreeIter type new.
		(listView getSelection getSelected: nil iter: iter)
                    ifTrue: [
			| memo |
			memo := binder find: (list getModel getOop: iter column: 2) asString.
			self changeCurrentMemo: memo.
		    ]]
	    selector: #value.
	^listView
    ]

    updateCurrentMemo [
	currentMemo ifNotNil: [
	    (currentMemo contents = textbuf text asUnicodeString) 
	        ifFalse: [
		    Transcript cr; show: 'update:';
		        show: currentMemo id asString;	cr.
		    currentMemo updateContents: textbuf text asUnicodeString.
		    self updateList.
		]
	]
    ]

    updateList [
	| listModel |
	listModel := list getModel.

	listModel clear.
	binder memoTbl do: [ :memo |
	    | iter |
	    iter := GTK.GtkTreeIter new.
	    listModel append: iter.
	    listModel setOop: iter column: 0 value: (memo timestamp printStringYyyyMmDd , ' ', memo timestamp printStringHhMm) asUnicodeString asByteArray.
	    listModel setOop: iter column: 1 value: (memo title) asByteArray.
	    listModel setOop: iter column: 2 value: (memo id) asByteArray. "hidden row"
	].
    ]

    changeCurrentMemo: newMemo [
	self updateCurrentMemo.
	Transcript
	    show: 'memoID='; show: newMemo id asString;
	    show: ' :'; show: newMemo title asString;
	    cr.

	currentMemo := newMemo.
	textbuf setText: (currentMemo contents) asByteArray.
    ]
]

Eval [
    hello := PettitWorkspace new.
    hello show.
    GTK.Gtk main
]
