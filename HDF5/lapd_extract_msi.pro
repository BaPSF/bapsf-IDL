COMPILE_OPT IDL2, HIDDEN
;FORWARD_FUNCTION lapd_port_to_z,lapd_z_to_port,mean,moment


c0=complex(0.0,0.0)
;root_path='/Users/vincena/data/recon01/'
root_path='./'
hdf5_path=root_path;+'hdf5/'
!PATH = hdf5_path + ' ' + !PATH  ; the separation character ';' is for Windows

; Create the object.
HDF5_file = OBJ_NEW('HDF5_file')

; Create/open an HDF5 file.
input_file = DIALOG_PICKFILE(PATH=hdf5_path)
;input_file = hdf5_path+'p49_xy_SIS_setup.hdf5'
IF (input_file EQ '') THEN GOTO, Cleanup

print, ''
print, '*********************************************************'
IF (FILE_TEST(input_file) EQ 1) THEN BEGIN
     print, 'Opening: ', input_file
     HDF5_file->Open, input_file, WRITE_FLAG=0 ;Open read-only
ENDIF

group_names = HDF5_file->Read_group_names()

msi_test = WHERE(group_names EQ 'MSI')

IF (msi_test[0] EQ -1) THEN BEGIN
 PRINT,'No machine state information group found.'
 PRINT,'Unable to create MSI data structure.'
 GOTO, Cleanup
ENDIF

PRINT,'Machine state information located.'

PRINT,''
PRINT,'-----------------------------------'


PRINT,'-----------------------------------'
msi_group = HDF5_file->Open_group('MSI')

msi_version=float(msi_group->Read_attribute('MSI version'))
PRINT,strcompress('MSI Version = '+string(msi_version))
PRINT,'-----------------------------------'

PRINT,'Meta information:'
temp_group = HDF5_file->Open_group('MSI/Magnetic field')
temp_dataset = temp_group->Read_dataset('Magnetic field profile')
n_msi = n_elements(temp_dataset._data[0,*])
print,strcompress('number of MSI snapshots taken = '+string(n_msi))
temp_summary = temp_group->Read_dataset('Magnetic field summary')
msi_timestamps = temp_summary._DATA.TIMESTAMP
print,strcompress('Datarun duration: '+string((msi_timestamps[n_msi-1]-msi_timestamps[0])/3600.)+' hours.')
OBJ_DESTROY, temp_group

window,0,xsize=700,ysize=1000
!P.charsize=3
!P.multi=[0,0,5]
!P.ticklen=1
!P.thick=2


PRINT,'-----------------------------------'
PRINT,'Processing magnetic field information'
bfield_group = HDF5_file->Open_group('MSI/Magnetic field')
msi_b0 = bfield_group->Read_simple_float_dataset('Magnetic field profile')
msi_b0_z = float(bfield_group->Read_attribute('Profile z locations'))
OBJ_DESTROY, bfield_group
msi_b0_ports = lapd_z_to_port(msi_b0_z)
;plot, msi_b0_z,msi_b0[*,0]
z_cathode = 1709.25 ;cm
z_anode = z_cathode - 50.2 ;cm
p_cathode = lapd_z_to_port(z_cathode)
p_anode   = lapd_z_to_port(z_anode)
plot, msi_b0_ports,msi_b0[*,0],xtitle='port number',ytitle='B0 (G)',$
 xgridstyle=1,ygridstyle=1
FOR i=1,n_msi-1 DO oplot, msi_b0_ports,msi_b0[*,i],color='ff00'x
plots,[1,1]*p_cathode,!y.crange,color='ff'x ;cathode
plots,[1,1]*p_anode,!y.crange,color='ff'x ;anode
plots,[1,1]*53.,!y.crange,color='ff'x ;last port
PRINT,'-----------------------------------'



PRINT,'-----------------------------------'
PRINT,'Processing plasma discharge pulser data'
discharge_group = HDF5_file->Open_group('MSI/Discharge')

discharge_dt = float(discharge_group->Read_attribute('Timestep'))
discharge_t0 = float(discharge_group->Read_attribute('Start time'))


discharge_current = discharge_group->Read_simple_float_dataset('Discharge current')
discharge_ca_voltage = discharge_group->Read_simple_float_dataset('Cathode-anode voltage')

