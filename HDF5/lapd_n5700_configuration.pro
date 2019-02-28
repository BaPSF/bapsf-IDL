FUNCTION lapd_n5700_configuration,input_file
;
;Returns an IDL structure containing the parsed information
;of the 'N5700_PS' Agilent programmable power supply configuration
;saved by the ACQ II system to an hdf5 file.
;
;Written by Steve Vincena, 12/06/2008
;
;Modification history:
;
;
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
  print,'-------------------------------------------------'
  print, 'Opening: ', input_file
  HDF5_file->Open, input_file
ENDIF

;------Attempt to open raw data and configuration group------------------
rac_group = HDF5_file->Open_group('Raw data + config')
rac_subgroup_names = rac_group->Read_group_names()
OBJ_DESTROY,rac_group
;-------------------------------------------------
;-------------process 6K Compumotor if it exists-------------------
n5700_group_test = WHERE(rac_subgroup_names EQ 'N5700_PS')
IF (n5700_group_test[0] NE -1) THEN BEGIN

  n5700_group_name='/Raw data + config/N5700_PS'
  print,'Power supply group =',n5700_group_name

  ;-------------process run-time list ----------
  ;Open Runtime list of current and voltages for every shot number
  ;If there is a N5700_PS group, there must be a Runtime List. No error check here
  n5700_rtl_dataset  = HDF5_file->Read_dataset(n5700_group_name+'/Run time list')
  n5700_shot_number  = reform(ulong64(n5700_rtl_dataset._DATA.SHOT_NUMBER))
  n5700_current_list = reform(float(n5700_rtl_dataset._DATA.CURRENT)) ;Amperes
  n5700_voltage_list = reform(float(n5700_rtl_dataset._DATA.VOLTAGE)) ;Volts
  n5700_config_list  = reform(n5700_rtl_dataset._DATA.CONFIGURATION_NAME)

  n_total = n_elements(n5700_voltage_list)
  n_configs=n_elements(uniq(n5700_config_list,sort(n5700_config_list)))

  IF  (n_configs GT 1)  THEN BEGIN
    PRINT,'Warning: this program currently outputs just the list of currents, voltages, and configuration names. It does not split lists.'
  ENDIF
 


ENDIF ELSE BEGIN ;end there was an N5700_PS group

  print,'No Agilent power supply of type N5700 found for this datarun.'
  print,'Creating default data structure instead.'
  n_total = ulong(1)
  n_configs = ulong(1)
  n5700_shot_number  = fltarr(n_total)
  n5700_current_list = fltarr(n_total)
  n5700_voltage_list = fltarr(n_total)
  n5700_config_list  = ['']


ENDELSE
  n5700_rtl = CREATE_STRUCT('n',n_total,'n_configs',n_configs,$
             'currents',n5700_current_list,'voltages',n5700_voltage_list, $
             'configs',n5700_config_list,'shot_numbers',n5700_shot_number)

OBJ_DESTROY, HDF5_file

out_message='Done.'
CLEANUP:
print,out_message
RETURN,n5700_rtl

END
