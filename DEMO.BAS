'$INCLUDE:'../QuickPakPro/QB64/PRO.BI'
'$INCLUDE:'../QuickPakPro/QB64/DIALOG.BI'
'$INCLUDE:'../QuickPakPro/QB64/DEFCNF.BI'
'$INCLUDE:'../QuickPakPro/QB64/SETCNF.BI'
'$INCLUDE:'./INCLUDE/ANSIPRNT.BI'

CONST APP_NAME = "DEMO"
CONST CANVAS_WIDTH_MAX = 240        ' max width of our text canvas
CONST CANVAS_WIDTH_MIN = 40
CONST CANVAS_HEIGHT_MAX = 67        ' max height of our text canvas
CONST CANVAS_HEIGHT_MIN = 25
CONST CANVAS_WIDTH_DEFAULT = 80     ' default width of our text canvas
CONST CANVAS_HEIGHT_DEFAULT = 25    ' default height of our text canvas
CONST CANVAS_FONT_DEFAULT = 16      ' default font that we want to use
CONST ANSI_CPS_DEFAULT = 3600       ' default rendering speed
CONST ANSI_CPS_MAX = 99999
CONST ANSI_CPS_MIN = 0
CONST UPDATES_PER_SECOND = 30

' Program events
CONST EVENT_NONE = 0 ' idle
CONST EVENT_QUIT = 1 ' user wants to quit
CONST EVENT_CMDS = 2 ' process command line
CONST EVENT_LOAD = 3 ' user want to load files
CONST EVENT_DROP = 4 ' user dropped files
CONST EVENT_DRAW = 5 ' draw next art

DIM SHARED Canvas AS LONG       ' a handle to the canvas image
DIM SHARED CanvasWidth AS LONG  ' the width of our window in characters
DIM SHARED CanvasHeight AS LONG ' the height of our window in characters
DIM SHARED CanvasFont AS LONG   ' just holds the font type (not a font handle!)
DIM SHARED ANSICPS AS LONG      ' rendering speed

CHDIR _STARTDIR$                         ' Change to the directory specifed by the environment
ANSICPS = ANSI_CPS_DEFAULT               ' set default speed
CanvasWidth = CANVAS_WIDTH_DEFAULT       ' set default width
CanvasHeight = CANVAS_HEIGHT_DEFAULT     ' set default height
CanvasFont = CANVAS_FONT_DEFAULT         ' set default font
SetupCanvas                              ' set the initial window size
_TITLE APP_NAME + " " + _OS$             ' Set app title to the way it was
_ALLOWFULLSCREEN _SQUAREPIXELS , _SMOOTH ' Allow the program window to run fullscreen with Alt+Enter
_ACCEPTFILEDROP                          ' Enable drag and drop of files

DIM event AS _BYTE

event = EVENT_CMDS ' defaults to command line event on program entry

' Event loop
DO
  SELECT CASE event
    CASE EVENT_QUIT: EXIT DO
    CASE EVENT_CMDS: event = DoCommandLine
    CASE EVENT_LOAD: event = DoSelectedFiles
    CASE EVENT_DROP: event = DoDroppedFiles
    CASE ELSE: event = DoWelcomeScreen
  END SELECT
LOOP

SYSTEM

' Automatically sets up the window size based on globals
SUB SetupCanvas

  IF Canvas < -1 THEN ' Free any old canvas
    SCREEN 0
    _FREEIMAGE Canvas
    Canvas = 0
  END IF

  Canvas = _NEWIMAGE(8 * CanvasWidth, CanvasFont * CanvasHeight * (1 - (CanvasFont = 8)), 32) ' 8 is the built-in font width
  SCREEN Canvas             ' make the canvas the default screen
  _FONT CanvasFont          ' set the current font
  LOCATE , , FALSE          ' turn cursor off

END SUB

