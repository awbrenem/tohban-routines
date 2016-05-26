; 0, To use, edit jumpa/jumpb, prota/protb, colla/collb. They corresponds to
;    jumps, protected time, collection time.
; 1, First location is the first element in jump, so # of jump is always >1.
; 2, Use last location, or known jump to update "first location".
; 3, The predict curve should be very accurate.
; 4, Don't put jump in between collections. Add 1min pad time between 
;    jump and collection. Don't let collection time overlap.
; 5, To ensure accuracy, if update "first location" using last location, then 
;   set 1st collection start from last time, set earlier.

; updated on 2015-09-16. Auto modify time range to include all protected blocks.
; updated on 2015-10-01. Add day of year info in title.

; **** combine jump & collection, sort, convert to abs memory id, print info,
; treat wrap, generate time & memory id for tplot, load contact time to tplot.

pro rbsp_b1_predict_plot_process, probe, jumps, colls, $
    lun = lun, time = t0, memf = memf, mems = mems

;!rbsp_efw.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/'


    ; constants.
    sz = 262144D            ; memory size, in block.
    s2b = sz/84890D         ; sec to 16438 block.
    s2b = sz/85890D         ; sec to 16438 block.
    s2b = sz/86916D         ; sec to 16438 block.
    print, 'conversion constant: ', s2b
;timespan,'2016-02-25',20
    ; load contact times.
    get_data, 'rbsp'+strlowcase(probe)+'_contact', tmp
    if tmp[0] eq 0 then begin
        rbsp_load_contact, cont, probe
        nrec = n_elements(cont)/2
        t0 = dblarr(nrec*3)
        for i = 0, nrec-1 do t0[i*3:i*3+2] = [reform(cont[i,*]),cont[i,1]+1e-5]
        tmp = dblarr(nrec*3) & tmp[2:*:3] = !values.d_nan

        vname = 'rbsp'+strlowcase(probe)+'_contact'
        store_data, vname, t0, tmp, limits = {labels:'contact', yrange:[-1,1], $
            ytitle:'', ytickformat:'(A1)', yticks:2, yminor:1, yticklen:0.01, $
            thick:5, panel_size:0.1, colors:6}
    endif

    if n_elements(lun) eq 0 then lun = -1
    ; combine jump and collection.
    njump = n_elements(jumps)/2 & ncoll = n_elements(colls)/3
    nmem = njump+ncoll
    mems = dblarr(nmem, 5)      ; [tsta, tend, memsta, memend, rate].
    mems[0:njump-1,0:1] = [[jumps[*,0]], [jumps[*,0]]]
    mems[0:njump-1,2:3] = [[jumps[*,1]], [jumps[*,1]]]
    mems[0:njump-1,4] = 0
    mems[njump:*,0:1] = colls[*,0:1]
    mems[njump:*,2:3] = 0
    mems[njump:*,4] = colls[*,2]
    idx = sort(mems[*,0])
    mems = mems[idx,*]

    ; convert to absolute memory id.
    for i = 0, nmem-1 do begin
        if mems[i,0] eq mems[i,1] then continue     ; jump.
        mems[i,2] = mems[i-1,3]
        mems[i,3] = mems[i,2]+(mems[i,1]-mems[i,0])*(mems[i,4]/16438D)*s2b
        mems[i,2:3] = long(mems[i,2:3]) mod sz      ; wrap absolute memory id.
    endfor

    ; print result.
    printf, lun, ''
    printf, lun, 'RBSP-'+strupcase(probe)
    fmt = '(I6)'
    for i = 0, nmem-1 do begin
        if mems[i,4] eq 0 then begin
            printf, lun, 'jump:          '+time_string(mems[i,0])+' to '+$
                string(mems[i,3],format=fmt)
        endif else if mems[i,4] eq -1 then begin
            printf, lun, 'wrap:          '+time_string(mems[i,0])
        endif else begin
            printf, lun, 'collection:    '+time_string(mems[i,0])+' to '+$
                time_string(mems[i,1])+'    '+string(mems[i,2],format=fmt)+$
                ' to '+string(mems[i,3],format=fmt)+' at '+$
                string(mems[i,4],format='(I5)')+' sample/s'
        endelse
    endfor

    ; treat memory overflow.
    i = 1 & dt = 0.1
    while i lt nmem do begin
        if mems[i,2] le mems[i,3] then begin        ; jump, or normal.
            if mems[i,0] eq mems[i,1] then begin    ; jump
                mems[i,1] = mems[i,0]+dt
                if i gt 1 then mems[i,2] = mems[i-1,3]
            endif
            i+=1 & continue
        endif
        twrap = mems[i,0]+(mems[i,1]-mems[i,0])*$
            (sz-1-mems[i,2])/(sz-1-mems[i,2]+mems[i,3])
        tmem = [twrap,twrap,!values.d_nan,!values.d_nan,-1]
        mems = [mems[0:i,*],transpose(tmem),mems[i:*,*]]
        mems[i,1] = twrap-dt & mems[i,3] = sz-1
        i+=2
        mems[i,0] = twrap+dt & mems[i,2] = 0
        i+=1
        nmem = n_elements(mems)/5
    endwhile

    ; convert to array.
    t0 = dblarr(nmem*2) & memf = dblarr(nmem*2)
    for i = 0, nmem-1 do begin
        t0[i*2:i*2+1] = mems[i,0:1]
        memf[i*2:i*2+1] = mems[i,2:3]
    endfor
