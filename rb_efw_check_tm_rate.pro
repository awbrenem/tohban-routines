;+

;

;-

pro rb_efw_check_tm_rate, probe, date, duration

if n_elements(probe) eq 0 then probe = 'a'
if n_elements(duration) eq 0 then duration = 6.0   ; days.
if n_elements(date) eq 0 then $
    date = time_string(systime(1)-(systime(1) mod 86400d)-duration*86400d)
timespan, date, duration+1, /days
rbx = string( probe, format='("rbsp",A)')

; load housekeeping data.
rbsp_load_efw_hsk, probe=probe, /get_support

options, '*_B1_RECPTR', 'ytickformat', '(I6.6)'
options, '*_B1_PLAYPTR', 'ytickformat', '(I6.6)'
options, '*_B1_PLAYPTR', 'ystyle', 18

get_data, rbx+'_efw_hsk_idpu_eng_SC_EFW_SSR', data=d
efw_ssr_alloc = 316964864L  ;bytes; R. Barnes, e-mail, 28 Aug 2013.
efw_ssr_bits = rbx + '_efw_hsk_EFW_SSR_BITS'
store_data, efw_ssr_bits, data = { x:d.x, y:d.y*double( efw_ssr_alloc)*8.d/100.d}

; estimate block and data rates from HSK.
dt_interpol = 600.  ; s.
b1_playptr_deriv_lim = 0.1  ; blks/s.

get_data, rbx+'_efw_hsk_idpu_fast_B1_PLAYPTR', data=d

; compute new sample time array.
t1 = min( d.x)
t2 = max( d.x)
ntt = ceil( (t2-t1)/dt_interpol)
tt = t1 + dt_interpol*dindgen( ntt)

yy = interpol( d.y, d.x, tt)
dyy = deriv( tt, yy)
idx = where( abs( dyy) gt b1_playptr_deriv_lim, icnt)
if icnt gt 0L then dyy[ idx] = !values.f_nan

store_data, rbx+'_efw_hsk_B1_PLAYPTR_interp', data={ x:tt, y:yy}
store_data, rbx+'_efw_hsk_B1_PLAYPTR_deriv', data={ x:tt, y:dyy}

vars = rbx+'_efw_hsk_*'
options, vars, 'ystyle', 18
options, vars, 'colors', [ 2]
options, vars, 'labflag', 1
options, vars, 'thick', 2.0
options, vars, 'ticklen', 1.0
options, vars, 'xgridstyle', 1
options, vars, 'ygridstyle', 1

options, '*_B1_PLAYPTR*', 'ytickformat', '(I6.6)'
options, '*_B1_PLAYPTR_deriv', 'ytickformat', '(F7.4)'

tplot_options, 'xmargin', [ 20., 10.]

;tplot, [ '*B2_OUTPTR', '*B1_PLAYPTR', '*SSR', '*_EFW_SSR_BITS']
;tplot,['*B1_PLAYPTR*','*B1_RECPTR*','*SSR*']
;tplot,['*RSTCTR*','*RSTFLAG*','*ERR*']    

vars = ['*_hsk_idpu_fast_B1_PLAYPTR','*B1_PLAYPTR_deriv', $
        '*hsk_idpu_fast_B1_RECPTR','*efw_hsk_idpu_eng_SC_EFW_SSR',$
        '*IBIAS1','*IBIAS2','*RSTCTR*','*RSTFLAG*','*ERR*']
        
tplot, vars


end
