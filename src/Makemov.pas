{----------------------------------------------------------------------------}
{                                Motion Picture                              }
{          --------------------------------------------------------          }
{             * Make Movie Program * version 1.0a * 05-10-1999 *             }
{          --------------------------------------------------------          }
{                   Dale Nunns                                               }
{                   dale.nunns@pmail.net  										     }
{                   http://come.to/Chippy/                                   }
{----------------------------------------------------------------------------}

Program MotionPictureMovieMaker;
Uses fdelay,Crt,Dos,Graphics;
var
    MovieListFileName,MovieSoundFileName,MovieDestFileName : String;
    MovieListFileID : text;
    ParamPos,FrameCapture : integer;
    NumFrames,MovieFrameFile : String;
Procedure MakeMovHelp;
Begin
clrscr;
Writeln('M O T I O N   P I C T U R E                                       Version 1.0a');
Writeln;
Writeln('By Dale Nunns');
Writeln(' Dale.Nunns@pmail.net');
Writeln(' http://come.to/chippy');
Writeln('-------------------------------------------------------------------------------');
Writeln('Creates a movie from a set of PCX files and a WAVE file as sound. The PCX files');
Writeln('must be 320x200 256 colour.');
Writeln;
Writeln('Makemov [-l; -s; -d] ');
Writeln(' eg. Makemov -l matrix.lst -s matrix.wav -d matrix.mot');
Writeln;
Writeln('  -l %ListFileName%  : is the list file contain the list of frames that must');
Writeln('                       be loaded. <REQUIRED>');
{Writeln('  -s %SoundFileName% : is the sound file that will play in the movie, this file');
Writeln('                       must be a WAVE file. <NOT REQUIRED>');}
Writeln('  -d %DestFileName%  : is the destination filename that the movie will be saved');
Writeln('                       as. <REQUIRED>');
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

Begin
  If ParamCount>0 then
   Begin
    For ParamPos := 1 to 6 do
     Begin
		if ParamStr(ParamPos) = '-l' then MovieListFileName := ParamStr(ParamPos + 1)
       else
		  if ParamStr(ParamPos) = '-L' then MovieListFileName := ParamStr(ParamPos + 1);
      if ParamStr(ParamPos) = '-d' then MovieDestFileName := ParamStr(ParamPos + 1)
       else
    	  if ParamStr(ParamPos) = '-D' then MovieDestFileName := ParamStr(ParamPos + 1);
		if ParamStr(ParamPos) = '-s' then MovieSoundFileName := ParamStr(ParamPos + 1)
       else
		  if ParamStr(ParamPos) = '-S' then MovieSoundFileName := ParamStr(ParamPos + 1);
     End;
    if length(MovieListFileName) = 0 then MakeMovHelp;
    if length(MovieDestFileName) = 0 then MakeMovHelp;

    if NOT FileExist(MovieListFileName) then
	  begin
      Writeln('Error File ' + MovieListFileName + ' does not exist.');
      Halt(0);
	  end;
    if length(MovieSoundFileName) <> 0 then
    begin
     if NOT FileExist(MovieSoundFileName) then
      begin
       Writeln('Error File ' + MovieSoundFileName + ' does not exist.');
       Halt(0);
	   end;
    end;
   end
   else MakeMovHelp;
clrscr;

Assign(MovieListFileID,MovieListFileName);
Reset(MovieListFileID);
Readln(MovieListFileID,NumFrames);

Screen13;
NewMovie(MovieDestFileName,Valconv(NumFrames));
For FrameCapture := 1 to Valconv(NumFrames) do
 begin
  Readln(MovieListFileID,MovieFrameFile);
  if NOT Load_Pcx(MovieFrameFile) then
   begin
    Screen3;
    Writeln('Error PCX file ' + MovieFrameFile + ' Not A Valid 256 Colour PCX.');
    CloseMovie;
    Close(MovieListFileID);
    Halt(0);
   end;
  SaveMovieFrame(FrameCapture);
 end;
CloseMovie;
Close(MovieListFileID);
Screen3;
end.