end

; run b1_status_crib if needed.
;get_data, 'rbspa_efw_b1_fmt_block_index2', tmp
;if tmp[0] eq 0 then b1_status_crib_pro

b1_status_crib_pro  ;uses rbsp_load_efw_b1,probe=probe

t0 = systime(1)-15d*86400
t1 = t0+20*86400
timespan, t0, t1-t0, /sec

;----------------------------------------------------------------------

; jumps: [n,2], each record in [tsta, absolute memory id].
; The 1st record is always the start location.
jumpa = [$      
   
   [time_double('2016-04-23/15:19'), 230000d],$
   [time_double('2016-05-16/14:53'), 130000d],$
   [time_double('2016-05-27/10:29'), 130000d],$
   [time_double('2016-05-28/04:24'), 254000d],$

    [0,0]]
jumpa = jumpa[*,0:n_elements(jumpa)/2-2]


jumpb = [$    
              
    [time_double('2016-04-23/13:42'), 37000d],$
    [time_double('2016-05-16/09:23'), 168000d],$
    [time_double('2016-05-26/13:48'), 41000d],$
              
    [0,0]]
jumpb = jumpb[*,0:n_elements(jumpb)/2-2]

jumpa = transpose(jumpa)
jumpb = transpose(jumpb)

; protected memory, [n,2], each record in [tsta, tend].
prota = [$
	
    ;[time_double(['2016-05-06/13:19','2016-05-06/15:00'])], $
    [time_double(['2016-05-06/19:24','2016-05-06/20:30'])], $
    [time_double(['2016-05-17/13:42','2016-05-17/14:54'])], $

    [0,0]]
prota = prota[*,0:n_elements(prota)/2-2]
    
    
protb = [$

    ;[time_double(['2016-05-06/15:00','2016-05-06/15:00'])], $
    [time_double(['2016-05-17/07:59','2016-05-17/10:45'])], $
	
    [0,0]]
protb = protb[*,0:n_elements(protb)/2-2]


prota = transpose(prota)
protb = transpose(protb)

; modify time span, make sure to include protected times.
t0 = systime(1)-15d*86400
t1 = t0+20*86400
t0 = min([[prota[*],protb[*]]-86400,t0])
timespan, t0, t1-t0, /sec

