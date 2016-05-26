;+
; Do the following things.
;   1, backup files: rbps_b1_predict_plot.pro, rbsp_efw_week.log, b1 webpage.
;   2, cleanup daily pdf plots.
;   3, find updated files: esvy, vsvy, spec, vb1.
;   4, for each updated vb1, do the following
;       a, run rbsp_efw_daily to download the data and save the plot.
;       b, find all chunk's start and end times and sample rate.
;       c, compare to rbsp_efw_week.log and find the updated part.
;       d, print updated chunk's info to log file, in the format used by rbsp_efw_week.log.
;       e, print updated chunk's info to log file, in the format used by RBSP_B1_log.xls.
;   5, download all updated spec data.
;
;   Note: when a playback spans two days, there may be a problem.
;
; Sheng, 2015-10-08.
;-

pro tohban_daily_update_curl_AB, year

; **** basic info.
	rbsp_efw_init
    !rbsp_efw.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/'
    if file_test('/Users/Shared/data/rbsp/',/directory) then $
        !rbsp_efw.local_data_dir = '/Users/Shared/data/rbsp/'
        
    ; probes, rbspa and rbspb.
    probes = ['a','b']
    nprobe = n_elements(probes)
    
    ; user and host.
    spawn, 'hostname', host
    usr = getenv('USER')
    usrhost = usr+'@'+host
    
    ; find root directory for tohban folder.
    dirs = strsplit(srootdir(),'/',/extract)
    ; assume this code is in <tobroot>/programs.
    tobroot = '/'+strjoin(dirs[0:n_elements(dirs)-3],'/')

    ; remote and local data directory.
    remroot = 'http://themis.ssl.berkeley.edu/data/rbsp'    ; remote URL root.
    case host of                     ; local root to save downloads.
        'm468h.space.umn.edu': locroot = '/Users/Shared/data/rbsp'
        else: locroot = getenv('HOME')+'/data/rbsp'
    endcase
    
    weeklog = tobroot+'/files/rbsp_efw_week.log'
    logfile = tobroot+'/files/daily_update.log'
    
    ; current unix time in UT and local time.
    utnow = systime(1)
    ltnow = time_double(systime(),tformat='Dow MTH DD hh:mm:ss YYYY')
    
    ; **** backup files.
    backupdir = tobroot+'/backups'+time_string(ltnow,tformat='/YYYY/MMDD')
    filedir = tobroot+'/files'
    file_mkdir, backupdir
    files = ['b1_cmd_crib.pro','b1_status.png','rbsp_b1_predict_plot.pro', $
    	'rbsp_efw_week.log','daily_update.log']
    for i = 0, n_elements(files)-1 do $
        file_copy, filedir+'/'+files[i], backupdir, /overwrite
    ; the webpages that have b1 update info.
    urls = '"'+remroot+'/rbsp'+probes+'/l1/vb1/'+$
        time_string(ltnow,tformat='YYYY')+'/?C=M;O=D"'
    for i = 0, nprobe-1 do spawn, $
        'curl '+urls[i]+' -o '+backupdir+'/rbsp'+probes[i]+'_vb1.html'

    openw, loglun, logfile, /get_lun
    printf, loglun, '**** Daily Update Log ****'
    printf, loglun, ''
    printf, loglun, '****'
    printf, loglun, ''
    printf, loglun, 'Backup files ...'
    printf, loglun, ''
    printf, loglun, 'Created at '+time_string(ltnow)
    printf, loglun, ''


; **** cleanup daily pdf.
    pdfs = file_search(filedir+'/*.pdf', count = cnt)
    if cnt ne 0 then for i = 0, cnt-1 do file_delete, pdfs[i]


