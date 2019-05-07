FUNCTION lapd_sis3305_configuration, input_file, requested_config_name, quiet=quiet
COMPILE_OPT IDL2
s='lapd_sis3305_configuration: '
;Import Struck Innovative Systems SIS3305 (1.25+GHZ 10bit) class digitizer
;configuration used by the "SIS Crate" remote digitizer module
;from an LAPD HDF5 datarun file.
;
;based on LAPD_SIS3302_CONFIGURATION, which was based on...
;LAPD_SIS_CONFIGURATION--the first SIS crate with variable number
;of SIS3301 digitizer boards.
;
;The "SIS Crate" module is based on a fixed configuration of
; (4)  3302 boards (SIS crate board type 2), crate slots 5,7,9,11
; (2)  3305 boards, (SIS crate board type 3) crate clots 13 and 15
; (1)  3820 clock/trigger distributer/delay generator (SIS board type 4), crate slot 3
;Note board type 1 refers to the computer/crate interface card but is not configurable as part of a datarun, crate slot 1
;
;Written by Steve Vincena, 9/28/2012
;
;
;Modification history:
;Oct 17, 2018   => Added 'quiet' option to suppress non-critical print outputs.
;
;
!Quiet=1
sis_structure = {dt:float(0.)}

; Open HDF5 file.
IF (input_file EQ '') THEN input_file = dialog_pickfile(path='./',title='Please choose an HDF5 file')
IF quiet EQ 0 THEN BEGIN
  PRINT, '-----------------------------------------------------------------------'
  PRINT, 'SIS CRATE, Digitizer type 3305 : Reading configuration for digitizer(s)'
ENDIF

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
    PRINT,'***********************'
    PRINT,'No SIS Crate configuration name supplied. Attempting to pick one out.'
    IF (N_ELEMENTS(sis_config_group_names) GT 1) THEN BEGIN
      PRINT,'SIS Crate 3305: Available configurations:'
      PRINT,sis_config_group_names
      PRINT
      PRINT,'***********************'
      PRINT,'SIS Crate 3305: WARNING: Multiple configurations detected.'
      PRINT,'SIS Crate 3305: Using the configuration group name that matches the first dataset name.'
      first_sis_dataset_name=reform(sis_dataset_names[0])
      selected_config_group_name = strmid(first_sis_dataset_name,0,stregex(first_sis_dataset_name,'\[')-1)

      PRINT

      PRINT,'SIS Crate 3305: This configuration group name is "'+selected_config_group_name+'".'
      print,'***********************'

    ENDIF ELSE BEGIN;Done with more than one sis group case
      print,'Only one SIS Crate configuration found: "'+sis_config_group_names[0]+'." Using this one.'
      selected_config_group_name = reform(sis_config_group_names[0])
    ENDELSE

  END ; One-argument case

  ;configuration name was supplied
  2: BEGIN
    PRINT,'---'
    PRINT,'Requested configuration: '+requested_config_name
    ii = WHERE(sis_config_group_names EQ requested_config_name)
    IF (ii[0] EQ -1) THEN BEGIN
      MESSAGE,'Requested SIS Crate configuration name ('+requested_config_name+') does not mactch any available configuration.'
      PRINT,'Valid configuration names:'
      PRINT,sis_config_group_names
      STOP
    ENDIF
    ;requested name found in SIS group. Use it.
    selected_config_group_name = requested_config_name

  END ;Two-argument case

  ELSE: MESSAGE,'Wrong number of arguments.'

ENDCASE
PRINT,'---'


; Open the config group that was selected
sis_config_group=sis_group->Open_group(selected_config_group_name)

;Notes:
;SIS3305 board 1 = Slot 13
;SIS3305 board 2 = Slot 15

;SIS crate 3305 configuration group names  are stored as
;"SIS crate 3305 configurations[n]" where n starts
; at 0 and increses by 1 for each active 3305 board.
;So, if boards 1 and 2 are active, you get groups:
;SIS crate 3305 configurations[0]  <- for board 1 (slot 13)
;SIS crate 3305 configurations[1]  <- for board 2 (slot 15)
;
;Note that if board 2 is the only active board, then it
;gets the name 'SIS crate 3305 configurations[0]'

