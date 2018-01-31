#NoEnv  						; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  				; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  	; Ensures a consistent starting directory.

; # Windows key
; + Shift key
; ^ Ctrl key
; ! Alt key     
^#d::


; Clear clipboard
clipboard=

; Select text and send Ctrl-C
Send {ShiftDown}{End}{ShiftUp}^c{Home}


; Wait for clipboard to fill and store value
ClipWait
declarationString := clipboard

; If declaration happens on multiple lines, look for semicolon (;)
if(InStr(declarationString,";") = 0 || InStr(declarationString,"{") = 0)
{	
	downCount = 0
	Loop 
	{
		downCount++
		clipboard=
		Send {Down}{Home}{ShiftDown}{End}{ShiftUp}^c{Home}
		ClipWait
		declarationString := declarationString . clipboard
	} until (InStr(declarationString,";") ||InStr(declarationString,"{"))
	
	Loop
	{
		Send {Up}
		downCount--
	} until downCount = 0
}


; Remove tabs and multiple spaces
declarationString := RegExReplace(declarationString, "[\s\t]+", " ") 


; Detect opening parenthesis position
openingParenPos := InStr(declarationString, "(")


; Detect last closing parenthesis
closingParenCount := 0
RegExReplace(declarationString,"\)",")",closingParenCount)
closingParenPos := InStr(declarationString, ")",false,1,closingParenCount)


; Detect function declaration end position (in case of const function)
funcEndPos := 0
if(InStr(declarationString, ";") = 0)
{
	funcEndPos := InStr(declarationString,"{")
}
else
{
	funcEndPos := InStr(declarationString, ";")
}

;---- TO COMPLETE -------------------------------------------
; Detect const function


; Detect template
templateString := ""
if(InStr(declarationString,"<") != 0)
{
}
;------------------------------------------------------------


; Split declaration in section and store elements in arrays
typeAndNameString := SubStr(declarationString,1,openingParenPos-1)
typeAndNameArray  := StrSplit(typeAndNameString,A_Space)
parametersString  := SubStr(declarationString,openingParenPos+1,closingParenPos-openingParenPos-1)
parametersArray   := StrSplit(parametersString,",")


Sleep, 10

debugmessage3 := "typeAndNameString = " . typeAndNameString
					. "`nparametersString = " . parametersString
;MsgBox % debugmessage3


; typeAndNameArray elements variables
functionName   := typeAndNameArray[typeAndNameArray.MaxIndex()]
functionReturn := ""
isVirtual      := 0
isStatic       := 0
;-- TO COMPLETE : add templates


; Detect and parse elements of typeAndNameArray
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
		; ignore element
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

parameterNamesArray := []
parameterTypesArray := []

; Detect and parse elements of parametersArray
Loop % parametersArray.MaxIndex()
{
	tempString := Trim(parametersArray[a_index])
	spacesCount := 0
	RegExReplace(tempString,"\s"," ",spacesCount)
	
	;debugMessage := "Spaces count = " . spacesCount . "`ntempString = " . tempString . "`nparametersArray[" . a_index . "] = " . parametersArray[a_index]
	;MsgBox % debugMessage
	
	paramNamePos := InStr(tempString, A_Space,false,1,spacesCount)+1
	
	
	;debugMessage2 := "name pushed = " . SubStr(tempString,paramNamePos) . "`ntype pushed = " . SubStr(tempString,1,paramNamePos-1)
	;MsgBox % debugMessage2
	
	parameterNamesArray.Push(SubStr(tempString,paramNamePos))
	parameterTypesArray.Push(SubStr(tempString,1,paramNamePos-1))	
}



; Write Doxygen string
lineCount := 0
doxygenString := "`n///"
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
return






