; +
; $Id: eph_sysvar__define.pro,v 1.2 2014/01/24 21:16:19 jpmorgen Exp $

; eph_sysvar__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  So call explicitly with an
; argument if you need to have a default structure with different
; initial values, or as in the case here, store the value in a system
; variable.

;; This defines the !eph system variable, which contains handy tokens
;; for the JPL ephemerides system.  THese tokes were taken from
;;
;; http://ssd.jpl.nasa.gov/horizons_doc.html
;;
;; on Tue Dec 30 19:15:36 2003  jpmorgen

; -

pro eph_sysvar__define, top
  ;; System variables cannot be redefined and named structures cannot
  ;; be changed once they are defined, so it is OK to check this right
  ;; off the bat
  defsysv, '!eph', exists=exists
  if exists eq 1 then begin
     if keyword_set(top) then $
       !eph.top = top
     return
  endif

  if N_elements(top) eq 0 then $
    top = '/data/NAIF'

  eph $
    = {eph_sysvar, $
       top		:	top, $
       jd_reduced	:	2400000.d, $
       kernels_loaded:	0, $
       p_idx		:	[0,1,2], $ ;; state vector indices
       v_idx		:	[3,4,5], $
       s_ssb		:	make_array(6, value=0d), $
       ssb		:	000, $
       sun		:	010, $  
       $ ;;
       mercury_bary	:	001, $ 
       mercury		:	199, $ 
       $ ;;
       venus_bary	:	002, $ 
       venus		:	299, $ 
       $ ;;
       earth_bary  	:	003, $ 
       earth       	:	399, $ 
       moon        	:	301, $ 
       $ ;;
       mars_bary   	:	004, $ 
       mars        	:	499, $ 
       phobos      	:	401, $ 
       deimos      	:	402, $ 
       $ ;;
       jupiter_bary	:	005, $ 
       jupiter     	:	599, $ 
       io          	:	501, $ 
       europa      	:	502, $ 
       ganymede    	:	503, $ 
       callisto    	:	504, $ 
       amalthea    	:	505, $ 
       himalia     	:	506, $ 
       elara       	:	507, $ 
       pasiphae    	:	508, $ 
       sinope      	:	509, $ 
       lysithea    	:	510, $ 
       carme       	:	511, $ 
       ananke      	:	512, $ 
       leda        	:	513, $ 
       thebe       	:	514, $ 
       adrastea    	:	515, $ 
       metis       	:	516, $ 
       $ ;;
       saturn_bary 	:	006, $ 
       saturn      	:	699, $ 
       mimas       	:	601, $ 
       enceladus   	:	602, $ 
       tethys      	:	603, $ 
       dione       	:	604, $ 
       rhea        	:	605, $ 
       titan       	:	606, $ 
       hyperion    	:	607, $ 
       iapetus     	:	608, $ 
       phoebe      	:	609, $ 
       janus       	:	610, $ 
       epimetheus  	:	611, $ 
       helene      	:	612, $ 
       telesto     	:	613, $ 
       calypso     	:	614, $ 
       atlas       	:	615, $ 
       prometheus  	:	616, $ 
       pandora     	:	617, $ 
       pan         	:	618, $ 
       $ ;;
       uranus_bary 	:	007, $ 
       uranus      	:	799, $ 
       ariel       	:	701, $ 
       umbriel     	:	702, $ 
       titania     	:	703, $ 
       oberon      	:	704, $ 
       miranda     	:	705, $ 
       cordelia    	:	706, $ 
       ophelia     	:	707, $ 
       bianca      	:	708, $ 
       cressida    	:	709, $ 
       desdemona   	:	710, $ 
       juliet      	:	711, $ 
       portia      	:	712, $ 
       rosalind    	:	713, $ 
       belinda     	:	714, $ 
       puck        	:	715, $ 
       caliban     	:	716, $ 
       sycorax     	:	717, $ 
       u10		:	718, $ 
       u1    		:	719, $ 
       u2    		:	720, $ 
       u3    		:	721, $ 
       $ ;;
       neptune_bary	:	008, $ 
       neptune     	:	899, $ 
       triton      	:	801, $ 
       nereid      	:	802, $ 
       naiad       	:	803, $ 
       thalassa    	:	804, $ 
       despina     	:	805, $ 
       galatea     	:	806, $ 
       larissa     	:	807, $ 
       proteus     	:	808, $ 
       $ ;;
       pluto_bary  	:	009, $ 
       pluto       	:	999, $ 
       charon      	:	901, $ 
       $ ;; Sample object tokens for non-solar system objects.  
       $ ;; Customize as needed (also below)
       cal	:	11,   $  ;; Calibration sources (e.g. comp lamp)
       tel	:	12,   $  ;; Telescope effects
       atm	:	13,   $  ;; atmosphere
       ipm	:	14,   $  ;; iterplanetary medium
       sso	:	15,   $  ;; solar system object
       rsun	:	16,   $  ;; reflected sunlight
       ism	:	17,   $  ;; interstellar medium
       gal	:	18,   $  ;; Galactic
       igm	:	19,   $  ;; intergalactic medium
       extragal	:	20,   $  ;; extragalactic object
       cosmo	:	21,   $  ;; cosmological object
       obj	:	22,   $  ;; unspecified object
       back	:	23,   $	 ;; unspecified background
       names		:	strarr(1000)}

  eph.names[000] = 'Solar System Barycenter'
  eph.names[010] = 'Sun'

  eph.names[001] = 'Mercury barycenter'
  eph.names[199] = 'Mercury'

  eph.names[002] = 'Venus barycenter'
  eph.names[299] = 'Venus'

  eph.names[003] = 'Earth barycenter'
  eph.names[399] = 'Earth'
  eph.names[301] = 'Moon'

  eph.names[004] = 'Mars barycenter'
  eph.names[499] = 'Mars'
  eph.names[401] = 'Phobos'
  eph.names[402] = 'Deimos'

  eph.names[005] = 'Jupiter barycenter'
  eph.names[599] = 'Jupiter'
  eph.names[501] = 'Io'
  eph.names[502] = 'Europa'
  eph.names[503] = 'Ganymede'
  eph.names[504] = 'Callisto'
  eph.names[505] = 'Amalthea'
  eph.names[506] = 'Himalia'
  eph.names[507] = 'Elara'
  eph.names[508] = 'Pasiphae'
  eph.names[509] = 'Sinope'
  eph.names[510] = 'Lysithea'
  eph.names[511] = 'Carme'
  eph.names[512] = 'Ananke'
  eph.names[513] = 'Leda'
  eph.names[514] = 'Thebe'
  eph.names[515] = 'Adrastea'
  eph.names[516] = 'Metis'

  eph.names[006] = 'Saturn barycenter'
  eph.names[699] = 'Saturn'
  eph.names[601] = 'Mimas'
  eph.names[602] = 'Enceladus'
  eph.names[603] = 'Tethys'
  eph.names[604] = 'Dione'
  eph.names[605] = 'Rhea'
  eph.names[606] = 'Titan'
  eph.names[607] = 'Hyperion'
  eph.names[608] = 'Iapetus'
  eph.names[609] = 'Phoebe'
  eph.names[610] = 'Janus'
  eph.names[611] = 'Epimetheus'
  eph.names[612] = 'Helene'
  eph.names[613] = 'Telesto'
  eph.names[614] = 'Calypso'
  eph.names[615] = 'Atlas'
  eph.names[616] = 'Prometheus'
  eph.names[617] = 'Pandora'
  eph.names[618] = 'Pan'

  eph.names[007] = 'Uranus barycenter'
  eph.names[799] = 'Uranus'
  eph.names[701] = 'Ariel'
  eph.names[702] = 'Umbriel'
  eph.names[703] = 'Titania'
  eph.names[704] = 'Oberon'
  eph.names[705] = 'Miranda'
  eph.names[706] = 'Cordelia'
  eph.names[707] = 'Ophelia'
  eph.names[708] = 'Bianca'
  eph.names[709] = 'Cressida'
  eph.names[710] = 'Desdemona'
  eph.names[711] = 'Juliet'
  eph.names[712] = 'Portia'
  eph.names[713] = 'Rosalind'
  eph.names[714] = 'Belinda'
  eph.names[715] = 'Puck'
  eph.names[716] = 'Caliban'
  eph.names[717] = 'Sycorax'
  eph.names[718] = '(1986U10)'
  eph.names[719] = '(1999U1)'
  eph.names[720] = '(1999U2)'
  eph.names[721] = '(1999U3)'

  eph.names[008] = 'Neptune barycenter'
  eph.names[899] = 'Neptune'
  eph.names[801] = 'Triton'
  eph.names[802] = 'Nereid'
  eph.names[803] = 'Naiad'
  eph.names[804] = 'Thalassa'
  eph.names[805] = 'Despina'
  eph.names[806] = 'Galatea'
  eph.names[807] = 'Larissa'
  eph.names[808] = 'Proteus'

  eph.names[009] = 'Pluto barycenter'
  eph.names[999] = 'Pluto'
  eph.names[901] = 'Charon'

  ;; Sample object tokens for non-solar system objects.  
  ;; Customize as needed (also above)
  eph.names[11] = 'cal'		;; Calibration sources (e.g. comp lamp)
  eph.names[12] = 'tel'		;; Telescope effects
  eph.names[13] = 'atm'		;; atmosphere
  eph.names[14] = 'ipm'		;; iterplanetary medium
  eph.names[15] = 'sso'		;; solar system object
  eph.names[16] = 'rsun'	;; reflected sunlight
  eph.names[17] = 'ism'		;; interstellar medium
  eph.names[18] = 'gal'		;; Galactic
  eph.names[19] = 'igm'		;; intergalactic medium
  eph.names[20] = 'extragal' 	;; extragalactic object
  eph.names[21] = 'cosmo'    	;; cosmological object
  eph.names[22] = 'obj'      	;; unspecified object
  eph.names[23] = 'back'     	;; unspecified background

  defsysv, '!eph', eph

end
