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
; $Id: eph_get_col.pro,v 1.1 2013/01/19 13:28:49 jpmorgen Exp $
;
; $Log: eph_get_col.pro,v $
; Revision 1.1  2013/01/19 13:28:49  jpmorgen
; Initial revision
;
;-
function eph_get_col, $
   fname_or_lun, $
   col_list=col_list, $ ;; list of column names matching the JPL ephemerides output (can be the first few char, if unique)
   target=target, $
   observer=observer

  init = {tok_sysvar}

  if N_elements(fname_or_lun) eq 0 then $
     message, 'ERROR: specify fname or open file logical unit.  I need a file to read.'

  ;; Open our file or transfer our input lun
  if size(/type, fname_or_lun) eq !tok.string then $
     openr, elun, fname_or_lun, /get_lun $
  else $
     elun = fname_or_lun
  if (fstat(elun)).open eq 0 then $
     message, 'ERROR: file/lun ' + strtrim(fname_or_lun, 2) + ' is not open'

  ;; Read our object and center keywords
  if arg_present(target) or arg_present(observer) then begin
     eph_get_info, elun, target=target, observer=observer
  endif

  ;; Read to the $$SOE one line at a time, but keep the previous two
  ;; lines so that the column headings are available
  line2 = '' & line1 = line2
  repeat begin
     ;; Save off previous lines
     line0 = line1
     line1 = line2
     readf, elun, line2
     a = strpos(line2, '$$SOE')
  endrep until a eq 0

  ;; Create an array of strings, each element has a column header in
  ;; it.  Here is where CSV output is critical
  col_heads = strsplit(line0, ',', /extract)

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
     ;; Allow the user to input only the first few characters of the
     ;; column name
     nchar = strlen(col_list[icl])
     ;; Search through all column headers in ephemeris for match
     for ich=0, N_elements(col_heads)-1 do begin
        if strcmp(col_list[icl], col_heads[ich], nchar, /fold_case) then begin
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

  ;; Read in a line of the ephemeris
  line = ''
  readf, elun, line
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
        data = !value.d_nan
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
        ;; condition leaves data as a real
        icerr: 

        endif ;; error condition
     endelse

     ;; Figure out if our data must be stored in type string.  This
     ;; misses space-delimited hh mm ss.s angles, which is why those
     ;; should be requested in decimal degrees anyway
     ;; --> sech for n.a. which are really numeric
     if stregex(/boolean, sdata[col_nums[icl]], '[a-z,\*]', /fold_case) then begin
        ;; This is a string
        data = sdata[col_nums[icl]]
     endif else begin
        ;; This is a number
        data = double(sdata[col_nums[icl]])
     endelse

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
  readf, elun, line
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
           ;; If we made it here, we are trying to stuff a string,
           ;; like n.a. into a double type
           message, 'WARNING: column ' + strtrim(icl, 2) + ' had a type conversion error' ;;,  /CONTINUE
        endif ;; error condition
     endfor ;; each column in col_list

     ;; Append in a memory sensitive way to end of ret_struct
     ret_struct = [temporary(ret_struct), new_struct]
     ;; Cancel our type conversion IOERROR condition --> eventually
     ;; may want a graceful IO error handler for premature EOF
     ;; Read in our next (or last) line
     readf, elun, line
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
