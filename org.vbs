' Author:kaplanke@gmail.com
'
' Royalty-free content.
' Author does not assume responsibility nor accept any liability arising from any kind of usage.

Option Explicit

' Search  domain.
Const strBase = "<LDAP://DC=internal,DC=example,DC=com>"
' Comma delimited list of attribute values to retrieve.
Const strAttributes = "distinguishedName,directReports,displayName,title,sAMAccountName,thumbNailPhoto,mobile,mail"
' Head of org query
Const strTopQuery = "(sAMAccountName=theManager)"
' Output folder
Const strOutFolder = ""
' Output file
Const strOutputFile = "org.json"
' Bmp folder
Const strBmpFolder = "faces/"

'Args
Dim boolProcessImages
boolProcessImages = Len(WScript.Arguments.Named.Item("images"))>0

'Vars
Dim orgStr, adoCommand, adoConnection, rs, objFSO, objStream
Dim strDN, strReport, strFilter, strQuery, title, mobile, mail
Dim byteArray2Text, thumbnailpath

' Use ADO to search Active Directory.
Set adoCommand = CreateObject("ADODB.Command")
Set adoConnection = CreateObject("ADODB.Connection")
adoConnection.Provider = "ADsDSOObject"
adoConnection.Open "Active Directory Provider"
Set adoCommand.ActiveConnection = adoConnection
adoCommand.Properties("Page Size") = 1000
adoCommand.Properties("Timeout") = 300
adoCommand.Properties("Cache Results") = False

' File system ops
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Document organization.
Call Reports(Null)

' Clean up.
adoConnection.Close

' Write to file
Set objStream = CreateObject("ADODB.Stream")
objStream.CharSet = "utf-8"
objStream.Open
objStream.writetext Replace(Left(orgStr, Len(orgStr)-1),",]","]")
objStream.SaveToFile strOutFolder + strOutputFile, 2
objStream.close

' Recursive subroutine to traverse organization.
Sub Reports(ByVal strParentQuery)

	Wscript.Echo "Processing " + strParentQuery
    If (IsNull(strParentQuery)) Then
        strFilter = strTopQuery
    Else
		adoCommand.CommandText = strBase & ";(distinguishedName="+ strParentQuery +");" & strAttributes & ";subtree"
		Dim adoRecordset2
		Set adoRecordset2 = adoCommand.Execute
		if adoRecordset2.EOF then
			exit sub
		end if
		orgStr = orgStr + processRecordStart(adoRecordset2)
        adoRecordset2.Close
        strFilter = "(manager=" & strParentQuery & ")"
    End If

    strQuery = strBase & ";" & strFilter & ";" & strAttributes & ";subtree"
    adoCommand.CommandText = strQuery
	Dim adoRecordset
    Set adoRecordset = adoCommand.Execute

    Do Until adoRecordset.EOF
        strDN = adoRecordset.Fields("distinguishedName").Value
		If InStr(strDN, "Disabled Users") = 0 then
			orgStr = orgStr + processRecordStart(adoRecordset)
			Dim arrReports
			arrReports = adoRecordset.Fields("directReports").Value
			If Not IsNull(arrReports) Then
				For Each strReport In arrReports
					If INSTR(strReport, "Disabled Users") = 0 Then
						Call Reports(strReport)
					End If
				Next
			End If
			orgStr = orgStr + processRecordEnd
		End If
        adoRecordset.MoveNext
    Loop
    adoRecordset.Close
	
	If Not IsNull(strParentQuery) Then
		orgStr = orgStr + processRecordEnd
	End If
	
End Sub

' Json object start for record
Function processRecordStart (ByVal rs)
	If boolProcessImages Then
		PreparePhoto rs.Fields("samaccountname").Value, rs.Fields("thumbNailPhoto").Value
	End If
	title = IIf(isnull(rs.Fields("title").value),"N/A",rs.Fields("title").value)
	mobile = IIf(isnull(rs.Fields("mobile").value),"N/A",rs.Fields("mobile").value)
	mail = IIf(isnull(rs.Fields("mail").value),"N/A",rs.Fields("mail").value)
	processRecordStart = "{""name"": """ + rs.Fields("displayName").value + _
							""", ""title"": """ + title +  _
							""", ""mobile"": """ + Replace(mobile,"""","") + _
							""", ""mail"": """ + Replace(mail,"""","") +  _
							""", ""image"": """ + strBmpFolder + rs.Fields("samaccountname").value + ".bmp"", ""children"": ["
End Function

' Json object end for record
Function processRecordEnd
	processRecordEnd = "]},"
End Function

' Get photo from AD
Sub PreparePhoto (ByVal samaccountname, ByVal bytes)
	  thumbnailpath = strOutFolder + strBmpFolder  & samaccountname & ".bmp"
	  If Len(bytes) > 0 Then
		Set rs = CreateObject("ADODB.Recordset")
		Err.Clear 
		rs.Fields.Append "temp", 201, LenB(bytes)
		If Err.Number <> 0 Then
			Exit Sub
		End if
		rs.Open
		rs.AddNew
		rs("temp").AppendChunk bytes
		rs.Update
		byteArray2Text = rs("temp")
		rs.Close
		Dim bmpFile
		Set bmpFile = objFSO.CreateTextFile(thumbnailpath, True)
		bmpFile.Write (byteArray2Text)
		bmpFile.Close
	  Else 
		' try https://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=xxx@example.com 
	  End If 
End Sub 

' IIf
Function IIf( expr, truepart, falsepart )
   IIf = falsepart
   If expr Then IIf = truepart
End Function