' Welcome screen loop
FUNCTION DoWelcomeScreen%%

  ' Allocate and setup the welcome screen
  DIM img AS LONG: img = _NEWIMAGE(80 * 8, 16 * 25, 32)
  SCREEN img

  ' Load the ANSI art data
  RESTORE Data_ANSIPrint_ans_3569
  DIM buffer AS STRING: buffer = LoadResource

  ' Render the ANSI art
  PrintANSI buffer, -1

  ' Get into a loop and check for input
  DIM k AS LONG, e AS _BYTE
  DO

    k = _KEYHIT

    IF k = KEY_ESCAPE THEN
      e = EVENT_QUIT
    ELSEIF _TotalDroppedFiles > 0 THEN
      e = EVENT_DROP
    ELSEIF k = KEY_F1 THEN
      e = EVENT_LOAD
    ELSEIF k = KEY_UPPER_F OR k = KEY_LOWER_F THEN
      CanvasFont = 24 - CanvasFont ' toggle between 16 and 8
    ELSEIF k = KEY_UP_ARROW THEN
      CanvasHeight = CanvasHeight + 1
      IF CanvasHeight > CANVAS_HEIGHT_MAX THEN CanvasHeight = CANVAS_HEIGHT_MAX
    ELSEIF k = KEY_DOWN_ARROW THEN
      CanvasHeight = CanvasHeight - 1
      IF CanvasHeight < CANVAS_HEIGHT_MIN THEN CanvasHeight = CANVAS_HEIGHT_MIN
    ELSEIF k = KEY_LEFT_ARROW THEN
      CanvasWidth = CanvasWidth - 1
      IF CanvasWidth < CANVAS_WIDTH_MIN THEN CanvasWidth = CANVAS_WIDTH_MIN
    ELSEIF k = KEY_RIGHT_ARROW THEN
      CanvasWidth = CanvasWidth + 1
      IF CanvasWidth > CANVAS_WIDTH_MAX THEN CanvasWidth = CANVAS_WIDTH_MAX
    ELSEIF k = KEY_PLUS OR k = KEY_EQUALS THEN
      ANSICPS = ANSICPS + 10
      IF ANSICPS > ANSI_CPS_MAX THEN ANSICPS = ANSI_CPS_MAX
    ELSEIF k = KEY_MINUS OR k = KEY_UNDERSCORE THEN
      ANSICPS = ANSICPS - 10
      IF ANSICPS < ANSI_CPS_MIN THEN ANSICPS = ANSI_CPS_MIN
    END IF

    COLOR Yellow, Purple
    LOCATE 15, 56: PRINT USING "##"; CanvasFont
    LOCATE 17, 58: PRINT USING "##"; CanvasHeight
    LOCATE 19, 57: PRINT USING "###"; CanvasWidth
    LOCATE 21, 57: PRINT USING "#####"; ANSICPS

    _LIMIT UPDATES_PER_SECOND

  LOOP WHILE e = EVENT_NONE

  ' Free screen image
  SCREEN 0
  _FREEIMAGE img

  DoWelcomeScreen = e

  Data_ANSIPrint_ans_3569:
  DATA 3569,1044,-1
  DATA eJytVs2PmkAU1/TWZO9NvUxP1Wy2ooAeOFnFlUTRCq5NNKGm2W2alt1ka2/8p27Cv9L3ZoZh+Ia2zygw
  DATA b3y/D94MdA6KTzqHgaHq/kvnoKr+y/+MDpS/eh0BXPCSQNDroe/huUe/HgThXzrMM/FRSqQDeI9Y8SwW
  DATA h+qTIyEB/ASkj6UCQAqw9JGCd70eHiALCcITjA/hxNhlGZaA8igOOQIe/geOARbuweB7gKYHHGXn9MP+
  DATA BMNf6Am7LMaKoXh9VAfnCBEgfa+PZUkQf6iugCJiWkp18W8FWAgCk0GMd/RQD6J4feogFKIF8cejtY9U
  DATA EZ1BpfNhnoLBAhTdUDVDGzTtPahjQAmNlxgYmlZags8v7JXiyNYqnU7r1oVhzGCGYmhjX1DVFP+SCRiW
  DATA pih+PpO68CncAsz8iJgwFo3h08i6oUVZfpc4FUj5bEzHMV4fVwC05nwAB7ocePoDRpQf+6vd0rVuHHNp
  DATA Tl0yt5amky4uiajPP0E+co0RbRZJNoKPRKeCi8xEun0Rl2x93U96KXYt05mWe2mbn13Ylz7tLDdRVuhO
  DATA gwk9Qk65mAvTkpLwb4byUnBdBZ9BR1MIsyQHRG5GnDkPHsrtm69tlyxM63Yh2ccna353MOpxAkUqhI5m
  DATA MmqbSBdUpZ11OIRxU4bS6jBYfWFpno27DbTYbL23yWS7Xe/LLZ1O7LuJI0xl9ysydKT1CnykTRki1bCq
  DATA JXOUlHZGI3dzF3/Eq3ITylLjNzvP1qU5x7W7RaMaOLu3Zu4ibexQj1uVq8r4nJRS54kQFjTNX7ZvaocS
  DATA bEKRr/GEDBOkwsTjUd5hdbFsqdnXwU25u1vTnplb4mxMc5a3F4x0XUWP4wzHRwGhLLnuW0ZKSUpLUXDc
  DATA HOSG8DGLMMMkGRwpzKIVg4JpOr48htyxxq+RpRG/sb6drle2a5Ffv7/+IKczOT2f31W2ZSacyW5qKsrE
  DATA dqzN8/fHM5nd+0+5M09jTfmWGls+Pd7vn34+yGNDZagqQ0W7vmq12u1N600Lo/3K+rgid7eTVjL+AE5A
  DATA qkw=

