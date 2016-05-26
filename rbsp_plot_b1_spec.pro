pro rbsp_plot_b1_spec,start_date,duration,manual_b1=manual_b1



;get_data,'rbspb_efw_b1_fmt_block_index2',data = dat 
;if ~is_struct(dat) then 
b1_status_crib_pro

dtime=0D
time2str,dtime
today=time_string(dtime)
today = (strsplit(today,'/',/extract))[0]

;old automaded start time so many days back
;start_time = time_string(dtime - duration*24*3600.)  ;seven days ago
;start_time = (strsplit(start_time,'/',/extract))[0]

timespan,start_date,duration

for xx=0,1 do begin
if xx eq 0 then probe = 'a'
if xx eq 1 then probe = 'b'

sc=probe

;load B1 collection times
rbsp_load_efw_burst_times
rbsp_load_efw_b1,probe=probe

if keyword_set(manual_b1) then man_b1

if ~keyword_set(manual_b1) then options,'rbsp'+sc+'_efw_b1_fmt_B1_available',color=0
                                options,'rbsp'+sc+'_efw_b1_fmt_B1_available','labels','  B1 Collected'

  ; load spectrograms.
    rbsp_efw_init
    !rbsp_efw.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/' 
    rbsp_load_efw_spec, probe = probe, type = 'calibrated'
    pre0 = 'rbsp'+probe+'_efw_'
    varspec = pre0+'64_spec'+['0','4']

tplot,['rbsp'+probe+'_efw_64_spec0','rbsp'+probe+'_efw_64_spec4']

if xx eq 0 then load_freq_v2  ; creats tplot vars : frequencies (fce,fce/2, lower hybrid)
if xx eq 1 then load_freq_v2,/probe_b

sc=probe
tplot,['rbsp'+sc+'_efw_64_spec0','rbsp'+sc+'_efw_playback','rbsp'+sc+'_efw_vb1_available']

if xx eq 0 then read_log_file,'a'
if xx eq 1 then read_log_file,'b' ;gets the requested playback times

get_data,'rbsp'+sc+'_efw_playback',data=pbk
store_data,'rbsp'+sc+'_efw_request',data={x:pbk.x,y:pbk.y+1.6} 
options,'rbsp'+sc+'_efw_request','labels','  B1 Requested'
options,'rbsp'+sc+'_efw_request',color=2

get_data,'rbsp'+sc+'_efw_download',data=pbk
store_data,'rbsp'+sc+'_efw_download2',data={x:pbk.x,y:pbk.y+2.5}
options,'rbsp'+sc+'_efw_download2','labels','  B1 Downloaded'
options,'rbsp'+sc+'_efw_download2',color=4

;gets playback from b1_status_crib
;get_data,'rbsp'+sc+'_efw_vb1_available',data=pbk
;pbk.y[where(pbk.y eq 0.0)]=!values.f_nan
;store_data,'rbsp'+sc+'_playback',data={x:pbk.x,y:pbk.y+2.0}
;options,'rbsp'+sc+'_playback',colors=4

options,'rbsp'+sc+'_efw_download2',thick=40
options,'rbsp'+sc+'_efw_request',thick=40
options,'rbsp'+sc+'_efw_b1_fmt_B1_available',thick=5


if ~keyword_set(manual_b1) then begin

store_data,'RBSP'+sc+'-b1-efw!Cspec!Cplayback',data=['rbsp'+sc+'_efw_64_spec0','rbsp'+sc+'_efw_b1_fmt_B1_available',$
'rbsp'+sc+'_efw_request','rbsp'+sc+'_efw_download2','rbsp'+sc+'_frequencies']

;store_data,'RBSP'+sc+'-b1-efw!Cspec!Cplayback',data=['rbsp'+sc+'_efw_64_spec0','rbsp'+sc+'_efw_b1_fmt_B1_available',$
;'rbsp'+sc+'_efw_request','rbsp'+sc+'_efw_download2']

endif else begin

get_data,'rbsp'+sc+'_efw_b1_fmt_B1_available',data = man_b1_names

store_data,'RBSP'+sc+'-b1-efw!Cspec!Cplayback',data=['rbsp'+sc+'_efw_64_spec0','rbsp'+sc+'_efw_b1_fmt_B1_available',$
'rbsp'+sc+'_efw_request','rbsp'+sc+'_efw_download2','rbsp'+sc+'_frequencies',man_b1_names]

endelse

ylim,['RBSP'+sc+'-b1-efw!Cspec!Cplayback'],0.5,10000

endfor 


tplot,['RBSPa-b1-efw!Cspec!Cplayback','RBSPb-b1-efw!Cspec!Cplayback'],title='RBSP A B b1 playback status as of '+today


get_timespan,ts

dur = round((ts[1]-ts[0])/(24.*3600.))

for yy=0,dur-1 do begin

stime = time_string(ts[0]+yy*24.*3600.)
timespan,stime,1

tplot,['RBSPa-b1-efw!Cspec!Cplayback','RBSPb-b1-efw!Cspec!Cplayback'],title='RBSP A B b1 playback status as of '+today

get_timespan,ts2
plot_date = time_string(ts2[0]+3600.)
plot_date = (strsplit(plot_date,'/',/extract))[0]

popen,'RBSP_AB_spec_b1_plbk_status_for_'+plot_date+'_as_of_'+today+'.ps'

tplot,['RBSPa-b1-efw!Cspec!Cplayback','RBSPb-b1-efw!Cspec!Cplayback'],title='RBSP A B b1 playback status as of '+today

pclose

spawn,'ps2pdf '+'RBSP_AB_spec_b1_plbk_status_for_'+plot_date+'_as_of_'+today+'.ps'
spawn,'mv '+'RBSP_AB_spec_b1_plbk_status_for_'+plot_date+'_as_of_'+today+'.pdf'+' ~/tohban/plots/'
spawn,'rm '+'RBSP_AB_spec_b1_plbk_status_for_'+plot_date+'_as_of_'+today+'.ps'


endfor

print,'Version updated Feb 6 2016'
end
