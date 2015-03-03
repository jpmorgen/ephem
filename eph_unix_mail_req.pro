;+
; NAME:
;
; PURPOSE:
;
; CATEGORY:
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
; $Id: eph_unix_mail_req.pro,v 1.1 2015/03/03 20:39:18 jpmorgen Exp $
;
; $Log: eph_unix_mail_req.pro,v $
; Revision 1.1  2015/03/03 20:39:18  jpmorgen
; Initial revision
;
;-
pro eph_unix_mail_req, $
   MH_dir=MH_dir, $ ;; directory where mail is dropped as individual numbered MH files (procmail may be required, see code)
   fnames=fnames, $ ;; ephemeris file name(s)
   outnames=outnames, $ ;; names of the files into which the individual HORZONS emails were put
   timeout=timeout, $
   N_new_files=N_new_files ;; allows for cases where there is not one return HORIZONS email per input filename

  if !version.os_family ne 'unix' then $
     message, 'ERROR: I don''t know how to handle mail in this environment'     

  message, /INFORMATIONAL, 'NOTE: sending email request to HORIZONS.  Successful output depends on email and procmail being set up properly.  See code.'
  ;; First of all, the command "mail" needs to do the right thing.
  ;; This assumes the presence of a UNIX-like mail command to send
  ;; the mail to HORIZONS

  ;; We assume the email comes back to the email account of the
  ;; current user and that user is are using procmail or some other
  ;; mail filter, to capture the return email and put it in a
  ;; particular directory as a numbered file.  This is done with
  ;; procmail by making a .forward containing

  ;; |/usr/bin/procmail

  ;; and a .procmailrc with

  ;; :0 c
  ;; * ^From.*Horizons Ephemeris System
  ;; /data/io/ssg/analysis/ephemerides/.

  ;; Search through all of the files in the directory for numbered
  ;; files which would be from previous runs of the HORIZONS
  ;; ephemerides processed by procmail, as described above.
  if NOT keyword_set(MH_dir) then $
     message, 'ERROR: MH_dir keyword must be set to the directory that your emial system drops the ephemeris files (see code for how to use procmail in a cool way to do this.'
  
  files = stregex(file_basename(file_search(MH_dir + path_sep() + '*')), '^[0-9]+$', /extract)
  ;; stregex extracts empty strings for non-matching entries.
  ;; Remove them
  good_idx = where(files ne '', N_orig_files)
  ;; Figure out how many more files we expect.  Let the user input
  ;; this number in case they have multiple objects on their command.
  ;; Otherwise, assume there will be just one return
  if NOT keyword_set(N_new_files) then $
     N_new_files = 1

  ;; Send our email command(s)
  for ifi=0, N_elements(fnames)-1 do begin
     spawn, 'mail -s JOB horizons@ssd.jpl.nasa.gov < ' + fnames[ifi], txtout, errout
     if errout ne '' then $
        message, 'ERROR:, mail command returned: ' + errout
  endfor ;; each file

  ;; Now we are in asyncronous land.  Keep checking our directory
  ;; until we timeout or have more files
  starttime = systime(/seconds)
  ;; Default timeout is 20 minutes.
  if NOT keyword_set(timeout) then $
     timeout = 20 ;; min

  repeat begin
     ;; Don't check too often so as to avoid unecessary load
     ;; on the OS
     wait, 30 ;; seconds
     files = stregex(file_basename(file_search(MH_dir + path_sep() + '*')), '^[0-9]+$', /extract)
     good_idx = where(files ne '', N_files)
     fail = systime(/seconds) - starttime ge timeout*60d
  endrep until fail or N_files - N_orig_files eq N_new_files

  ;; Return new filenames in outnames keyword
  if fail then begin
     message, /CONTINUE, 'WARNING: expected files not received from HORIZONS within ' + strtrim(timeout, 2) + ' min.  Is your email/procmail system set up properly?  It is not the end of the world if it is not.  If the HORIZONS answers are not in your regular email, send the file ' + fnames + ' to horizons@ssd.jpl.nasa.gov with the subject JOB.'
  endif else begin
     ;; Now we have to be careful with numeric order, since the
     ;; files are returned in alphabetical order <sigh>
     files = fix(files[good_idx])
     sidx = sort(files)
     outnames = MH_dir + path_sep() + strtrim(files[sidx[N_orig_files:N_orig_files+N_new_files-1]], 2)
     message, /CONTINUE, 'NOTE: received the following files back from HORIZONS.  These may be captured in the outnames keyword.'
     print, outnames
  endelse ;; success

end
