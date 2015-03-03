;+
; NAME: eph_table_req
;
; PURPOSE: generate an email request file to generate a table-type
; HORIZONS ephemeris at particular times (TLIST).
;
; CATEGORY: ephemerides
;
; CALLING SEQUENCE: eph_table_req
;
; DESCRIPTION: generate an email request file to generate a table-type
; HORIZONS ephemeris at particular times (TLIST).  If you have a
; standard begin and end time request, the web page is probably
; easier, or you can modify this code to implement that feature.

; This code does not actually send the file it creates to HORIZONS,
; since that depends on the details of your OS and mail setup.  There
; is am implementation of an automatic email and receipt system for
; UNIX-like systems described in ssg_ephem_req.pro

;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:

; fname: filename to write request to

; command: HORIZONS-style command (usually the object code, e.g. '501'
; for Io)

; center: HORIZONS center designation (e.g. 695 or 695@599 for Kitt
; Peak)

; tlist: list of times for which you want the ephemeris calculated
; (in JD or MJD)

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
; $Id: eph_table_req.pro,v 1.1 2015/03/03 20:39:01 jpmorgen Exp $
;
; $Log: eph_table_req.pro,v $
; Revision 1.1  2015/03/03 20:39:01  jpmorgen
; Initial revision
;
;-
pro eph_table_req, $
   fname=fname, $ ;; output filename
   command=command, $ ;; this is the object that you want to look at
   center=center, $ ;; observatory or body code (e.g. 695 for Kitt Peak, 501 if you want to look at Jupiter from Io)
   coord_type=coord_type, $ ;; if center calls for coordinates (e.g. c@399), this specifies GEODETIC or CYLINDRICAL
   site_coord=site_coord, $ ;; if user-entered coordinates
   tlist=tlist

  ;; Read in token system variable so code can read in English
  init = {tok_sysvar}

  if N_elements(fname) eq 0 then $
     message, 'ERROR: fname keyword missing.  I need a file to write the output to.'
  if N_elements(command) eq 0 then $
     message, 'ERROR: command keyword missing.  I need to know which object you are looking at.'
  if N_elements(center) eq 0 then $
     message, 'ERROR: center keyword missing.  I need to know which object you are looking at.'
  if N_elements(tlist) eq 0 then $
     message, 'ERROR: tlist keyword missing.  I need to know what times you want calculations.  If you don''t care for particular times, you can use the web interface with CSV output'

  if size(/type, command) ne !tok.string then $
     message, 'ERROR: command must be a string (e.g. ''501'' for Io.  The strtrim(num, 2) command is handy to generate the string from a number)'
  if size(/type, center) ne !tok.string then $
     message, 'ERROR: center must be a string (e.g. ''695'' for Kitt Peak or ''500 @501'' of Io body center)'

  ;; Open our file for writing, getting our unit number and storing it
  ;; in eru (ephemeris request unit)
  openw, eru, fname, /get_lun

  printf, eru, '!$$SOF (ssd)       JPL/Horizons Execution Control VARLIST        
  printf, eru, '
  ;; Write out our COMMAND, which tells HORIZONS which object we are
  ;; looking at.  Doesn't need quotes around it if it is an
  ;; isolated command (e.g. command = '501' is the same as command = 501)
  printf, eru, " COMMAND    = ", command
  printf, eru, ""
  printf, eru, " OBJ_DATA   = 'NO'"
  printf, eru, " MAKE_EPHEM = 'YES'" 
  printf, eru, " TABLE_TYPE = 'OBS' "
  printf, eru, " CENTER    = ", center
  if keyword_set(coord_type) then $
       printf, eru, " COORD_TYPE    = ", coord_type
  ;; quotes are required here
  if keyword_set(site_coord) then $
       printf, eru, " SITE_COORD    = '", site_coord, "'"
  printf, eru, ""

  ;; Write our TLIST
  printf, eru, "TLIST= "
  for it=0,N_elements(tlist)-1 do begin
     printf, eru, format='("''", D18.8, "''")', tlist[it]
  endfor

  printf, eru, ""

  ;; Get all quantities, since disk space and bandwidth are cheap.
  ;; This could be changed later.
  printf, eru, " QUANTITIES = 'A'"
  ;; It is important for eph_get_col that things be generated in CSV format
  printf, eru, " CSV_FORMAT = 'YES'"

  ;; These and other quantities could be changed by optional keywords
  ;; at some future version.
  printf, eru, " REF_SYSTEM = 'J2000'"
  printf, eru, " CAL_FORMAT = 'BOTH'"
  printf, eru, " ANG_FORMAT = 'DEG'"
  printf, eru, " APPARENT   = 'AIRLESS'"
  printf, eru, " TIME_DIGITS = 'FRACSEC'"
  printf, eru, " TIME_ZONE   = '+00:00'"
  printf, eru, " RANGE_UNITS = 'AU'"
  printf, eru, " SUPPRESS_RANGE_RATE= 'NO'"
  printf, eru, " ELEV_CUT   = '-90'"
  printf, eru, " SKIP_DAYLT = 'NO'"
  printf, eru, ' SOLAR_ELONG= "0,180"'
  printf, eru, " AIRMASS    = '38.0'"
  printf, eru, " EXTRA_PREC = 'NO'"
  printf, eru, " R_T_S_ONLY = 'NO'"
  printf, eru, "!$$EOF++++++++++++++++++++++++++++++++++++++++++++++++++++++"

  ;; Close our file and free the lun
  free_lun, eru

end