discharge_nt = n_elements(discharge_current[*,0])
discharge_tvals = findgen(discharge_nt)*discharge_dt + discharge_t0
discharge_tvals_ms = discharge_tvals*1e3
plot,discharge_tvals_ms,discharge_current[*,0],xtitle='time (msec)',ytitle='Discharge current (Amperes)',xgridstyle=1,ygridstyle=1
FOR i=1,n_msi-1 DO oplot,discharge_tvals_ms,discharge_current[*,i],color='ffff'x

plot,discharge_tvals_ms,discharge_ca_voltage[*,0],xtitle='time (msec)',ytitle='Cathode-Anode Voltage (Volts)',xgridstyle=1,ygridstyle=1
FOR i=1,n_msi-1 DO oplot,discharge_tvals_ms,discharge_ca_voltage[*,i],color='ffff00'x

discharge_summary = discharge_group->Read_dataset('Discharge summary')
discharge_pulse_lengths = discharge_summary._DATA.PULSE_LENGTH
discharge_peak_currents = discharge_summary._DATA.PEAK_CURRENT
discharge_bank_voltages = discharge_summary._DATA.BANK_VOLTAGE
discharge_dvfs = discharge_summary._DATA.DATA_VALID ;data valid flags

IF (n_msi EQ 1 ) THEN BEGIN
 PRINT,'This appears to be an aborted datarun'
 discharge_bank_voltage = discharge_bank_voltages[0]
 discharge_bank_voltage_stddev = float(0.)
 discharge_peak_current = discharge_peak_currents[0]
 discharge_peak_current_stddev = float(0.)
 discharge_pulse_length = discharge_pulse_lengths[0]
 discharge_pulse_length_stddev = float(0.)
ENDIF ELSE BEGIN
 discharge_bank_voltage = mean(discharge_bank_voltages)
 discharge_bank_voltage_stddev = STDEV(discharge_bank_voltages)
 discharge_peak_current = mean(discharge_peak_currents)
 discharge_peak_current_stddev = STDEV(discharge_peak_currents)
 discharge_pulse_length = mean(discharge_pulse_lengths)
 discharge_pulse_length_stddev = STDEV(discharge_pulse_lengths)
ENDELSE


print,strcompress('Discharge bank voltage: '+string(discharge_bank_voltage)+$
 ' +/- '+string(discharge_bank_voltage_stddev)+ ' Volts')

print,strcompress('Discharge peak current: '+string(discharge_peak_current)+$
 ' +/- '+string(discharge_peak_current_stddev)+ ' Amperes')

print,strcompress('Discharge pulese length: '+string(discharge_pulse_length)+$
 ' +/- '+string(discharge_pulse_length_stddev)+ ' seconds')

OBJ_DESTROY,discharge_group
PRINT,'-----------------------------------'
PRINT,''





PRINT,'-----------------------------------'
PRINT,'Processing MSI Interferometer array'
uwave_group = HDF5_file->Open_group('MSI/Interferometer array')
uwave_group_names = uwave_group->Read_group_names()
uwave_nunits = n_elements(uwave_group) ;this should be equal to the 'Interferometer count' attribute of the 'Interferometer array' group
uwave_dts     = fltarr(uwave_nunits)
uwave_t0s     = fltarr(uwave_nunits)
uwave_zs      = fltarr(uwave_nunits)
uwave_nbarls  = fltarr(uwave_nunits)


temp_group = HDF5_file->Open_group('MSI/Interferometer array/Interferometer [0]')
temp_dataset = temp_group->Read_simple_float_dataset('Interferometer trace')
uwave_nt = n_elements(temp_dataset[*,0])
temp_dt = float(temp_group->Read_attribute('Timestep'))
temp_t0 = float(temp_group->Read_attribute('Start time'))
OBJ_DESTROY,temp_group
plot,1e3*((findgen(uwave_nt)*temp_dt+temp_t0)),temp_dataset[*,0],$
 xtitle='time (msec)',ytitle='output (V)'

uwave_traces  = fltarr(uwave_nt,n_msi,uwave_nunits)
uwave_tvals   = fltarr(uwave_nt,uwave_nunits)