END FUNCTION

FUNCTION DoFileDraw%% (fileName AS STRING)

  DoFileDraw = EVENT_DRAW ' default event is to draw next file

  SetupCanvas ' setup the canvas to draw on

  ' Set the app title to display the file name
  _TITLE APP_NAME + " - " + GetFileNameFromPath(fileName)

  DIM fh AS LONG: fh = FREEFILE
  OPEN fileName FOR BINARY ACCESS READ AS fh
  COLOR DarkGray, Black ' reset the foregound and background colors
  CLS ' this will reset the cursor to 1, 1
  PrintANSI INPUT$(LOF(fh), fh), ANSICPS
  CLOSE fh

  _TITLE APP_NAME + " - [ESC to EXIT] - " + GetFileNameFromPath(fileName)

  DIM k AS LONG

  DO
    
    k = _KEYHIT

    IF _TOTALDROPPEDFILES > 0 THEN
      DoFileDraw = EVENT_DROP
      EXIT DO
    ELSEIF k = 21248 THEN ' Shift + Delete - you known what it does
      message$ = "Are you sure you want to delete " + fileName + + " permanently?"
      IF MessageBox(APP_NAME, message$, "yesno", "question", 0) = 1 THEN
        MessageBoxS APP_NAME, "KILL IT", "warning"
        'KILL fileName
        EXIT DO
      END IF
    END IF

    _LIMIT UPDATES_PER_SECOND

  LOOP UNTIL k = KEY_ESCAPE

  _TITLE APP_NAME + " " + _OS$ ' Set app title to the way it was

END FUNCTION

' Processes the command line one file at a time
FUNCTION DoCommandLine%%

  DIM i AS _UNSIGNED LONG
  DIM e AS _BYTE: e = EVENT_NONE

  IF (COMMAND$(1) = "/?" OR COMMAND$(1) = "-?") THEN
    'TODO: This should be a "screen"; not a "message box"...
    MessageBoxS APP_NAME, APP_NAME + CHR$(13) + "Syntax: DEMO [ansi_art.ans]" + CHR$(13) + "    /?: Shows this message" + STRING$(2, 13) + "Copyright (c) 2023, Cory Smith" + STRING$(2, 13) + "https://github.com/dualbrain/", "info"
    e = EVENT_QUIT
  ELSE
    FOR i = 1 TO _COMMANDCOUNT
      e = DoFileDraw(COMMAND$(i))
      IF e <> EVENT_DRAW THEN EXIT FOR
    NEXT
  END IF

  DoCommandLine = e

END FUNCTION