; collection, [n,3], each record in [tsta, tend, rate].
colla = [$  
    
    [time_double(['2016-04-23/15:20', '2016-04-23/20:49']),16384],$
    [time_double(['2016-04-23/20:51', '2016-04-23/22:50']), 2048],$
    [time_double(['2016-04-24/01:17', '2016-04-24/05:46']),16384],$
    [time_double(['2016-04-24/05:48', '2016-04-24/07:47']), 2048],$
    [time_double(['2016-04-24/10:14', '2016-04-24/14:43']),16384],$
    [time_double(['2016-04-24/14:45', '2016-04-24/16:44']), 2048],$
    [time_double(['2016-04-24/19:11', '2016-04-24/23:40']),16384],$
    [time_double(['2016-04-24/23:42', '2016-04-25/01:41']), 2048],$
    [time_double(['2016-04-25/04:09', '2016-04-25/07:28']),16384],$
    [time_double(['2016-04-26/15:57', '2016-04-26/20:26']),16384],$
    [time_double(['2016-04-26/20:28', '2016-04-26/22:27']), 2048],$
    [time_double(['2016-04-27/00:54', '2016-04-27/05:23']),16384],$
    [time_double(['2016-04-27/05:25', '2016-04-27/07:24']), 2048],$
    [time_double(['2016-04-27/09:51', '2016-04-27/14:20']),16384],$
    [time_double(['2016-04-27/14:22', '2016-04-27/16:21']), 2048],$
    [time_double(['2016-04-27/18:48', '2016-04-27/23:17']),16384],$
    [time_double(['2016-04-27/23:19', '2016-04-28/01:18']), 2048],$
    [time_double(['2016-04-28/03:45', '2016-04-28/08:14']),16384],$
    [time_double(['2016-04-28/08:16', '2016-04-28/10:15']), 2048],$
    [time_double(['2016-04-29/15:34', '2016-04-29/20:03']),16384],$
    [time_double(['2016-04-29/20:05', '2016-04-29/22:04']), 2048],$
    [time_double(['2016-04-30/00:31', '2016-04-30/05:00']),16384],$
    [time_double(['2016-04-30/05:02', '2016-04-30/07:01']), 2048],$
    [time_double(['2016-04-30/09:28', '2016-04-30/13:57']),16384],$
    [time_double(['2016-04-30/13:59', '2016-04-30/15:58']), 2048],$
    [time_double(['2016-04-30/18:25', '2016-04-30/22:54']),16384],$
    [time_double(['2016-04-30/22:56', '2016-05-01/00:55']), 2048],$
    [time_double(['2016-05-01/03:22', '2016-05-01/07:51']),16384],$
    [time_double(['2016-05-01/07:53', '2016-05-01/09:52']), 2048],$
    [time_double(['2016-05-05/14:47', '2016-05-05/19:16']),16384],$
    [time_double(['2016-05-05/19:18', '2016-05-05/21:17']), 2048],$
    [time_double(['2016-05-05/23:44', '2016-05-06/04:13']),16384],$
    [time_double(['2016-05-06/04:15', '2016-05-06/06:14']), 2048],$
    [time_double(['2016-05-06/08:41', '2016-05-06/13:10']),16384],$
    [time_double(['2016-05-06/13:12', '2016-05-06/15:11']), 2048],$
    [time_double(['2016-05-06/17:39', '2016-05-06/22:08']),16384],$
    [time_double(['2016-05-06/22:10', '2016-05-07/00:09']), 2048],$
    [time_double(['2016-05-07/02:36', '2016-05-07/07:05']),16384],$
    [time_double(['2016-05-07/07:07', '2016-05-07/09:06']), 2048],$
    [time_double(['2016-05-16/14:54', '2016-05-16/16:53']), 2048],$
    [time_double(['2016-05-16/19:20', '2016-05-16/23:49']),16384],$
    [time_double(['2016-05-16/23:51', '2016-05-17/01:50']), 2048],$
    [time_double(['2016-05-17/04:18', '2016-05-17/08:47']),16384],$
    [time_double(['2016-05-17/08:49', '2016-05-17/10:48']), 2048],$
    [time_double(['2016-05-17/13:15', '2016-05-17/17:44']),16384],$
    [time_double(['2016-05-17/17:46', '2016-05-17/19:45']), 2048],$
    [time_double(['2016-05-17/22:12', '2016-05-18/01:30']),16384],$
    [time_double(['2016-05-27/10:30', '2016-05-27/12:29']), 2048],$
    [time_double(['2016-05-27/14:57', '2016-05-27/19:26']),16384],$
    [time_double(['2016-05-27/19:28', '2016-05-27/21:27']), 2048],$
    [time_double(['2016-05-27/23:54', '2016-05-28/04:23']),16384],$
    [time_double(['2016-05-28/04:25', '2016-05-28/06:24']), 2048],$
    [time_double(['2016-05-28/08:51', '2016-05-28/13:20']),16384],$
    [time_double(['2016-05-28/13:22', '2016-05-28/15:21']), 2048],$
    [time_double(['2016-05-28/17:48', '2016-05-28/22:17']),16384],$
    [time_double(['2016-05-28/22:19', '2016-05-29/00:18']), 2048],$
        
    [0,0,0]]    ; this line keeps the above lines in same format.
