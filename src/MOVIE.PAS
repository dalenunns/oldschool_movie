{----------------------------------------------------------------------------}
{                                Motion Picture                              }
{          --------------------------------------------------------          }
{               * Movie Program * version 1.0a * 05-10-1999 *                }
{          --------------------------------------------------------          }
{                   Dale Nunns                                               }
{                   dale.nunns@pmail.net  										     }
{                   http://come.to/Chippy/                                   }
{----------------------------------------------------------------------------}

Program MotionPicture;
uses fdelay,crt,dos,graphics;
var Error_Found : boolean;
    I : integer;
Procedure ChkPass;
 begin
  textColor(7);
  write('[   ');
  textColor(2);
  write('FOUND');
  textColor(7);
  writeln('   ]');
 end;
Procedure ChkFail;
 begin
  textColor(7);
  write('[ ');
  textColor(4 + 128);
  write('NOT FOUND');
  textColor(7);
  writeln(' ]');
 end;

Procedure CheckSystem;
begin
Write(' Checking For 80286 or higher processor..........                 ');
if CpuType >= 1 then ChkPass else ChkFail;
Write(' Checking For ColorVGA...........................                 ');
if VideoCard = VGAColor then ChkPass else ChkFail;
{Write(' Checking For SoundCard..........................                 ');
if Init_Sound then ChkPass else ChkFail;}
Write(' Checking For Windows............................                 ');
if Chk4Win then ChkPass else ChkFail;
end;

Procedure Intro;
begin
clrscr;
Writeln('M O T I O N   P I C T U R E                                       Version 1.0a');
Writeln;
Writeln('By Dale Nunns');
Writeln(' Dale.Nunns@pmail.net');
Writeln(' http://come.to/chippy');
Writeln;
Writeln;
Writeln('Checking System Requirments:');
Writeln('-------------------------------------------------------------------------------');
Writeln;
CheckSystem;
writeln;
textColor(7 + 128);
Writeln('                             *Press Any Key To Continue*                       ');
TextColor(7);
repeat until keypressed;
Clrscr;
Error_Found := False;

if CpuType >= 1 then
 else
 begin
  Writeln('Error 80286 Or higher Processor Not Detected.. It is required for this program.');
  Error_Found := True;
 end;

if VideoCard <> VGAColor then
 Begin
  Writeln('Error VGA Colour Graphics Adapter Not detected.. It is required for this program.');
  Error_Found := True;
 End;
if Error_Found then Halt(0);
end;

Procedure MovieCmdHelp;
Begin
clrscr;
Writeln('M O T I O N   P I C T U R E                                       Version 1.0a');
Writeln;
Writeln('By Dale Nunns');
Writeln(' Dale.Nunns@pmail.net');
Writeln(' http://come.to/chippy');
Writeln('-------------------------------------------------------------------------------');
Writeln('Plays a 320x200 256 colour movie. Created using MakeMov.');
Writeln;
Writeln('Movie %MovieFileName% ');
Writeln(' eg. Movie matrix.mot');
Writeln;
Writeln('  %MovieFileName%    : is the filename and path of the movie that you want to');
Writeln('                       play. <REQUIRED>');
Halt(0);
End;

Function FileExist(FileName : String) : Boolean;
Var
  DirInfo : SearchRec;
begin
  FindFirst(FileName, AnyFile, DirInfo);
  if (DosError = 0) then
    FileExist := True
  else
    FileExist := False;
end;

Var MovieFileName: String;
    CheckDisabled : Boolean;
begin


  If ParamCount>0 then
    if ParamStr(1) = '-n' then
     begin
       CheckDisabled := True;
       MovieFileName := ParamStr(2);
     end
    else
     if ParamStr(1) = '-N' then
      Begin
	    CheckDisabled := True;
       MovieFileName := ParamStr(2);
      end
      else
       if ParamStr(2) = '-N' then
        Begin
	      CheckDisabled := True;
         MovieFileName := ParamStr(1);
        end
        else
         if ParamStr(2) = '-N' then
          Begin
	        CheckDisabled := True;
           MovieFileName := ParamStr(1);
          end

    else MovieFileName := ParamStr(1);

    if NOT FileExist(MovieFileName) then
     begin
     if NOT (ParamCount >0) then MovieCmdHelp;
     Writeln('Error. The file ' + MovieFileName + ' does not exist.');
     halt(0);
     end;

if NOT (ParamCount >0) then MovieCmdHelp;
if NOT CheckDisabled then Intro;
Screen13;

repeat
OpenMovie(MovieFileName);
For I := 1 to GetNumFrames do
Begin
 LoadNextFrame;
 delay(100);
end;
CloseMovie;
until keypressed;

Screen3
end.