' Processes dropped files one file at a time
FUNCTION DoDroppedFiles%%

  ' Make a copy of the dropped file and clear the list
  REDIM fileNames(1 TO _TOTALDROPPEDFILES) AS STRING
  DIM i AS _UNSIGNED LONG
  DIM e AS _BYTE: e = EVENT_NONE

  FOR i = 1 TO _TOTALDROPPEDFILES
    fileNames(i) = _DROPPEDFILE(i)
  NEXT
  _FINISHDROP

  ' Now play the dropped file one at a time
  FOR i = LBOUND(fileNames) TO UBOUND(fileNames)
    e = DoFileDraw(fileNames(i))
    IF e <> EVENT_DRAW THEN EXIT FOR
  NEXT

  DoDroppedFiles = e

END FUNCTION

' Processes a list of files selected by the user
FUNCTION DoSelectedFiles%%

  DIM ofdList AS STRING
  DIM e AS _BYTE: e = EVENT_NONE

  ' -----
  ' Added to initialize the screen for the dialog...
  ' Really should look into how to call this from the "welcome screen"
  DIM img AS LONG: img = _NEWIMAGE(80 * 8, 16 * 25, 32)
  SCREEN img
  ' -----

  ofdList = OpenFileDialog$(APP_NAME, NULLSTRING, "*.ans|*.ANS|*.asc|*.ASC|*.diz|*.DIZ|*.nfo|*.NFO|*.txt|*.TXT", "ANSI Art Files", TRUE)

  ' -----
  ' Need to set ourselves back to the state we began.
  SCREEN 0
  _FREEIMAGE img
  ' -----

  IF ofdList = NULLSTRING THEN EXIT FUNCTION

  REDIM fileNames(0 TO 0) AS STRING
  DIM i AS LONG: DIM j AS LONG

  j = ParseOpenFileDialogList(ofdList, fileNames())

  FOR i = 0 TO j - 1
    e = DoFileDraw(fileNames(i))
    IF e <> EVENT_DRAW THEN EXIT FOR
  NEXT

  DoSelectedFiles = e

END FUNCTION

' This is a simple text parser that can take an input string from OpenFileDialog$ and spit out discrete filepaths in an array
' Returns the number of strings parsed
FUNCTION ParseOpenFileDialogList& (ofdList AS STRING, ofdArray() AS STRING)

  DIM p AS LONG: DIM c AS LONG
  DIM ts AS STRING

  REDIM ofdArray(0 TO 0) AS STRING
  ts = ofdList

  DO

    p = INSTR(ts, "|")

    IF p = 0 THEN
      ofdArray(c) = ts
      ParseOpenFileDialogList& = c + 1
      EXIT FUNCTION
    END IF

    ofdArray(c) = LEFT$(ts, p - 1)
    ts = MID$(ts, p + 1)

    c = c + 1
    REDIM _PRESERVE ofdArray(0 TO c) AS STRING

  LOOP

END FUNCTION

' Gets the filename portion from a file path
FUNCTION GetFileNameFromPath$ (pathName AS STRING)

  DIM i AS _UNSIGNED LONG

  ' Retrieve the position of the first / or \ in the parameter from the
  FOR i = LEN(pathName) TO 1 STEP -1
    IF ASC(pathName, i) = KEY_SLASH OR ASC(pathName, i) = KEY_BACKSLASH THEN EXIT FOR
  Next

  ' Return the full string if pathsep was not found
  IF i = 0 THEN
    GetFileNameFromPath = pathName
  ELSE
    GetFileNameFromPath = RIGHT$(pathName, LEN(pathName) - i)
  END IF

END FUNCTION

' -----

