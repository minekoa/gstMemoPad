gstMemoPad

## このツールは
かつて、自分用のメモツールとして作成した MemoPad を GNU Smalltalk に移植しつつ
GNU Smalltalk 用の実験パッドとして作った PettitWorkspace と合体し、
コードの実験もメモもかける軽量ツールとして作成しました。

## 主な特徴

特に保存操作を意識せず、バシバシメモを取ることが出きます。
（現状ではアプリケーション終了時に保存される動作になっています）

## 起動方法

### 1. バインダ（メモの保存フォルダ）の指定

pad.st 最下部 Eval ブロック内にハードコート記述されたパスを
都合の良いパスに置き換えます。

```smalltalk
Eval [
     | binderPath |
     "Binderのパスを取得
     ./pad.st -a hogehoge_binderpath  と打つと任意のメモバインダを開けます
     何も指定しない場合は本コードにハードコードされたデフォルトのパスを開きます"
     (Smalltalk getArgc = 0) 
       ifTrue: [ binderPath := '../../Dropbox/contents/memopad/memo']
       ifFalse: [ binderPath := Smalltalk getArgv: 1].
    Transcript show: 'Open MemoBinder: '; show: binderPath; cr.
```
（上記コードの ifTrue: ブロック内で binderPath に設定されているパスを書き換える）


または、argv でBinderのパスを与えることもできます（後述）


### 2. アプリケーションの起動
その後、以下を実行します。

```
$ ./pad.st
```
argv でBinderのパスを与えるには以下のようにします

```
./pad.st -a test_binder
```

note:
GNU Smalltalk は プログラムからコマンドライン引数を取得出来るようにするためには
-a オプションが必要です。

## 未実装機能

Smalltalk Pad としての機能

* 右クリックからの doit, printit
* Transcript 機能（今は起動元のコンソールにでるが、専用のウインドウが開くとよいか？）
* Classブラウザ機能

MemoPad アプリとしての機能 (Python からの移植）

* changelog 作成機能（アプリが落ちた時の変更内容の救済機能】
* リスト部をドラックすることでメモを「ペラペラめくる」機能

## 捕捉
changelog 機能がないので、アプリが落ちることで作ったメモがうっかり消えてしまう事故から
救済することができません。そこで、そのページで

```smalltalk
self updateCurrentMemo.
binder save: currentMemo. 
```

を doit することで、そのページを保存することができますので、
その場しのぎ的に利用ください。

note:
doit/ printit は PettitWorkspace 自体を self として
実行されます

```
                                                             ┌──────────────┐
┌────────┐               ┌──────────┐ /│Memoオブジェクトの取り纏めと└┐     
│PettitWorkspace │binder ◆───│ MemoBinder         │/ │シリアライズを担う            │
├────────┤               ├──────────┤  └───────────────┘
│                │               │-path               │
│                │               │-memoTbl            │
│                │               ├──────────┤
│                │               │+memoTbl            │
│                │               │+createMemo         │
│                │               │+deleteMemo: memoObj│
│                │               │+load               │
│                │               │+save               │
│                │               │+save: memoObj      │
│                │               │+find: memoId       │
└────────┘               └──────────┘
         currentMemo ◇                  ◆1
                     │                  │0..*
                     │           ┌────────┐
                     │           │     Memo       │
                     │           ├────────┤
                     └────→ │-contents       │
                                  │-timestamp      │
                                  │-isUpdate       │
                                  ├────────┤
                                  │+contents       │
                                  │+timestamp      │
                                  │+isUPdate       │
                                  │+updateContents:│
                                  │+setTimeStamp   │
                                  │+id             │
                                  │+title          │
                                  └────────┘
```
