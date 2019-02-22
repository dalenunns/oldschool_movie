----------------------------------------------------------------------------
                                Motion Picture                              
          --------------------------------------------------------          
                        * version 1.0a * 05-10-1999 *                
          --------------------------------------------------------          
                   Dale Nunns                                               
                   dale.nunns@pmail.net                                                                                     }
                   http://come.to/Chippy/                                   
----------------------------------------------------------------------------

MAKEMOV.EXE:
        eg : C:\>makemov -l movie.lst -d movie.mot
        -l : use this to specify the location of the LIST file. (More info
             below.)
        -d : use this to specify the location of the Destination Movie file.

  LIST FILE:
        eg :
           2
           C:\movie\Frame1.pcx
           C:\movie\Frame2.pcx

        In the top of this file you put the number of Frames.
        Then the location of each PCX a 320x200 256colour images, which are
        the frames of the movie.

----------------------------------------------------------------------------

MOVIE.EXE  :
        eg : movie movie.mot

        After which you specify the location of the Movie File created with
        Makemov.exe

----------------------------------------------------------------------------

