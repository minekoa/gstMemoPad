#!/usr/bin/env gst

PackageLoader fileInPackage: 'Iconv'.

DateTime subclass: Timestamp [
    | milliseconds |
    setMilliseconds: ms [
	<category: 'private'>
	milliseconds := ms
    ]

    < aTimestamp [
	<category: 'testing'>
	"todo: UTC の考慮"
	^super < aTimestamp 
         or: [super = aTimestamp and: [milliseconds < aTimestamp milliseconds]]
    ]
    
    millisecond [ 
	<category: 'computations'>
	^milliseconds \\ 1000
    ]
    milliseconds [
	<category: 'private'>
	^milliseconds
    ]

    Timestamp class >> year: y month: m day: d hour: h minute: min second: s millisecond: ms [
	<category: 'instance creation'>
	^(super
	      year: y
	      month: m
	      day: d
	      hour: h
	      minute: min
	      second: s) 
              setMilliseconds: (((h * 60 + min) * 60 + s) * 1000 + ms)
    ]

    Timestamp class >> newFromString: timestampString [
	| tmp |
	<category: 'instance creation'>
	"0000-11-22T334455666 形式
		 0000 ..year
		 11   ..month
		 22   ..day
		 33   ..hour
		 44   ..minute
		 55   ..second
		 666  ..millisecond
	の文字列から生成する"

	tmp := timestampString substrings: #($T $-).
	^Timestamp year: (tmp at:1) asInteger
		   month: (tmp at:2) asInteger
		   day: (tmp at:3) asInteger
		   hour:  ((tmp at:4) copyFrom:1 to:2) asInteger
		   minute:((tmp at:4) copyFrom:3 to:4) asInteger
		   second:((tmp at:4) copyFrom:5 to:6) asInteger
		   millisecond: ((tmp at:4) copyFrom:7 to:9) asInteger.
    ]

    Timestamp class >> now [
	| secondClock utcSecondClock millisecondClock |

	<category: 'instance creation'>
	secondClock := Time secondClock.
	utcSecondClock := Time utcSecondClock.
	millisecondClock := Time millisecondClock.
	^(self
	      fromDays: secondClock // 86400
	      seconds: secondClock \\ 86400
	      offset: (Duration fromSeconds: secondClock - utcSecondClock))
	setMilliseconds: millisecondClock
    ]

    printYyyyMmDdOn: aStream [
	<category: 'printing'>
	aStream
	    next: 3 - (self year abs log: 10) floor put: $0;
	    print: self year abs;
	    nextPut: $-;
	    next: (self month < 10 ifTrue:[1] ifFalse:[0]) put: $0;
	    print: self month;
	    nextPut: $-;
	    next: (self day < 10 ifTrue:[1] ifFalse: [0]) put: $0;
	    print: self day.
    ]

    printHhMmOn: aStream [
	<category: 'printing'>
	aStream    
	    next: (self hour < 10 ifTrue: [1] ifFalse: [0]) put: $0;
	    print: self hour;
	    nextPut: $:;
	    next: (self minute < 10 ifTrue: [1] ifFalse: [0]) put: $0;
	    print: self minute.
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream "nextPut: (self year < 0 ifTrue: [$-] ifFalse: [Character space]);"
	    next: 3 - (self year abs log: 10) floor put: $0;
	    print: self year abs;
	    nextPut: $-;
	    next: (self month < 10 ifTrue:[1] ifFalse:[0]) put: $0;
	    print: self month;
	    nextPut: $-;
	    next: (self day < 10 ifTrue:[1] ifFalse: [0]) put: $0;
	    print: self day;
	    nextPut: $T;
	    next: (self hour < 10 ifTrue: [1] ifFalse: [0]) put: $0;
	    print: self hour;
	    "nextPut: $:;"
	    next: (self minute < 10 ifTrue: [1] ifFalse: [0]) put: $0;
	    print: self minute;
	    "nextPut: $:;"
	    next: (self second < 10 ifTrue: [1] ifFalse: [0]) put: $0;
	    print: self second;
	    "nextPut: $:;"
	    next: 2 - (self millisecond abs log: 10) floor put: $0;
	    print: self millisecond.
    ]
]

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
	Transcript cr;
	    show: 'Save start!'; cr.
	self memoTbl do: [ :memo|
	    | file fs |

	    memo isUpdate ifTrue: [
		file := self getPath / memo fileName asFile.
		fs := file open: FileStream write.
		fs nextPutAll: (memo contents asString: self fileEncoding).
		fs close.
		Transcript show: '-save :'; show: memo id printString; cr .
	    ]
	].
	Transcript show: 'Save end!'; cr.
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
    | ts1 ts2 ts3 |
    ts1 := Timestamp year: 2011
                     month: 09
                     day:    12 
                     hour:   13 
                     minute: 21 
                     second: 45 
                     millisecond: 893.
    ts1 printNl.
    ts2 := Timestamp now.
    ts2 printNl.
    ts3 := Timestamp newFromString: '2011-09-12T132145893000'.
    ts3 printNl.
]
"

"
Eval [
    | binder |
    binder := MemoBinder new.
    binder setPath: '/media/cofs3/tools/memopad/memo'.
    binder load.
    binder printListNl.

]
"
