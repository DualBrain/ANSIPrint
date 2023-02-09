$IF BASE64_BAS = UNDEFINED THEN

  $LET BASE64_BAS = TRUE

  ' Convert a normal string to a base64 string
  FUNCTION EncodeBase64$ (s AS STRING)

    CONST BASE64_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    DIM buffer AS STRING 
    DIM result AS STRING 
    DIM i AS _UNSIGNED LONG

    FOR i = 1 TO LEN(s)
      buffer = buffer + CHR$(ASC(s, i))
      IF LEN(buffer) = 3 THEN
        result = result + CHR$(ASC(BASE64_CHARACTERS, 1 + (_SHR(ASC(buffer, 1), 2))))
        result = result + CHR$(ASC(BASE64_CHARACTERS, 1 + (_SHL((ASC(buffer, 1) AND 3), 4) OR _SHR(ASC(buffer, 2), 4))))
        result = result + CHR$(ASC(BASE64_CHARACTERS, 1 + (_SHL((ASC(buffer, 2) AND 15), 2) OR _SHR(ASC(buffer, 3), 6))))
        result = result + CHR$(ASC(BASE64_CHARACTERS, 1 + (ASC(buffer, 3) AND 63)))
        buffer = NULLSTRING
      END IF
    NEXT

    ' Add padding
    IF LEN(buffer) > 0 THEN
      result = result + CHR$(ASC(BASE64_CHARACTERS, 1 + (_SHR(ASC(buffer, 1), 2))))
      IF LEN(buffer) = 1 THEN
        result = result + CHR$(ASC(BASE64_CHARACTERS, 1 + (_SHL(ASC(buffer, 1) AND 3, 4))))
        result = result + "=="
      ELSE
        result = result + CHR$(ASC(BASE64_CHARACTERS, 1 + (_SHL((ASC(buffer, 1) AND 3), 4) OR _SHR(ASC(buffer, 2), 4))))
        result = result + CHR$(ASC(BASE64_CHARACTERS, 1 + (_SHL(ASC(buffer, 2) AND 15, 2))))
        result = result + "="
      END IF
    END IF

    EncodeBase64 = result

  END FUNCTION

  ' Convert a base64 string to a normal string
  FUNCTION DecodeBase64$ (s AS STRING)

    CONST BASE64_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    DIM buffer AS STRING
    DIM result AS STRING
    DIM i AS _UNSIGNED LONG
    DIM char1 AS _UNSIGNED _BYTE
    DIM char2 AS _UNSIGNED _BYTE
    DIM char3 AS _UNSIGNED _BYTE
    DIM char4 AS _UNSIGNED _BYTE

    FOR i = 1 TO LEN(s) STEP 4
      char1 = INSTR(BASE64_CHARACTERS, CHR$(ASC(s, i))) - 1
      char2 = INSTR(BASE64_CHARACTERS, CHR$(ASC(s, i + 1))) - 1
      char3 = INSTR(BASE64_CHARACTERS, CHR$(ASC(s, i + 2))) - 1
      char4 = INSTR(BASE64_CHARACTERS, CHR$(ASC(s, i + 3))) - 1
      buffer = CHR$(_SHL(char1, 2) OR _SHR(char2, 4)) + CHR$(_SHL(char2 AND 15, 4) OR _SHR(char3, 2)) + CHR$(_SHL(char3 AND 3, 6) OR char4)
      result = result + buffer
    Next

    ' Remove padding
    IF RIGHT$(s, 2) = "==" THEN
      result = LEFT$(result, LEN(result) - 2)
    ELSEIF RIGHT$(s, 1) = "=" THEN
      result = LEFT$(result, LEN(result) - 1)
    END IF

    DecodeBase64 = result

  END FUNCTION

  ' Loads a binary file encoded with Bin2Data
  ' Usage:
  '   1. Encode the binary file with Bin2Data
  '   2. Include the file or it's contents
  '   3. Load the file like so:
  '       Restore label_generated_by_bin2data
  '       Dim buffer As String
  '       buffer = LoadResource   ' buffer will now hold the contents of the file
  FUNCTION LoadResource$

    DIM ogSize AS _UNSIGNED LONG
    DIM resSize AS _UNSIGNED LONG
    DIM isCompressed AS _BYTE

    READ ogSize, resSize, isCompressed ' read the header

    DIM buffer AS STRING
    DIM result AS STRING

    ' Read the whole resource data
    DO WHILE LEN(result) < resSize
      READ buffer
      result = result + buffer
    LOOP

    ' Decode the data
    buffer = DecodeBase64(result)

    ' Expand the data if needed
    IF isCompressed THEN
      result = _INFLATE$(buffer, ogSize)
    ELSE
      result = buffer
    END IF

    LoadResource = result

  END FUNCTION

$END IF