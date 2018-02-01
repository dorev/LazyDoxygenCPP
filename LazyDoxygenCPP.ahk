#NoEnv  						; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  				; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  	; Ensures a consistent starting directory.

; # Windows key
; + Shift key
; ^ Ctrl key
; ! Alt key     
^#d::

; Settings
;------------------------------------------------------------------------------
skipConfirmation := 0


; Detect declaration
;------------------------------------------------------------------------------

; Clear clipboard
clipboard=

; Select text and send Ctrl-C
Send {Home}{ShiftDown}{End}{ShiftUp}^c{Home}
ClipWait
declarationString := clipboard

; Detect end of declaration
if(InStr(declarationString,";") = 0 && InStr(declarationString,"{") = 0)
{	
	downCount = 0
	Loop 
	{
		downCount++
		clipboard=
		Send {Down}{Home}{ShiftDown}{End}{ShiftUp}^c{Home}
		ClipWait
		declarationString := declarationString . clipboard
	} until (InStr(declarationString,";") || InStr(declarationString,"{"))
	
	Loop
	{
		Send {Up}
		downCount--
	} until downCount = 0
}


declarationString := RegExReplace(declarationString, "[\s\t]+", " ") 
declarationString := Trim(declarationString)


; Detect delimiters
;------------------------------------------------------------------------------
openingParenPos := InStr(declarationString, "(")

closingParenCount := 0
RegExReplace(declarationString,"\)",")", closingParenCount)
closingParenPos := InStr(declarationString, ")", false, 1, closingParenCount)


; Detect function declaration end position (in case of const function)
;------------------------------------------------------------------------------
funcEndPos := 0
if(InStr(declarationString, ";") = 0)
{
	funcEndPos := InStr(declarationString, "{")
}
else
{
	funcEndPos := InStr(declarationString, ";")
}


; Detect const function
;------------------------------------------------------------------------------
isConst := 0
isConstString := SubStr(declarationString, closingParenPos + 1, funcEndPos-closingParenPos-1)
isConstString := Trim(isConstString)

if(isConstString = "const")
{
	isConst := 1
}


; Detect template TO COMPLETE
;------------------------------------------------------------------------------
;templateString := ""
;if(InStr(declarationString,"<") != 0)
;{
;}


; Parse declaration
;------------------------------------------------------------------------------
typeAndNameString := SubStr(declarationString,1,openingParenPos-1)
typeAndNameArray  := StrSplit(typeAndNameString,A_Space)
parametersString  := SubStr(declarationString,openingParenPos+1,closingParenPos-openingParenPos-1)
parametersArray   := StrSplit(parametersString,",")


; Type and name parsing
;------------------------------------------------------------------------------
functionName   := typeAndNameArray[typeAndNameArray.MaxIndex()]
functionReturn := ""
isVirtual      := 0
isStatic       := 0
;-- TO COMPLETE : add templates parameters

Loop % typeAndNameArray.MaxIndex()-1
{
	if(typeAndNameArray[a_index] = "virtual")
	{
		isVirtual = 1
	} 
	else if(typeAndNameArray[a_index] = "static")
	{	
		isStatic = 1
	}
	else if(typeAndNameArray[a_index] = "extern" || typeAndNameArray[a_index] = "inline")
	{
		; Ignore element
	}
	else
	{
		if(StrLen(functionReturn) > 1) 
		{
			functionReturn := functionReturn . " " 
		}
		functionReturn := functionReturn . typeAndNameArray[a_index]
	}
}


; Parameters parsing
;------------------------------------------------------------------------------
parameterNamesArray := []
parameterTypesArray := []

; Detect and parse elements of parametersArray
Loop % parametersArray.MaxIndex()
{
	tempString := Trim(parametersArray[a_index])
	lastTempStringChar := ""
	StringRight, lastTempStringChar, tempString, 1
	
	; Detect callback, check if last param char is ")"
	if(lastTempStringChar = ")")
	{
		; Identify delimiters
		;callbackNameOpeningParenPos
		;callbackNameClosingParenPos
		;callbackParamOpeningParenPos
		;callbackParamClosingParenPos
	}
	else
	{
		; Find last element of parameter (name)
		spacesCount := 0
		RegExReplace(tempString,"\s"," ",spacesCount)
		paramNamePos := InStr(tempString, A_Space,false,1,spacesCount)+1
		
		; Fill array
		parameterNamesArray.Push(SubStr(tempString,paramNamePos))
		parameterTypesArray.Push(SubStr(tempString,1,paramNamePos-1))	
	}
}


; Write Doxygen string
;------------------------------------------------------------------------------
lineCount := 0
doxygenString := "///"
			   . "`n/// " . functionName
			   . "`n/// `n"

Loop % parameterNamesArray.MaxIndex()
{
	doxygenString := doxygenString . "/// @param " . parameterNamesArray[a_index] . " - `n"
	lineCount++
}				

if(functionReturn != "void")
{
	doxygenString := doxygenString . "/// @returns `n"
	lineCount++
}

doxygenString := doxygenString . "///`n"


; Confirmation and printing
;------------------------------------------------------------------------------
if(skipConfirmation)
{
	Send % doxygenString
	Loop % lineCount + 2
	{
		Send, {Up}
	}	
	Send, {End}
}
else
{
	MsgBox, 1,Lazy Doxygen, %doxygenString%
	IfMsgBox, OK
	{
		Send % doxygenString
		Loop % lineCount + 2
		{
			Send, {Up}
		}	
		Send, {End}
	}
	IfMsgBox, Cancel
	{
	}
}

Return