#
#  This file tries to set the PENCIL_HOME environment variable if it
#  doesn't exist yet, and then adds stuff to your PATH and IDL_PATH.
#  If _sourceme_quiet is set, no output is printed, which enables you to
#  put the lines
#    setenv PENCIL_HOME [...]
#    set _sourceme_quiet; source $PENCIL_HOME/sourceme.csh; unset _sourceme_quiet
#  into you .cshrc file
#

#  set cdpath = ( . ../  ../../ ../../../ ~/ )

if (! $?PENCIL_HOME) then
  unset _sourceme		# tabula rasa without PENCIL_HOME
  #
  # Try to identify position of the code's home directory:
  #
  foreach _dir ( . .. ../.. ../../.. ../../../.. \
                pencil pencil-code \
		f90/pencil f90/pencil-code \
		pencil_modular f90/pencil_modular)
    if ( (-e $_dir/sourceme.csh) && \
         (-d $_dir/bin)          && \
	 (-d $_dir/doc)          && \
	 (-d $_dir/src)          && \
	 (-d $_dir/samples)         \
       ) then
      set back_again = `pwd`     
      cd $_dir; setenv PENCIL_HOME `pwd`; cd $back_again
      goto found
    endif
  end

  echo "sourceme.csh: Cannot locate home directory of pencil code."
  echo "  Try sourcing me from the home directory itself, or set PENCIL_HOME"
  goto eof
endif
    
found:
if (! $?_sourceme_quiet) echo "PENCIL_HOME = <$PENCIL_HOME>"

if (! $?_sourceme) then		# called for the fist time?
  if (-d $PENCIL_HOME/bin) then
    #  Set shell path
    if (! $?_sourceme_quiet) echo "Adding $PENCIL_HOME/{bin,utils{,/axel}} to PATH"
    set path = ( $path $PENCIL_HOME/bin \
                       $PENCIL_HOME/utils \
		       $PENCIL_HOME/utils/axel )
    #  Set path for DX macros
    if ($?DXMACROS) then
      setenv DXMACROS "${PENCIL_HOME}/dx/macros:$DXMACROS"
    else
      setenv DXMACROS "${PENCIL_HOME}/dx/macros"
    endif
    #  Set IDL path
    if ($?IDL_PATH) then
      setenv IDL_PATH "./idl:../idl:+${PENCIL_HOME}/idl:./data:./tmp:$IDL_PATH"
    else
      setenv IDL_PATH "./idl:../idl:+${PENCIL_HOME}/idl:./data:./tmp:<IDL_DEFAULT>"
    endif
    set _sourceme = 'set'
  else
    echo "Not adding $PENCIL_HOME/bin to PATH: not a directory"
  endif
  #
  #  additional aliases (for axel)
  #
  alias gb '\cd $gt ; set gg=$gb ; set gb=$gt ; set gt=$gg ; echo $gt "->" $gb'
  alias gt 'set gt=$cwd; \cd \!^ ; set gb=$cwd ; echo $gt "->" $gb'
  # alias d ls -sCF
  alias .. 'set pwd = $cwd ; cd ..'
  # alias local 'cp -p \!:1 tmp.$$; \rm \!:1; mv tmp.$$ \!:1; chmod u+w \!:1'
endif

#
#  Clean up and exit
#
eof:

unset _dir
