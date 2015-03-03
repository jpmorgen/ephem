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
; $Id: eph_get_info.pro,v 1.2 2015/03/03 20:37:37 jpmorgen Exp $
;
; $Log: eph_get_info.pro,v $
; Revision 1.2  2015/03/03 20:37:37  jpmorgen
; Summary: Check in for git
;
; Revision 1.1  2013/01/18 14:38:39  jpmorgen
; Initial revision
;
;-
pro eph_get_info, $
   fname_or_lun, $
   target=target, $
   observer=observer

  init = {tok_sysvar}

  ;; Set up a CATCH so that we can free our lun, if we opened it
  CATCH, err
  if err ne 0 then begin
     CATCH, /CANCEL
     if size(/type, fname_or_lun) eq !tok.string then $
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

  line = ''

  ;; Look for the subject line of the email, since that has the most
  ;; technical description of the observer and target
  ;; Subject: MAJOR BODY #C(695@399)_T(501) (1/1)
  repeat begin
     ON_IOERROR, rlerr
     readf, elun, line
     ;; Hide our error label in a statement that doesn't
     ;; normally get executed
     if 0 then begin
        rlerr: 
        message, 'ERROR: unexpected IO error while searching for Subject line '
     endif ;; file I/O error condition

     ;; If we made it here, we have sucessfully read in another line
     ;; from the file.  Look for the Subject line of the email
     a = strpos(line, 'Subject:')

  endrep until a eq 0  

  ;; Extract center body
  p1 = strpos(line, '#C(')
  p2 = strpos(line, ')', p1)
  ;; Return as string since it has the @ in it
  observer = strmid(line, p1+3, p2-(p1+3))

  ;; Extract the target body.  Start search beyond first set of parenthesis
  p1 = strpos(line, '_T(')
  p2 = strpos(line, ')', p1)
  ;; Return as integer
  target = fix(strmid(line, p1+3, p2-(p1+3)))

  ;; --> Add more as needed.

  ;; Close our file and free the lun, if we were the ones who opened it
  if size(/type, fname_or_lun) eq !tok.string then $
     free_lun, elun

end
