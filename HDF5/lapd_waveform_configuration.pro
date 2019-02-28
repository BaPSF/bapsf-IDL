FUNCTION lapd_waveform_configuration,input_file
;
;Returns an IDL structure containing the parsed information
;of the 'N5700_PS' Agilent programmable power supply configuration
;saved by the ACQ II system to an hdf5 file.
;
;Written by Steve Vincena, 05/22/2009
;Based on lapd_n5700_configuration
;Unfortunately, the command string itself is not part of the Run Time List (RTL), only
; the shot number and the name of the configuration. In the N5700, voltage
; and current were stored in the RTL. We must extract in information
; from the appropriate "Configuration name: <name>" group in the Waveform group.
;
;
;Modification history:
;
;
;Limitations:
; 
;Currently, this function expects only a single list of frequencies to be changing
;and it creates structure tags for the return variable appropriate with this assumption.
;
;This function assumes one configuration. If there are multiple configs, this chooses
;the first one.
;-------------------------------------------------



; Open HDF5 file.

IF (input_file EQ '') THEN BEGIN
  input_file=''
  input_file=dialog_pickfile()
ENDIF
IF (input_file EQ '') THEN BEGIN
  out_message='Error associated with input file'
  GOTO,CLEANUP
ENDIF


; Create the object.

HDF5_file = OBJ_NEW('HDF5_file')

IF (FILE_TEST(input_file) EQ 1) THEN BEGIN

  print,'---------------Waveform Module ------------------------'
  print, 'Opening: ', input_file
  HDF5_file->Open, input_file

ENDIF



;------Attempt to open raw data and configuration group------------------

rac_group = HDF5_file->Open_group('Raw data + config')
rac_subgroup_names = rac_group->Read_group_names()

OBJ_DESTROY,rac_group

;-------------------------------------------------

;-------------process Waveform Module  if it exists-------------------

waveform_group_test = WHERE(rac_subgroup_names EQ 'Waveform')

IF (waveform_group_test[0] NE -1) THEN BEGIN



  waveform_group_name='/Raw data + config/Waveform'

  print,'Waveform group =',waveform_group_name
  
  waveform_group = HDF5_file->Open_group(waveform_group_name)
  waveform_config_group_names = waveform_group->Read_group_names()
  n_configs = n_elements(waveform_config_group_names)

  IF  (n_configs GT 1)  THEN BEGIN
    PRINT,'< lapd_waveform_configuration > Warning: this program currently outputs just the list of currents, voltages, and configuration names. It does not split lists.'
  ENDIF

  config_group = waveform_group->Open_group(waveform_config_group_names[0])

  wcl = config_group->Read_attribute('Waveform command list')

  freqs = float(strsplit(wcl,'FREQ ',/extract,/regex))
  nfreqs = n_elements(freqs)


; for now, ignore the run time list
;
;  ;-------------process run-time list ----------
;  ;
;  ;If there is a Waveform group, there must be a Runtime List. No error check here
;
;  waveform_rtl_dataset  = HDF5_file->Read_dataset(waveform_group_name+'/Run time list')
;  waveform_shot_number  = reform(ulong64(waveform_rtl_dataset._DATA.SHOT_NUMBER))
;  waveform_current_list = reform(float(waveform_rtl_dataset._DATA.CURRENT)) ;Amperes
;  waveform_voltage_list = reform(float(waveform_rtl_dataset._DATA.VOLTAGE)) ;Volts
;  waveform_config_list  = reform(waveform_rtl_dataset._DATA.CONFIGURATION_NAME)
;
;
;  n_total = n_elements(waveform_voltage_list)
;  n_configs=n_elements(uniq(waveform_config_list,sort(waveform_config_list)))
;


  OBJ_DESTROY,config_group
  OBJ_DESTROY,waveform_group
 





ENDIF ELSE BEGIN ;end there was an Waveform group



  print,'No Agilent Waveform module found for this datarun.'
  print,'Creating default data structure instead.'

  ;n_total = ulong(1)
;  n_configs = ulong(1)
;  waveform_shot_number  = fltarr(n_total)
;  waveform_current_list = fltarr(n_total)
;  waveform_voltage_list = fltarr(n_total)
;  waveform_config_list  = ['']
   wcl = ['']
   freqs=fltarr(1)
   nfreqs=long(1)





ENDELSE

  wcl_struct = CREATE_STRUCT('command_list',wcl,'nfreqs',nfreqs,'freqs',freqs)

;  wcl_struct = CREATE_STRUCT('n',n_total,'n_configs',n_configs,$
;             'currents',waveform_current_list,'voltages',waveform_voltage_list, $
;             'configs',waveform_config_list,'shot_numbers',waveform_shot_number)



OBJ_DESTROY, HDF5_file



out_message='Done.'

CLEANUP:

print,out_message

RETURN,wcl_struct



END


