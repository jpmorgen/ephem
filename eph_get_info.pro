;+
; NAME: eph_get_info
;
; PURPOSE: read HORIZONS ephemeris file and return various values in keywords
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
; $Id: eph_get_info.pro,v 1.1 2013/01/18 14:38:39 jpmorgen Exp $
;
; $Log: eph_get_info.pro,v $
; Revision 1.1  2013/01/18 14:38:39  jpmorgen
; Initial revision
;
;-
pro eph_get_info, $
   fname_or_lun, $
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

  line = ''

  ;; Look for the subject line of the email, since that has the most
  ;; technical description of the observer and target
  ;; Subject: MAJOR BODY #C(695@399)_T(501) (1/1
  repeat begin
     readf, elun, line
     a = strpos(line, 'Subject:')
  endrep until a eq 0  

  ;; Extract center body
  repeat begin
     readf, elun, line
     a = strpos(line, 'Center body name:')
  endrep until a eq 0
  p1 = strpos(line, '(')
  p2 = strpos(line, ')')
  observer = strmid(line, p1+1, p2-1)


  ;; --> maybe I should read things from the subject line, since that
  ;; has the clearest statement of the cneter and target
  repeat begin
     readf, elun, line
     a = strpos(line, 'Target body name:')
  endrep until a eq 0

  ;; Extract the target body
  p1 = strpos(line, '(')
  p2 = strpos(line, ')')
  target = fix(strmid(line, p1+1, p2-1))


  ;; --> Add more as needed.

  ;; Close our file and free the lun, if we were the ones who opened it
  if size(/type, fname_or_lun) eq !tok.string then $
     free_lun, elun

end
