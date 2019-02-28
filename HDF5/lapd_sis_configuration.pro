FUNCTION LAPD_SIS_CONFIGURATION,input_file,requested_config_name
;Import Struck Innovative Systems SIS3301-class digitizer configuration
;from an LAPD HDF5 datarun file.
;
;Written by Steve Vincena, 7/31/2007
;
;
;Modification history:
;9/9/9 STV If there are multiple configurations, the function no longer
;          chooses the first one, but takes the one that matches the name for the first
;          dataset in the SIS 3301 group
;12/9/2009 STV  Added the ability to request a specific configuration name.
;
;
PRINT,'---------------------------------------------------'
PRINT,'SIS3301 MODULE: Reading configuration for digitizer'
!Quiet=1
sis_structure = {dt:float(0.)}

; Open HDF5 file.
IF (input_file EQ '') THEN GOTO, Cleanup

; Create the object.
HDF5_file = OBJ_NEW('HDF5_file')

; Open an HDF5 file.
IF (FILE_TEST(input_file) EQ 1) THEN HDF5_file->Open, input_file


;------Attempt to open raw data and configuration group------------------
rac_group = HDF5_file->Open_group('Raw data + config')
rac_subgroup_names = rac_group->Read_group_names()
OBJ_DESTROY,rac_group

;-------------Process SIS3301 digitizer group if it exists-------------------
sis_group_test = WHERE(rac_subgroup_names EQ 'SIS 3301')
IF (sis_group_test[0] NE -1) THEN BEGIN
;;;;;;;;;;;;;begin import;;;;;;;;;




;--------read SIS 3301 information--------------------------------------------
sis_group_name = '/Raw data + config/SIS 3301'
sis_group=HDF5_file->Open_group(sis_group_name)
sis_dataset_names=sis_group->Read_dataset_names()



sis_config_group_names=sis_group->Read_group_names()

short_config_names=sis_config_group_names

;Strip 'Configuration: ' from names
FOR i=0,N_ELEMENTS(sis_config_group_names)-1 DO BEGIN
 short_config_names[i] = strmid(sis_config_group_names[i],15)
END


CASE N_PARAMS() OF

  ;No configuration name supplied
  1: BEGIN
    PRINT,'***********************'
    PRINT,'No SIS3301 configuration name supplied. Attempting to pick one out.'
    IF (N_ELEMENTS(short_config_names) GT 1) THEN BEGIN
      PRINT,'SIS3301 MODULE: Available configurations:'
      PRINT,short_config_names
      PRINT
      PRINT,'***********************'
      PRINT,'SIS3301 MODULE: WARNING: Multiple configurations detected.'


      PRINT,'SIS3301 MODULE: Using the configuration group name that matches the first dataset name.'
      first_sis_dataset_name=reform(sis_dataset_names[0])
      selected_config_group_name = 'Configuration: '+strmid(first_sis_dataset_name,0,stregex(first_sis_dataset_name,'\[')-1)

      PRINT

      PRINT,'SIS3301 MODULE: This configuration group name is "'+selected_config_group_name+'".'
      print,'***********************'

    ENDIF ELSE BEGIN;Done with more than one sis group case
      print,'Only one SIS configuration found: '+short_config_names[0]+' Using this one.'
      selected_config_group_name = reform(sis_config_group_names[0])
    ENDELSE

  END ; One-argument case

  ;configuration name was supplied
  2: BEGIN
    PRINT,'---'
    PRINT,'Requested configuration: '+requested_config_name
    ii = WHERE(sis_config_group_names EQ ('Configuration: '+requested_config_name) )
    IF (ii[0] EQ -1) THEN BEGIN
      MESSAGE,'Requested SIS configuration name ('+requested_config_name+') does not mactch any available configuration.'
      PRINT,'Valid configuration names:'
      PRINT,short_config_names
      STOP
    ENDIF
    ;requested name found in SIS group. Use it.
    selected_config_group_name = 'Configuration: '+requested_config_name

  END ;Two-argument case

  ELSE: MESSAGE,'Wrong number of arguments.'

ENDCASE
PRINT,'---'


; Open the config group that was selected
sis_config_group=sis_group->Open_group(selected_config_group_name)