colla = colla[*,0:n_elements(colla)/3-2]


collb = [$
   
    [time_double(['2016-04-23/13:43', '2016-04-23/18:12']),16384],$
    [time_double(['2016-04-23/18:14', '2016-04-23/20:13']), 2048],$
    [time_double(['2016-04-23/22:46', '2016-04-24/03:15']),16384],$
    [time_double(['2016-04-24/03:17', '2016-04-24/05:16']), 2048],$
    [time_double(['2016-04-24/07:50', '2016-04-24/12:19']),16384],$
    [time_double(['2016-04-24/12:21', '2016-04-24/14:20']), 2048],$
    [time_double(['2016-04-24/16:53', '2016-04-24/21:22']),16384],$
    [time_double(['2016-04-24/21:24', '2016-04-24/23:23']), 2048],$
    [time_double(['2016-04-25/01:56', '2016-04-25/06:20']),16384],$
    [time_double(['2016-04-26/14:09', '2016-04-26/18:38']),16384],$
    [time_double(['2016-04-26/18:40', '2016-04-26/20:39']), 2048],$
    [time_double(['2016-04-26/23:12', '2016-04-27/03:41']),16384],$
    [time_double(['2016-04-27/03:43', '2016-04-27/05:42']), 2048],$
    [time_double(['2016-04-27/08:15', '2016-04-27/12:44']),16384],$
    [time_double(['2016-04-27/12:46', '2016-04-27/14:45']), 2048],$
    [time_double(['2016-04-27/17:18', '2016-04-27/21:47']),16384],$
    [time_double(['2016-04-27/21:49', '2016-04-27/23:48']), 2048],$
    [time_double(['2016-04-28/02:21', '2016-04-28/06:50']),16384],$
    [time_double(['2016-04-28/06:52', '2016-04-28/08:51']), 2048],$
    [time_double(['2016-04-29/14:34', '2016-04-29/19:03']),16384],$
    [time_double(['2016-04-29/19:05', '2016-04-29/21:04']), 2048],$
    [time_double(['2016-04-29/23:37', '2016-04-30/04:06']),16384],$
    [time_double(['2016-04-30/04:08', '2016-04-30/06:07']), 2048],$
    [time_double(['2016-04-30/08:40', '2016-04-30/13:09']),16384],$
    [time_double(['2016-04-30/13:11', '2016-04-30/15:10']), 2048],$
    [time_double(['2016-04-30/17:43', '2016-04-30/22:12']),16384],$
    [time_double(['2016-04-30/22:14', '2016-05-01/00:13']), 2048],$
    [time_double(['2016-05-01/02:47', '2016-05-01/07:16']),16384],$
    [time_double(['2016-05-01/07:18', '2016-05-01/09:17']), 2048],$
    [time_double(['2016-05-05/15:24', '2016-05-05/19:53']),16384],$
    [time_double(['2016-05-05/19:55', '2016-05-05/21:54']), 2048],$
    [time_double(['2016-05-06/00:28', '2016-05-06/04:57']),16384],$
    [time_double(['2016-05-06/04:59', '2016-05-06/06:58']), 2048],$
    [time_double(['2016-05-06/09:31', '2016-05-06/14:00']),16384],$
    [time_double(['2016-05-06/14:02', '2016-05-06/16:01']), 2048],$
    [time_double(['2016-05-06/18:34', '2016-05-06/23:03']),16384],$
    [time_double(['2016-05-06/23:05', '2016-05-07/01:04']), 2048],$
    [time_double(['2016-05-07/03:37', '2016-05-07/08:06']),16384],$
    [time_double(['2016-05-07/08:08', '2016-05-07/10:07']), 2048],$
    [time_double(['2016-05-16/09:24', '2016-05-16/11:23']), 2048],$
    [time_double(['2016-05-16/13:56', '2016-05-16/18:25']),16384],$
    [time_double(['2016-05-16/18:27', '2016-05-16/20:26']), 2048],$
    [time_double(['2016-05-16/22:59', '2016-05-17/03:28']),16384],$
    [time_double(['2016-05-17/03:30', '2016-05-17/05:29']), 2048],$
    [time_double(['2016-05-17/08:02', '2016-05-17/12:31']),16384],$
    [time_double(['2016-05-17/12:33', '2016-05-17/14:32']), 2048],$
    [time_double(['2016-05-17/17:05', '2016-05-17/21:34']),16384],$
    [time_double(['2016-05-17/21:36', '2016-05-17/23:35']), 2048],$
    [time_double(['2016-05-26/13:49', '2016-05-26/15:48']), 2048],$
    [time_double(['2016-05-26/18:21', '2016-05-26/22:50']),16384],$
    [time_double(['2016-05-26/22:52', '2016-05-27/00:51']), 2048],$
    [time_double(['2016-05-27/03:24', '2016-05-27/07:53']),16384],$
    [time_double(['2016-05-27/07:55', '2016-05-27/09:54']), 2048],$
    [time_double(['2016-05-27/12:27', '2016-05-27/16:56']),16384],$
    [time_double(['2016-05-27/16:58', '2016-05-27/18:57']), 2048],$
    [time_double(['2016-05-27/21:30', '2016-05-28/01:59']),16384],$
    [time_double(['2016-05-28/02:01', '2016-05-28/04:00']), 2048],$
 
    [0,0,0]]    ; this line keeps the above lines in same format.
