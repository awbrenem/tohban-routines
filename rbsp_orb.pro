;+
; Type: procedure.
; Purpose: Calculate future collection times, using given apogee time.
; Parameters:
;   probe: string, in, req. 'a' or 'b'.
;   reftime: string, in, req. Reference time, ususally be the apogee time.
;       Can be in DOY or any formats accepted by time_double.
;   mode: string, in, optional. Known collection modes.
; Keywords:
;   norbit, int, in, opt. Number of orbit to calculate, default is 15.
; Notes: none.
; Dependence: tdas.
; History:
;   2014-03-14, Sheng Tian, create.
;-

pro rbsp_orb, probe, reftime, norbit = norb, mode = mode
    on_error, 0

    ; allow fussy order of probe and reftime.
    if n_params() ne 2 then message, 'need probe and time ...'
    if strlen(reftime) eq 1 then begin    ; switch probe and reftime.
        tmp = reftime & reftime = probe & probe = tmp
    endif
    lun = -1    ; console.

; **** modify this part to change collection mode.
; 
;   In certain collection mode, for each orbit of collection,
;   there may be 1 or more chunks of collections.
;   Each chunk may have distinct duration, sample rate.
;   There may be padding time between chunks, padding time have to be > 1 min.
;
;       mode, sets the current collection mode.
;       duras, chunk duration in hr for each chunk in one orbit.
;       rates, sample rate in kHz, or ksample/sec.
;       tpres, padding minutes, make certain chunk starts later.
;       tafts, padding minutes, make certain chunk ends sooner.
;   
;   This collection mode is a fixed pattern. We will place this pattern
;   with respect to certain reference time, usually the apogee time.
;
;       dtref, in hour, reference time - the beginning of collection.
;   
;   We use this code to automatically generate many orbits of collections.
;
;       norb, sets how many orbits to print.
;
;   Orbital period decays slowly, use consecutive apogee times to recalc
;   the period if needed.
;
;   Each mode may have its own convenient format, modify the 'print results'
;   part if needed.

;    if n_elements(mode) eq 0 then mode = '8k16k8k141'
    if n_elements(mode) eq 0 then mode = '16k2k'

    if n_elements(norb) eq 0 then norb = 15
    
    case mode of
        ; -/+2hr @16k around apogee, -/+1hr @8k around 16k collection.
        '8k16k8k141': begin
            if probe eq 'a' then begin
                duras = [1,4,1]
                rates = [8,16,8]
                tpres = [0,0,1]
                tafts = [1,0,0]
                dtref = 3
            endif else begin
                duras = [1,4,1]
                rates = [8,16,8]
                tpres = [0,0,1]
                tafts = [1,0,0]
                dtref = 3
            endelse
        end
        ; -3.5hr/+1hr @16k around apogee, 2hr @2k after 16k collection.
        '16k2k': begin
            if probe eq 'a' then begin
                duras = [4.5,2]
                rates = [16,2]
                tpres = [0,1]
                tafts = [1,0]
                dtref = 3.5
            endif else begin
                duras = [4.5,2]
                rates = [16,2]
                tpres = [0,1]
                tafts = [1,0]
                dtref = 3.5
            endelse
        end
        ; -/+2.5hr @4k around apogee.
        else: begin
            if probe eq 'a' then begin
                duras = [5]
                rates = [4]
                tpres = [0]
                tafts = [0]
                dtref = 2.5
            endif else begin
                duras = [5]
                rates = [4]
                tpres = [0]
                tafts = [0]
                dtref = 2.5
            endelse

            end
    endcase

    ncoll = n_elements(duras)

    
; **** determine reference time, usually be the apogee time.
    tmp = strsplit(reftime,'-')
    doy = (n_elements(tmp) eq 2)? 1: 0
    if keyword_set(doy) then $
        tapo = time_double(reftime,tformat='YYYY-DOY/hh:mm:ss') $
    else tapo = time_double(reftime)
    
    tref0 = tapo-dtref*3600d  ; start time of 1st chunk.

    
