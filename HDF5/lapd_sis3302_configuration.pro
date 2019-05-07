FUNCTION lapd_sis3302_configuration, input_file, requested_config_name, quiet=quiet
COMPILE_OPT IDL2
s='lapd_sis3302_configuration: '
;Import Struck Innovative Systems SIS3302 (100MHZ 16bit) class digitizer
;configuration used by the "SIS Crate" remote digitizer module
;from an LAPD HDF5 datarun file.
;
;based on LAPD_SIS_CONFIGURATION--the first SIS crate with variable number
;of SIS3301 digitizer boards.
;The "SIS Crate" module is based on a fixed configuration of
; (4)  3302 boards
; (2)  3305 boards, and
; (1)  3820 clock/trigger distributer/delay generator
;
;Written by Steve Vincena, 9/26/2012
;
;
;Modification history:
;Oct 17, 2018   => Added 'quiet' option to suppress non-critical print outputs.
;
;
IF quiet EQ 0 THEN BEGIN
  PRINT,'-----------------------------------------------------------------------'
  PRINT,'SIS CRATE, Digitizer type 3302 : Reading configuration for digitizer(s)'
ENDIF
!Quiet=1
sis_structure = {dt:float(0.)}

; Open HDF5 file.
IF (input_file EQ '') THEN input_file = dialog_pickfile(path='./',title='Please choose an HDF5 file')

; Create the object.
HDF5_file = OBJ_NEW('HDF5_file')

; Open an HDF5 file.
IF (FILE_TEST(input_file) EQ 1) THEN HDF5_file->Open, input_file


;------Attempt to open raw data and configuration group------------------
rac_group = HDF5_file->Open_group('Raw data + config')
rac_subgroup_names = rac_group->Read_group_names()
OBJ_DESTROY,rac_group
;
;-------------Process 'SIS crate' group if it exists-------------------
sis_group_test = WHERE(rac_subgroup_names EQ 'SIS crate')
IF (sis_group_test[0] EQ -1) THEN BEGIN
  print,'No SIS crate module associated with this hdf5 file'
  goto,cleanup
ENDIF



sis_group_name = '/Raw data + config/SIS crate'
sis_group=HDF5_file->Open_group(sis_group_name)
sis_dataset_names=sis_group->Read_dataset_names()

;The groups directly under the 'SIS crate' group are different
;configurations used during the datarun
;
sis_config_group_names=sis_group->Read_group_names()


CASE N_PARAMS() OF

  ;No configuration name supplied
  1: BEGIN
    IF quiet EQ 0 THEN BEGIN
      PRINT,'***********************'
      PRINT,'No SIS Crate configuration name supplied. Attempting to pick one out.'
    ENDIF
    IF (N_ELEMENTS(sis_config_group_names) GT 1) THEN BEGIN
      IF quiet EQ 0 THEN BEGIN
        PRINT,'SIS Crate 3302: Available configurations:'
        PRINT,sis_config_group_names
        PRINT
        PRINT,'***********************'
        PRINT,'SIS Crate 3302: WARNING: Multiple configurations detected.'
        PRINT,'SIS Crate 3302: Using the configuration group name that matches the first dataset name.'
      ENDIF
      first_sis_dataset_name=reform(sis_dataset_names[0])
      selected_config_group_name = strmid(first_sis_dataset_name,0,stregex(first_sis_dataset_name,'\[')-1)

      IF quiet EQ 0 THEN BEGIN
        PRINT

        PRINT,'SIS Crate 3302: This configuration group name is "'+selected_config_group_name+'".'
        print,'***********************'
      ENDIF
    ENDIF ELSE BEGIN;Done with more than one sis group case
      IF quiet EQ 0 THEN print,'Only one SIS Crate configuration found: "'+sis_config_group_names[0]+ $
        '." Using this one.'
      selected_config_group_name = reform(sis_config_group_names[0])
    ENDELSE

  END ; One-argument case

  ;configuration name was supplied
  2: BEGIN
    IF quiet EQ 0 THEN BEGIN
      PRINT,'---'
      PRINT,'Requested configuration: '+requested_config_name
    ENDIF
    ii = WHERE(sis_config_group_names EQ requested_config_name)
    IF (ii[0] EQ -1) THEN BEGIN
      MESSAGE,'Requested SIS Crate configuration name ('+requested_config_name+') does not match'+$
        ' any available configuration.'
      PRINT,'Valid configuration names:'
      PRINT,sis_config_group_names
      STOP
    ENDIF
    ;requested name found in SIS group. Use it.
    selected_config_group_name = requested_config_name
  END ;Two-argument case

  ELSE: MESSAGE,'Wrong number of arguments.'