collb = collb[*,0:n_elements(collb)/3-2]


;--------------------------------------------------------------------------------
   
colla = transpose(colla)
collb = transpose(collb)
; future collections.
store_data, 'rbspa_b1_fcollection', colla[*,0], colla[*,0:1]
store_data, 'rbspb_b1_fcollection', collb[*,0], collb[*,0:1]


rbsp_b1_predict_plot_process, 'a', jumpa, colla, $
    time = timea, memf = memaf, mems = mema
rbsp_b1_predict_plot_process, 'b', jumpb, collb, $
    time = timeb, memf = membf, mems = memb

; **** below are from Aaron.
; create a tplot variable with the future memory locations.
store_data,'future_a',data={x:timea,y:memaf}
store_data,'future_b',data={x:timeb,y:membf}
options,['future_a','future_b'],'colors',250
options,['future_a','future_b'],'thick',2

; treat protect memory.
get_data,'rbspa_efw_b1_fmt_block_index2',data=gootmpa
get_data,'rbspb_efw_b1_fmt_block_index2',data=gootmpb
gootmpa2 = gootmpa
gootmpb2 = gootmpb

gootmpa2.y = !values.f_nan
gootmpb2.y = !values.f_nan

tpa0 = reform(prota[*,0]) & tpa1 = reform(prota[*,1])
for vv=0,n_elements(tpa0)-1 do begin
    boob = where((gootmpa.x ge tpa0[vv]) and (gootmpa.x le tpa1[vv]))
    if boob[0] ne -1 then gootmpa2.y[boob] = gootmpa.y[boob]
endfor
tpb0 = reform(protb[*,0]) & tpb1 = reform(protb[*,1])
for vv=0,n_elements(tpb0)-1 do begin
    boob = where((gootmpb.x ge tpb0[vv]) and (gootmpb.x le tpb1[vv]))
    if boob[0] ne -1 then gootmpb2.y[boob] = gootmpb.y[boob]
endfor
store_data,'rbspa_efw_b1_fmt_block_index3',data=gootmpa2
store_data,'rbspb_efw_b1_fmt_block_index3',data=gootmpb2
options,'rbsp?_efw_b1_fmt_block_index3','colors',100
options,'rbsp?_efw_b1_fmt_block_index3','psym',4

; prepare tplot.
store_data,'comba',data=['rbspa_efw_b1_fmt_block_index_cutoff',$
    'rbspa_efw_b1_fmt_block_index','rbspa_efw_b1_fmt_block_index2',$
    'rbspa_efw_b1_fmt_block_index3','future_a','rbspa_contact']
