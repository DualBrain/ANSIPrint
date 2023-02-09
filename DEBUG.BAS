'$INCLUDE: './INCLUDE/ANSIPRNT.BI'

$DEBUG
SCREEN _NEWIMAGE(8 * 80, 16 * 25, 32)
_FONT 16

DO
  DIM ansFile AS STRING: ansFile = "./DEMOS/ANSI.ANS"
  IF NOT _FILEEXISTS(ansFile) THEN EXIT DO
  DIM fh AS LONG: fh = FREEFILE
  OPEN ansFile FOR BINARY ACCESS READ AS fh
  COLOR DarkGray, Black
  CLS
  PrintANSI INPUT$(LOF(fh), fh), -1 ' put a -ve number here for superfast rendering
  CLOSE fh
  _TITLE "Press any key to open another file...": SLEEP 3600
LOOP
END

'$INCLUDE: './INCLUDE/ANSIPRNT.BAS'