clock_rate_string=sis_config_group->Read_attribute('Clock rate')
print,'Digitizer clock rate: '+clock_rate_string
iclock_rate_MHz = float(0.) & s1='' &  s2=''
reads,clock_rate_string,s1,iclock_rate_MHz,s2,format="(A8,I0,A4)"

shots_to_average=sis_config_group->Read_attribute('Shots to average')
;print,'shots to average=',shots_to_average

samples_to_average_string=sis_config_group->Read_attribute('Samples to average')
IF (samples_to_average_string EQ 'No averaging') THEN isamples_to_average=1 ELSE BEGIN
reads,samples_to_average_string,s1,isamples_to_average,s2,format="(A8,' ',I0,' ',A)"
ENDELSE
;print,'samples to average=',isamples_to_average

clock_rate=float(iclock_rate_MHz)*1e6/float(isamples_to_average)
print,strcompress('Effective clock rate: '+string(clock_rate/1e6)+' MHz')
dt=1./clock_rate

;--------extract number of samples for each board in the configuration----------------
sis_board_group_names=sis_config_group->Read_group_names()
n_sis_boards=n_elements(sis_board_group_names)
ntvec=lonarr(n_sis_boards)

for i_board=0L,n_sis_boards-1 do begin
 sis_board_group=sis_config_group->Open_group(sis_board_group_names[i_board])
 ntvec[i_board]=long(sis_board_group->Read_attribute('Board samples'))
 OBJ_DESTROY,sis_board_group
endfor
;-----------------------------------------------------------------------------


OBJ_DESTROY,sis_config_group

;Total number of datasets in the SIS3301 group (two for each channel)
n_datasets=N_ELEMENTS(sis_dataset_names)


;Now, count the number of datasets based on the configuration name, not total number

; Are there multiple channels digitized?
; Note: There are exactly two datasets in the SIS group for each channel digitized.
; One for the dataset and one for the header dataset
IF (n_datasets GT 2) THEN BEGIN

;   Are there multiple configurations?
    IF (N_ELEMENTS(short_config_names) GT 1) THEN BEGIN
;     parse out just the configuration part of the dataset names, ie no ' [3:0]'
;     or ' [3:0] headers' substrings
      dataset_prefix_names=STRARR(n_datasets)
      FOR i=0,n_datasets-1 DO BEGIN
        temp_ds_name = reform(sis_dataset_names[i])
        dataset_prefix_names[i] = strmid(temp_ds_name,0,stregex(temp_ds_name,'\[')-1)
      ENDFOR
;     Find those indices that match the chosen sis configuratioe
      short_selected_config_name = reform(strmid(selected_config_group_name,15))
      index_result = WHERE(dataset_prefix_names EQ short_selected_config_name[0])
;     Select out just the matching ones
      sis_dataset_names = sis_dataset_names[index_result]
      ;update the resulting number of datasets
      n_datasets=N_ELEMENTS(sis_dataset_names)
    ENDIF; multiple configurations
    n_data_datasets=n_datasets/2
    n_header_datasets=n_datasets/2

;   Now just sort the dataset and header dataset names
    sis_data_dataset_names=sis_dataset_names[indgen(n_data_datasets)*2]
    sis_header_dataset_names=sis_dataset_names[indgen(n_header_datasets)*2+1]

;Just one channel digitized, but still return as a vector for generalized post-processing
ENDIF ELSE BEGIN
  n_data_datasets=1L
  n_header_datasets=1L
  sis_data_dataset_names=[sis_dataset_names[0]]
  sis_header_dataset_names=[sis_dataset_names[1]]
ENDELSE





dt=[dt] ;this syntax because future versions of this program
;        should return a vector of dt's, one for each channel.
;        Upstream analysis programs shouldn't have to keep track
;        of which digitizers used fixed parameters for all channels
;        or differ by board, or by channel itself.
clock_rate=[clock_rate]

channel_rates = clock_rate
;NOTE there are many more which we have not yet processed
sis_structure = CREATE_STRUCT('nchan',n_data_datasets,'nt',ntvec,$
      'dt',dt,'digitization_rate',channel_rates,$
      'dataset_names',sis_data_dataset_names,$
      'header_names',sis_header_dataset_names)
ENDIF


OBJ_DESTROY,sis_group
OBJ_DESTROY,rac_group

OBJ_DESTROY, HDF5_file
Cleanup:

RETURN,sis_structure

END
