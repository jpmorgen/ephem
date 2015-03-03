;+
; NAME: eph_load_kernels
;
;
;
; PURPOSE: Make sure kernels are loaded for objects listed in the objs
; for time UT 
;
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;
;
;
; INPUTS: UT, objs
;
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:  
;
;   Common blocks are ugly.  Consider using package-specific system
;   variables.
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS: 
;
;   This code is highly dependent on the kernels that are available on
;   disk.  Please modify it as needed.
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
; $Id: eph_load_kernels.pro,v 1.2 2015/03/03 20:38:37 jpmorgen Exp $
;-

pro eph_load_kernels, UT, objs


  init = {eph_sysvar}



  ;; dtpool and gnpool are broken right now, so just use a temporary
  ;; system variable for the ssg appliction.

  if !eph.kernels_loaded then return

  
  ;; Leap seconds and relativistic corrections to get from Coordinated
  ;; Universal Time (UTC) to Barycentric Dynamical Time (TDB) also
  ;; called Ephemeris Time (ET)
  cspice_furnsh, !eph.top + '/generic_kernels/lsk/naif0010.tls'
  ;; Basic planetary constants, including orientation and radius values
  cspice_furnsh, !eph.top + '/generic_kernels/pck/pck00010.tpc'
  ;; An alias for ITRF93
  cspice_furnsh, !eph.top + '/generic_kernels/pck/earth_fixed.tf'
  ;; The ITR93A earth rotation model.  This goes from 1972 to April 2007
  cspice_furnsh, !eph.top + '/generic_kernels/pck/earth_720101_070426.bpc'
  ;; This extends the above rotation model to 2023.
  cspice_furnsh, !eph.top + '/generic_kernels/pck/earth_070425_370426_predict.bpc'
  ;; Orbit paths for Earth and Jupiter barycenters, Sun + Galilean
  ;; satellites and a few of the small Jovian moons 1900 -- 2100
  cspice_furnsh, !eph.top + '/generic_kernels/spk/satellites/jup310.bsp'

  !eph.kernels_loaded = 1

  return

  ;; CODE CAN'T BE USED UNTIL cspice_dtpool et al. are fixed

  ;; MODIFY THESE AS LEAP SECONDS OR LACK THEREOF BECOME KNOWN.  You
  ;; can download the latest leapsecond kernel file from:
  ;; ftp@naif.jpl.nasa.gov:/pub/naif/generic_kernels/lsk
  ;; or check on the status of leap seconds at:
  ;; http://www.iers.org
  leap_sec_file = !eph.top + '/generic_kernels/lsk/naif0010.tls'
  good_through = '2012-JUL-1'



  ;; dtpool and gnpool are broken right now, so just use a temporary
  ;; system variable for the ssg appliction.

  ;; First check to see if a time kernel is loaded.  Time kernels have
  ;; leap seconds and relativistic corrections to get from Coordinated
  ;; Universal Time (UTC) to Barycentric Dynamical Time (TDB) also
  ;; called Ephemeris Time (ET)
  cspice_dtpool, 'DELTET/DELTA_T_A', found, n, dtype
  if found eq 0 then begin
     ;; Load the latest time kernel
     cspice_furnsh, leap_sec_file
  endif
  ;; Get the date through which the above leapsecond file is known to
  ;; be good
  cspice_str2et, good_through, last_leap_et
  ;; Check to see if our time is covered in this time kernel
  cspice_str2et, UT, et
  if et gt last_leap_et then begin
     message, 'WARNING: leapsecond file may be out of date.  Please update this procedure.'
  endif
  
  ;; APPLICATION SPECIFIC KERNELS.  Order is important here, since
  ;; kernel variables can get overwritten when they are re-read.
  ;; Since this routine might be called multiple times, unexpected
  ;; results might occur unless it is called _every_ time and the code
  ;; is designed carefully.
  
  ;; Check for barycenters
  bary_idx = where(objs gt 0 and objs lt 100, count)
  if count gt 0 then begin
     
  endif
  



  ;; Jupiter system
  jov_idx = where((objs ge 501 and objs le 599) or $
                  objs eq 5, count)
  if count gt 0 then begin
     cspice_gnpool, 'BODY' + !eph.io
  endif



  
end
