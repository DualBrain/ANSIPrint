' TODO:
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#screen-colors
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#window-title
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#soft-reset
'   https://github.com/a740g/ANSIPrint/blob/master/docs/ansimtech.txt

'$INCLUDE:'./ANSIPRNT.BI'

$IF ANSIPRINT_BAS = UNDEFINED THEN

  $LET ANSIPRINT_BAS = TRUE

  ' sANSI - the ANSI stream to render
  ' nCPS - characters / second (bigger numbers means faster; -ve number to disable)
  SUB PrintANSI (sANSI AS STRING, nCPS AS LONG)
    STATIC colorLUTInitialized AS LONG ' if this is true then the legacy color table has been initialized
    DIM state AS LONG ' the current parser state
    DIM i AS LONG ' the current character index
    DIM ch AS LONG ' the current character
    REDIM arg(1 TO ANSI_ARG_COUNT) AS LONG ' CSI argument list
    DIM argIndex AS LONG ' the current CSI argument index & count; 0 means no arguments
    'DIM leadInPrefix AS LONG  ' the type of lead-in prefix that was specified; this can help diffrentiate what the argument will be used for
    DIM isBold AS LONG ' text attribute
    DIM isBlink AS LONG ' text attribute
    DIM isInvert AS LONG ' text attribute
    DIM x AS LONG ' temp variable used in many places (usually as counter / index)
    DIM y AS LONG ' temp variable used in many places (usually as counter / index)
    DIM z AS LONG ' temp variable used in many places (usually as counter / index)
    DIM fc AS _UNSIGNED LONG ' foreground color
    DIM bc AS _UNSIGNED LONG ' background color
    DIM savedDECX AS LONG ' DEC saved cursor position
    DIM savedDECY AS LONG 
    DIM savedSCOX AS LONG ' SCO saved cursor position
    DIM savedSCOY AS LONG
    DIM oldControlChr AS LONG ' to save old ContolChr
    ' We only support rendering to 32bpp images
    IF _PIXELSIZE < 4 THEN ERROR ERROR_FEATURE_UNAVAILABLE
    ' Setup legacy color LUT if needed
    IF NOT colorLUTInitialized THEN
      InitializeANSIColorLUT
      colorLUTInitialized = TRUE
    END IF
    ' Save the old ControlChr state
    oldControlChr = _ControlChr
    _CONTROLCHR ON ' get assist from QB64's control character handling (only for tabs; we are pretty much doing the rest ourselves)
    ' Get the current cursor position
    savedDECX = POS(0)
    savedDECY = CSRLIN
    savedSCOX = savedDECX
    savedSCOY = savedDECY
    ' Reset the foreground and background color
    fc = ANSI_DEFAULT_COLOR_FOREGROUND
    SetTextCanvasColor fc, FALSE, TRUE
    bc = ANSI_DEFAULT_COLOR_BACKGROUND
    SetTextCanvasColor bc, TRUE, TRUE
    state = ANSI_STATE_TEXT ' we will start parsing regular text by default
    FOR i = 1 TO LEN(sANSI)
      ch = ASC(sANSI, i)
      SELECT CASE state
        CASE ANSI_STATE_TEXT ' handle normal characters (including some control characters)
          SELECT CASE ch
            CASE ANSI_SUB ' stop processing and exit loop on EOF (usually put by SAUCE blocks)
              state = ANSI_STATE_END
            CASE ANSI_BEL ' handle Bell - because QB64 does not (even with ControlChr On)
              BEEP
            CASE ANSI_BS ' handle Backspace - because QB64 does not (even with ControlChr On)
              x = POS(0) - 1
              IF x > 0 THEN LOCATE , x ' move to the left only if we are not on the edge
            CASE ANSI_LF ' handle Line Feed because QB64 screws this up and moves the cursor to the beginning of the next line
              x = POS(0) ' save old x pos
              PRINT CHR$(ch); ' use QB64 to handle the LF and then correct the mistake
              LOCATE , x ' set the cursor to the old x pos
            CASE ANSI_FF ' handle Form Feed - because QB64 does not (even with ControlChr On)
              LOCATE 1, 1
            CASE ANSI_CR ' handle Carriage Return because QB64 screws this up and moves the cursor to the beginning of the next line
              LOCATE , 1
            'CASE ANSI_DEL ' TODO: Check what to do with this
            CASE ANSI_ESC ' handle escape character
              state = ANSI_STATE_BEGIN ' beginning a new escape sequence
            CASE ELSE ' print the character
              PRINT CHR$(ch);
              IF nCPS > 0 THEN _LIMIT nCPS ' limit the loop speed if char/sec is a positive value
          END SELECT
        CASE ANSI_STATE_BEGIN ' handle escape sequence
          SELECT CASE ch
            CASE IS < ANSI_SP ' handle escaped character
              _CONTROLCHR OFF
              PRINT CHR$(ch); ' print escaped ESC character
              _CONTROLCHR ON
              IF nCPS > 0 THEN _LIMIT nCPS ' limit the loop speed if char/sec is a positive value
              state = ANSI_STATE_TEXT
            CASE ANSI_ESC_DECSC ' Save Cursor Position in Memory
              savedDECX = POS(0)
              savedDECY = CSRLIN
              state = ANSI_STATE_TEXT
            CASE ANSI_ESC_DECSR ' Restore Cursor Position from Memory
              LOCATE savedDECY, savedDECX
              state = ANSI_STATE_TEXT
            CASE ANSI_ESC_RI ' Reverse Index
              y = CSRLIN - 1
              IF y > 0 THEN LOCATE y
              state = ANSI_STATE_TEXT
            CASE ANSI_ESC_CSI ' handle CSI
              REDIM arg(1 TO ANSI_ARG_COUNT) AS LONG ' reset the control sequence arguments
              argIndex = 0 ' reset argument index
              'leadInPrefix = 0 ' reset lead-in prefix
              state = ANSI_STATE_SEQUENCE
            CASE ELSE ' throw an error for stuff we are not handling
              ERROR ERROR_FEATURE_UNAVAILABLE
          END SELECT
        CASE ANSI_STATE_SEQUENCE ' handle CSI sequence
          SELECT CASE ch
            CASE ANSI_0 TO ANSI_QUESTION_MARK ' argument bytes
                If argIndex < 1 Then argIndex = 1 ' set the argument index to one if this is the first time
                Select Case ch
                    Case ANSI_0 To ANSI_9 ' handle sequence numeric arguments
                        arg(argIndex) = arg(argIndex) * 10 + ch - ANSI_0
                    Case ANSI_SEMICOLON ' handle sequence argument seperators
                        argIndex = argIndex + 1 ' increment the argument index
                    Case ANSI_EQUALS_SIGN, ANSI_GREATER_THAN_SIGN, ANSI_QUESTION_MARK ' handle lead-in prefix
                        ' NOP: leadInPrefix = ch ' just save the prefix type
                    Case Else ' throw an error for stuff we are not handling
                        Error ERROR_FEATURE_UNAVAILABLE
                End Select
            Case ANSI_SP To ANSI_SLASH ' intermediate bytes
                Select Case ch
                    Case ANSI_SP ' ignore spaces
                        ' NOP
                    Case Else ' throw an error for stuff we are not handling
                        Error ERROR_FEATURE_UNAVAILABLE
                End Select
            CASE ANSI_AT_SIGN TO ANSI_TILDE ' final byte
              SELECT CASE ch
                CASE ANSI_ESC_CSI_SM, ANSI_ESC_CSI_RM ' Set and reset screen mode
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  SELECT CASE arg(1)
                    CASE 0 TO 6, 14 TO 18 ' all mode changes are ignored. the screen type must be set by the caller
                        ' NOP
                    CASE 7 ' Enable / disable line wrapping
                      ' NOP: QB64 does line wrapping by default
                      IF ANSI_ESC_CSI_RM = ch THEN ' ANSI_ESC_CSI_RM disable line wrapping unsupported
                        ERROR ERROR_FEATURE_UNAVAILABLE
                      END IF
                    CASE 12 ' Text Cursor Enable / Disable Blinking
                      ' NOP
                    CASE 25 ' make cursor visible / invisible
                      IF ANSI_ESC_CSI_SM = ch THEN ' ANSI_ESC_CSI_SM make cursor visible
                        LOCATE , , 1
                      ELSE ' ANSI_ESC_CSI_RM make cursor invisible
                        LOCATE , , 0
                      END IF
                    CASE ELSE ' throw an error for stuff we are not handling
                      ERROR ERROR_FEATURE_UNAVAILABLE
                  END SELECT
                CASE ANSI_ESC_CSI_ED ' Erase in Display
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  SELECT CASE arg(1)
                    CASE 0 ' clear from cursor to end of screen
                      ClearTextCanvasArea POS(0), CSRLIN, TextCanvasWidth, CSRLIN ' first clear till the end of the line starting from the cursor
                      ClearTextCanvasArea 1, CSRLIN + 1, TextCanvasWidth, TextCanvasHeight ' next clear the whole canvas below the cursor
                    CASE 1 ' clear from cursor to beginning of the screen
                      ClearTextCanvasArea 1, CSRLIN, POS(0), CSRLIN ' first clear from the beginning of the line till the cursor
                      ClearTextCanvasArea 1, 1, TextCanvasWidth, CSRLIN - 1 ' next clear the whole canvas above the cursor
                    CASE 2 ' clear entire screen (and moves cursor to upper left like ANSI.SYS)
                      Cls
                    CASE 3 ' clear entire screen and delete all lines saved in the scrollback buffer (scrollback stuff not supported)
                      ClearTextCanvasArea 1, 1, TextCanvasWidth, TextCanvasHeight
                    CASE ELSE ' throw an error for stuff we are not handling
                      ERROR ERROR_FEATURE_UNAVAILABLE
                  END SELECT
                CASE ANSI_ESC_CSI_EL ' Erase in Line
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  SELECT CASE arg(1)
                    CASE 0 ' erase from cursor to end of line
                      ClearTextCanvasArea POS(0), CSRLIN, TextCanvasWidth, CSRLIN
                    CASE 1 ' erase start of line to the cursor
                      ClearTextCanvasArea 1, CSRLIN, POS(0), CSRLIN
                    CASE 2 ' erase the entire line
                      ClearTextCanvasArea 1, CSRLIN, TextCanvasWidth, CSRLIN
                    CASE ELSE ' throw an error for stuff we are not handling
                      ERROR ERROR_FEATURE_UNAVAILABLE
                  END SELECT
                CASE ANSI_ESC_CSI_SGR ' Select Graphic Rendition
                  x = 1 ' start with the first argument
                  IF argIndex < 1 THEN argIndex = 1 ' this allows '[m' to be treated as [0m
                  DO WHILE x <= argIndex ' loop through the argument list and process each argument
                    SELECT CASE arg(x)
                      CASE 0 ' reset all modes (styles and colors)
                        fc = ANSI_DEFAULT_COLOR_FOREGROUND
                        bc = ANSI_DEFAULT_COLOR_BACKGROUND
                        isBold = FALSE
                        isBlink = FALSE
                        isInvert = FALSE
                        SetTextCanvasColor fc, isInvert, TRUE
                        SetTextCanvasColor bc, Not isInvert, TRUE
                      CASE 1 ' enable high intensity colors
                        IF fc < 8 THEN fc = fc + 8
                        isBold = TRUE
                        SetTextCanvasColor fc, isInvert, TRUE
                      CASE 2, 22 ' enable low intensity, disable high intensity colors
                        IF fc > 7 THEN fc = fc - 8
                        isBold = FALSE
                        SetTextCanvasColor fc, isInvert, TRUE
                      CASE 3, 4, 23, 24 ' set / reset italic & underline mode ignored
                          ' NOP: This can be used if we load monospaced TTF fonts using 'italics', 'underline' properties
                      CASE 5, 6 ' turn blinking on
                        IF bc < 8 THEN bc = bc + 8
                        isBlink = TRUE
                        SetTextCanvasColor bc, NOT isInvert, TRUE
                      CASE 7 ' enable reverse video
                        IF NOT isInvert THEN
                          isInvert = TRUE
                          SetTextCanvasColor fc, isInvert, TRUE
                          SetTextCanvasColor bc, NOT isInvert, TRUE
                        END IF
                      CASE 25 ' turn blinking off
                        IF bc > 7 THEN bc = bc - 8
                        isBlink = FALSE
                        SetTextCanvasColor bc, NOT isInvert, TRUE
                      CASE 27 ' disable reverse video
                        IF isInvert THEN
                          isInvert = FALSE
                          SetTextCanvasColor fc, isInvert, TRUE
                          SetTextCanvasColor bc, NOT isInvert, TRUE
                        END IF
                      CASE 30 TO 37 ' set foreground color
                        fc = arg(x) - 30
                        IF isBold THEN fc = fc + 8
                        SetTextCanvasColor fc, isInvert, TRUE
                      CASE 38 ' set 8-bit 256 or 24-bit RGB foreground color
                        z = argIndex - x ' get the number of arguments remaining
                        IF arg(x + 1) = 2 AND z >= 4 THEN ' 32bpp color with 5 arguments
                          fc = _RGB32(arg(x + 2) AND &HFF, arg(x + 3) AND &HFF, arg(x + 4) AND &HFF)
                          SetTextCanvasColor fc, isInvert, FALSE
                          x = x + 4 ' skip to last used arg
                        ELSEIF arg(x + 1) = 5 AND z >= 2 THEN ' 256 color with 3 arguments
                          fc = arg(x + 2)
                          SetTextCanvasColor fc, isInvert, TRUE
                          x = x + 2 ' skip to last used arg
                        ELSE
                          ERROR ERROR_CANNOT_CONTINUE
                        END IF
                      CASE 39 ' set default foreground color
                        fc = ANSI_DEFAULT_COLOR_FOREGROUND
                        SetTextCanvasColor fc, isInvert, TRUE
                      CASE 40 TO 47 ' set background color
                        bc = arg(x) - 40
                        IF isBlink THEN bc = bc + 8
                        SetTextCanvasColor bc, NOT isInvert, TRUE
                      CASE 48 ' set 8-bit 256 or 24-bit RGB background color
                        z = argIndex - x ' get the number of arguments remaining
                        IF arg(x + 1) = 2 AND z >= 4 THEN ' 32bpp color with 5 arguments
                          bc = _RGB32(arg(x + 2) AND &HFF, arg(x + 3) AND &HFF, arg(x + 4) AND &HFF)
                          SetTextCanvasColor bc, NOT isInvert, FALSE
                          x = x + 4 ' skip to last used arg
                        ELSEIF arg(x + 1) = 5 AND z >= 2 THEN ' 256 color with 3 arguments
                          bc = arg(x + 2)
                          SetTextCanvasColor bc, NOT isInvert, TRUE
                          x = x + 2 ' skip to last used arg
                        ELSE
                          ERROR ERROR_CANNOT_CONTINUE
                        END IF
                      CASE 49 ' set default background color
                        bc = ANSI_DEFAULT_COLOR_BACKGROUND
                        SetTextCanvasColor bc, NOT isInvert, TRUE
                      CASE 90 TO 97 ' set high intensity foreground color
                        fc = 8 + arg(x) - 90
                        SetTextCanvasColor fc, isInvert, TRUE
                      CASE 100 TO 107 ' set high intensity background color
                        bc = 8 + arg(x) - 100
                        SetTextCanvasColor bc, NOT isInvert, TRUE
                      CASE ELSE ' throw an error for stuff we are not handling
                        ERROR ERROR_FEATURE_UNAVAILABLE
                    END SELECT
                    x = x + 1 ' move to the next argument
                  LOOP
                CASE ANSI_ESC_CSI_SCP ' Save Current Cursor Position (SCO)
                  IF argIndex > 0 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting args
                  savedSCOX = POS(0)
                  savedSCOY = CSRLIN
                CASE ANSI_ESC_CSI_RCP ' Restore Saved Cursor Position (SCO)
                  IF argIndex > 0 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting args
                  LOCATE savedSCOY, savedSCOX
                CASE ANSI_ESC_CSI_PABLODRAW_24BPP ' PabloDraw 24-bit ANSI sequences
                  IF argIndex <> 4 THEN ERROR ERROR_CANNOT_CONTINUE ' we need 4 arguments
                  SetTextCanvasColor _RGB32(arg(2) AND &HFF, arg(3) AND &HFF, arg(4) AND &HFF), arg(1) = FALSE, FALSE
                CASE ANSI_ESC_CSI_CUP, ANSI_ESC_CSI_HVP ' Cursor position or Horizontal and vertical position
                  IF argIndex > 2 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 2 args
                  y = TextCanvasHeight
                  IF arg(1) < 1 THEN
                    arg(1) = 1
                  ELSEIF arg(1) > y THEN
                    arg(1) = y
                  END IF
                  x = TextCanvasWidth
                  IF arg(2) < 1 THEN
                    arg(2) = 1
                  ELSEIF arg(2) > x THEN
                    arg(2) = x
                  END IF
                  LOCATE arg(1), arg(2) ' line #, column #
                CASE ANSI_ESC_CSI_CUU ' Cursor up
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  IF arg(1) < 1 THEN arg(1) = 1
                  y = CSRLIN - arg(1)
                  IF y < 1 THEN arg(1) = 1
                  LOCATE y
                CASE ANSI_ESC_CSI_CUD ' Cursor down
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  IF arg(1) < 1 THEN arg(1) = 1
                  y = CSRLIN + arg(1)
                  z = TextCanvasHeight
                  IF y > z THEN y = z
                  LOCATE y
                CASE ANSI_ESC_CSI_CUF ' Cursor forward
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  IF arg(1) < 1 THEN arg(1) = 1
                  x = POS(0) + arg(1)
                  z = TextCanvasWidth
                  IF x > z THEN x = z
                  LOCATE , x
                CASE ANSI_ESC_CSI_CUB ' Cursor back
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  IF arg(1) < 1 THEN arg(1) = 1
                  x = POS(0) - arg(1)
                  IF x < 1 THEN x = 1
                  LOCATE , x
                CASE ANSI_ESC_CSI_CNL ' Cursor Next Line
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  IF arg(1) < 1 THEN arg(1) = 1
                  y = CSRLIN + arg(1)
                  z = TextCanvasHeight
                  IF y > z THEN y = z
                  LOCATE y, 1
                CASE ANSI_ESC_CSI_CPL ' Cursor Previous Line
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  IF arg(1) < 1 THEN arg(1) = 1
                  y = CSRLIN - arg(1)
                  IF y < 1 THEN y = 1
                  LOCATE y, 1
                CASE ANSI_ESC_CSI_CHA ' Cursor Horizontal Absolute
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  x = TextCanvasWidth
                  IF arg(1) < 1 THEN
                    arg(1) = 1
                  ELSEIF arg(1) > x THEN
                    arg(1) = x
                  END IF
                  LOCATE , arg(1)
                CASE ANSI_ESC_CSI_VPA ' Vertical Line Position Absolute
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  y = TextCanvasHeight
                  IF arg(1) < 1 THEN
                      arg(1) = 1
                  ELSEIF arg(1) > y THEN
                      arg(1) = y
                  END IF
                  LOCATE arg(1)
                CASE ANSI_ESC_CSI_DECSCUSR
                  IF argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg
                  SELECT CASE arg(1)
                    CASE 0, 3, 4 ' Default, Blinking & Steady underline cursor shape
                      LOCATE , , , 29, 31 ' this should give a nice underline cursor
                    CASE 1, 2 ' Blinking & Steady block cursor shape
                      LOCATE , , , 0, 31 ' this should give a full block cursor
                    CASE 5, 6 ' Blinking & Steady bar cursor shape
                      LOCATE , , , 16, 31 ' since we cannot get a bar cursor in QB64, we'll just use a half-block cursor
                    CASE ELSE ' throw an error for stuff we are not handling
                      ERROR ERROR_FEATURE_UNAVAILABLE
                  End Select
                CASE ELSE ' throw an error for stuff we are not handling
                  ERROR ERROR_FEATURE_UNAVAILABLE
              END SELECT
              ' End of sequence
              state = ANSI_STATE_TEXT
            CASE ELSE ' throw an error for stuff we are not handling
              ERROR ERROR_FEATURE_UNAVAILABLE
          END SELECT
        CASE ANSI_STATE_END ' exit loop if end state was set
          EXIT FOR
        CASE ELSE ' this should never happen
          ERROR ERROR_CANNOT_CONTINUE
      END SELECT
    NEXT
    ' Set ControlChr the way we found it
    IF oldControlChr THEN
      _CONTROLCHR OFF
    ELSE
      _CONTROLCHR ON
    END IF
  END SUB

  ' Set the foreground or background color
  SUB SetTextCanvasColor (c AS _UNSIGNED LONG, isBackground AS LONG, isLegacy AS LONG)
    SHARED ANSIColorLUT() AS _UNSIGNED LONG
    DIM nRGB AS _UNSIGNED LONG
    IF isLegacy THEN
      nRGB = ANSIColorLUT(c)
    ELSE
      nRGB = c
    END IF
    IF isBackground THEN
      ' Echo "Background color" + STR$(c) + " (" + HEX$(nRGB) + ")"
      Color , nRGB
    ELSE
      ' Echo "Foreground color" + STR$(c) + " (" + HEX$(nRGB) + ")"
      COLOR nRGB
    END IF
  END SUB

  ' Returns the number of characters per line
  FUNCTION TextCanvasWidth&
    TextCanvasWidth& = _WIDTH \ _FONTWIDTH ' this will cause a divide by zero if a variable width font is used; use monospaced fonts to avoid this
  END FUNCTION

  ' Returns the number of lines
  FUNCTION TextCanvasHeight&
    TextCanvasHeight& = _HEIGHT \ _FONTHEIGHT
  END FUNCTION

  ' Clears a given portion of screen without disturbing the cursor location and screen colors
  SUB ClearTextCanvasArea (l AS LONG, t AS LONG, r AS LONG, b AS LONG)
    DIM i AS LONG
    DIM w AS LONG
    DIM x AS LONG
    DIM y AS LONG
    Dim fc As _UNSIGNED LONG
    Dim bc As _UNSIGNED LONG
    w = 1 + r - l ' calculate width
    IF w > 0 AND t <= b THEN ' only proceed is width is > 0 and height is > 0
      ' Save some stuff
      fc = _DEFAULTCOLOR
      bc = _BACKGROUNDCOLOR
      x = POS(0)
      y = CSRLIN
      COLOR Black, Black ' lights out
      FOR i = t TO b
        LOCATE i, l: PRINT SPACE$(w); ' fill with SPACE
      NEXT
      ' Restore saved stuff
      COLOR fc, bc
      LOCATE y, x
    END IF
  END SUB

  ' Initializes the ANSI legacy color LUT
  SUB InitializeANSIColorLUT
    SHARED ANSIColorLUT() AS _UNSIGNED LONG
    DIM c AS LONG
    DIM i AS LONG
    DIM r AS LONG
    DIM g AS LONG
    DIM b AS LONG
    ' The first 16 are the standard 16 ANSI colors (VGA style)
    ANSIColorLUT(0) = Black ' exact match
    ANSIColorLUT(1) = _RGB32(170, 0, 0) '  1 red
    ANSIColorLUT(2) = _RGB32(0, 170, 0) '  2 green
    ANSIColorLUT(3) = _RGB32(170, 85, 0) '  3 yellow (not really yellow; oh well)
    ANSIColorLUT(4) = _RGB32(0, 0, 170) '  4 blue
    ANSIColorLUT(5) = _RGB32(170, 0, 170) '  5 magenta
    ANSIColorLUT(6) = _RGB32(0, 170, 170) '  6 cyan
    ANSIColorLUT(7) = DarkGray ' white (well VGA defines this as (170, 170, 170); darkgray is (169, 169, 169); so we are super close)
    ANSIColorLUT(8) = _RGB32(85, 85, 85) '  8 grey
    ANSIColorLUT(9) = _RGB32(255, 85, 85) '  9 bright red
    ANSIColorLUT(10) = _RGB32(85, 255, 85) ' 10 bright green
    ANSIColorLUT(11) = _RGB32(255, 255, 85) ' 11 bright yellow
    ANSIColorLUT(12) = _RGB32(85, 85, 255) ' 12 bright blue
    ANSIColorLUT(13) = _RGB32(255, 85, 255) ' 13 bright magenta
    ANSIColorLUT(14) = _RGB32(85, 255, 255) ' 14 bright cyan
    ANSIColorLUT(15) = White ' exact match
    ' The next 216 colors (16-231) are formed by a 3bpc RGB value offset by 16, packed into a single value
    FOR c = 16 TO 231
      i = ((c - 16) \ 36) MOD 6
      IF i = 0 THEN r = 0 ELSE r = (14135 + 10280 * i) \ 256
      i = ((c - 16) \ 6) MOD 6
      IF i = 0 THEN g = 0 ELSE g = (14135 + 10280 * i) \ 256
      i = ((c - 16) \ 1) MOD 6
      IF i = 0 THEN b = 0 ELSE b = (14135 + 10280 * i) \ 256
      ANSIColorLUT(c) = _RGB32(r, g, b)
    NEXT
    ' The final 24 colors (232-255) are grayscale starting from a shade slighly lighter than black, ranging up to shade slightly darker than white
    FOR c = 232 TO 255
      g = (2056 + 2570 * (c - 232)) \ 256
      ANSIColorLUT(c) = _RGB32(g, g, g)
    Next
  END SUB

$END IF