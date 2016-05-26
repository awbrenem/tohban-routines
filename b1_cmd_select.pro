pro b1_cmd_select_print_info, str0, probe, trange, cmd_string
    
    str2 = strsplit(cmd_string,'(,)',/extract)
    block0 = double(str2[1])
    nblock = double(str2[2])
    print, ''
    print, ''
    print, '**** For b1_cmd_crib.pro'
    print, str0
    print, cmd_string
    print, ''
    print, ''
    print, '**** For rbsp_b1_predict_plot.pro'
    print, "    [time_double(['"+time_string(trange[0],precision=-1)+"','"+$
        time_string(trange[1],precision=-1)+"'])], $"
    print, ''
    print, ''
    print, '**** For rbsp_efw_week.log'
    print, 'playback    '+probe+'   '+time_string(trange[0],precision=-1)+$
        '    '+time_string(trange[1],precision=-1)+'    '+$
        time_string(systime(1),precision=-3)+'      '+$
        string(block0,format='(I-6)')+'  '+$
        string(nblock,format='(I-)')
   print, ''
   print, ''
   tab = string(9b) & rate = (probe eq 'b')? '4096':'16384'
   print, '**** For RBSP_B1_log.xls'
   print, time_string(trange[0],tformat='MM/DD/yy')+tab+rate+tab+tab+tab+tab+$
       time_string(trange[0],tformat='hh:mm')+'-'+$
       time_string(trange[1],tformat='hh:mm')+tab+$
       'Requested '+time_string(systime(1),tformat='MM/DD')+tab+tab+tab+$
       string(block0,format='(I)')+tab+string(nblock,format='(I)')
   print, ''
   print, ''
end

pro b1_cmd_select, str0, nday, probe_b=probe_b,add_frequencies = add_frequencies

;!rbsp_efw.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/'


;.run b1_status_crib
get_data, 'rbspa_efw_b1_fmt_block_index', tmp
if n_elements(tmp) eq 1 then b1_status_crib_pro

; default settings.
dt = 86400d
t0 = systime(1)
t0 = t0-(t0 mod dt)+dt
dt = n_elements(nday)? nday: 10  ; # of days.
t0 = time_string(t0-dt*86400d)

if n_elements(str0) ne 0 then begin
    ; mode 1: str0 in format: RBSPB (2014-11-02/13:00:00 - 2014-11-02/15:00:00):
    if strmid(str0,0,4) eq 'RBSP' then begin
        ; parse the string.
        str1 = strsplit(str0, ' ()', /extract)
        if n_elements(str1) eq 5 then begin
            probe = strlowcase(strmid(str1[0],0,1,/reverse_offset))
            trange = time_double(str1[[1,3]])
        endif
        rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
        b1_cmd_select_print_info, str0, probe, trange, cmd_string
        return
    ; mode 2: str0 is t0 for timespan.
    endif else t0 = str0
endif

get_data,'rbspa_efw_b1_fmt_B1_available',data=test
if ~ is_struct(test) then print,'.run b1_status_crib'
if ~ is_struct(test) then return

timespan, t0, dt

probe='a'
if keyword_set(probe_b) then probe = 'b'
sc=probe

  ; load spectrograms.
    rbsp_efw_init
    !rbsp_efw.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/'
    rbsp_load_efw_spec, probe = probe, type = 'calibrated'
    pre0 = 'rbsp'+probe+'_efw_'
    varspec = pre0+'64_spec'+['0','4']
tplot,['rbsp'+probe+'_efw_64_spec0','rbsp'+probe+'_efw_64_spec4']


if keyword_set(add_frequencies) then begin

if ~ keyword_set(probe_b) then load_freq_v2  ; creats tplot vars : frequencies and plasma density
if  keyword_set(probe_b) then load_freq_v2,/probe_b


store_data,'RBSP'+probe+'_spec0_plot_with_b1_aval',data=['rbsp'+probe+'_efw_64_spec0','rbsp'+probe+'_efw_b1_fmt_B1_available','rbsp'+sc+'_frequencies']
store_data,'RBSP'+probe+'_spec4_plot_with_b1_aval',data=['rbsp'+probe+'_efw_64_spec4','rbsp'+probe+'_efw_b1_fmt_B1_available','rbsp'+sc+'_frequencies']

endif else begin


store_data,'RBSP'+probe+'_spec0_plot_with_b1_aval',data=['rbsp'+probe+'_efw_64_spec0','rbsp'+probe+'_efw_b1_fmt_B1_available']
store_data,'RBSP'+probe+'_spec4_plot_with_b1_aval',data=['rbsp'+probe+'_efw_64_spec4','rbsp'+probe+'_efw_b1_fmt_B1_available']

endelse

ylim,['RBSP'+probe+'_spec0_plot_with_b1_aval','RBSP'+probe+'_spec4_plot_with_b1_aval'],0.5,10000



;--------------------------------------------------------------

!p.background = 255
!p.color = 0

for xx=0,5 do begin

timespan,t0,dt

print,'b1 select'
print,xx

tlimit,/f

;tplot,['rbsp'+probe+'_b1_status','Plasma!CDensity!Ccm!e-3!n','RBSP'+probe+'_spec0_plot_with_b1_aval','RBSP'+probe+'_spec4_plot_with_b1_aval']

tplot,['rbsp'+probe+'_b1_status','RBSP'+probe+'_spec0_plot_with_b1_aval','RBSP'+probe+'_spec4_plot_with_b1_aval']

tlimit

ctime,x1,y1,npoints=1,/exact
wait,1
ctime,x2,y2,npoints=1,/exact

print,y1
print,y2

stime = time_string(x1)
etime = time_string(x2)

date=(strsplit(stime,'/',/extract))[0]

timespan,date,3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
if keyword_set(probe_b) then probe='b'
cmd_string = ''
str0 = 'RBSP'+strupcase(probe)+' ('+stime+' - '+etime+'):'
trange=time_double([stime,etime])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
b1_cmd_select_print_info, str0, probe, trange, cmd_string

;prints something like util.QUEUE_B1PLAYBACK( 100528, 5412)

stp =''
read,stp,prompt='Done choosing b1 playback times? (y/n)'
if stp eq 'y' then return

endfor

print,'Nov 19, 2015 version of program, run on'
dtime=0D
time2str,dtime
print,time_string(dtime)


end
