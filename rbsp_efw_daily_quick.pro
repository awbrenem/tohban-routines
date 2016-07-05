;+
; Type: crib.
; Purpose: Generate daily plot for rbsp efw, necessary for large file (>4GB).
; Parameters:
;   date, in, string, req. Any string accepted by time_double.
;   probe, in, string, req. Can only be 'a' or 'b'.
; Keywords:
;   del, in, int, opt. Set rec interval, default is 1000.
; Notes: none.
; Dependence: tdas.
; History:
;   2014-03-05, Sheng Tian, create.
;-

pro rbsp_efw_daily_quick, date, probe, del = recdel

    timespan, date, 1
    pre0 = 'rbsp'+probe+'_efw_'
    
    tplot_options, 'labflag', 1
    rbsp_efw_init
    !rbsp_efw.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/'


    print, 'load efw waveform, esvy and vb1 ...'
    rbsp_load_efw_waveform, probe = probe, type = 'calibrated', $
        datatype = ['esvy']
    rbsp_load_efw_waveform, probe = probe, type = 'calibrated', $
        datatype = ['vb1'], /downloadonly, files = fn

    ; throw away spin axis E in esvy.
    print, 'throw spin axis E field in esvy ...'
    get_data, pre0+'esvy', t0, tmp
    tmp[*,2] = 0
    store_data, pre0+'esvy', t0, tmp
    
    ; convert vb1 to eb1, 2-1, 3-4, throw away 56.
    print, 'get b1 E12 from vb1 ...'
    if n_elements(recdel) eq 0 then recdel = 1000
    cdfid = cdf_open(fn)
    cdf_control, cdfid, variable = 'epoch', get_var_info = vinfo, /zvariable
    maxrec = vinfo.maxrec+1
    nrec = maxrec/recdel
    cdf_varget, cdfid, 'epoch', et16, rec_start = 0, rec_interval = recdel, $
        rec_count = nrec
    et16 = transpose(et16)
    ; convert epoch16 to ut sec.
    t0 = real_part(et16)+imaginary(et16)*1d-12 - 62167219200D
;    t0 = sfmepoch(stoepoch(et16,'epoch16'),'unix')
    print, 'data rate: ', 1d/(t0[2]-t0[1])*recdel
    cdf_varget, cdfid, 'vb1', vb1, rec_start = 0, rec_interval = recdel, $
        rec_count = nrec
    vb1 = transpose(vb1)
    e12 = .1*(vb1[*,0]-vb1[*,1])
    vb1 = 0
    store_data, pre0+'e12b1', t0, e12, limits = {labels:'B1 E12!C  (mV/m)'}
    cdf_close, cdfid

    title = 'EFW daily plot, '+'RBSP-'+strupcase(probe)+', '+$
        time_string(systime(1)-6d*3600,tformat='YYYY-MM-DD')
    vars = pre0+['esvy','e12b1']
    tplot, vars, title = title
end