; **** find newly updated cdfs.
    date = time_string(ltnow,tformat='DD-MTH-YYYY')
    printf, loglun, '****'
    printf, loglun, ''
    printf, loglun, 'Check newly updated B1 data ...'

    ; check esvy, vsvy, spec, vb1.
    vars = ['esvy','vsvy','spec','vb1']
    nvar = n_elements(vars)
    level = 'l1'        ; data level.
    str1 = time_string(ltnow,tformat='YYYY')     ; year.
    if n_elements(year) then str1 = year


    ; construct filename and path.
    files = strarr(nprobe,nvar)
    paths = strarr(nprobe,nvar)
    for i = 0, nprobe-1 do begin
        pre = 'rbsp'+probes[i]
        for j = 0, nvar-1 do begin
            str2 = '[0-9]{8}'   ; string used in file name, YYYYMMDD.
            if vars[j] eq 'spec' then str2 = '64_'+str2
            files[i,j] = strjoin([pre,level,vars[j],str2],'_')+'_v[0-9]{2}.cdf'
            paths[i,j] = strjoin([pre,level,vars[j],str1],'/')
        endfor
    endfor
    files = files[*]
    paths = paths[*]
    nfile = n_elements(files)

    ; find the newly updated cdfs.
    cdfs = ''
    cdfpaths = ''
    for i = 0, nfile-1 do begin
        locpath = locroot+'/'+paths[i]
        rempath = remroot+'/'+paths[i]
        if file_test(locpath,/directory) eq 0 then file_mkdir, locpath

        ; download the index html.
        html = locpath+'/.remote-index.html'
        spawn, 'curl "'+rempath+'/" -o "'+html+'"'

        ; read the index html to find which files are updated.
        nline = file_lines(html)
        lines = strarr(nline)
        openr, lun, html, /get_lun
        readf, lun, lines
        free_lun, lun
        
        for j = 0, nline-1 do begin     ; loop to find updated cdf file.
            tline = lines[j]
            ; match update date: DD-Mon-YYYY.
            idx = strpos(tline, date)   
            if idx[0] eq -1 then continue
            ; match cdf filename: rbspx_l1_var_YYYYMMDD_v??.cdf'.
            cdf = stregex(tline, files[i], /extract)
            if cdf eq '' then continue
            cdfs = [cdfs, cdf]
            cdfpaths = [cdfpaths, paths[i]]
        endfor
    endfor
    
    if n_elements(cdfs) eq 1 then return    ; no updated file.
    cdfs = cdfs[1:*]
    cdfpaths = cdfpaths[1:*]

    ; print updated file to log.
    for i = 0, nvar-1 do begin
        printf, loglun, ''
        printf, loglun, '* '+vars[i]
        for j = 0, n_elements(cdfs)-1 do $
            if strpos(cdfs[j], vars[i]) ne -1 then $
                printf, loglun, cdfpaths[j]+'/'+cdfs[j]
    endfor


; **** download updated spec data.
    printf, loglun, ''
    printf, loglun, '****'
    printf, loglun, ''
    printf, loglun, 'Download updated spec data'
    printf, loglun, ''
    idx = where(stregex(cdfs,'spec') ne -1, cnt)
    if cnt ne 0 then begin
        speccdfs = cdfs[idx]
        for i = 0, cnt-1 do begin
            printf, loglun, speccdfs[i]
            tdate = strmid(speccdfs[i], stregex(speccdfs[i],str2), 8)
            tdate = strmid(tdate,0,4)+'-'+strmid(tdate,4,2)+'-'+strmid(tdate,6,2)
            timespan, tdate, 1
            tprobe = strmid(speccdfs[i],4,1)
            rbsp_load_efw_spec, probe = tprobe, type = 'calibrated', /downloadonly
        endfor
    endif


; **** read updated B1 data, register each chunk's start and end times and data rate.
    printf, loglun, ''
    printf, loglun, '****'
    printf, loglun, ''
    printf, loglun, 'Read B1 data, make daily plot, updates for rbsp_efw_week.log ...'
    idx = where(stregex(cdfs,'vb1') ne -1, cnt)
    if cnt eq 0 then begin
        printf, loglun, ''
        printf, loglun, 'No B1 update ...'
        free_lun, loglun
        return
    endif
    b1cdfs = cdfs[idx]  ; b1 data's file name.

    recdel = 1000d          ; down sample b1 data, 1 out of 1000.
    maxdt = 1/1024d*recdel  ; threshold for data gap.
    maxdt = 60              ; threshold as 1 min.

    xlslogs = ''
    tab = string(9b)

    ; process each b1 file.
    for i = 0, n_elements(b1cdfs)-1 do begin
        chunks = {tsta:0d, tend:0d, samplerate:''}

        printf, loglun, ''
        printf, loglun, '* '+b1cdfs[i]
        
        ; do not download file on Tohban laptop.
