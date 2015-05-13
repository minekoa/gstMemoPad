#!/usr/bin/env gst

PackageLoader fileInPackage: 'GTK'.
PackageLoader fileInPackage: 'Iconv'.

Object subclass: PettitWorkspace [
    | rootbox sw1 sw2 textview textbuf list doitBtn window |

    doit [
        ^Behavior evalString: textbuf text to: self.
    ]

    delete: aWiget event: aGdkEvent [
        GTK.Gtk mainQuit.
        ^false
    ]

    show [
	| header listModel |
        window := GTK.GtkWindow new: GTK.Gtk gtkWindowToplevel.
        window setTitle: 'GUI Tester'.
        window connectSignal: 'delete_event' 
            to: self selector: #delete:event: userData: nil.

        window setBorderWidth: 10.

        rootbox := GTK.GtkVBox new: false spacing: 0.
        window add: rootbox.

	"Table for Memo-List"
	list := GTK.GtkTreeView new.
	header := #('Date' 'Title').
	header keysAndValuesDo: [ :i :value |
	    | rend col |
	    rend := GTK.GtkCellRendererText new.
	    col  := GTK.GtkTreeViewColumn new.
	    col setTitle: value;
		packStart: rend expand: true;
		addAttribute: rend attribute: 'text' column: i-1.
	    list insertColumn: col position: -1
	].

	listModel := GTK.GtkListStore new: 2
				      varargs: { GTK.GValue gTypeString.
						 GTK.GValue gTypeString }.
	list setModel: listModel.

	'/media/cofs3/tools/memopad/memo' asFile namesDo: [:filename|
	    | iter file title|
	    file := '/media/cofs3/tools/memopad/memo' / filename asFile.
	    (file isDirectory not & (filename = 'trash') not) ifTrue: [
		iter := GTK.GtkTreeIter new.
		listModel append: iter.
		listModel setOop: iter column: 0 value: filename.
		title := (file open: 'rw') nextLine.
		title ifNil: [title := ''] 
		      ifNotNil: [title := (title asString asUnicodeString:'CP932') asByteArray].
	        listModel setOop: iter column: 1 value: title
	    ]
	].

	list getSelection connectSignal: 'changed' 
			  to: [ 
			      | iter |
			      iter := GTK.GtkTreeIter type new.
			      (list getSelection getSelected: nil iter: iter)
				  ifTrue: [
				      |result f|
				      result := list getModel getOop: iter column: 1.
				      result printNl. 

				      f := '/media/cofs3/tools/memopad/memo' / 
					  (list getModel getOop: iter column: 0) asString.
				      textbuf setText: (f contents asUnicodeString: 'CP932') asByteArray
				  ]
				 
			  ] selector: #value.

        sw1 := GTK.GtkScrolledWindow withChild: list.
        sw1 setPolicy: GTK.Gtk gtkPolicyAutomatic
	    vscrollbarPolicy: GTK.Gtk gtkPolicyAlways.

        textview := GTK.GtkTextView new.
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
]

Eval [
    hello := PettitWorkspace new.
    hello show.
    GTK.Gtk main
]