;The dataset names on a test case looked to be in sequential order,
;but this was not the case for the 3302 boards. This might be
;because of the apparent alphabetic sorting which places
;'Slot 11' beofre 'Slot 5', which would not be a problem with the 3305's,
;but the code from the 3302's is eassy to implement.

;Our test configuration called 'fast_variable_1',
;contains the following datasets:
;
;fast_variable_1 [Slot 13: SIS 3305 FPGA 1 ch 1]
;fast_variable_1 [Slot 13: SIS 3305 FPGA 1 ch 1] headers
;fast_variable_1 [Slot 13: SIS 3305 FPGA 1 ch 2]
;fast_variable_1 [Slot 13: SIS 3305 FPGA 1 ch 2] headers
;fast_variable_1 [Slot 13: SIS 3305 FPGA 1 ch 3]
;fast_variable_1 [Slot 13: SIS 3305 FPGA 1 ch 3] headers
;fast_variable_1 [Slot 13: SIS 3305 FPGA 1 ch 4]
;fast_variable_1 [Slot 13: SIS 3305 FPGA 1 ch 4] headers
;fast_variable_1 [Slot 13: SIS 3305 FPGA 2 ch 1]
;fast_variable_1 [Slot 13: SIS 3305 FPGA 2 ch 1] headers
;fast_variable_1 [Slot 13: SIS 3305 FPGA 2 ch 2]
;fast_variable_1 [Slot 13: SIS 3305 FPGA 2 ch 2] headers
;fast_variable_1 [Slot 13: SIS 3305 FPGA 2 ch 3]
;fast_variable_1 [Slot 13: SIS 3305 FPGA 2 ch 3] headers
;fast_variable_1 [Slot 13: SIS 3305 FPGA 2 ch 4]
;fast_variable_1 [Slot 13: SIS 3305 FPGA 2 ch 4] headers
;fast_variable_1 [Slot 15: SIS 3305 FPGA 1 ch 1]
;fast_variable_1 [Slot 15: SIS 3305 FPGA 1 ch 1] headers
;fast_variable_1 [Slot 15: SIS 3305 FPGA 2 ch 3]
;fast_variable_1 [Slot 15: SIS 3305 FPGA 2 ch 3] headers

;So, we need a mapping from a requested real board to a logical board
;We could return an array of type 'structure' that always has
;four indices, initialized with zeros and null string tags, and
;then populate it in the correct order based on what boards
;took data.

;Note that the configuration group contains useful attributes for this.
;For the same example configuration as above, we have
;U32[4]    SIS crate base addresses =  939524096,2684354560,2701131776
;U32[4]    SIS crate board types = 4,3,3
;U32[4]    SIS crate config indices = 0,0,1
;I32[1]    SIS crate max average shots = 1
;U32[4]    SIS crate slot numbers = 3,13,15

;So, SIS3305 board 1 (slot 13) uses 'SIS crate 3305 configurations[0]'
;and SIS3305 board 2 (slot 15) uses 'SIS crate 3305 configurations[1]'

;We could return a structure with params for all 16 channels and
;Then a logical list for the active channels and
;an array of size [2,8] for board and channel.
;It's easiest to go board by board, so...

;Define variables

;Note that the 3820-related code is replicated in the lapd_sis3302_configuration
;program. They should both be kept in sync, or put into a sub-program.
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
;
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
global_clocktick = 1.0d-8 ;sec
delay_clockticks = sis3820_config_group->Read_attribute('Delay')
delay_seconds            = global_clocktick*double(delay_clockticks)

;Done with sis3820 board
 OBJ_DESTROY,sis3820_config_group


