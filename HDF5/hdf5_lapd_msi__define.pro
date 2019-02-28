; NAME:
;   HDF5_LaPD_MSI
;
; PURPOSE:
;   This object encapsulates various operations on LaPD Machine State Information stored in HDF5 format.
;
; CALLING SEQUENCE:
;     HDF5_LaPD_MSI = OBJ_NEW('HDF5_LaPD_MSI')                ; initially creates the object
;     HDF5_LaPD_MSI->Open, filepath                       ; opens an LaPD HDF5 file
;
;     system_names = HDF5_LaPD_MSI->Read_system_names()   ; returns an array of names of systems monitored by the LAPD Housekeepign computer whose data is stored in the HDF5 datafile
;     dataset_names = $
;          HDF5_LaPD_MSI->Read_dataset_names(device_name) ; Currently no analogue
;     dataset = HDF5_LaPD_MSI->Read_dataset $
;                    (system_name, dataset_name)      ; returns the specified dataset for the specified system --
;                                                     ; the dataset is stored in a structure returned by H5_PARSE
;
;     status = HDF5_LaPD_MSI->Get_error_status()          ; returns error information...
;     message = HDF5_LaPD_MSI->Get_error_message()        ;
;     call_stack = HDF5_LaPD_MSI->Get_error_call_stack()  ;
;
;     HDF5_LaPD_MSI->Close                                ; closes the file (optional, done automatically when
;                                                         ;   object is destroyed)
;     OBJ_DESTROY, HDF5_LaPD_MSI                          ; destroys the object and closes the file, if open
;
; KEYWORD PARAMETERS:
;   HDF5_LaPD_MSI::Init:
;   FILEPATH: The full path of the LaPD HDF5 file to open.
;   Example: create an HDF5_LaPD_MSI object and open a specified file at the same time:
;     HDF5_LaPD_MSI = OBJ_NEW('HDF5_LaPD_MSI', FILEPATH='/bapsf/data8/experimentname/datafile.hdf5')
;
; ERROR HANDLING:
;   Error handling is specified by the HDF5_error class.  Currently, when an error
;   is hit information is stored and displayed, then execution is halted.  This
;   is also how the underlying HDF5 functions and procedures operate.  Great caution
;   must be exercised if this behavior is ever changed because the code in many places
;   depends on the execution halting.
;
; MODIFICATION HISTORY:
;   Original HDF5_LaPD Object code written by  Jim Bamber  July, 2005.
;   HDF5_LaPD_MSI Object code extension written by  Steve Vincena  August, 2006.
;


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI::Init
;
; Purpose:
;  Initializes the HDF5_LaPD_MSI object, optionally opening the specified file.
;
FUNCTION HDF5_LaPD_MSI::Init, FILEPATH=filepath

    self.error = OBJ_NEW('HDF5_error')
    self.msi_group = OBJ_NEW('HDF5_group')

    IF (N_ELEMENTS(filepath) EQ 1) THEN $
         self->Open, filepath

    RETURN, 1
END


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI::Cleanup
;
; Purpose:
;  Cleans up all memory associated with the HDF5_LaPD_MSI object.
;
PRO HDF5_LaPD_MSI::Cleanup

    self->Close

    OBJ_DESTROY, self.error
    OBJ_DESTROY, self.msi_group

END


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI::Open
;
; Purpose:
;  Opens the specified file.
;
PRO HDF5_LaPD_MSI::Open, filepath

    self.file_id = H5F_OPEN(filepath)
    IF (self.file_id EQ 0) THEN $
         self.error->Handle_error, "File: " + filepath + " could not be opened by H5F_OPEN()"

    self.msi_group->Open, self.file_id, "/MSI"
    attribute = self.msi_group->Read_attribute("MSI version")
    self.version = attribute
    PRINT,"MSI Data version = "+ self.version


END


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI::Close
;
; Purpose:
;  Closes the currently open file.
;
PRO HDF5_LaPD_MSI::Close

    self.msi_group->Close

    IF (self.file_id NE 0) THEN $
         H5F_CLOSE, self.file_id

    self.file_id = 0
    self.version = ""

END


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI::Get_<property>
;
; Purpose:
;  This is a series of functions to return various internal properties.
;
FUNCTION HDF5_LaPD_MSI::Get_error_status
    RETURN, self.error->Get_status()
END

FUNCTION HDF5_LaPD_MSI::Get_error_message
    RETURN, self.error->Get_message()
END

FUNCTION HDF5_LaPD_MSI::Get_error_call_stack
    RETURN, self.error->Get_call_stack()
END


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI::Read_system_names
;
; Purpose:
;  Returns an array of the names of the devices connected for the data run
;  represented by the current LaPD raw HDF5 file.
;
FUNCTION HDF5_LaPD_MSI::Read_system_names

    system_names = self.msi_group->Read_group_names()

    IF (system_names[0] EQ '') THEN  system_names = STRARR(1)

    RETURN, system_names
END


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI::Read_dataset_names
;
; Purpose:
;  Returns an array of the dataset names for the specified machine housekeeping system.  Note that
;  the term "dataset" is used in the same sense as the HDF5 dataset.
;  For example the "Magnetic field" system comprises three datasets:
;  (1) "Magnet power supply currents"
;  (2) "Magnetic field profile"
;  (3) "Magnetic field summary"
;
;
FUNCTION HDF5_LaPD_MSI::Read_dataset_names, system_name

    system_group = self.raw_group->Open_group(system_name)
    dataset_names = system_group->Read_dataset_names()
    OBJ_DESTROY, system_group

    RETURN, dataset_names
END


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI::Read_dataset
;
; Purpose:
;  Returns the specified dataset, for the specified system, in the form of a
;  result structure as used by H5_PARSE.  See p. 116 of "IDL Scientific Data
;  Formats" (sdf.pdf) for details on this data structure.  It is the same as
;  what is returned by H5_BROWSER as well.
;
FUNCTION HDF5_LaPD_MSI::Read_dataset, system_name, dataset_name

    system_group = self.raw_group->Open_group(system_name)
    dataset = system_group->Read_dataset(dataset_name)
    OBJ_DESTROY, system_group

    RETURN, dataset
END


;----------------------------------------------------------------------------
; HDF5_LaPD_MSI__define
;
; Purpose:
;  Defines the object structure for an HDF5_LaPD_MSI object.
;
PRO HDF5_LaPD_MSI__define
    struct = { HDF5_LaPD_MSI, $
               file_id: 0L, $
               version: "", $
               msi_group: OBJ_NEW('HDF5_group'), $
               error: OBJ_NEW('HDF5_error') $
             }
END