store_data,'combb',data=['rbspb_efw_b1_fmt_block_index_cutoff',$
    'rbspb_efw_b1_fmt_block_index','rbspb_efw_b1_fmt_block_index2',$
    'rbspb_efw_b1_fmt_block_index3','future_b','rbspb_contact']
store_data, 'comba2', data = ['rbspa_efw_b1_fmt_block_index', 'future_a']
store_data, 'combb2', data = ['rbspb_efw_b1_fmt_block_index', 'future_b']

tnow = systime(1)
doy = time_string(tnow, tformat='DOY')
title = 'RBSP B1 STATUS - '+$
    time_string(tnow, tformat='DOW MTH DD hh:mm:ss YYYY UTC')+'  DOY-'+doy

sz = 262144D            ; memory size, in block.
ylim,['comba','combb'],0,sz
options,'rbsp?_b1_status','panel_size',0.5
tplot,['comba','rbspa_b1_status','combb','rbspb_b1_status'], title = title
timebar, tnow

;timespan,'2015-11-30',20
	

; print last position: time and memory id.
get_data, 'rbspa_efw_b1_fmt_block_index_cutoff', data = tmp
print, 'RBSP-A last pos:    '+time_string(tmp.x[1])+'    at    '+$
    string(tmp.y[1],format='(I6)')
get_data, 'future_a', t0, yy
idx = (where(tmp.x[1] le t0, cnt))[0]
if cnt ne 0 then begin
    loc = interpol(yy[[idx-1,idx]],t0[[idx-1,idx]],tmp.x[1])
    print, 'RBSP-A predict pos: '+time_string(tmp.x[1])+'    at    '+$
        string(loc,format='(F8.1)')
    print, yy[idx]
    get_data, 'rbspb_efw_b1_fmt_block_index_cutoff', data = tmp
    print, 'RBSP-B last pos:    '+time_string(tmp.x[1])+'    at    '+$
        string(tmp.y[1],format='(I6)')
    get_data, 'future_b', t0, yy
    idx = (where(tmp.x[1] le t0))[0]
    loc = interpol(yy[[idx-1,idx]],t0[[idx-1,idx]],tmp.x[1])
    print, 'RBSP-B predict pos: '+time_string(tmp.x[1])+'    at    '+$
        string(loc,format='(F8.1)')
    print, yy[idx]
endif


;print,'type .c to print the plot to ~/tohban/files/'
;stop

@tplot_com.pro
tr = tplot_vars.options.trange
pcharsize_saved=!p.charsize
pfont_saved=!p.font
pcharthick_saved=!p.charthick
pthick_saved=!p.thick

set_plot,'Z'
;rbsp_efw_init,/reset ; try to get decent colors in the Z buffer
!p.background = 255
!p.color = 0
    
device,set_resolution=[3200,2400],set_font='helvetica',/tt_font,set_character_size=[28,35]

!p.thick=4.
!p.charthick=4.

options,['comba','combb'],'ytickformat','(I6.6)'

tplot_options,'xmargin',[14,22]
tplot, trange = tr
;timebar,jumpa_s,color=50,varname=['comba','rbspa_b1_status']
;timebar,jumpb_s,color=50,varname=['combb','rbspb_b1_status']


; take snapshot of z buffer
snapshot=tvrd()
device,/close

; convert snapshot from index colors to true colors
tvlct,r,g,b,/get

sz=size(snapshot,/dimensions)
snapshot3=bytarr(3,sz[0],sz[1])
snapshot3[0,*,*]=r[snapshot]
snapshot3[1,*,*]=g[snapshot]
snapshot3[2,*,*]=b[snapshot]

; shrink snapshot
xsize=800
ysize=600
snapshot3=rebin(snapshot3,3,xsize,ysize)

;	timespan,'2015-11-30',20

print, 'saving png ...'
; write a png
write_png,getenv('HOME')+'/tohban/files/b1_status.png',snapshot3
spawn, 'rm ~/Desktop/b1_status.png'

set_plot,'X'
;rbsp_efw_init,/reset
!p.background = 255
!p.color = 0
!p.charsize=pcharsize_saved
!p.font=pfont_saved
!p.charthick=pcharthick_saved
!p.thick=pthick_saved
tplot

end
