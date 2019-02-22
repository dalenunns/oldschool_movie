{----------------------------------------------------------------------------}
{                                Motion Picture                              }
{          --------------------------------------------------------          }
{               * Sound Unit * version 1.0a * 05-10-1999 *                   }
{         Some code for this unit was taken from SWAG the main source        }
{                  was Andree Borrmann's Wav file player.                    }
{                                                                            }
{          --------------------------------------------------------          }
{                   Dale Nunns                                               }
{                   dale.nunns@pmail.net  										     }
{                   http://come.to/Chippy/                                   }
{----------------------------------------------------------------------------}
{$M 4096,0,65500}
unit Sound;
Interface

uses crt,dos;
Const dma    = 4096;
Type  id_t   = Array[1..4] of Char;
      riff_t = Record
                R_Ident : id_t;
                length  : Longint;
                C_Ident : id_t;
                S_Ident : id_t;
                s_length: Longint;
                Format  ,
                Modus   : Word;
                freq    ,
                byte_p_s: LongInt;
                byte_sam,
                bit_sam : Word;
                temp : string[13];
                D_Ident : id_t;
                d_length: LongInt;
              End;
      blaster_T = Record
                    port : Word;
                    dmac ,
                    hdmac,
                    irq  : Byte;
                  End;
      buffer_T = Array[1..dma] of Byte;

Var id       : riff_T;
    fn       : String;
    wav      : File;
    sbb      : Word;
    Ende     : Boolean;
    blaster  : Blaster_T;
    alt_irq  : Pointer;
    dma_buf_1,
    dma_buf_2,
    zwi      : ^Buffer_T;
    Channel  : Byte;
    WavePlaying : boolean;
	 p,s,s2 : Word;
    w      : LongInt;
Const RIFF : id_t = ('R','I','F','F');
      WAVE : id_t = ('W','A','V','E');
      FMT_ : id_t = ('f','m','t',' ');
      DATA : id_t = ('d','a','t','a');

      DMA_Dat : Array [0..7,1..6] of Byte=
                  (($A,$C,$B,$0,$87,$1),
                   ($A,$C,$B,$2,$83,$3),
                   ($A,$C,$B,$4,$81,$5),
                   ($A,$C,$B,$6,$82,$7),
                   ($D4,$D8,$D6,$C0,$8F,$C2),
                   ($D4,$D8,$D6,$C4,$8B,$C6),
                   ($D4,$D8,$D6,$C8,$89,$CA),
                   ($D4,$D8,$D6,$CC,$8A,$CE));

Function Init_Sound : boolean;
Function Load_Wav(FileName : string) : boolean;
Function Play_Wave : boolean;
Procedure Shutdown_Sound;



implementation
Procedure Blaster_Command(c :Byte); Assembler;
Asm
    Mov dx,Word Ptr sbb
    Add dx,$c
 @t:In al,dx
    And al,128
    Jnz @t
    Mov al,c
    Out dx,al
End;

Procedure Init_SB(base : Word);
Var w,w2:Word;
Begin
  sbb:=base;
  Port[base+6]:=1; Delay(4); Port[base+6]:=0; w:=0; w2:=0;
  Repeat
    Repeat Inc(w); Until ((Port[base+$e] and 128)=128) or (w>29);
    Inc(w2);
  Until (Port[base+$a]=$AA) or (W2>30);
  If w2>30 then
    Begin
      WriteLn('Failed to ReSet Blaster');
      Halt(128);
    End;
  Blaster_Command($d1);
End;

Procedure Set_Stereo; Assembler;
Asm
  Mov dx,Word Ptr sbb
  Add dx,$4
  Mov al,$e
  Out dx,al
  Inc dx
  In al,dx
  And al,253
  Or al,2
  Out dx,al
End;

Procedure Clear_Stereo; Assembler;
Asm
  Mov dx,Word Ptr sbb
  Add dx,$4
  Mov al,$e
  Out dx,al
  Inc dx
  In al,dx
  And al,253
  Out dx,al
End;

Function No_Wave(Var id:riff_T):Boolean;
Begin
  With id do
    No_Wave:=(R_Ident<>RIFF) or
             (C_Ident<>WAVE) or
             (S_Ident<>FMT_) or
             (D_Ident<>DATA);
End;

Function Init_Sound : boolean;
Var b : Byte;
Begin
  Blaster.Port:=0;
  Blaster.dmac:=0;
  Blaster.hdmac:=0;
  Blaster.irq:=0;
  WavePlaying := False;
  fn:=GetEnv('BLASTER');
  If fn='' then
    Begin
     Init_Sound := FALSE;
     exit;
    End;
  b:=1;
  Repeat
    Case fn[b] of
      'A' : Repeat
              Inc(b);
              Blaster.Port:=Blaster.Port*16+Ord(fn[b])-48;
            Until Fn[b+1]=' ';
      'D' : Begin
              Blaster.DMAc:=Ord(fn[b+1])-48;
              Inc(b,2);
            End;
      'I' : Repeat
              Inc(b);
              Blaster.IRQ:=Blaster.IRQ*16+Ord(fn[b])-48;
            Until Fn[b+1]=' ';
      'H' : Begin
              Blaster.hDMAc:=Ord(fn[b+1])-48;
              Inc(b,2);
            End;
        End;
    Inc(b);
  Until b>Length(fn);
end;

Function Load_Wav(FileName : string) : boolean;
begin
  With Blaster do
  Init_SB(Blaster.Port);
  fn:=FileName;
  Assign(wav,fN);
  {$I-} ReSet(wav,1); {$I+}
  If IOResult<>0 then
    Begin
      {File Not Found}
      Load_Wav := False;
      exit;
    End;
  BlockRead(wav,id,Sizeof(id));

  If no_Wave(id) then
    Begin
      Writeln(id.r_ident);
      Writeln(id.c_ident);
      Writeln(id.s_ident);
      Writeln(id.d_ident);
      WriteLn('"',fn,'" seems to be no WAVE-File...');
      Halt(128);
    End;

{  Write('Wave    : ',id.bit_sam,'bit ');}

  If id.Modus=2 then
    Begin
      Set_Stereo;
{      Write('stereo ');}
    End
  Else
    Begin
      Clear_Stereo;
{      Write('mono    ');}
    End;
  If (id.bit_sam>8) and (Blaster.hdmac>3) then
    Channel:=Blaster.hdmac
  Else Channel:=Blaster.dmac;
{  WriteLn(id.freq,' Hz  ',id.byte_p_s,' Bytes/Sec');
  WriteLn('Length  : ',id.d_length,' Bytes    ',id.d_length div id.byte_p_s, ' Sec');
  WriteLn('Playing : ',fn);}
End;

{$F+}
Procedure Stelle_DMA(Freq: Word;Var size : Word);
Var PageNr,PageAdress,DMALength: Word;
Begin
  Inline($FA);
  Asm
    Mov ax,Word Ptr DMA_Buf_1[2]
    Shr ax,12
    Mov Word Ptr PageNr,ax
    Mov ax,Word Ptr DMA_Buf_1[2]
    Shl ax,4
    Mov Word Ptr PageAdress,ax
    Mov ax,Word Ptr DMA_Buf_1
    Add Word Ptr PageAdress,ax
    Adc Word Ptr PageNr,0
  End;
  DMALength:=Size;
  Freq:=256-Trunc(1000000/Freq);
  If Channel>3 then
    Begin
      DMALength:=DMALength div 2;
      PageAdress:=PageAdress div 2;
      If Odd(PageNr) then
        Begin
          Dec(PageNr);
          PageAdress:=PageAdress+$8000
        End;
    End;
  If id.Modus=2 then
    Begin
      If id.bit_sam=16
        then Blaster_Command($A4)
        Else Blaster_Command($A8);
    End
  Else
    If id.bit_sam=16
      then Blaster_Command($A4);

  Dec(DMALength);

  Port[DMA_dat[Channel,1]]:=$4 or (Channel and $3);
  Port[DMA_dat[Channel,2]]:=$0;
  Port[DMA_dat[Channel,3]]:=$49;
  Port[DMA_dat[Channel,4]]:=lo(PageAdress);
  Port[DMA_dat[Channel,4]]:=hi(PageAdress);
  Port[DMA_dat[Channel,5]]:=lo(PageNr);
  Port[DMA_dat[Channel,6]]:=lo(DMALength);
  Port[DMA_dat[Channel,6]]:=hi(DMALength);
  Port[DMA_dat[Channel,1]]:=(Channel and $3);

  Blaster_Command($40);
  Blaster_Command(Lo(Freq));
  Blaster_Command($48);
  Blaster_Command(lo(DMALength));
  Blaster_Command(hi(DMALength));
  Blaster_Command($91);
  Inline($FB);
End;

Procedure Ausgabe_IRQ; Interrupt;
Var test : Byte;
Begin
  Inline($FA);
  Port[$20]:=$20;
  test:=Port[sbb+$e];
  Ende:=True;
  Inline($fB);
End;
{$F-}

Procedure Play;
Begin
  GetMem(zwi,16);
  GetMem(dma_buf_1,dma);
  p:=16;
  While (Seg(dma_buf_1^[1]) mod 4096)>(4096-(dma*2 div 16)) do
    Begin
      FreeMem(dma_buf_1,dma);
      FreeMem(zwi,p);
      p:=p+16;
      If p>65525 then halt(111);
      GetMem(zwi,p);
      GetMem(dma_buf_1,dma);
    End;
  GetMem(dma_buf_2,dma);
  FreeMem(zwi,p);
  port[$21]:=Port[$21] and (255 xor (1 shl Blaster.IRQ));
  GetIntVec(Blaster.IRQ+8,Alt_irq);
  SetIntVec(Blaster.IRQ+8,@Ausgabe_IRQ);
  w:=id.freq*id.modus;
  BlockRead(wav,dma_buf_1^[1],dma,s);
	WavePlaying := true;
end;

Function Play_Wave : boolean;
begin
    if NOT WavePlaying then
    play
    else
    begin
    Ende:=False;
    Stelle_DMA(w,s);
    BlockRead(wav,dma_buf_2^[1],dma,s2);
    Repeat Until Ende;
    s:=s2;
    zwi:=dma_buf_1;
    dma_buf_1:=dma_buf_2;
    dma_buf_2:=zwi;
    if EoF(wav) then Play_Wave := False;
	end;
end;
 { Until EoF(wav) or Keypressed;}
{  While KeyPressed do w:=Ord(ReadKey);
  If EoF(wav) then
    Begin
      Ende:=False;
      Stelle_DMA(w,s);
      Repeat Until Ende;
    End;                }

Procedure Shutdown_Sound;
begin
  SetintVec(Blaster.IRQ+8,Alt_IRQ);
  FreeMem(dma_buf_1,dma);
  FreeMem(dma_buf_2,dma);
  Port[$21]:=Port[$21] or (1 shl Blaster.IRQ);
  Blaster_Command($d3);
  WavePlaying := False;
End;


end.

