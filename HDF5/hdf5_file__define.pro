; NAME:
;   HDF5_file
;
; PURPOSE:
;   This object encapsulates various I/O operations on HDF5 files.
;
; CALLING SEQUENCE:
;     HDF5_file = OBJ_NEW('HDF5_file')                ; initially creates the object
;     HDF5_file->Open, filename                       ; opens an HDF5 file
;     HDF5_file->Create, filename                     ; creates a new HDF5 file
;
;     group_names = HDF5_file->Read_group_names()     ; returns an array of names of groups contained in this file
;     group = HDF5_file->Open_group(group_name)       ; opens a group contained within this file
;     group = HDF5_file->Create_group(group_name)     ; creates a group in this file
;                                                     ;   note: both the above functions return a group object 
;
;     dataset_names = HDF5_file->Read_dataset_names() ; returns an array of dataset names contained in this file
;     dataset = HDF5_file->Read_dataset(dataset_name) ; reads the specified dataset and returns it in an H5_PARSE
;                                                     ;   style structure
;     HDF5_file->Write_dataset, dataset_name, data    ; writes the specified data into a dataset in this file
;
;     status = HDF5_file->Get_error_status()          ; returns error information...
;     message = HDF5_file->Get_error_message()        ;
;     location = HDF5_file->Get_error_location()      ;
;
;     HDF5_file->Close                                ; closes the HDF5 file
;     OBJ_DESTROY, HDF5_file                          ; destroys the object and closes the file if open
;
; KEYWORD PARAMETERS:
;   HDF5_file::Init:
;   FILENAME: The full path of the HDF5 file to open or create.
;   OPERATION: 'Open' or 'Create'
;   Example: create an HDF5_file object and open a specified file at the same time:
;     HDF5_file = OBJ_NEW('HDF5_file', FILENAME='C:\Data\Alfven_waves\Alfven1\test.hdf5', OPERATION='Open')
;
;   HDF5_file::Write_dataset:
;   CHUNK_DIMENSIONS: Must be of the same dimensionality as the data but with the same
;     or smaller extents.  For this method, where all the data are written at once,
;     the safest thing is to set chunk_dimensions to be the same as the data, which is
;     the default.  If chunk_dimensions is set the extents should divide evenly into
;     the data extents.
;   GZIP: Ranges from 0 (no compression) to 9 (max compression).
;   Example: write a dataset in this file with chunking and maximum compression:
;     test_data = FINDGEN(100, 100)
;     HDF5_file->Write_dataset, 'test_data', test_data, CHUNK_DIMENSIONS=[50, 50], GZIP=9
;
; ERROR HANDLING:
;   Execution will stop when an error is hit.  This is how the underlying HDF5
;   functions and procedures operate.  See HDF5_error for more details.
;
; MODIFICATION HISTORY:
;   Written by:  Jim Bamber  July, 2005.
;   Steve Vincena, April, 2007.  Added ability to open read-only files with optional 'write_flag' keyword
;   Steve Vincena 07/19/2007 ;   Added Read_simple_float_dataset method which reads the specified
;                                dataset (assumed to be attached to the currently open file and
;                                remoces H5_PARSE-style structure and just returns the data portion typecast as float.
;   Steve Vincena, 07/23/2007    Changed the 'FILEPATH' keyword to 'FILENAME' in the 'Open' method.
;                                This was done since there is an IDL function named 'FILEPATH' and there were
;                                rare programming problems because of this.
; 
;
; Steve Vincena 10/22/2012 added method, 'HDF5_file::Read_attribute'
; to allow the reading of the LaPD HDF5 software version attribute
; or anything else from the root of the file

; Steve Vincena 10/22/2012 added 'COMPILE_OPT IDL2,HIDDEN' to all methods



;----------------------------------------------------------------------------
; HDF5_file::Init
;
; Purpose:
;  Initializes the HDF5_file object, optionally opening or creating the specified
;  file.
;
FUNCTION HDF5_file::Init, FILENAME=filename, OPERATION=operation
    COMPILE_OPT IDL2,HIDDEN

    self.error = OBJ_NEW('HDF5_error')
    self.root_group = OBJ_NEW('HDF5_group')

    IF (N_ELEMENTS(filename) EQ 1) THEN $
         IF (operation EQ 'Open') THEN $
              self->Open, filename $
         ELSE IF (operation EQ 'Create') THEN $
              self->Create, filename $
         ELSE $
              self.error->Handle_error, 'OPERATION must be Open or Create'

    RETURN, 1
END


;----------------------------------------------------------------------------
; HDF5_file::Cleanup
;
; Purpose:
;  Cleans up all memory associated with the HDF5_file object.
;
PRO HDF5_file::Cleanup
    COMPILE_OPT IDL2,HIDDEN

    self->Close

    OBJ_DESTROY, self.error
    OBJ_DESTROY, self.root_group

END


;----------------------------------------------------------------------------
; HDF5_file::Open
;
; Purpose:
;  Opens the specified file.
;
; April, 2007. Steve Vincena. Added ability to open read-only files
;                             with optional 'write_flag' keyword

PRO HDF5_file::Open, filename, WRITE_FLAG=write_flag
    COMPILE_OPT IDL2,HIDDEN

    IF (KEYWORD_SET(WRITE_FLAG)) THEN BEGIN
     self.file_id = H5F_OPEN(filename, WRITE=write_flag)
    ENDIF ELSE BEGIN
     self.file_id = H5F_OPEN(filename, WRITE=0)
    ENDELSE

    IF (self.file_id EQ 0) THEN $
         self.error->Handle_error, "File: " + filename + " could not be opened by H5F_OPEN()"

    self.root_group->Open, self.file_id, "/"

END


;----------------------------------------------------------------------------
; HDF5_file::Create
;
; Purpose:
;  Creates the specified file.
;
PRO HDF5_file::Create, filename
    COMPILE_OPT IDL2,HIDDEN

    IF (FILE_TEST(filename) EQ 1) THEN $
         self.error->Handle_error, "File: " + filename + " already exists"

    self.file_id = H5F_CREATE(filename)
    IF (self.file_id EQ 0) THEN $
         self.error->Handle_error, "File: " + filename + " could not be created by H5F_CREATE()"

    self.root_group->Open, self.file_id, "/"

END


;----------------------------------------------------------------------------
; HDF5_file::Close
;
; Purpose:
;  Closes the currently open file.
;
PRO HDF5_file::Close
    COMPILE_OPT IDL2,HIDDEN

    self.root_group->Close

    IF (self.file_id NE 0) THEN $
         H5F_CLOSE, self.file_id

    self.file_id = 0

END


;----------------------------------------------------------------------------
; HDF5_file::Read_group_names
;
; Purpose:
;  Returns a list of names of the groups attached to this file.
;
FUNCTION HDF5_file::Read_group_names
    COMPILE_OPT IDL2,HIDDEN
    RETURN, self.root_group->Read_group_names()
END
;----------------------------------------------------------------------------
; HDF5_file::Read_attribute
;
; Purpose:
;  Returns the value of a named attribute of the file itself.
;
FUNCTION HDF5_file::Read_attribute,aname
    COMPILE_OPT IDL2,HIDDEN
;    attribute_id = H5A_OPEN_NAME(self.root_group,aname)
;    attribute = H5A_READ(attribute_id)
;    H5A_CLOSE, attribute_id
;    RETURN, attribute
     RETURN,self.root_group->Read_attribute(aname)
END


;----------------------------------------------------------------------------
; HDF5_file::Open_group
;
; Purpose:
;  Opens the specified group, assumed to be attached to the currently open
;  file, and returns it as an object.  It is the responsibility of the caller
;  to destroy the returned HDF5_group object.
;
FUNCTION HDF5_file::Open_group, group_name
    COMPILE_OPT IDL2,HIDDEN

    RETURN, self.root_group->Open_group(group_name)
END


;----------------------------------------------------------------------------
; HDF5_file::Create_group
;
; Purpose:
;  Creates the specified group within the currently open file and returns it as
;  an object.  It is the responsibility of the caller to destroy the returned
;  HDF5_group object.
;
FUNCTION HDF5_file::Create_group, group_name
    COMPILE_OPT IDL2,HIDDEN

    RETURN, self.root_group->Create_group(group_name)
END


;----------------------------------------------------------------------------
; HDF5_file::Read_dataset_names
;
; Purpose:
;  Returns a list of names of the datasets attached to this file.
;
FUNCTION HDF5_file::Read_dataset_names
    COMPILE_OPT IDL2,HIDDEN

    RETURN, self.root_group->Read_dataset_names()
END


;----------------------------------------------------------------------------
; HDF5_file::Read_dataset
;
; Purpose:
;  Reads the specified dataset, assumed to be attached to the currently open
;  file, and returns it packaged in an H5_PARSE style structure.
;
FUNCTION HDF5_file::Read_dataset, dataset_name
    COMPILE_OPT IDL2,HIDDEN

    RETURN, self.root_group->Read_dataset(dataset_name)

END


;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; HDF5_file::Read_simple_float_dataset
;
; 07/19/2007 Steve Vincena
; Purpose:
;  Reads the specified dataset, assumed to be attached to the currently open
;  file.
;  Get rid of the H5_PARSE style structure and just return
;  the data portion typecast as float.
; 
;
FUNCTION HDF5_file::Read_simple_float_dataset, dataset_name
    COMPILE_OPT IDL2,HIDDEN

    RETURN, self.root_group->Read_simple_float_dataset(dataset_name)

END


;----------------------------------------------------------------------------
; HDF5_file::Write_dataset
;
; Purpose:
;  creates a dataset based on the data passed in, attached to the currently open
;  file, and with max_dimensions, chunk_dimensions, and gzip as optionally specified.
;  Multiple dimensional arrays of simple data types (like ints or floats) work
;  fine.  More complex data types have not been tested.
;
PRO HDF5_file::Write_dataset, dataset_name, $
                              data, $
                              CHUNK_DIMENSIONS=chunk_dimensions, $
                              GZIP=gzip
    COMPILE_OPT IDL2,HIDDEN

     self.root_group->Write_dataset, dataset_name, $
                                     data, $
                                     CHUNK_DIMENSIONS=chunk_dimensions, $
                                     GZIP=gzip
END


;----------------------------------------------------------------------------
; HDF5_file::Get_<property>
;
; Purpose:
;  This is a series of functions to return various internal properties.
;
FUNCTION HDF5_file::Get_error_status
    COMPILE_OPT IDL2,HIDDEN
    RETURN, self.error->Get_status()
END

FUNCTION HDF5_file::Get_error_message
    COMPILE_OPT IDL2,HIDDEN
    RETURN, self.error->Get_message()
END

FUNCTION HDF5_file::Get_error_call_stack
    COMPILE_OPT IDL2,HIDDEN
    RETURN, self.error->Get_call_stack()
END


;----------------------------------------------------------------------------
; HDF5_file__define
;
; Purpose:
;  Defines the object structure for an HDF5_file object.
;
PRO HDF5_file__define
    COMPILE_OPT IDL2,HIDDEN
    struct = { HDF5_file, $
               file_id: 0L, $
               root_group: OBJ_NEW('HDF5_group'), $
               error: OBJ_NEW('HDF5_error') $
             }
END