;determine 3305 boards that were used
sis_board_types = sis_config_group->Read_attribute('SIS crate board types')
sis3305_board_indices = where(sis_board_types eq 3)
if (sis3305_board_indices[0] eq -1) then begin
  print,'SIS3305 configuration: no active 3305 boards!'
  stop
endif
sis_all_config_indices = sis_config_group->Read_attribute('SIS crate config indices')
sis3305_config_indices = sis_all_config_indices[sis3305_board_indices]
sis_all_slot_numbers = sis_config_group->Read_attribute('SIS crate slot numbers')
sis3305_slot_numbers = sis_all_slot_numbers[sis3305_board_indices]
sis3305_board_numbers = (sis3305_slot_numbers-13)/2 +1

print,'SIS3305 boards used:',sis3305_board_numbers
n_active_boards = n_elements(sis3305_board_numbers)


;by board
;45 attributes per board
;Note that attributes for each board are grouped by which FPGA they
;use. FPGA 1 controls channels 1,2,3,4
;while FPGA 2 controls channels 5,6,7,8
chan_to_fpga = long([1,1,1,1,2,2,2,2])
chan_to_fpga_chan = long([1,2,3,4,1,2,3,4])
bw_index_to_bw = float([1e9,1.8e9])
mode_index_to_dt = float([8e-10,4e-10,2e-10]);sec (for 4chan,2chan,1chan per FPGA)


dt                = fltarr(2,8)
time_acquired     = dblarr(2,8)
comment           = strarr(2,8)
bandwidth         = fltarr(2,8) ;1='full=1.8GHz', 0='Nominal 1GHz typical'
;dc_offset         = dblarr(2,8) ;NO dc offsets for 3305's
datatype          = strarr(2,8)
channel_enabled   = bytarr(2,8)
channel_number    = ulonarr(2,8)
board_number      = ulonarr(2,8)
samples           = ulon64arr(2,8) ;Only 2GB/board, but you might accidentally
;                               multiply this by your total shots or something
nt                = ulon64arr(2,8) ;same as 'samples'
;sample_averaging  = ulonarr(2,8) ;No sample averaging for 3305's (bummer)
shots_averaged    = ulonarr(2,8);actually stored as a signed 32-bit integer in the hdf5 for some reason, but 2^31 shots on lapd is still about 68 years at 1Hz


for i=0,n_active_boards-1 do begin

  ;We assume that the board numbers could be out of order
  iboard  = sis3305_board_numbers[i]-1
  iconfig = sis3305_config_indices[i]

  ;open configuration group for this board
  board_config_name = 'SIS crate 3305 configurations'+$
                    strcompress('['+string(iconfig)+']',/remove_all)
  board_config_group = sis_config_group->Open_group(board_config_name)

  ;Start reading attributes and computing quantities
  ;-------------------------------------------------------------
 

  ;First read quantities that are common to all channels on each board
  ;-------------------------------------------------------------

  ;Digitization period
  chan_mode = board_config_group->Read_attribute('Channel mode')
  dt[iboard,*] = mode_index_to_dt[chan_mode]
  bw_mode = board_config_group->Read_attribute('Bandwidth')
  bandwidth[iboard,*] = bw_index_to_bw[bw_mode]

  IF quiet EQ 0 THEN print, strcompress('SIS3305 : Board '+string(iboard+1)+ $
    ': Effective clock rate= '+string(1./dt[iboard,0]/1e9)+' GHz')

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
    
    i_fpga = chan_to_fpga[ichan]
    fpga_string=strcompress(string(i_fpga),/remove_all)
    i_fpga_chan = chan_to_fpga_chan[ichan]
    fpga_chan_string=strcompress(string(i_fpga_chan),/remove_all)

    ;Was the channel active?
    qstring = 'FPGA '+fpga_string+' Enabled '+fpga_chan_string
    active_string = board_config_group->Read_attribute(qstring)
    channel_enabled[iboard,ichan] = (active_string EQ 'TRUE') ? 1 : 0

    ;What was in the 'user comment' field of the configuration?
    qstring = 'FPGA '+fpga_string+' Comment '+fpga_chan_string
    comment[iboard,ichan] = board_config_group->Read_attribute(qstring)

    ;How did the user label this data type?
    qstring = 'FPGA '+fpga_string+' Data type '+fpga_chan_string
    datatype[iboard,ichan] = board_config_group->Read_attribute(qstring)

    ;The channel number modified to have FPGA 2 channels be 5,6,7,8
    qstring = 'FPGA '+fpga_string+' Ch '+fpga_chan_string
    channel_number[iboard,ichan] = (i_fpga-1)*4 + board_config_group->Read_attribute(qstring)

  endfor ; ichan
  ;close configuration group for this board
  OBJ_DESTROY,board_config_group
