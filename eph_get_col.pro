;+
; NAME: eph_get_col
;
; PURPOSE: read columns from a JPL ephemerides
;
; CATEGORY: ephemerides
;
; CALLING SEQUENCE:
;
; DESCRIPTION:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMON BLOCKS:  
;   Common blocks are ugly.  Consider using package-specific system
;   variables.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;
; $Id: eph_get_col.pro,v 1.3 2015/03/03 20:36:50 jpmorgen Exp $
;
; $Log: eph_get_col.pro,v $
; Revision 1.3  2015/03/03 20:36:50  jpmorgen
; Summary: Go back to exact column names, check in for git
;
; Revision 1.2  2013/03/05 22:04:00  jpmorgen
; Fix column listing bug.  Get ready to remove abbreviation feature,
; since it doesn't work with "r"
;
; Revision 1.1  2013/01/19 13:28:49  jpmorgen
; Initial revision
;
;-
function eph_get_col, $
   fname_or_lun, $
   col_list=col_list, $ ;; list of column names matching the JPL ephemerides output.  Must be exact
   _REF_EXTRA=extra ;; return values from eph_get_info

  init = {tok_sysvar}

  ;; Set up a CATCH so that we can free our lun, if we opened it
  CATCH, err
  if err ne 0 then begin
     CATCH, /CANCEL
     if size(/type, fname_or_lun) eq !tok.string and N_elements(elun) ne 0 then $
        free_lun, elun
     ;; Pass the message on to the caller, who may have set a CATCH
     message, /NONAME, !error_state.msg
  endif

  if N_elements(fname_or_lun) eq 0 then $
     message, 'ERROR: specify fname or open file logical unit.  I need a file to read.'

  ;; Open our file or transfer our input lun
  if size(/type, fname_or_lun) eq !tok.string then $
     openr, elun, fname_or_lun, /get_lun $
  else $
     elun = fname_or_lun
  if (fstat(elun)).open eq 0 then $
     message, 'ERROR: file/lun ' + strtrim(fname_or_lun, 2) + ' is not open'

  ;; Read information from the ephemeris header, if desired
  if N_elements(extra) ne 0 then begin
     eph_get_info, elun, _EXTRA=extra
  endif

  ;; Read to the $$SOE one line at a time, but keep the previous two
  ;; lines so that the column headings are available
  line2 = '' & line1 = line2
  repeat begin
     ;; Save off previous lines
     line0 = line1
     line1 = line2
     ON_IOERROR, rherr
     readf, elun, line2
     ;; Hide our error label in a statement that doesn't
     ;; normally get executed
     if 0 then begin
        rherr: 
        message, 'ERROR: unexpected IO error while looking for $$SOE'
     endif ;; file I/O error condition
     a = strpos(line2, '$$SOE')
  endrep until a eq 0

  ;; Create an array of strings, each element has a column header in
  ;; it.  Here is where CSV output is critical
  col_heads = strsplit(line0, ',', /extract)
  ;; Trim off leading and trailing spaces
  col_heads = strtrim(col_heads, 2)

  ;; If no col_list is specified, return all columns.
  if N_elements(col_list) eq 0 then begin
     ;; HORIZONS generally returns some columns with null entries,
     ;; since columns are allocated by number, so get rid of those
     good_idx = where(col_heads ne ' ')
     col_list = col_heads[good_idx]     
  endif ;; setting default col_list

  ;; Find which column numbers we are looking for
  col_nums = make_array(N_elements(col_list), value=-1)
  for icl=0,N_elements(col_list)-1 do begin
     nchar = strlen(col_list[icl])
     ;; Search through all column headers in ephemeris for match
     for ich=0, N_elements(col_heads)-1 do begin
        if strcmp(col_list[icl], col_heads[ich], /fold_case) then begin
           ;; We have a match.  Check for duplicates.  For now, raise
           ;; a nasty error
           if col_nums[icl] ne -1 then $
              message, 'ERROR: duplicate columns found.  Check col_list against ephemeris file to make sure you are cut/pasting properly'
           
           ;; If we made it here, we have found our first and
           ;; hopefully only match for our desired column head
           col_nums[icl] = ich

        endif ;; match 
     endfor ;; each column header in ephemeris file
  endfor ;; each desired column name in col_list

  ;; Check col_nums to make sure we haven't missed any columns
  bad_idx = where(col_nums eq -1, count)
  if count gt 0 then begin
     print, col_list[bad_idx]
     message, 'ERROR: did not find the above listed columns'
  endif

  ;; If we made it here, we should have a list of column numbers of
  ;; all the columns we want.
  
  ;; Make our return structure.  Because of syntatical issues, IDL
  ;; structure tags cannot be made directly from HORIZONS column
  ;; names.  The best we can do in a generic sense is just make
  ;; numbered structure tags.

  ;; Prepare our typecasting variable.  There may be a more elegant
  ;; way to do this.  The problem is a scaler variable just gets
  ;; overwritten.  An array or struct has a forced type.
  darr = make_array(2, value=0d)

  ;; Read in the first line of the ephemeris
  line = ''
  ON_IOERROR, rc1err
  readf, elun, line
  if 0 then begin
     rc1err: 
     message, 'ERROR: unexpected IO error while reading first line of ephemeris'
  endif ;; file I/O error condition

  ;; Break it up into strings
  sdata = strsplit(line, ',', /extract)
  for icl=0, N_elements(col_list)-1 do begin
     ;; Figure out what type our column is.  Put the answer into the
     ;; variable "data"

     ;; Default is to assume column is a string.  Remove any padding
     data = strtrim(sdata[col_nums[icl]], 2)

     ;; HORIZONS returns n.a. if there is a nonsense answer
     ;; (e.g. airmass below the horizon).  We want to store that as
     ;; NAN
     if strlowcase(data) eq 'n.a.' then begin
        data = !values.d_nan
     endif else begin
        ;; Use IDL's type casting and IO error catching to help
        ;; figure out if something needs to be stored as a string or
        ;; can be a number
        ON_IOERROR, icerr
        ;; This will raise an error if the column is really a string
        darr[0] =  data

        ;; If we made it here, we did not raise an error, our column can
        ;; be stored as a real number
        data = darr[0]

        ;; The error condition leaves data as a string, the non-error
        ;; condition leaves data as a real, so there is nothing left
        ;; to do
        icerr: 

     endelse ;; not n.a. 

     ;; If this is the first time through, create a structure with
     ;; a generic tag name
     new_struct = create_struct(string("c", strtrim(icl, 2)), data)

     ;; Append that to the return structure
     if N_elements(ret_struct) eq 0 then begin
        ret_struct = new_struct
     endif else begin
        ret_struct = struct_append(ret_struct, new_struct)
     endelse
  endfor ;; each col in col_list
  
  ;; We now have one structure element.  We want to return an array of
  ;; this structure with all of the data loaded into it.

  ;; Prepare a template single array element
  new_struct = ret_struct
  ON_IOERROR, rl1err
  readf, elun, line

  ;; Hide our error label in a statement that doesn't
  ;; normally get executed
  if 0 then begin
     rl1err: 
     message, 'ERROR: unexpected IO error'
  endif ;; file I/O error condition

  while strpos(line, '$$EOE') eq -1 do begin
     sdata = strsplit(line, ',', /extract)
     for icl=0, N_elements(col_list)-1 do begin
        ;; Catch type conversion errors
        ON_IOERROR, tcerr
        ;; Rely on IDL to do the type conversion
        new_struct.(icl) =  sdata[col_nums[icl]]
        ;; Hide our error label in a statement that doesn't
        ;; normally get executed
        if 0 then begin
           tcerr: 
           ;; Mark type conversion errors with NANs.  They are
           ;; probably n.a., anyway
           new_struct.(icl) = !values.d_nan           
        endif ;; error condition
     endfor ;; each column in col_list
     ;; Cancel our type conversion error condition 
     ON_IOERROR, null

     ;; Append in a memory sensitive way to end of ret_struct
     ret_struct = [temporary(ret_struct), new_struct]

     ;; Get ready to read our next line
     ON_IOERROR, rlerr
     readf, elun, line
     
     ;; Hide our error label in a statement that doesn't
     ;; normally get executed
     if 0 then begin
        rlerr: 
        message, 'ERROR: unexpected IO error'
     endif ;; file I/O error condition

  endwhile

  ;; Close our file and free the lun, if we were the ones who opened it
  if size(/type, fname_or_lun) eq !tok.string then $
     free_lun, elun

  ;; Add one more thing to the ret_struct: the official HORIZONS
  ;; column names.  This makes the output read something like data.column.0
  ret_struct = create_struct('col_names', col_heads[col_nums], $
                             'data', temporary(ret_struct))
  return, ret_struct

end