ENDCASE
IF quiet EQ 0 THEN PRINT,'---'


; Open the config group that was selected
sis_config_group=sis_group->Open_group(selected_config_group_name)

;Notes:
;SIS3302 board 1 = Slot 5
;SIS3302 board 2 = Slot 7
;SIS3302 board 3 = Slot 9
;SIS3302 board 4 = Slot 11

;SIS crate 3302 configuration group names  are stored as
;"SIS crate 3302 configurations[n]" where n starts
; at 0 and increses by 1 for each active 3302 board.
;So, if boards 1,2,4 are active, you get groups:
;SIS crate 3302 configurations[0]  <- for board 1 (slot 5)
;SIS crate 3302 configurations[1]  <- for board 2 (slot 9)
;SIS crate 3302 configurations[2]  <- for board 4 (slot 11)

;But, the dataset names are not guaranteed to be in this same order.
;For example, in a test configuration called 'variable_2', this
;was the order of all the datasets which were digitized (including headers):
;variable_2 [Slot 11: SIS 3302 ch 1]
;variable_2 [Slot 11: SIS 3302 ch 1] headers
;variable_2 [Slot 5: SIS 3302 ch 1]
;variable_2 [Slot 5: SIS 3302 ch 1] headers
;variable_2 [Slot 5: SIS 3302 ch 2]
;variable_2 [Slot 5: SIS 3302 ch 2] headers
;variable_2 [Slot 5: SIS 3302 ch 7]
;variable_2 [Slot 5: SIS 3302 ch 7] headers
;variable_2 [Slot 5: SIS 3302 ch 8]
;variable_2 [Slot 5: SIS 3302 ch 8] headers
;variable_2 [Slot 9: SIS 3302 ch 1]
;variable_2 [Slot 9: SIS 3302 ch 1] headers
;variable_2 [Slot 9: SIS 3302 ch 3]
;variable_2 [Slot 9: SIS 3302 ch 3] headers
;variable_2 [Slot 9: SIS 3302 ch 5]
;variable_2 [Slot 9: SIS 3302 ch 5] headers
;variable_2 [Slot 9: SIS 3302 ch 7]
;variable_2 [Slot 9: SIS 3302 ch 7] headers

;So, we need a mapping from a requested real board to a logical board
;We could return an array of type 'structure' that always has
;four indices, initialized with zeros and null string tags, and
;then populate it in the correct order based on what boards
;took data.

;Note that the configuration group contains useful attributes for this.
;For the same example configuration as above, we have
;variable_2 (227692)
;  Group size = 52
;  Number of attributes = 5
;U32[4]    SIS crate base addresses = 1342177280,939524096,1610612736,1744830464
;U32[4]    SIS crate board types = 2,4,2,2
;U32[4]    SIS crate config indices = 0,0,1,2
;I32[1]    SIS crate max average shots = 3
;U32[4]    SIS crate slot numbers = 5,3,9,11

;So, SIS3302 board 3 (slot 9) uses 'SIS crate 3302 configurations[1]'
;By taking only board type 2 from the board types array, we can index

;We could return a structure with params for all 32 channels and
;Then a logical list for the active channels and
;an array of size [4,8] for board and channel.
;It's easiest to go board by board, so...

;Define variables

clock_odd_outputs_strings=['Clock','Start/stop']
clock_even_outputs_strings=['Clock','Start/stop']
clock_source_strings=['Internal 100 MHz (delay locked loop)',$
 '2nd Internal 100 MHz (U580)','External Clock','VME Key Clock']
clock_mode_strings = ['Double clock',$
 'Straight clock','1/2 clock','1/4 clock','User-specified divider']


;global, defined by the 3820 board
 sis3820_config_group = sis_config_group->Open_group('SIS crate 3820 configurations[0]')





;Current use of the SIS crate (09/26/2012) should ONLY be run
;with the clock delay different than the values shown below
clock_freq_div_code      = ulong(1)
clock_freq_div           = ''
clock_mode_code          = ulong(1)
clock_mode               = ''
clock_source_code        = ulong(1)
clock_source             = ''
clock_even_outputs_code  = ulong(1)
clock_even_outputs       = ''
clock_odd_outputs_code   = ulong(0)
clock_odd_outputs        = ''