FUNCTION MessageBox(caption$, message$, button$, icon$, defaultButton)

  IF icon$ <> "" THEN
  END IF
  IF defaultButton THEN
  END IF

  if len(message$) > 60 THEN message$ = LEFT$(message$, 60)

  DIM button AS LONG
  SELECT CASE button$
    CASE "ok": button = 0
    CASE "okcancel": button = 1
    CASE "abortretryignore": button = 2
    CASE "yesnocancel": button = 3
    CASE "yesno": button = 4
    CASE "retrycancel": button = 5
    CASE ELSE
  END SELECT

  REDIM menu$(0)
  REDIM text$(0 TO 4)
  REDIM response$(0)
  text$(0) = caption$
  text$(1) = "< OK >"
  text$(2) = " "
  text$(3) = message$
  text$(4) = " "
  action = 0: scrnRow = 0: choice = 1: clr = 112: style = 11

  CALL Dialog(choice, text$(), response$(), menu$(), scrnRow, style, clr, action)

  ' wdth = 54                'a box 54 characters wide will be centered on screen
  ' LOCATE 3                 'the top of the box goes on line 3
  ' CALL CSMsgBox(message$, wdth, cnf)
  ' k = WaitKey

  ' Translate result to "visible button number".
  SELECT CASE button
    CASE 1, 2: MessageBox = result
    CASE 3
      SELECT CASE result
        CASE 3: MessageBox = 1
        CASE 4: MessageBox = 2
        CASE 5: MessageBox = 3
        CASE ELSE: MessageBox = 0
      END SELECT
    CASE 4
      SELECT CASE result
        CASE 6: MessageBox = 1
        CASE 7: MessageBox = 2
        CASE ELSE: MessageBox = 0
      END SELECT
    CASE 5
      SELECT CASE result
        CASE 2: MessageBox = 2
        CASE 4: MessageBox = 1
        CASE ELSE: MessageBox = 0
      END SELECT
    CASE ELSE
      MessageBox = 0
  END SELECT

  ' IF icon$ <> "" THEN
  '   ' Not sure if will support "icon$"; but should allow for it for 
  '   ' compatibility reasons.
  ' END IF

  ' WHILE INKEY$ <> "": WEND

  ' ' save screen
  ' PCOPY 0, 1

  ' ' store current fg/bg
  ' DIM ofg AS LONG: DIM obg AS LONG
  ' ofg = _DEFAULTCOLOR
  ' obg = _BACKGROUNDCOLOR

  ' 'TODO: should determine which "screen mode"
  ' '      we are in as RGB colors is only available in 
  ' '      non-SCREEN 0 modes.

  ' ' determine and set fg/bg
  ' DIM fg AS LONG: fg = _RGB32(0,0,0)
  ' DIM bg AS LONG: bg = _RGB32(170,170,170)
  
  ' COLOR fg, bg

  ' DIM tp AS LONG: tp = 9
  ' DIM lt AS LONG: lt = 10
  ' DIM ht AS LONG: ht = 7
  ' DIM wd AS LONG: wd = 60

  ' ' draw the overall box
  ' DIM r AS LONG
  ' LOCATE tp, lt: PRINT CHR$(218) + STRING$(wd - 2, 196) + CHR$(191)
  ' FOR r = tp + 1 TO tp + ht - 1
  '   LOCATE r, lt: PRINT CHR$(179) + SPACE$(wd - 2) + CHR$(179)
  ' NEXT
  ' LOCATE tp + ht, lt: PRINT CHR$(192) + STRING$(wd - 2, 196) + CHR$(217)
  ' LOCATE tp + ht - 2, lt: PRINT CHR$(195) + STRING$(wd - 2, 196) + CHR$(180)
  
  ' ' shadow?

  ' ' draw caption
  ' IF caption$ <> "" THEN
  '   LOCATE tp, 40 - ((LEN(caption$) + 2) \ 2)
  '   PRINT " " + caption$ + " "
  ' END IF

  ' 'TODO: Need to reformat (wordwrap) message.
  ' '      Need to move this process above so we
  ' '      can determine the number of lines needed.
  ' r = tp + 1
  ' DIM m$
  ' DIM po AS LONG: po = 1
  ' DIM o AS LONG
  ' DO
  '   LOCATE r, lt + 2
  '   o = INSTR(po, message$, CHR$(13)) ' HACK: using passed in CR;
  '   IF o = 0 THEN                     '       passing of this should not be required.
  '     m$ = MID$(message$, po)
  '     po = LEN(message$) + 1
  '   ELSE
  '     m$ = MID$(message$, po, (o - po))
  '     po = o + 1
  '   END IF
  '   PRINT m$
  '   r = r + 1
  '   IF po > LEN(message$) THEN EXIT DO
  ' LOOP

  ' ' draw buttons
  ' IF defaultButton THEN
  '   'TODO: Need to handle/implement.
  ' END IF
  ' IF button$ = "yesno" THEN
  '   LOCATE tp + ht - 1, lt + 15: PRINT "< YES >"
  '   LOCATE tp + ht - 1, lt + wd - 20: PRINT "< NO >"
  '   'TODO: Need to implement additional "button" styles
  ' ELSE
  '   LOCATE tp + ht - 1, 38: PRINT "< OK >"
  ' END IF

  ' WHILE INKEY$ = "": WEND

  ' COLOR ofg, obg

  ' PCOPY 1, 0

  ' ' restore screen
  ' MessageBox = 0

