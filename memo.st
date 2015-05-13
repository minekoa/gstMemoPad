#!/usr/bin/env gst

PackageLoader fileInPackage: 'Iconv'.
FileStream fileIn: 'timestamp.st'.

Object subclass: MemoBinder [
    | path memoTbl |
    setPath: aPath [path := aPath]
    getPath [^path]
    fileEncoding [^'CP932']

    memoTbl [
	"最近のメモが先頭になるようにソート"
	^memoTbl ifNil: [ 
	    memoTbl := SortedCollection sortBlock: [:a :b| a timestamp > b timestamp ]
	]
    ]

    createMemo [
	| timestamp memo |
	timestamp := Timestamp now.
	memo := Memo new: timestamp.
	self memoTbl add: memo.
	^memo
    ]

    find: memoId [
	self memoTbl do: [ :memo|
	    (memo id asString = memoId asString) ifTrue: [^memo] 
	].
	^ nil
    ]

    load [
	self getPath asFile namesDo: [:filename|
	    | file fs memo timestamp |
	    file := self getPath / filename asFile.
	    file isDirectory not ifTrue: [
		fs := file open: FileStream read.
		timestamp := Timestamp newFromString: (File stripPathFrom: file name).
		memo := Memo new: timestamp.
		memo setContents: (fs contents asUnicodeString: self fileEncoding).

		fs close.
		self memoTbl add: memo.
	    ]
	].
    ]

    save [
	Transcript cr; show: 'Save start!'; cr.
	self memoTbl do: [ :memo| self save: memo].
	Transcript show: 'Save end!'; cr.
    ]

    save: memo [
	| file fs |
	memo isUpdate ifTrue:[
	    file := self getPath / memo fileName asFile.
	    fs := file open: FileStream write.
	    fs nextPutAll: (memo contents asString: self fileEncoding).
	    fs close.
	    Transcript show: '-save :'; show: memo id printString; cr .
	]
    ]


    printListNl [
	"デバッグ用"
	self memoTbl do: [ :memo|
	    | ws |
	    ws := WriteStream on: String new.
	    memo timestamp printYyyyMmDdOn: ws.
	    ws nextPut: Character space.
	    memo timestamp printHhMmOn: ws.
	    Transcript cr;
		show: ws contents;
		show: ' | ';
	    show: memo title asString.
	].
	Transcript cr.
    ]
]

Object subclass: Memo [
    | contents timestamp isUpdate |

    Memo class >> new: aTimestamp [
	| memo |
	memo := Memo new.
	memo setTimestamp: aTimestamp.
	^memo
    ]
    setContents: aContents [
	contents := aContents asUnicodeString.
    ]

    contents [
	^ contents ifNil: [contents := UnicodeString new]
    ]

    updateContents: aContents [
	isUpdate := true.
	self setContents: aContents
    ]

    title [
	| lines |
	lines := self contents lines.
	lines size = 0 ifTrue: [^UnicodeString new] ifFalse: [^lines at: 1]
    ]

    id [
	^self timestamp printString, '000'
    ]

    isUpdate [^isUpdate ifNil: [isUpdate := false]]

    timestamp [^timestamp]
    setTimestamp: aTimestamp [timestamp := aTimestamp]

    fileName [^(self id , '.memo') asString]

]

"
Eval [
    | binder |
    binder := MemoBinder new.
    binder setPath: '/media/cofs3/tools/memopad/memo'.
    binder load.
    binder printListNl.

]
"