clock_mode_code = sis3820_config_group->Read_attribute('Clock mode')
clock_mode=clock_mode_strings[clock_mode_code]
if (clock_mode_code ne 1) then begin
  print,s+'Error.'
  print,'Only "Straight clock" mode is handled for SIS3820 board'
  print,'Current SIS3820 clock mode ='+clock_mode
  STOP
endif

clock_source_code = sis3820_config_group->Read_attribute('Clock source')
clock_source=clock_source_strings[clock_source_code]
if (clock_source_code ne 1) then begin
  print,s+'Error.'
  print,'Only "2nd Internal 100MHz (U580)" source is handled for SIS3820 board'
  print,'Current SIS3820 clock source ='+clock_source
  STOP
endif


;Determine user-defined delay from the master clock input to the distributed start trigger
global_clocktick = 1e-8 ;sec
delay_clockticks = sis3820_config_group->Read_attribute('Delay')
delay_seconds            = global_clocktick*double(delay_clockticks)

;Done with sis3820 board
 OBJ_DESTROY,sis3820_config_group


;determine 3302 boards that were used
sis_board_types = sis_config_group->Read_attribute('SIS crate board types')
sis3302_board_indices = where(sis_board_types eq 2)
if (sis3302_board_indices[0] eq -1) then begin
  print,'SIS3302 configuration: no active 3302 boards!'
  stop
endif
sis_all_config_indices = sis_config_group->Read_attribute('SIS crate config indices')
sis3302_config_indices = sis_all_config_indices[sis3302_board_indices]
sis_all_slot_numbers = sis_config_group->Read_attribute('SIS crate slot numbers')
sis3302_slot_numbers = sis_all_slot_numbers[sis3302_board_indices]
sis3302_board_numbers = (sis3302_slot_numbers-5)/2 +1

IF quiet EQ 0 THEN print,'SIS3302 boards used:', sis3302_board_numbers
n_active_boards = n_elements(sis3302_board_numbers)


;by board
;44 attributes per board

dt                = fltarr(4,8)
time_acquired     = dblarr(4,8)
comment           = strarr(4,8)
dc_offset         = dblarr(4,8)
datatype          = strarr(4,8)
channel_enabled   = bytarr(4,8)
channel_number    = ulonarr(4,8)
board_number      = ulonarr(4,8)
samples           = ulonarr(4,8)
nt                = ulonarr(4,8) ;same as 'samples'
sample_averaging  = ulonarr(4,8)
shots_averaged    = ulonarr(4,8)


for i=0,n_active_boards-1 do begin

  ;We assume that the board numbers could be out of order
  iboard  = sis3302_board_numbers[i]-1
  iconfig = sis3302_config_indices[i]

  ;open configuration group for this board
  board_config_name = 'SIS crate 3302 configurations'+$
                    strcompress('['+string(iconfig)+']',/remove_all)
  board_config_group = sis_config_group->Open_group(board_config_name)

  ;Start reading attributes and computing quantities
  ;-------------------------------------------------------------
 

  ;First read quantities that are common to all channels on each board
  ;-------------------------------------------------------------

  ;Hardware sample averaging 0=none, 1= average 2, 2= average 4,...,7=average 128
  hardware_average_code = board_config_group->Read_attribute('Sample averaging (hardware)')
  sample_averaging[iboard,*] = (2L^hardware_average_code)
  dt[iboard,*] = global_clocktick * float(sample_averaging[iboard,*])
  IF quiet EQ 0 THEN print, strcompress('SIS3302 : Board '+string(iboard+1)+ $
      ': Effective clock rate= '+string(1./dt[iboard,0]/1e6)+' MHz')

  ;Samples digitized
  samples[iboard,*] = board_config_group->Read_attribute('Samples')
  nt[iboard,*] = samples[iboard,*]

  ;Number of shots averaged together in software
  shots_averaged[iboard,*] = board_config_group->Read_attribute('Shot averaging (software)')
  
  time_acquired[iboard,*] = double(samples[iboard,*]) * dt[iboard,*]
  board_number[iboard,*] = iboard+1



  ;Now loop through all channels
  ;-------------------------------------------------------------

  for ichan=0,7 do begin

    ;Make a string from the channel number for ease.
    cstring=strcompress(string(ichan+1),/remove_all)

    ;Was the channel active?
    qstring = 'Enabled '+cstring
    active_string = board_config_group->Read_attribute(qstring)
    channel_enabled[iboard,ichan] = (active_string EQ 'TRUE') ? 1 : 0

    ;What was in the 'user comment' field of the configuration?
    qstring = 'Comment '+cstring
    comment[iboard,ichan] = board_config_group->Read_attribute(qstring)

    ;What was the DC offset set by the user on the digitizer?
    qstring = 'DC offset '+cstring
    dc_offset[iboard,ichan] = board_config_group->Read_attribute(qstring)

    ;How did the user label this data type?
    qstring = 'Data type '+cstring
    datatype[iboard,ichan] = board_config_group->Read_attribute(qstring)

    ;The channel number really should be ichan+1, but let's read it from the hdf5 file anyway
    qstring = 'Ch '+cstring
    channel_number[iboard,ichan] = board_config_group->Read_attribute(qstring)

  endfor ; ichan
  ;close configuration group for this board
  OBJ_DESTROY,board_config_group
