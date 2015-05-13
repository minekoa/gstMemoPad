#!/usr/bin/env gst

PackageLoader fileInPackage: 'GTK'.

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
        window := GTK.GtkWindow new: GTK.Gtk gtkWindowToplevel.
        window setTitle: 'GUI Tester'.
        window connectSignal: 'delete_event' 
            to: self selector: #delete:event: userData: nil.

        window setBorderWidth: 10.

        rootbox := GTK.GtkVBox new: false spacing: 0.
        window add: rootbox.

	list := GTK.GtkList new.
	'/media/cofs3/tools/memopad/memo' asFile namesDo: [:filename|
	    | listItem |
		listItem := GTK.GtkListItem newWithLabel: filename.
	    list add: listItem.
	    listItem show
	].
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
