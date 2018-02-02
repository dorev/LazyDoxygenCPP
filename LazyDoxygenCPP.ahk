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
		
		; In case no end of declaration is detected after 10 lines
		if(downCount > 10)
		{
			MsgBox, 48,LazyDoxygenCPP, No end of declaration detected, validate presence of `; or {
			Loop
			{
				Send {Up}
				downCount--
			} until downCount = 0
			
			return
		}
		
	} until (InStr(declarationString,";") || InStr(declarationString,"{"))
	
	Loop
	{
		Send {Up}
		downCount--
	} until downCount = 0
}

declarationString := Trim(RegExReplace(declarationString, "[\s\t]+", " "))


; Identify delimiters
;------------------------------------------------------------------------------
openingParenPos := InStr(declarationString, "(")

closingParenCount := 0
RegExReplace(declarationString,"\)",")", closingParenCount)
closingParenPos := InStr(declarationString, ")", false, 1, closingParenCount)

typeAndNameString := SubStr(declarationString,1,openingParenPos-1)
parametersString  := SubStr(declarationString,openingParenPos+1,closingParenPos-openingParenPos-1)

; Detect function declaration end position (in case of const function)
;------------------------------------------------------------------------------
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
isConstString := Trim(SubStr(declarationString, closingParenPos + 1, funcEndPos-closingParenPos-1))

if(isConstString = "const")
{
	isConst := 1
}


; Detect template
;------------------------------------------------------------------------------
isTemplate := 0
if(InStr(declarationString,"<") != 0)
{
	; Identify delimiters
	templateOpeningPos := InStr(declarationString,"<")
	
	; In the case there is more than one embedded template
	greaterThanSignCount := 0
	RegExReplace(declarationString,">",">", greaterThanSignCount)
	templateClosingPos := InStr(declarationString, ">", false, 1, greaterThanSignCount)
	
	templateString := Trim(SubStr(declarationString,templateOpeningPos+1, templateClosingPos-templateOpeningPos-1))
	isTemplate := 1
	
	typeAndNameString := Trim(SubStr(typeAndNameString,templateClosingPos+1))
}


; Type and name parsing
;------------------------------------------------------------------------------
typeAndNameArray  := StrSplit(typeAndNameString,A_Space)
parametersArray   := StrSplit(parametersString,",")
functionName   := typeAndNameArray[typeAndNameArray.MaxIndex()]
functionReturn := ""
isVirtual      := 0
isStatic       := 0

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
	
	; Detect C++ 2005 callback, check if last param char is ")"
	if(lastTempStringChar = ")")
	{	
		; Identify delimiters
		callbackNameOpeningParenPos  := InStr(tempString,"(")
		callbackNameClosingParenPos  := InStr(tempString,")")
		callbackParamOpeningParenPos := InStr(tempString,"(", false, 1, 2)
		callbackParamClosingParenPos := InStr(tempString,")", false, 1, 2)
		
		; Retrieve elements
		callbackReturn := Trim(SubStr(tempString, 1, callbackNameOpeningParenPos-1))
		callbackName   := Trim(SubStr(tempString, callbackNameOpeningParenPos+1, callbackNameClosingParenPos-callbackNameOpeningParenPos-1))
		callbackName   := Trim(SubStr(callbackName,InStr(callbackName,"*")+1))
		callbackParams := Trim(SubStr(tempString, callbackParamOpeningParenPos+1, callbackParamClosingParenPos-callbackParamOpeningParenPos-1))

		; Fill array
		parameterNamesArray.Push(callbackName)
		parameterTypesArray.Push(callbackReturn . "(" . callbackParams . ")")
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
			   
if(isTemplate)
{
	doxygenString := doxygenString . " (template)"
}			   

doxygenString := doxygenString . "`n/// `n"

Loop % parameterNamesArray.MaxIndex()
{
	doxygenString := doxygenString . "/// @param " . parameterNamesArray[a_index] . " - `n"
	lineCount++
}				

if(functionReturn != "void")
{
	doxygenString := doxygenString . "/// @return " . functionReturn . " - `n"
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
	MsgBox, 1,LazyDoxygenCPP, %doxygenString%
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