endfor ; i (active board)

OBJ_DESTROY,sis_config_group
OBJ_DESTROY,sis_group

;by full channel (Not returning these as of 9/26/2012)
chan_dt                = reform(transpose(dt),32)
chan_time_acquired     = reform(transpose(time_acquired),32)
chan_comment           = reform(transpose(comment),32)
chan_dc_offset         = reform(transpose(dc_offset),32)
chan_datatype          = reform(transpose(datatype),32)
chan_channel_enabled   = reform(transpose(channel_enabled),32)
chan_channel_number    = reform(transpose(channel_number),32)
chan_samples           = reform(transpose(samples),32)
chan_board_number      = reform(transpose(board_number),32)
chan_nt                = reform(transpose(nt),32)
chan_sample_averaging  = reform(transpose(sample_averaging),32)
chan_shots_averaged    = reform(transpose(shots_averaged),32)


enabled_indices = where(chan_channel_enabled eq 1)
nchannels = n_elements(enabled_indices)
;Surely this won't occur at this stage...
if (enabled_indices[0] eq -1) then begin
  print,'SIS3302 configuration: There are no channels enabled!'
  stop
endif

;by logical channel
lc_dt                = chan_dt[enabled_indices]
lc_time_acquired     = chan_time_acquired[enabled_indices]
lc_comment           = chan_comment[enabled_indices]
lc_dc_offset         = chan_dc_offset[enabled_indices]
lc_datatype          = chan_datatype[enabled_indices]
lc_channel_enabled   = chan_channel_enabled[enabled_indices]
lc_channel_number    = chan_channel_number[enabled_indices]
lc_samples           = chan_samples[enabled_indices]
lc_board_number      = chan_board_number[enabled_indices]
lc_nt                = chan_nt[enabled_indices]
lc_sample_averaging  = chan_sample_averaging[enabled_indices]
lc_shots_averaged    = chan_shots_averaged[enabled_indices]




sis_structure = CREATE_STRUCT('dt',dt,$
'nt',           nt           ,$
'time_acquired',time_acquired,$
'comment',     comment     ,$
'dc_offset',  dc_offset  ,$
'datatype',  datatype  ,$
'channel_enabled', channel_enabled ,$
'channel_number',  channel_number  ,$
'board_number',   board_number   ,$
'samples',       samples       ,$
'sample_averaging',sample_averaging ,$
'shots_averaged',shots_averaged,$
'nchannels',nchannels,$
'clock_mode_code',clock_mode_code,$
'clock_mode',clock_mode,$
'clock_source_code',clock_source_code,$
'clock_source',clock_source,$
'delay_clockticks',delay_clockticks,$
'delay_seconds',delay_seconds,$
'lc_dt',           lc_dt           ,$
'lc_nt',           lc_nt           ,$
'lc_time_acquired',lc_time_acquired,$
'lc_comment',     lc_comment     ,$
'lc_dc_offset',  lc_dc_offset  ,$
'lc_datatype',  lc_datatype  ,$
'lc_channel_enabled', lc_channel_enabled ,$
'lc_channel_number',  lc_channel_number  ,$
'lc_board_number',   lc_board_number   ,$
'lc_samples',       lc_samples       ,$
'lc_sample_averaging',lc_sample_averaging ,$
'lc_shots_averaged',lc_shots_averaged)


IF quiet EQ 0 THEN print, strcompress('Total channels digitized: '+string(nchannels))


Cleanup:
OBJ_DESTROY, HDF5_file

RETURN, sis_structure

END