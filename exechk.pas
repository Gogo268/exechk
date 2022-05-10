program Fantastic; {The program isn't fantastic but whatever...}
uses WinCrt; {To compile under DOS, replace WinCrt with Crt, Dos and it should work fine...}
Type ExeHeaderType=Record
			ExeFileId	: Word;
                        BytesAtLastPage	: Word;
                        NumberOfPages	: Word;
                        RelocEntries	: Word;
                        SizeOfHeader	: Word;
                        MinParagraphs	: Word;
                        MaxParagraphs	: Word;
                        StackSegment	: Word;
                        StackPointer	: Word;
                        CheckSum	: Word;
                        InitialIP	: Word;
                        CodeSegment	: Word;
                        ByteOffset	: Word;
                        OverlayNumber	: Word;
End;
Var
	ExeFileName:	String;
        ExeFile:   	File;
        RecordBuffer:	Array[1..512] of Byte;
        WordBuffer:	Array[1..256] of Word absolute RecordBuffer;
        ExeHeader:	ExeHeaderType;
Function HexW(Hw:LongInt): String;
Const HexStr='0123456789ABCDEF';
Var A,B,C,D,X:String[1];
	Begin
	 X:='';
         If Hw > $FFFF Then X:=Copy(HexStr, ((Hw and $F0000) shr 16)+1,1);
         A:=Copy(HexStr, ((Hw and $F000) shr 12)+1,1);
         B:=Copy(HexStr, ((Hw and $0F00) shr 8)+1,1);
         C:=Copy(HexStr, ((Hw and $00F0) shr 4)+1,1);
         D:=Copy(HexStr, (Hw and $000F)+1,1);
         HexW:=X+A+B+C+D;
        End;
Procedure AnalOut (S:String;D:LongInt);
	Begin
         Writeln(S,HexW(D):14,D:12);
        End;
Procedure AnalOutW (S:String;SS,D:Word);
	Begin
         Writeln(S,(HexW(SS)+':'+HexW(D)):14,D:12);
        End;
Procedure AnalyzeExeFile;
	Var
        ExeSize,MinLoad,X,Y:LongInt;
        CalcSum,I,J,K:Word;
        Ch:Char;
        Begin
        With ExeHeader Do
        Begin
        ExeSize:=Round(((NumberOfPages-1)*512.0)+BytesAtLastPage);
        MinLoad:=(MinParagraphs*16)+ExeSize-(SizeOfHeader*16);
        Writeln(ExeFileName:25,'  (hex)		(dec)');
        Writeln;
	{Output of the EXE information}
        AnalOut('.EXE size (bytes)	', ExeSize);
        AnalOut('Minimum load size (bytes)	',MinLoad);
        AnalOut('Overlay Number	',OverlayNumber and $00FF);
        AnalOutW('Initial CS:IP	',CodeSegment, InitialIP);
        AnalOutW('Initial SS:SP	',StackSegment, StackPointer);
        AnalOut('Minimum allocation (para)	',MinParagraphs);
        AnalOut('Maximum allocation (para)	',MaxParagraphs);
        AnalOut('Header size (para)	',SizeOfHeader);
        AnalOut('Relocation table offset	',ByteOffset);
        AnalOut('Relocation entries	',RelocEntries);
        Writeln;
        AnalOut('Checksum (header)	',CheckSum);
        CalcSum:=0;
        Checksum:=Checksum+$FFFF;
        Reset(ExeFile,512);
        For I:=1 to NumberOfPages do
        Begin
        	FillChar (RecordBuffer, 512, 0);
                BlockRead (ExeFile,RecordBuffer,1,K);
                For J:=1 to 256 do
                Begin
                	CalcSum:=Calcsum+WordBuffer[J];
                        CheckSum:=CheckSum-WordBuffer[J];
                End;
        End;
        Close (ExeFile);
        AnalOut('CheckSum (calculated)		',CalcSum);
        AnalOut('Checksum should be		',CheckSum);
        Writeln;
	{Some kind of checksum checker that should hopefully work correctly.}
        If CalcSum=$FFFF Then
        	Writeln(ExeFileName, ' has correct checksum in header.') Else
        Begin
        Write ('May I fix it? (Y/N) :');
        Ch:=ReadKey;
        Writeln(Ch);
        If Ch in ['Y','y'] Then
        	Begin
                 Reset (ExeFile,$1B);
		 BlockWrite (ExeFile,ExeHeader,1); {this is supposed to restore the regular EXE header, however this doesn't check jackshit and just does whatever it feels like, doesn't seem to affect generic Win32 applications at least..}
                 Close(ExeFile);
                 Writeln('exechk: ', ExefileName, ' has been fixed');
        		End;
        	End;
	End;
End;
Begin
	Writeln('Pure masochistic EXE Header and Checksum Utility');
        Writeln('Copyright (C) 2022 by re9177, Made in Yugoslavia.');
        Writeln;
        If ParamCount=0 Then Writeln ('usage: exechk file') Else
        Begin
         ExeFileName:=ParamStr(1);
         If Pos('.',ExeFileName)=0 Then ExeFileName := ExeFileName+'.exe';
         Assign (ExeFile,ExeFileName);
         Reset (ExeFile,$1B);
        If IOResult=0 Then
        Begin
         BlockRead(ExeFile,ExeHeader,1);
         Close(ExeFile);
        End Else
        Begin
         Writeln('exechk: ', ExeFileName, ': File not found');
         Halt(1);
        End;
         If ExeHeader.ExeFileId=$5A4D Then AnalyzeExeFile
	 Else Writeln ('exechk: This is not an EXE file!'); {TODO: fix the fact it still reads COM files for some reason... although it might not harm them, i don't know.}
        End;
End.
