{----------------------------------------------------------------------------}
{                                Motion Picture                              }
{          --------------------------------------------------------          }
{               * Graphics Unit * version 1.0a * 05-10-1999 *                }
{       Some code for this unit was taken from SWAG the and many wepages.    }
{         The PCX loader was written by Norman Yen And modified by me.       }
{               The Text command was written by Joachim Henke.               }
{
{                                                                            }
{          --------------------------------------------------------          }
{                   Dale Nunns                                               }
{                   dale.nunns@pmail.net  										     }
{                   http://come.to/Chippy/                                   }
{----------------------------------------------------------------------------}

Unit Graphics;

Interface

CONST Screen = $a000;
type
  CardType = (none,mda,cga,egamono,egacolor,
              vgamono,vgacolor,mcgamono,mcgacolor);

Procedure Screen13;
Procedure Screen3;
Procedure Cls (ScreenAddr : word;colour : byte);
Procedure PutPixel(ScreenAddr : word;x,y : integer ; c : byte);
Function  GetPixel(ScreenAddr : word;x, y : Word) : Byte;
Procedure GetPalette(index : Byte; var r, g, b : Byte);
Procedure SetPalette(index, r, g, b : Byte);
Procedure TextOut(x,y : byte ; s : openstring ; colour,bkcolour :byte );
Procedure SaveScreenToFile(ScreenAddr : word;FileName : string);
Procedure ReadScreenFromFile(ScreenAddr : word;FileName : string);
Procedure SavePaletteFile(FileName : string);
Procedure LoadPaletteFile(FileName : string);
Procedure Box(ScreenAddr: word;x,y,x1,y1,c:integer);
Procedure SaveImage(Filename : string);
Procedure LoadImage(Filename : string);
Procedure LoadNextFrame;
Procedure SaveMovieFrame(FrameNo : integer);
Procedure OpenMovie(FileName : string);
Function GetNumFrames : integer;
Procedure NewMovie(FileName : string; NumFrames : integer);
Procedure CloseMovie;
Procedure SetVirtual;
Function  Chk4Win : Boolean;
Function StrConv(I: Longint): String;
Function ValConv(S: string): longint;
Function Load_Pcx(FileName : String) : Boolean;
Function VideoCard: CardType;
Function CpuType :Word;

Implementation

Uses Crt, Dos;
Type  Virtual = Array [1..64000] of byte;  { The size of our Virtual Screen }
      VirtPtr = ^Virtual;                  { Pointer to the virtual screen }
	   pcxheader_rec=record
       manufacturer: byte;
       version: byte;
       encoding: byte;
       bits_per_pixel: byte;
       xmin, ymin: word;
       xmax, ymax: word;
       hres: word;
       vres: word;
       palette: array [0..47] of byte;
       reserved: byte;
       colour_planes: byte;
       bytes_per_line: word;
       palette_type: word;
       filler: array [0..57] of byte;
      end;

var
      Virscr : VirtPtr;
      Vaddr,bytes,width, depth  : word;                        { The segment of our virtual screen}
      header: pcxheader_rec;
  	   palette: array [0..767] of byte;
      f,MovieID: file;
      c: byte;
      NumFrames : integer;


{
***********************
**Graphics Procedures**
***********************
}

Procedure Screen13; assembler;
{Sets the Video mode to 320x200x256c (mode13h)}
asm
   mov AX,13h
   int 10h
end;

Procedure Screen3; assembler;
{Sets the Video mode back to textmode.}
asm
   mov AX,3
   int 10h
end;

Procedure Cls (ScreenAddr : word;colour : byte);
{Clears the Screen to a specific color.}
begin;
	fillchar(mem[ScreenAddr:0],64000,colour);
end;

Procedure PutPixel(ScreenAddr : word;x,y : integer ; c : byte);
{Puts a Pixel at X,Y with C as it's colour.}
begin;
 mem[ScreenAddr:x+(y*320)]:= c;
end;

Function GetPixel(ScreenAddr : word;x, y : Word) : Byte;
{Gets the Colour of the Pixel at X,Y}
begin
  GetPixel := Mem[ScreenAddr : y * 320 + x];
end;

Procedure GetPalette(index : Byte; var r, g, b : Byte);
{Get's the RGB values for the given Index.}
begin
  Port[$3C7] := index;
  r := Port[$3C9];
  g := Port[$3C9];
  b := Port[$3C9];
end;

Procedure SetPalette(index, r, g, b : Byte);
{Set's the RGB value for the given Index.}
begin
  Port[$3C8] := index;
  Port[$3C9] := r;
  Port[$3C9] := g;
  Port[$3C9] := b;
end;

procedure TextOut(x,y : byte ; s : openstring ; colour,bkcolour :byte );
{Displays the Text at the X,Y Position with a certain colour and background Colour}
var
	chr : char;
    StringLength  : byte;
Begin
	for StringLength := 1 to ord(s[0]) do
   begin
   	chr := s[StringLength];
      asm
      	mov AH,02H
			xor BH,bh
			mov DH,[y]
			mov DL,[x]
			int 10h
            mov AH,09h
			mov AL,[chr]
            mov BH,[bkcolour]
            mov BL,[colour]
            mov CX,01h
			int 10h
			inc [x]
		end;
	end;
end;

Procedure SaveScreenToFile(ScreenAddr : word;FileName : string);
var FileID : file;
begin;
assign (FileID,FileName);
rewrite (FileID,1);
blockwrite(FileID,mem[ScreenAddr:0],320*200);
close(FileID);
end;

Procedure ReadScreenFromFile(ScreenAddr : word;FileName : string);
var FileID : file;
begin;
assign (FileID,FileName);
reset (FileID,1);
blockread(FileID,mem[ScreenAddr:0],320*200);
close(FileID);
end;

Procedure SavePaletteFile(FileName : string);
var FileID : file;
    PalR,PalG,PalB : String;
    i,r,g,b : byte;
begin;
assign(FileID,FileName);
rewrite(FileID,1);
for i:= 0 to 255 do
 begin
    GetPalette(i,r,g,b);
    PalR[i] := chr(r);
    PalG[i] := chr(g);
    PalB[i] := chr(b);
 end;
blockwrite(FileID,PalR,256);
blockwrite(FileID,PalG,256);
blockwrite(FileID,PalB,256);
close(FileID);
end;

Procedure LoadPaletteFile(FileName : string);
var FileID : file;
    PalR,PalG,PalB : String;
    i,r,g,b : byte;
begin;
assign(FileID,FileName);
reset(FileID,1);
blockread(FileID,PalR,256);
blockread(FileID,PalG,256);
blockread(FileID,PalB,256);

for i:= 0 to 255 do
 begin
    r := ord(PalR[i]);
    g := ord(PalG[i]);
    b := ord(PalB[i]);
    SetPalette(i,r,g,b);
 end;
close(FileID);
end;

Procedure SetVirtual;
Begin
  GetMem (VirScr,64000);
  vaddr := seg(virscr^);
End;

Procedure Box(ScreenAddr: word;x,y,x1,y1,c:integer);
var xpos,ypos : integer;

Begin
for xpos := x to x1 do       {Draws Topline of box}
 begin
   PutPixel(ScreenAddr,xpos,y,c);
 end;

for xpos := x to x1 do       {Draws Bottomline of box}
 begin
   PutPixel(ScreenAddr,xpos,y1,c);
 end;

for ypos := y to y1 do       {Draws Sides of box}
 begin
  PutPixel(ScreenAddr,x,ypos,c);
  PutPixel(ScreenAddr,x1,ypos,c);
 end;
End;

Procedure SaveImage(Filename : string);
var FileID : file;
    PalR,PalG,PalB : String;
    i,r,g,b : byte;
begin;
assign(FileID,FileName);
rewrite(FileID,1);
for i:= 0 to 255 do
 begin
    GetPalette(i,r,g,b);
    PalR[i] := chr(r);
    PalG[i] := chr(g);
    PalB[i] := chr(b);
 end;
blockwrite(FileID,PalR,256);
blockwrite(FileID,PalG,256);
blockwrite(FileID,PalB,256);
blockwrite(FileID,mem[Screen:0],320*200);
close(FileID);
End;

Procedure NewMovie(FileName : string; NumFrames : integer);
begin
assign(MovieID,FileName);
rewrite(MovieID,1);
Blockwrite(MovieID,NumFrames,3);
end;

Procedure OpenMovie(FileName : string);
begin
assign(MovieID,FileName);
reset(MovieID,1);
Blockread(MovieID,NumFrames,3);
end;

Function GetNumFrames : integer;
begin
GetNumFrames := NumFrames;
end;

Procedure CloseMovie;
begin
close(MovieID);
end;

Procedure SaveMovieFrame(FrameNo : integer);
var PalR,PalG,PalB : String;
    i,r,g,b : byte;
begin
for i:= 0 to 255 do
 begin
    GetPalette(i,r,g,b);
    PalR[i] := chr(r);
    PalG[i] := chr(g);
    PalB[i] := chr(b);
 end;
blockwrite(MovieID,FrameNo,3); { Frame No }
blockwrite(MovieID,PalR,256);  {              }
blockwrite(MovieID,PalG,256);  { Pallete Code }
blockwrite(MovieID,PalB,256);  {              }
blockwrite(MovieID,mem[Screen:0],320*200);  { Image }
End;

Procedure LoadNextFrame;
var PalR,PalG,PalB : String;
    i,r,g,b : byte;
    FrameNo : integer;
begin;
Blockread(MovieID,FrameNo,3);
blockread(MovieID,PalR,256);
blockread(MovieID,PalG,256);
blockread(MovieID,PalB,256);
for i:= 0 to 255 do
 begin
    r := ord(PalR[i]);
    g := ord(PalG[i]);
    b := ord(PalB[i]);
    SetPalette(i,r,g,b);
 end;
blockread(MovieID,mem[Screen:0],320*200);
End;


Procedure LoadImage(Filename : string);
var FileID : file;
    PalR,PalG,PalB : String;
    i,r,g,b : byte;
begin;
assign(FileID,FileName);
reset(FileID,1);
blockread(FileID,PalR,256);
blockread(FileID,PalG,256);
blockread(FileID,PalB,256);
for i:= 0 to 255 do
 begin
    r := ord(PalR[i]);
    g := ord(PalG[i]);
    b := ord(PalB[i]);
    SetPalette(i,r,g,b);
 end;
blockread(FileID,mem[Screen:0],320*200);
close(FileID);
End;

  {
  Move(Virscr^,MEM[VGA:0],64000); (*Stick the virtual page to the vga mem*)
  FreeMem (VirScr,64000); (*Free up virtual memory*)
   }
procedure Read_PCX_Line(vidoffset: word);
var c, run: byte;
    n: integer;
    w: word;
begin
  n:=0;
  while (n < bytes) do
  begin
    blockread (f, c, 1);
    if ((c and 192)=192) then
    begin
      run:=c and 63;
      blockread (f, c, 1);
      n:=n+run;
      for w:=0 to run-1 do
      begin
        mem [$a000:vidoffset]:=c;
        inc (vidoffset);
      end;
    end else
    begin
      n:=n+1;
      mem [$a000:vidoffset]:=c;
      inc (vidoffset);
    end;
  end;
end;

procedure Unpack_PCX_File;
var i: integer;
begin
  for i:=0 to 767 do
    palette [i]:=palette [i] shr 2;
  asm
    mov ax,1012h
    xor bx,bx
    mov cx,256
    mov dx,offset palette
    int 10h
  end;
  for i:=0 to depth-1 do
    Read_PCX_Line (i*320);
end;

Function Load_Pcx(FileName : String) : Boolean;
begin
    assign (f, FileName);
    reset (f,1);
    blockread (f, header, sizeof (header));
    if (header.manufacturer=10) and (header.version=5) and
       (header.bits_per_pixel=8) and (header.colour_planes=1) then
    begin
      seek (f, filesize (f)-769);
      blockread (f, c, 1);
      if (c=12) then
      begin
        blockread (f, palette, 768);
        seek (f, 128);
        width:=header.xmax-header.xmin+1;
        depth:=header.ymax-header.ymin+1;
        bytes:=header.bytes_per_line;
        Unpack_PCX_File;
      end else Load_Pcx := FALSE;
    end else Load_Pcx := FALSE;
    close (f);
end;
{
***********************
***Other  Procedures***
***********************
}

Function Chk4Win : Boolean;
{Checks if Windows Is running.}
Var
  Regs : Registers;
begin
  Regs.AX := $4680;    { Win 3.x Standard check }
  Intr($2F, Regs);     { Call Int 2F }
  if Regs.AX <> 0 then { if AX = 0 Win in Real mode }
  begin                { else check For enhanced mode }
    Regs.AX := $1600;  { Win 3.x Enhanced check }
    Intr($2F, Regs);   { Call Int 2F }
    if Regs.AL in [$00,$80,$01,$FF] then { Check returned value }
      Chk4Win := False   { Nope not installed }
    else
      Chk4Win := True;   { Ya it is }
  end
  else
    Chk4Win := True;     { Return True }
end;

function StrConv(I: Longint): String;
var
 S: string[11];
begin
 Str(I, S);
 StrConv := S;
end;

function ValConv(S: string): longint;
var
 I : longint;
 err : integer;
begin
 Val(S, I,err);
 ValConv := I;
end;

Function VideoCard: CardType;
Var
  code : Byte;
  Regs : Registers;
begin
  Regs.AH := $1A;      (* call VGA Identify Adapter Function *)
  Regs.AL := $00;      (* clear AL to 0...*)
  Intr($10, Regs);     (* call BIOS *)
  If Regs.AL = $1A then
  begin
    Case Regs.BL of
      $00 : VideoCard := NONE;       (* no Graphic card *)
      $01 : VideoCard := MDA;        (* monochrome *)
      $02 : VideoCard := CGA;        (* cga *)
      $04 : VideoCard := EGAColor;   (* ega color *)
      $05 : VideoCard := EGAMono;    (* ega mono*)
      $07 : VideoCard := VGAMono;    (* vga mono *)
      $08 : VideoCard := VGAColor;   (* vga color *)
      $0A,
      $0C : VideoCard := MCGAColor;  (* mcga color *)
      $0B : VideoCard := MCGAMono;   (* mcga mono *)
      Else
        VideoCard := CGA
    end
  end
  Else
  begin
    Regs.AH := $12;         (* use another Function service *)
    Regs.BX := $10;         (* BL = $10 means return EGA info *)
    Intr($10, Regs);        (* call BIOS video Function *)
    If Regs.bx <> $10 Then  (* bx unchanged means EGA is not present *)
    begin
      Regs.AH := $12;
      Regs.BL := $10;
      Intr($10, Regs);
      If Regs.BH = 0 Then
        VideoCard := EGAColor
      Else
        VideoCard := EGAMono
    end
    Else
    begin
      Intr($11, Regs);     (* eguipment determination service *)
      code := (Regs.AL and $30) shr 4;
      If (code = 3) Then
        VideoCard := MDA
      Else
        VideoCard := CGA
    end
  end
end; (* VideoCard *)

FUNCTION CpuType :WORD; ASSEMBLER;
                 {  Returns a value depending on the type of CPU        }
                 {          0 = 8088/V20 or compatible                  }
                 {          1 = 80286    2 = 80386/80486+               }
ASM
  Xor DX,DX                             {  Clear DX                     }
  Push DX
  PopF                                  {  Clear Flags                  }
  PushF
  Pop AX                                {  Load Cleared Flags           }
  And AX,$0F000                         {  Check hi bits for F0h        }
  Cmp AX,$0F000
  Je @Quit                              {  Quit if 8088                 }
  Inc DX
  Mov AX,$0F000                         {  Now Check For 80286          }
  Push AX
  PopF
  PushF
  Pop AX
  And AX,$0F000                         {  If The top 4 bits aren't set }
  Jz @Quit                              {  Its a 80286+                 }
  Inc DX                                {  Else its a 80386 or better   }
@Quit:
  Mov AX,DX                             {  Return Result in AX          }
END;{CpuType}
end.