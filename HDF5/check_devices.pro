;NAME:        check_devices.pro
;AUTHOR:      Steve Vincena / swjtang
;DATE:        16 Aug 2018
;DESCRIPTION: Returns an array after checking if a device is being used from within the datafile.
;SYNTAX:      Result = CHECK_DEVICES(input_file)
;CHANGELOG:   Oct 04, 2017 => (swjtang) Added NI_XZ as a check-able device
;             Oct 16, 2017 => (") Added SIS board type as an additional condition to check for an active device.
;             Aug 16, 2018 => (") Added NI_XYZ as a check-able device

FUNCTION CHECK_DEVICES, input_file

devices       = ['6K Compumotor','SIS crate','SIS 3302','SIS 3305','SIS 3301','n5700','NI_XZ','NI_XYZ']
ndevices      = n_elements(devices)
check_devices = {name:devices, active:fltarr(ndevices)}

;;;; OPEN .HDF5 FILE ------------------------------------------------------------------------------
IF (input_file EQ '') THEN GOTO, Cleanup

IF (FILE_TEST(input_file) EQ 1) THEN BEGIN
    ;;;; CREATE THE OBJECT ----------------------------------------------------
    HDF5_file = OBJ_NEW('HDF5_file')
    HDF5_file->Open, input_file
ENDIF ELSE GOTO, Cleanup

;;;; OPEN RAW DATA AND CONFIGURATION GROUP --------------------------------------------------------
rac_group = HDF5_file->Open_group('Raw data + config')
rac_subgroup_names = rac_group->Read_group_names()

;;;; READ GROUP NAMES TO DETERMINE IF A DEVICE IS PRESENT -----------------------------------------
FOR idevice=0, ndevices-1 DO BEGIN
   device_test = WHERE(rac_subgroup_names EQ devices[idevice])
   IF ( device_test NE -1 ) THEN check_devices.active[idevice] = 1
ENDFOR

;;;; CHECK FOR FAST OR SLOW DIGITIZERS ON SIS CRATE -----------------------------------------------
IF check_devices.active[1] THEN BEGIN
    siscrate = rac_group->Open_group('SIS crate')
    siscrate_config_names = siscrate->Read_group_names()
    FOR iconfig=0, n_elements(siscrate_config_names)-1 DO BEGIN
        siscrate_subgroup = siscrate->open_group(siscrate_config_names[iconfig])
        siscrate_subgroup_names = siscrate_subgroup->Read_group_names()
        FOR idevice=0, ndevices-1 DO BEGIN
            siscrate_test = WHERE(strmid(siscrate_subgroup_names,0,21) EQ 'SIS crate ' $
                            +strmid(devices[idevice],4,strlen(devices[idevice])-1)+' config')
            IF ( siscrate_test[0] NE -1 ) THEN BEGIN
                sis_board_types = siscrate_subgroup->Read_attribute('SIS crate board types')
                sis3302_board_indices = where(sis_board_types eq 2)
                sis3305_board_indices = where(sis_board_types eq 3)
                CASE devices[idevice] OF
                    'SIS 3302': IF (sis3302_board_indices[0] NE -1) THEN check_devices.active[idevice] = 1
                    'SIS 3305': IF (sis3305_board_indices[0] NE -1) THEN check_devices.active[idevice] = 1
                    ELSE:       check_devices.active[idevice] = 1
                ENDCASE
            ENDIF
        ENDFOR
    ENDFOR
    OBJ_DESTROY, siscrate_subgroup
    OBJ_DESTROY, siscrate
ENDIF

OBJ_DESTROY, rac_group
OBJ_DESTROY, hdf5_file

Cleanup:
RETURN, check_devices
END
