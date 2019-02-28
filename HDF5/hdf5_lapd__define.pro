; NAME:
;   HDF5_LaPD
;
; PURPOSE:
;   This object encapsulates various I/O operations on LaPD raw data/config files stored in HDF5 format.
;
; CALLING SEQUENCE:
;     HDF5_LaPD = OBJ_NEW('HDF5_LaPD')                ; initially creates the object
;     HDF5_LaPD->Open, filename                       ; opens an LaPD raw HDF5 file
;
;     device_names = HDF5_LaPD->Read_device_names()   ; returns an array of names of devices used in the data run
;     dataset_names = $
;          HDF5_LaPD->Read_dataset_names(device_name) ; returns an array of dataset names for the specified device
;     dataset = HDF5_LaPD->Read_dataset $
;                    (device_name, dataset_name)      ; returns the specified dataset for the specified device --
;                                                     ; the dataset is stored in a structure returned by H5_PARSE
;
;     status = HDF5_LaPD->Get_error_status()          ; returns error information...
;     message = HDF5_LaPD->Get_error_message()        ;
;     call_stack = HDF5_LaPD->Get_error_call_stack()  ;
;
;     HDF5_LaPD->Close                                ; closes the file (optional, done automatically when
;                                                     ;   object is destroyed)
;     OBJ_DESTROY, HDF5_LaPD                          ; destroys the object and closes the file, if open
;
; KEYWORD PARAMETERS:
;   HDF5_LaPD::Init:
;   INPUT_FILE: The full path of the LaPD raw HDF5 file to open.
;   Example: create an HDF5_LaPD object and open a specified file at the same time:
;     HDF5_LaPD = OBJ_NEW('HDF5_LaPD', FILENAME='C:\Data\Alfven_waves\Alfven1\test.hdf5')
;
; ERROR HANDLING:
;   Error handling is specified by the HDF5_error class.  Currently, when an error
;   is hit information is stored and displayed, then execution is halted.  This
;   is also how the underlying HDF5 functions and procedures operate.  Great caution
;   must be exercised if this behavior is ever changed because the code in many places
;   depends on the execution halting.
;
; MODIFICATION HISTORY:
;   Written by:  Jim Bamber  July, 2005.
;   07/23/207 Steve Vincena. Changed the 'Open' method to use the keyword 'FILENAME' instead of 'FILEPATH'
;              'FILENAME' should still contain the full path. This was changed because
;              there is an IDL function called "FILEPATH', and there were rare programming
;              cases in which there was confusion.
;


;----------------------------------------------------------------------------
; HDF5_LaPD::Init
;
; Purpose:
;  Initializes the HDF5_LaPD object, optionally opening the specified file.
;
FUNCTION HDF5_LaPD::Init, FILENAME=filename

    self.error = OBJ_NEW('HDF5_error')
    self.root_group = OBJ_NEW('HDF5_group')
    self.raw_group = OBJ_NEW('HDF5_group')

    IF (N_ELEMENTS(filename) EQ 1) THEN $
         self->Open, filename

    RETURN, 1
END


;----------------------------------------------------------------------------
; HDF5_LaPD::Cleanup
;
; Purpose:
;  Cleans up all memory associated with the HDF5_LaPD object.
;
PRO HDF5_LaPD::Cleanup

    self->Close

    OBJ_DESTROY, self.error
    OBJ_DESTROY, self.root_group
    OBJ_DESTROY, self.raw_group

END


;----------------------------------------------------------------------------
; HDF5_LaPD::Open
;
; Purpose:
;  Opens the specified file.
;
PRO HDF5_LaPD::Open, filename

    self.file_id = H5F_OPEN(filename)
    IF (self.file_id EQ 0) THEN $
         self.error->Handle_error, "File: " + filename + " could not be opened by H5F_OPEN()"

    self.root_group->Open, self.file_id, "/"
    attribute = self.root_group->Read_attribute("LaPD HDF5 software version")
    self.version = attribute
    IF ( (self.version NE '1.0') AND $
         (self.version NE '1.1') ) THEN $
         self.error->Handle_error, "File version: " + self.version + " is not supported"