END FUNCTION

SUB MessageBoxS(caption$, message$, icon$)

  ignore = MessageBox(caption$, message$, "ok", "info", 0)

  ' ' old copy, need to update based on improvements to MessageBox.

  ' WHILE INKEY$ <> "": WEND

  ' ' save screen
  ' PCOPY 0, 1

  ' ' store current fg/bg
  ' DIM ofg AS LONG: DIM obg AS LONG
  ' ofg = _DEFAULTCOLOR
  ' obg = _BACKGROUNDCOLOR

  ' ' determine and set fg/bg
  ' DIM fg AS LONG: fg = _RGB32(0,0,0)
  ' DIM bg AS LONG: bg = _RGB32(170,170,170)
  ' COLOR fg, bg

  ' DIM tp AS LONG: tp = 9
  ' DIM lt AS LONG: lt = 10
  ' DIM ht AS LONG: ht = 7
  ' DIM wd AS LONG: wd = 60

  ' ' draw the overall box
  ' DIM r AS LONG
  ' LOCATE tp, lt: PRINT CHR$(218) + STRING$(wd - 2, 196) + CHR$(191)
  ' FOR r = tp + 1 TO tp + ht - 1
  '   LOCATE r, lt: PRINT CHR$(179) + SPACE$(wd - 2) + CHR$(179)
  ' NEXT
  ' LOCATE tp + ht, lt: PRINT CHR$(192) + STRING$(wd - 2, 196) + CHR$(217)
  ' LOCATE tp + ht - 2, lt: PRINT CHR$(195) + STRING$(wd - 2, 196) + CHR$(180)
  
  ' ' shadow?

  ' ' draw caption
  ' IF caption$ <> "" THEN
  '   LOCATE tp, 40 - ((LEN(caption$) + 2) \ 2)
  '   PRINT " " + caption$ + " "
  ' END IF

  ' r = tp + 1
  ' DIM m$
  ' DIM po AS LONG: po = 1
  ' DIM o AS LONG
  ' DO
  '   LOCATE r, lt + 2
  '   o = INSTR(po, message$, CHR$(13))
  '   IF o = 0 THEN 
  '     m$ = MID$(message$, po)
  '     po = LEN(message$) + 1
  '   ELSE
  '     m$ = MID$(message$, po, (o - po))
  '     po = o + 1
  '   END IF
  '   PRINT m$
  '   r = r + 1
  '   IF po > LEN(message$) THEN EXIT DO
  ' LOOP

  ' ' draw button
  ' LOCATE tp + ht - 1, 38: PRINT "< OK >"

  ' WHILE INKEY$ = "": WEND

  ' COLOR ofg, obg

  ' ' restore screen
  ' PCOPY 1, 0

END SUB

FUNCTION OpenFileDialog$(caption$, defaultPathAndFile$, filterPatterns$, singleFilterDescription$, allowMultipleSelects&)
  'TODO: Need to implement some version of an
  '      Open File Dialog...
  IF allowMultipleSelects& THEN
  END IF
  IF MessageBox(caption$, defaultPathAndFile$ + CHR$(13) + filterPatterns$ + CHR$(13) + singleFilterDescription$, "ok", "question", 0) THEN
  END IF
  OpenFileDialog$ = NULLSTRING
END FUNCTION

' -----

'$INCLUDE:'../QuickPakPro/QB64/PRO.BAS'
'$INCLUDE:'../QuickPakPro/QB64/DIALOG.BAS'
'$INCLUDE:'../QuickPakPro/QB64/MSGBOX.BAS'
'$INCLUDE:'./INCLUDE/ANSIPRNT.BAS'
'$INCLUDE:'./INCLUDE/BASE64.BAS'