; **** figure out orbital period.

    scatapos = [$
        '2015-292/05:02:28', $
        '2015-292/13:59:35', $
        '2015-292/22:56:42', $
        '2015-293/07:53:49', $
        '2015-293/16:50:56', $
        '2015-294/01:48:03', $
        '2015-294/10:45:10', $
        '2015-294/19:42:17', $
        '2015-295/04:39:24', $
        '2015-295/13:36:31', $
        '2015-295/22:33:37']

    scbtapos = [$
        '2015-292/05:55:13', $
        '2015-292/14:58:24', $
        '2015-293/00:01:34', $
        '2015-293/09:04:45', $
        '2015-293/18:07:55', $
        '2015-294/03:11:06', $
        '2015-294/12:14:16', $
        '2015-294/21:17:27', $
        '2015-295/06:20:37', $
        '2015-295/15:23:48']

    apotimes = (probe eq 'a')? scatapos: scbtapos
    apotimes = time_double(apotimes,tformat='YYYY-DOY/hh:mm:ss')
    periods = apotimes[1:*]-apotimes[0:n_elements(apotimes)-2]
    period = mean(periods)
    stddev = stddev(periods)
    printf, lun, ''
    printf, lun, 'RBSP-'+strupcase(probe)+' period (sec): '+string(period)
    printf, lun, 'RBSP-'+strupcase(probe)+' period (hr): '+string(period/3600d)
    printf, lun, 'RBSP-'+strupcase(probe)+' stddev (sec): '+string(stddev)
    printf, lun, ''

    ; period for a is 8.9781349 hr, for b is 9.0277778 hr.
    if probe eq 'a' then period = 32321.286d else period = 32500d
    
    ; updated period 2015-09-24.
    ; period for a is 8.9762698 hr, for b is 9.0277778 hr.
    if probe eq 'a' then period = 32314.571d else period = 32500d
    
    ; updated period 2015-10-11.
    ; period for a is 8.9531746 hr, for b is 9.0277778 hr.
    if probe eq 'a' then period = 32231.429d else period = 32500d

    ; updated period 2015-10-18.
    ; period for a is 8.9519167 hr, for b is 9.0529321 hr.
    if probe eq 'a' then period = 32226.900d else period = 32590.556d


; **** collection start and end times and sample rate.
    infos = make_array(norb, ncoll, value = {tsta:0d, tend:0d, rate:''})
        for i = 0, norb-1 do begin
            tref = tref0+i*period
            for j = 0, ncoll-1 do begin
                infos[i,j].tend = tref+total(duras[0:j])*3600d
                infos[i,j].tsta = infos[i,j].tend-duras[j]*3600d
                infos[i,j].tsta+= tpres[j]*60d
                infos[i,j].tend-= tafts[j]*60d
                infos[i,j].rate = string(rates[j]*1024,format='(I5)')
            endfor
    endfor


; **** print results.
    
    case mode of
        ; print 8k for 6hr, interrupt by 16k for 4hr.
        '8k16k8k141': begin
            printf, lun, ''
            printf, lun, 'RBSP-'+strupcase(probe)+', time of collection'
            printf, lun, ''
            printf, lun, 'RBSP-'+strupcase(probe)+' 8k collection:'
            for i = 0, norb-1 do begin
                printf, lun, $
                    time_string(infos[i,0].tsta,tformat='YYYY-MM-DD/hh:mm')+'  to  '+$
                    time_string(infos[i,2].tend,tformat='YYYY-MM-DD/hh:mm')
            endfor
            printf, lun, ''
            printf, lun, 'Interrupted by 16k collections:'
            for i = 0, norb-1 do begin
                printf, lun, $
                    time_string(infos[i,1].tsta,tformat='YYYY-MM-DD/hh:mm')+'  to  '+$
                    time_string(infos[i,1].tend,tformat='YYYY-MM-DD/hh:mm')
            endfor
        end

        else: begin
            ; print according to sample rate, high sample rate first.
            rateorder = reverse(rates[sort(rates)])
            rateorder = rateorder[uniq(rateorder)]
            printf, lun, ''
            printf, lun, 'RBSP-'+strupcase(probe)+', time of collection'
            for k = 0, n_elements(rateorder)-1 do begin
                trate = string(rateorder[k]*1024,format='(I5)')
                printf, lun, ''
                printf, lun, 'RBSP'+strupcase(probe)+' '+string(rateorder[k],format='(I0)')+'k collection:'
                for i = 0, norb-1 do begin
                    for j = 0, ncoll-1 do begin
                        if infos[i,j].rate eq trate then $
                            printf, lun, $
                                time_string(infos[i,j].tsta,tformat='YYYY-MM-DD/hh:mm')+'  to  '+$
                                time_string(infos[i,j].tend,tformat='YYYY-MM-DD/hh:mm')
                    endfor
                endfor
            endfor
        end
    endcase
    
    printf, lun, ''
    printf, lun, 'Same collection times, in format for rbsp_b1_predict_plot'
    for i = 0, norb-1 do begin
        for j = 0, ncoll-1 do begin
            printf, lun, "    [time_double(['" + $
                time_string(infos[i,j].tsta,tformat='YYYY-MM-DD/hh:mm')+"', '" + $
                time_string(infos[i,j].tend,tformat='YYYY-MM-DD/hh:mm')+"']),"+ $
                infos[i,j].rate+'],$'
        endfor
    endfor

end

rbsp_orb, 'b', '2015-10-13/12:00', mode = '8k16k8k141'
end
