FUNCTION LAPD_TVS_CONFIGURATION,input_file
;Import TVS600 class digitizer configuration from an LAPD HDF5 datarun file.
;
;Written by Steve Vincena, 7/23/2007
;
;
;Modification history:
;
;
tvs_structure = {dt:float(0.)}

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

;-------------Process TVS645A digitizer group if it exists-------------------
tvs_group_test = WHERE(rac_subgroup_names EQ 'TVS645A')
IF (tvs_group_test[0] NE -1) THEN BEGIN


tvs_group_name = '/Raw data + config/TVS645A'
tvs_group=HDF5_file->Open_group(tvs_group_name)
tvs_dataset_names=tvs_group->Read_dataset_names()
n_channels=N_ELEMENTS(tvs_dataset_names)/2
tvs_real_dataset_names=tvs_dataset_names[indgen(n_channels)*2]
tvs_header_dataset_names=tvs_dataset_names[indgen(n_channels)*2+1]

print,'Number of TVS645A channels digitized:',n_channels
digitizer_units=lonarr(n_channels)
digitizer_channels=lonarr(n_channels)
channel_config_names=strarr(n_channels)
channel_nts = ulon64arr(n_channels)
channel_dts = fltarr(n_channels)
channel_nshots = ulon64arr(n_channels)
sr_possibilities=['','k','m','g']
sr_multipliers=float([1.0,1e3,1e6,1e9])

FOR i_channel = 0,n_channels-1 DO BEGIN
 dataset_index=2*i_channel
 dataset_string=tvs_dataset_names[dataset_index]
 digitizer_units[i_channel]=long(stregex(stregex(dataset_string,'\[[0-9]+',/extract),'[0-9]+',/extract))
 digitizer_channels[i_channel]=long(stregex(stregex(dataset_string,'[0-9]+\]',/extract),'[0-9]+',/extract))
channel_config_names[i_channel] = 'Configuration: '+strmid(dataset_string,0,stregex(dataset_string,'\[')-1)
 horizontal_group_name=channel_config_names[i_channel]+'/'+ $
   'Digitizer units['+strcompress(string(digitizer_units[i_channel]),/remove_all)+']'+'/Horizontal'
 horizontal_group = tvs_group->Open_group(horizontal_group_name)
 sample_rate_string=horizontal_group->Read_attribute('Sample rate')
 sample_rate_mantissa=float(sample_rate_string)
 sr_symbol = strlowcase(strmid(sample_rate_string,strlen(sample_rate_string)-1))
 sample_rate_multiplier=sr_multipliers[WHERE(sr_possibilities EQ sr_symbol)]
 channel_dts[i_channel] = 1./(sample_rate_mantissa * sample_rate_multiplier[0])
 nsample_string=horizontal_group->Read_attribute('Record length')
 channel_nts[i_channel]=ulong64(nsample_string)
; channel_nshots[i_channel] = (tvs_group->Read_dataset(dataset_string))._NELEMENTS/channel_nts[i_channel]/nx/ny/nz

 OBJ_DESTROY,horizontal_group

ENDFOR

channel_rates = 1./channel_dts
;NOTE there are many more which we have not yet processed
tvs_structure = CREATE_STRUCT('nchan',n_channels,'nt',channel_nts,$
      'dt',channel_dts,'digitization_rate',channel_rates,$
      'dataset_names',tvs_real_dataset_names,$
      'header_names',tvs_header_dataset_names)
ENDIF


OBJ_DESTROY,tvs_group
OBJ_DESTROY,rac_group

OBJ_DESTROY, HDF5_file
Cleanup:

RETURN,tvs_structure

END
