'$INCLUDE: './INCLUDE/ANSIPRNT.BI'

'$DEBUG

ansFile$ = "./DEMOS/ANSI.ANS"

IF NOT _FILEEXISTS(ansFile$) THEN 
  PRINT "'"; ansFile$; "' not found."
ELSE

  _TITLE ansFile$

  fh = FREEFILE
  OPEN ansFile$ FOR BINARY ACCESS READ AS fh
  sequence$ = INPUT$(LOF(fh), fh)
  CLOSE fh

  SCREEN _NEWIMAGE(8 * 80, 16 * 25, 32)
  _FONT 16
  COLOR DarkGray, Black: CLS
  PrintANSI sequence$, -1 ' put a -ve number here for superfast rendering

  WHILE INKEY$ = "": WEND

  SYSTEM

END IF

'$INCLUDE: './INCLUDE/ANSIPRNT.BAS'