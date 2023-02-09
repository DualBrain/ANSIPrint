$IF WIN THEN
  DECLARE LIBRARY
    FUNCTION MessageBox (BYVAL ignore&, message$, title$, BYVAL type&)
  END DECLARE
$ELSE
  DECLARE LIBRARY ""
    FUNCTION MessageBox (BYVAL ignore&, message$, title$, BYVAL type&)
  END DECLARE
$END IF

result = MessageBox(0, "Hello World!", "MSGBOX Sample", 0)