;        if usr eq 'tohban' then continue

        ; B1 file name is in rbspx_l1_vb1_yyyymmdd_vxx.cdf.
        tprobe = strmid(b1cdfs[i],4,1)
        tdate = time_double(strmid(b1cdfs[i],13,8),tformat='YYYYMMDD')
        tdate = time_string(tdate,tformat='YYYY-MM-DD')
        prefix = 'rbsp'+tprobe

        ; save a plot to <tohban>/files, and have tplot vars rbspx_[esvy,e12b1].
        epsfile = tobroot+'/files/'+prefix+'_efw_daily_'+tdate+'.eps'
        figfile = tobroot+'/files/'+prefix+'_efw_daily_'+tdate+'.pdf'
        set_plot, 'ps'
        device, filename = epsfile, xsize = 6, ysize = 4, /inch, /tt_font, $
            /encapsulate, /decompose, /color, bits_per_pixel = 8
        !p.font = 1
        rbsp_efw_daily, tdate, tprobe, del = recdel
        device, /close
        set_plot, 'x'
        cmd = '-dEPSCrop "'+epsfile+'" "'+figfile+'"'
        spawn, 'ps2pdf '+cmd, tmp, errmsg
        if errmsg ne '' then spawn, '/opt/local/bin/ps2pdf '+cmd, errmsg
        if errmsg eq '' then file_delete, epsfile

        ; figure out each block's start and end time.
        vars = prefix+'_efw_e12b1'
        get_data, vars, t0
        store_data, vars, /delete ; free up memory.
        nrec = n_elements(t0)
        dt = [0,t0[1:nrec-1]-t0[0:nrec-2]]
        idx = where(dt gt maxdt, cnt)
        if cnt eq 0 then idx = [[0], [nrec-1]] $
        else idx = [[0,idx+1],[idx-1,nrec-1]]
        
        for j = 0, n_elements(idx)/2-1 do begin
            tsta = t0[idx[j,0]]
            tend = t0[idx[j,1]]
            tdt = dt[idx[j,0]:idx[j,1]]
            tdt = tdt[uniq(tdt, sort(tdt))]
            trates = round(alog(recdel/tdt/1024)/alog(2))
            trates = trates[where(trates gt 0)] ; remove 0, which is probably the mode change time.
            trates = trates[uniq(trates, sort(trates))]
            trates = reverse(2^trates)   ; sample rate in kHz, largest to smallest.
            samplerate = strjoin(string(trates*1024,format='(I0)'),'/')
            ; flor the times to current minute.
            tsta = tsta-(tsta mod 60)
            tend = tend-(tend mod 60)
            chunks = [chunks,{tsta:tsta,tend:tend,samplerate:samplerate}]
        endfor
        chunks = chunks[1:*]
        nchunk = n_elements(chunks)
        
        ; read relative entries on this cdf in rbsp_efw_week.log.
        stastr = strupcase('rbsp-'+tprobe)+' download {{{'
        endstr = '}}}'
        tline = ''
        openr, weekloglun, weeklog, /get_lun
        while not eof(weekloglun) do begin
            readf, weekloglun, tline
            if strpos(tline, stastr) ne -1 then break
        endwhile
        entrys = ''
        while strpos(tline, endstr) eq -1 do begin
            readf, weekloglun, tline
            if strpos(strmid(tline,0,52), tdate) ne -1 then $
                entrys = [entrys,tline]
        endwhile
        free_lun, weekloglun
        nentry = n_elements(entrys)-1   ; remove first empty entry.
        if nentry ne 0 then entrys = entrys[1:*]
        
        for j = 0, nchunk-1 do begin
            ; find in each entry, works for no entry too.
            maxtsta = chunks[j].tsta    ; find new entry's start time.
            for k = 0, nentry-1 do begin
                entrytsta = time_double(strmid(entrys[k],16,16))
                entrytend = time_double(strmid(entrys[k],36,16))
                ; if current entry contains current chunk.
                if chunks[j].tsta ge entrytsta and $
                   chunks[j].tend le entrytend then begin
                    maxtsta = chunks[j].tend    ; force to skip print.
                    continue
                endif
                ; if current entry has no overlap with current chunk.
                if chunks[j].tsta gt entrytend or $
                   chunks[j].tend lt entrytsta then $
                    continue    ; keep current chunk's info.
                ; if current chunk contains current entry.
                if chunks[j].tsta lt entrytsta and $
                   chunks[j].tend gt entrytend then $
                       maxtsta >= entrytend+60 ; 1 min after current entry ends.
                ; if current entry overlap with current chunk.
                maxtsta >= entrytend+60     ; 1 min after current entry ends.
            endfor
            if maxtsta ge chunks[j].tend then begin
                printf, loglun, 'No new data ...'
                continue    ; no update.
            endif
            if chunks[j].tend-maxtsta lt 60 then begin
                printf, loglun, 'Less than 1 min ...'
                continue    ; no update.
            endif
            printf, loglun, 'download    '+tprobe+'   '+$
                time_string(maxtsta,tformat='YYYY-MM-DD/hh:mm')+'    '+$
                time_string(chunks[j].tend,tformat='YYYY-MM-DD/hh:mm')+'    '+$
                time_string(ltnow,tformat='YYYY-MM-DD')+'    '+$
                chunks[j].samplerate
            xlslogs = [xlslogs,$
                time_string(chunks[j].tsta,tformat='hh:mm')+' to '+$
                time_string(chunks[j].tend,tformat='hh:mm')+' as of '+$
                time_string(ltnow,tformat='MM/DD')]
        endfor
    endfor
    
    ; **** print updates for RBSP_B1_log.xls
    printf, loglun, ''
    printf, loglun, '****'
    printf, loglun, ''
    printf, loglun, 'Updates for RBSP_B1_log.xls'
    nxlslog = n_elements(xlslogs)
    for i = 1, nxlslog-1 do printf, loglun, xlslogs[i]
  

; **** finish up.
    ltnow = time_double(systime(),tformat='Dow MTH DD hh:mm:ss YYYY')
    printf, loglun, ''
    printf, loglun, '****'
    printf, loglun, ''
    printf, loglun, 'Finished at '+time_string(ltnow)
    free_lun, loglun

end
