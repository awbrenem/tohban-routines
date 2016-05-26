pro load_E_dat,date,sc,burst=burst

probe=sc

timespan,date,1,/day
        get_timespan,ts
        date=time_string(ts[0])

         rbsp_efw_init
        !rbsp_efw.user_agent = ''

        rbsp_load_spice_kernels


;load E field

rbsp_load_efw_waveform_l3,probe=sc


;load potential

rbsp_load_efw_waveform, probe=probe,  type='calibrated',datatype=['vsvy']

split_vec, 'rbsp?_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']

store_data,'V1-and-V2!CVolts',data=['rbsp'+sc+'_efw_vsvy_V1','rbsp'+sc+'_efw_vsvy_V2']
store_data,'V3-and-V4!CVolts',data=['rbsp'+sc+'_efw_vsvy_V3','rbsp'+sc+'_efw_vsvy_V4']

get_data,'rbsp'+sc+'_efw_vsvy_V1',data=V1
get_data,'rbsp'+sc+'_efw_vsvy_V2',data=V2
if is_struct(V1) then SC_pot=(V1.y+V2.y)/2

get_data,'rbsp'+sc+'_efw_vsvy_V3',data=V3
get_data,'rbsp'+sc+'_efw_vsvy_V4',data=V4


store_data,'-SC-POT.!CVOLTS',data={x:V1.x,y:SC_pot},dlim={constant:[0]}

e1 = (-V2.y + V1.y)*10
e2 = (-V4.y + V3.y)*10

store_data,'E!Cv1-v2!Cv3-v4!CmV/m',data={x:V1.x,y:[[e1],[e2]]},dlim={colors:[2,4],labels:['v1-v2','v3-v4']}



rbsp_load_efw_esvy_mgse,probe=probe,/no_spice_load
split_vec,'rbsp'+probe+'_efw_esvy'                                         
store_data,'EUV!CmV/m',data=['rbsp'+probe+'_efw_esvy_x','rbsp'+probe+'_efw_esvy_y']



split_vec,'rbsp'+probe+'_efw_esvy_mgse'
store_data,'E-mgse',data=['rbsp'+probe+'_efw_esvy_mgse_y','rbsp'+probe+'_efw_esvy_mgse_z']


tplot,['V1-and-V2!CVolts','V3-and-V4!CVolts','-SC-POT.!CVOLTS','*IBIAS1*','E!Cv1-v2!Cv3-v4!CmV/m','rbsp'+sc+'_efw_e-hires-uvw_efield_uvw','E-mgse']




if keyword_set(burst) then begin 

;rbsp_load_efw_waveform, probe=probe,  type='calibrated',datatype=['eb1']

if keyword_set(burst) then rbsp_load_efw_waveform, probe=probe,  type='calibrated',datatype=['vb1']
if keyword_set(burst) then rbsp_load_efw_waveform, probe=probe,  type='calibrated',datatype=['eb2']

;if keyword_set(burst) then rbsp_load_efw_waveform, probe=probe,  type='raw',datatype=['vb1']
;if keyword_set(burst) then rbsp_load_efw_waveform, probe=probe,  type='raw',datatype=['eb2']


split_vec,'rbsp'+sc+'_efw_vb1'                                    
split_vec,'rbsp'+sc+'_efw_eb2' 

store_data,'b1v1-and-b1v2',data=['rbsp'+sc+'_efw_vb1_0','rbsp'+sc+'_efw_vb1_1']
store_data,'b1v3-and-b1v4',data=['rbsp'+sc+'_efw_vb1_2','rbsp'+sc+'_efw_vb1_3']

get_data,'rbsp'+sc+'_efw_vb1_1',data=bv2
get_data,'rbsp'+sc+'_efw_vb1_0',data=bv1
get_data,'rbsp'+sc+'_efw_vb1_2',data=bv3
get_data,'rbsp'+sc+'_efw_vb1_3',data=bv4

eb1u = (bv1.y-bv2.y)*1000./100.
eb1v = (bv3.y-bv4.y)*1000./100.

store_data,'E-burst-1!CmV/m',data={x:bv1.x,y:[[eb1u],[eb1v]]},dlim={labels:['eb1_v1-v2','eb1_v3-v4'],colors:[2,4]}

print,'the b1 data rate is:'
print,1/find_datarate(bv2.x[0:100])

store_data,'Eb2',data=['rbsp'+sc+'_efw_eb2_x','rbsp'+sc+'_efw_eb2_y']

get_data,'rbsp'+sc+'_efw_eb2_y',data=b2

print,'the b2 data rate is:'
print,1/find_datarate(b2.x[0:100])

tplot,['rbspa_efw_e-hires-uvw_e_hires_uvw','V1-and-V2!CVolts','V3-and-V4!CVolts','E!Cv1-v2!Cv3-v4!CmV/m','E-burst-1!CmV/m','Eb2']

endif


;routines to load filterbank and spectral plots
;rbsp_load_efw_spec, probe=sc,type='calibrated'

;rbsp_load_efw_fbk,probe=sc,type='calibrated'
;rbsp_split_fbk,sc,/combine


end