FOR i=0, uwave_nunits-1 DO BEGIN
 interf_name  = uwave_group_names[i]
 temp_group   = uwave_group->Open_group(interf_name)
 uwave_dts[i] = float(temp_group->Read_attribute('Timestep'))
 uwave_t0s[i] = float(temp_group->Read_attribute('Start time'))
 uwave_zs[i]  = float(temp_group->Read_attribute('z location'))
 uwave_nbarls[i]  = float(temp_group->Read_attribute('n_bar_L'))
 uwave_traces[*,*,i] = temp_group->Read_simple_float_dataset('Interferometer trace')
 
 uwave_tvals[*,i] = findgen(uwave_nt)*uwave_dts[i]+uwave_t0s[i]
 FOR j = 0,n_msi-1 DO BEGIN
  oplot,1e3*uwave_tvals[*,i],uwave_traces[*,j,i],color='ff00ff'x
 ENDFOR
 OBJ_DESTROY,temp_group
ENDFOR


OBJ_DESTROY,uwave_group
PRINT,'-----------------------------------'



PRINT,'-----------------------------------'
PRINT,'Processing gas pressure information'
gas_group = HDF5_file->Open_group('MSI/Gas pressure')
gas_rga = abs(gas_group->Read_simple_float_dataset('RGA partial pressures'))
gas_rga_amus = long(reform(gas_group->Read_attribute('RGA AMUs')))
gas_rga_namus = n_elements(gas_rga_amus)

gas_name_table = strarr(gas_rga_namus)
gas_name_table[*] = strcompress('Mass '+string(INDGEN(gas_rga_namus)+1)+' amu')
gas_short_name_table = gas_name_table
IF (msi_version le 0.5) THEN BEGIN ;uses masses 1 to 50 in ascending order
 ;The rga cannot distinguish H2 from D2, nor N2 from CO
 gas_name_table[2-1]='Hydrogen' & gas_short_name_table[2-1] = 'H2/D2'
 gas_name_table[4-1]='Helium' & gas_short_name_table[4-1] = 'He'
 gas_name_table[18-1]='Water' & gas_short_name_table[18-1] = 'H20'
 gas_name_table[20-1]='Neon' & gas_short_name_table[20-1] = 'Ne'
 gas_name_table[40-1]='Argon' & gas_short_name_table[40-1] = 'Ar'
ENDIF

gas_summary = gas_group->Read_dataset('Gas pressure summary')
gas_peak_amus = gas_summary._DATA.PEAK_AMU
gas_fill_pressures = gas_summary._DATA.FILL_PRESSURE
gas_peak_amu = gas_peak_amus[0]


IF (n_msi EQ 1 ) THEN BEGIN
 gas_fill_pressure = gas_fill_pressures[0]
 gas_fill_pressure_stddev = float(0.)
ENDIF ELSE BEGIN
 gas_fill_pressure = mean(gas_fill_pressures)
 gas_fill_pressure_stddev = STDEV(gas_fill_pressures)
ENDELSE


OBJ_DESTROY,gas_group
plot,gas_rga_amus,alog10(gas_rga),psym=3,xticks=gas_rga_namus/5,xtitle='AMU',ytitle='log10 torr'
gas_major_species = strcompress(gas_name_table[gas_peak_amu-1],/remove_all)
print,'Majority species: '+gas_major_species
print,strcompress('Machine fill pressure: '+string(gas_fill_pressure)+$
 ' +/- '+string(gas_fill_pressure_stddev)+ ' torr')

FOR i=0, gas_rga_namus-1 DO BEGIN
 plots,[1,1]*gas_rga_amus[i],[!y.crange[0],alog10(gas_rga[i])],thick=3
ENDFOR
 plots,[1,1]*gas_rga_amus[gas_peak_amu-1],[!y.crange[0],alog10(gas_rga[gas_peak_amu-1])],thick=3,color='ff'x

PRINT,'-----------------------------------'




PRINT,'-----------------------------------'
PRINT,'Processing cathode heater information'
heater_group = HDF5_file->Open_group('MSI/Heater')
OBJ_DESTROY,heater_group
PRINT,'-----------------------------------'






Cleanup:
OBJ_DESTROY, HDF5_file
print,'done'


end
