#!/usr/bin/env gst


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
	    next: ((self millisecond = 0) ifTrue: [2] ifFalse: [2 - (self millisecond abs log: 10) floor]) put: $0;
	    print: self millisecond.
    ]


    printStringYyyyMmDd [
	| ws |
	<category: 'printing'>
	ws := WriteStream on: String new.
	self printYyyyMmDdOn: ws.
	^ws contents
    ]

    printStringHhMm [
	| ws |
	<category: 'printing'>
	ws := WriteStream on: String new.
	self printHhMmOn: ws.
	^ws contents
    ]

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
