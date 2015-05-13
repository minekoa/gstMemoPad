#!/usr/bin/env gst

PackageLoader fileInPackage: 'GTK'.
PackageLoader fileInPackage: 'Iconv'.
FileStream fileIn: 'memo.st'.

Object subclass: PettitWorkspace [
    | rootbox sw1 sw2 textview textbuf list doitBtn window binder currentMemo |

    doit [
        ^Behavior evalString: textbuf text to: self.
    ]

    delete: aWiget event: aGdkEvent [
	self saveCurrentMemo.
	binder save.

        GTK.Gtk mainQuit.
        ^false
    ]

    show [
        window := GTK.GtkWindow new: GTK.Gtk gtkWindowToplevel.
        window setTitle: 'MemoPad-st ver.0.0.1'.
        window connectSignal: 'delete_event' 
            to: self selector: #delete:event: userData: nil.

        window setBorderWidth: 10.

        rootbox := GTK.GtkVBox new: false spacing: 0.
        window add: rootbox.

	"binder := self createBinder: '/media/cofs3/tools/memopad/memoForTest'."
	binder := self createBinder: '/media/cofs3/tools/memopad/memo'. 
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

        rootbox packStart: sw1 expand: true fill: true padding: 1.
	sw1 show.
	list show.

        rootbox packStart: sw2 expand: true fill: true padding: 1.
        sw2 show.
        textview show.

        doitBtn := GTK.GtkButton newWithLabel: 'Doit'.
        doitBtn connectSignal: 'clicked'
            to: self selector: #doit userData: nil.
        rootbox packStart: doitBtn expand: false fill: true padding: 0.
        doitBtn show.

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
	    | ws iter |
	    ws := WriteStream on: String new.
	    memo timestamp printYyyyMmDdOn: ws.

	    iter := GTK.GtkTreeIter new.
	    listModel append: iter.
	    listModel setOop: iter column: 0 value: (ws contents asUnicodeString:'CP932') asByteArray.
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
		(list getSelection getSelected: nil iter: iter)
                    ifTrue: [
			| memo |
			memo := binder find: (list getModel getOop: iter column: 2) asString.
			self changeCurrentMemo: memo.
		    ]]
	    selector: #value.
	^listView
    ]

    saveCurrentMemo [
	currentMemo ifNotNil: [
	    (currentMemo contents = textbuf text asUnicodeString) 
	        ifFalse: [
		    Transcript cr; show: 'save';
		        show: currentMemo id asString;	cr.
		    currentMemo updateContents: textbuf text asUnicodeString.]
	]
    ]

    changeCurrentMemo: newMemo [
	self saveCurrentMemo.
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