endfor ; i (active board)

OBJ_DESTROY,sis_config_group
OBJ_DESTROY,sis_group

;by full channel (Not returning these as of 9/26/2012)
chan_dt                = reform(transpose(dt),16)
chan_time_acquired     = reform(transpose(time_acquired),16)
chan_comment           = reform(transpose(comment),16)
;chan_dc_offset         = reform(transpose(dc_offset),16)
chan_bandwidth          = reform(transpose(bandwidth),16)
chan_datatype          = reform(transpose(datatype),16)
chan_channel_enabled   = reform(transpose(channel_enabled),16)
chan_channel_number    = reform(transpose(channel_number),16)
chan_samples           = reform(transpose(samples),16)
chan_board_number      = reform(transpose(board_number),16)
chan_nt                = reform(transpose(nt),16)
;chan_sample_averaging  = reform(transpose(sample_averaging),16)
chan_shots_averaged    = reform(transpose(shots_averaged),16)


enabled_indices = where(chan_channel_enabled eq 1)
nchannels = n_elements(enabled_indices)
;Surely this won't occur at this stage...
if (enabled_indices[0] eq -1) then begin
  print,'SIS3305 configuration: There are no channels enabled!'
  stop
endif

;by logical channel
lc_dt                = chan_dt[enabled_indices]
lc_time_acquired     = chan_time_acquired[enabled_indices]
lc_comment           = chan_comment[enabled_indices]
;lc_dc_offset         = chan_dc_offset[enabled_indices]
lc_bandwidth          = chan_bandwidth[enabled_indices]
lc_datatype          = chan_datatype[enabled_indices]
lc_channel_enabled   = chan_channel_enabled[enabled_indices]
lc_channel_number    = chan_channel_number[enabled_indices]
lc_samples           = chan_samples[enabled_indices]
lc_board_number      = chan_board_number[enabled_indices]
lc_nt                = chan_nt[enabled_indices]
;lc_sample_averaging  = chan_sample_averaging[enabled_indices]
lc_shots_averaged    = chan_shots_averaged[enabled_indices]




sis_structure = CREATE_STRUCT('dt',dt,$
'nt',           nt           ,$
'time_acquired',time_acquired,$
'comment',     comment     ,$
;'dc_offset',  dc_offset  ,$
'bandwidth',  bandwidth  ,$
'datatype',  datatype  ,$
'channel_enabled', channel_enabled ,$
'channel_number',  channel_number  ,$
'board_number',   board_number   ,$
'samples',       samples       ,$
;'sample_averaging',sample_averaging ,$
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
;'lc_dc_offset',  lc_dc_offset  ,$
'lc_bandwidth',  lc_bandwidth  ,$
'lc_datatype',  lc_datatype  ,$
'lc_channel_enabled', lc_channel_enabled ,$
'lc_channel_number',  lc_channel_number  ,$
'lc_board_number',   lc_board_number   ,$
'lc_samples',       lc_samples       ,$
;'lc_sample_averaging',lc_sample_averaging ,$
'lc_shots_averaged',lc_shots_averaged)


IF quiet EQ 0 THEN print, strcompress('Total channels digitized: '+string(nchannels))



Cleanup:
OBJ_DESTROY, HDF5_file

RETURN, sis_structure

END