;   File formats under versions 1.0 and 1.1 (i.e. all currently supported versions are identical
    self.raw_group->Open, self.file_id, "Raw data + config"

END


;----------------------------------------------------------------------------
; HDF5_LaPD::Close
;
; Purpose:
;  Closes the currently open file.
;
PRO HDF5_LaPD::Close

    self.root_group->Close
    self.raw_group->Close

    IF (self.file_id NE 0) THEN $
         H5F_CLOSE, self.file_id

    self.file_id = 0
    self.version = ""

END


;----------------------------------------------------------------------------
; HDF5_LaPD::Get_<property>
;
; Purpose:
;  This is a series of functions to return various internal properties.
;
FUNCTION HDF5_LaPD::Get_error_status
    RETURN, self.error->Get_status()
END

FUNCTION HDF5_LaPD::Get_error_message
    RETURN, self.error->Get_message()
END

FUNCTION HDF5_LaPD::Get_error_call_stack
    RETURN, self.error->Get_call_stack()
END


;----------------------------------------------------------------------------
; HDF5_LaPD::Read_device_names
;
; Purpose:
;  Returns an array of the names of the devices connected for the data run
;  represented by the current LaPD raw HDF5 file.
;
FUNCTION HDF5_LaPD::Read_device_names

    group_names = self.raw_group->Read_group_names()
    IF (group_names[0] EQ '') THEN $
         device_names = STRARR(1) $
    ELSE BEGIN $
         indices = WHERE(group_names NE 'Data run sequence' )
         IF (indices[0] NE -1) THEN $
              device_names = group_names[indices] $
         ELSE $
              device_names = STRARR(1)
    ENDELSE

    RETURN, device_names
END


;----------------------------------------------------------------------------
; HDF5_LaPD::Read_dataset_names
;
; Purpose:
;  Returns an array of the dataset names for the specified device.  Note that
;  the term "dataset" is used in the same sense as the HDF5 dataset; in other
;  words, the 2-D array of digitized data is considered to be a single dataset
;  and the associated headers are considered to be another dataset.  The naming
;  convention under versions 1.0 and 1.1 of the LaPD HDF5 software are like:
;
;    2-D array of digitized data: '3 channels [0:0]'
;    associated headers:          '3 channels [0:0] headers'
;
;  The '3 channels' refers to the configuration used for the device and the '[0:0]'
;  refers to the board and channel numbers, i.e. [<board>:<channel>]
;
FUNCTION HDF5_LaPD::Read_dataset_names, device_name

    device_group = self.raw_group->Open_group(device_name)
    dataset_names = device_group->Read_dataset_names()
    OBJ_DESTROY, device_group

    RETURN, dataset_names
END


;----------------------------------------------------------------------------
; HDF5_LaPD::Read_dataset
;
; Purpose:
;  Returns the specified dataset, for the specified device, in the form of a
;  result structure as used by H5_PARSE.  See p. 116 of "IDL Scientific Data
;  Formats" (sdf.pdf) for details on this data structure.  It is the same as
;  what is returned by H5_BROWSER as well.
;
FUNCTION HDF5_LaPD::Read_dataset, device_name, dataset_name

    device_group = self.raw_group->Open_group(device_name)
    dataset = device_group->Read_dataset(dataset_name)
    OBJ_DESTROY, device_group

    RETURN, dataset
END


;----------------------------------------------------------------------------
; HDF5_LaPD__define
;
; Purpose:
;  Defines the object structure for an HDF5_LaPD object.
;
PRO HDF5_LaPD__define
    struct = { HDF5_LaPD, $
               file_id: 0L, $
               version: "", $
               root_group: OBJ_NEW('HDF5_group'), $
               raw_group: OBJ_NEW('HDF5_group'), $
               error: OBJ_NEW('HDF5_error') $
             }
END







