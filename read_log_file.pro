
function rbsp_efw_week_prepare, struct, probe
    if n_elements(struct) eq 0 then return, -1   
    idx = where(struct.sat eq probe, cnt)
    if cnt eq 0 then return, -1
    tmp = struct[idx] & idx = sort(tmp.tr[0,*]) & tmp = tmp[idx]
    return, tmp
end


pro rbsp_efw_week_totplot, struct, vname, color, label
    dt = 1e-5
    deflim = {yrange:[-1,1], ytitle:'', ytickformat:'(A1)', $
        yticks:2, yminor:1, yticklen:0.01, thick:5, panel_size:0.1}
    if size(struct[0],/type) eq 8 then begin
        nrec = n_elements(struct) & x = dblarr(nrec*3)
        for i = 0, nrec-1 do x[i*3:i*3+2] = [struct[i].tr,struct[i].tr[1]+dt]
        y = dblarr(nrec*3) & y[2:*:3] = !values.d_nan
    endif else begin
        x = systime(1) & x = [x,x+dt]
        y = [0d,0d]
    endelse
    store_data, vname, x, y, limits = $
        create_struct(deflim, 'colors', color, 'labels', label)
end


pro read_log_file,probe

rbsp_efw_init

  compile_opt idl2

    tnowut = systime(1)                 ; current time in ut.
    tnowlt = tnowut-5D*3600             ; current time in local time.
    tdaylt = tnowlt-(tnowlt mod 86400)  ; start of current day.
    trbar = tdaylt+[-10,5]*86400D       ; -10/+5 day of current day.


    ;contacts = {sat:'',tr:[0D,0D]}
    playbacks = {sat:'',tr:[0D,0D],tmod:0D,mem:[0D,0D]}
    ;collections = {sat:'',tr:[0D,0D],rate:0D}
    downloads = {sat:'',tr:[0D,0D],tomod:0D}
    cancels = {sat:'',tr:[0D,0D],tomod:0D}


 ; read log file.
   ; tmp = routine_filepath('~/Desktop/code/scotts_tohban_changes/rbsp_efw_week')
   ; fnlog = file_dirname(tmp)+path_sep()+file_basename(tmp,'.pro')+'.log'
   ; if file_test(fnlog) eq 0 then message, 'cannot find log file ...'
   ; nentry = file_lines(fnlog)


   fnlog = '~/tohban/files/rbsp_efw_week.log'
   nentry = file_lines(fnlog)
   
    openr, lun, fnlog, /get_lun
    tline = ''
    for i = 0, nentry-1 do begin
        readf, lun, tline
        tmp = strsplit(tline, /extract)     ; use white space.
        case tmp[0] of
           ; 'contact': contacts = [contacts, $
            ;    {sat:tmp[1],tr:time_double(tmp[2:3],tformat='YYYY-DOY/hh:mm')}]
            'playback': playbacks = [playbacks, $
                {sat:tmp[1],tr:time_double(tmp[2:3]),tmod:time_double(tmp[4]),$
                mem:double(tmp[5:6])}]
  	;		'collection': collections = [collections, $
    ;            {sat:tmp[1],tr:time_double(tmp[2:3]),rate:double(tmp[4])}]
            'download': downloads = [downloads, $
                {sat:tmp[1],tr:time_double(tmp[2:3]),tmod:time_double(tmp[4])}]
            'canceled': cancels = [cancels, $
                {sat:tmp[1],tr:time_double(tmp[2:3]),tmod:time_double(tmp[4])}]
            else: ; do nothing.
        endcase
    endfor
    free_lun, lun


    ;contacts = contacts[1:*]
    playbacks = playbacks[1:*]
    ;collections = collections[1:*]
    downloads = downloads[1:*]
    cancels = cancels[1:*]

;conts = rbsp_efw_week_prepare(contacts, probe)
    plays = rbsp_efw_week_prepare(playbacks, probe)
    ;colls = rbsp_efw_week_prepare(collections, probe)
    downs = rbsp_efw_week_prepare(downloads, probe)
    cancs = rbsp_efw_week_prepare(cancels, probe)


pre0 = 'rbsp'+probe+'_efw_'

 ; plot status bars.
   ; rbsp_efw_week_totplot, conts, pre0+'contact', 6, 'contact'
    rbsp_efw_week_totplot, plays, pre0+'playback', 2, 'playback'
    ;rbsp_efw_week_totplot, colls, pre0+'collection', 0, 'collection'
    rbsp_efw_week_totplot, downs, pre0+'download', 4, 'download'
    rbsp_efw_week_totplot, cancs, pre0+'canceled', 1, 'canceled'

    vars = [pre0+['playback','download']]
    title = 'RBSP EFW week report, RBSP-'+strupcase(probe)
    tplot, vars, title = title
    timebar, tnowut

end


