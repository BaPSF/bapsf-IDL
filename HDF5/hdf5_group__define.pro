;NAME:
;   HDF5_group
;
; PURPOSE:
;   This object encapsulates operations pertaining to the HDF5 group.
;
; CALLING SEQUENCE:
;     HDF5_group = OBJ_NEW('HDF5_group')               ; initially creates the object
;     HDF5_group->Open, loc_id, name                   ; opens an HDF5 group attached under "loc_id"
;     HDF5_group->Create, loc_id, name                 ; creates an HDF5 group under "loc_id"
;
;     group_names = HDF5_group->Read_group_names()     ; returns the names of sub-groups attached under this group
;     sub_group = HDF5_group->Open_group(group_name)   ; opens a sub-group attached under this group
;     sub_group = HDF5_group->Create_group(group_name) ; creates a sub-group under this group
;                                                      ;   note: both the above functions return a group object
;
;     dataset_names = HDF5_group->Read_dataset_names() ; returns the names of datasets attached under this group
;     dataset = HDF5_group->Read_dataset(dataset_name) ; reads the specified dataset and returns it in an H5_PARSE
;                                                      ;   style structure
;     datasubset = HDF5_group->Read_datasubset(dataset_name , datastart, datacount, datastride, REFORMFLAG=reformflag)
;                                                      Returns the requested Hyperslab as a structure given by H5_PARSE
;
;     HDF5_group->Write_dataset, dataset_name, data    ; writes the specified data into a dataset under this group
;
;     attr = HDF5_group->Read_attribute(attr_name)     ; reads the specified attribute (only tested for strings)
;
;     status = HDF5_group->Get_error_status()          ; returns error information...
;     message = HDF5_group->Get_error_message()        ;
;     location = HDF5_group->Get_error_location()      ;
;
;     HDF5_group->Close                                ; closes the group (also done when object destroyed)
;     OBJ_DESTROY, HDF5_group                          ; destroys the object and closes the group, if open
;
; KEYWORD PARAMETERS:
;   HDF5_group::Init:
;   LOC_ID: The location id of the HDF5 file or group that contains the group to be opened.
;   NAME: The name of the group to be opened.
;   Example: create an HDF5_group object and open a specified group at the same time -- call is made from
;     within an HDF5_LaPD object:
;     Raw_group = OBJ_NEW('HDF5_group', LOC_ID=self.file_id, NAME='Raw data + config')
;
;   HDF5_group::Write_dataset:
;   CHUNK_DIMENSIONS: Must be of the same dimensionality as the data but with the same
;     or smaller extents.  For this method, where all the data are written at once,
;     the safest thing is to set chunk_dimensions to be the same as the data, which is
;     the default.  If chunk_dimensions is set the extents should divide evenly into
;     the data extents.
;   GZIP: Ranges from 0 (no compression) to 9 (max compression).
;   Example: write a dataset in this group with chunking and maximum compression:
;     test_data = FINDGEN(100, 100)
;     HDF5_group->Write_dataset, 'test_data', test_data, CHUNK_DIMENSIONS=[50, 50], GZIP=9
;
; ERROR HANDLING:
;   Execution will stop when an error is hit.  This is how the underlying HDF5
;   functions and procedures operate.
;
; MODIFICATION HISTORY:
;   Written by:  Jim Bamber  July, 2005.
;   Steve Vincena, April 2007,   Added 'Read_datasubset' method
;                                Returns a subset of the specified dataset using H5S_SELECT_HYPERSLAB.
;                                The form of the result in the form of a result structure as used by H5_PARSE.
;   Steve Vincena, April, 2007.  Added ability to open read-only files with optional 'write_flag' keyword
;   Steve Vincena 07/19/2007 ;   Added Read_simple_float_dataset method which reads the specified
;                                dataset (assumed to be attached to the currently open file and
;                                removes H5_PARSE-style structure and just returns the data portion typecast as float.
;


;----------------------------------------------------------------------------
; HDF5_group::Init
;
; Purpose:
;  Initializes the HDF5_group object, optionally opening the specified group.
;
;  This function returns a 1 if initialization is successful, or 0 otherwise.
;
FUNCTION HDF5_group::Init, LOC_ID=loc_id, NAME=name
COMPILE_OPT idl2,HIDDEN

    self.error = OBJ_NEW('HDF5_error')

    IF ( (N_ELEMENTS(loc_id) EQ 1) AND (N_ELEMENTS(name) EQ 1) ) THEN $
         self->Open, loc_id, name

    RETURN, 1
END


;----------------------------------------------------------------------------
; HDF5_group::Cleanup
;
; Purpose:
;  Cleans up all memory associated with the HDF5_group object.
;
PRO HDF5_group::Cleanup
COMPILE_OPT idl2,HIDDEN

    self->Close
    OBJ_DESTROY, self.error

END


;----------------------------------------------------------------------------
; HDF5_group::Open
;
; Purpose:
;  Opens the specified group and activates this object.
;
PRO HDF5_group::Open, loc_id, name
COMPILE_OPT idl2,HIDDEN

    self.loc_id = loc_id
    self.name = name
    self.group_id = H5G_OPEN(loc_id, name)
    IF (self.group_id EQ 0) THEN $
         self.error->Handle_error, "Group: " + name + " could not be opened by H5G_OPEN()"

END


;----------------------------------------------------------------------------
; HDF5_group::Create
;
; Purpose:
;  Creates the specified group and activates this object.
;
PRO HDF5_group::Create, loc_id, name
COMPILE_OPT idl2,HIDDEN

    self.loc_id = loc_id
    self.name = name
    self.group_id = H5G_CREATE(loc_id, name)
    IF (self.group_id EQ 0) THEN $
         self.error->Handle_error, "Group: " + name + " could not be created by H5G_CREATE()"

END


;----------------------------------------------------------------------------
; HDF5_group::Close
;
; Purpose:
;  Closes the currently open group.
;
PRO HDF5_group::Close
COMPILE_OPT idl2,HIDDEN

    IF (self.group_id NE 0) THEN $
         H5G_CLOSE, self.group_id

    self.loc_id = 0
    self.group_id = 0
    self.name = ""

END


;----------------------------------------------------------------------------
; HDF5_group::Open_group
;
; Purpose:
;  Opens the specified sub-group assumed to be attached to the currently open
;  group and returns it as an object.  It is the responsibility of the caller
;  to destroy the returned HDF5_group object.
;
FUNCTION HDF5_group::Open_group, sub_group_name
COMPILE_OPT idl2,HIDDEN

    sub_group = OBJ_NEW('HDF5_group')
    sub_group->Open, self.group_id, sub_group_name

    RETURN, sub_group

END


;----------------------------------------------------------------------------
; HDF5_group::Create_group
;
; Purpose:
;  Creates the specified sub-group assumed to be attached to the currently open
;  group and returns it as an object.  It is the responsibility of the caller
;  to destroy the returned HDF5_group object.
;
FUNCTION HDF5_group::Create_group, sub_group_name
COMPILE_OPT idl2,HIDDEN

    sub_group = OBJ_NEW('HDF5_group')
    sub_group->Create, self.group_id, sub_group_name

    RETURN, sub_group

END


;----------------------------------------------------------------------------
; HDF5_group::Get_<property>
;
; Purpose:
;  This is a series of functions to return various internal properties.
;
FUNCTION HDF5_group::Get_error_status
COMPILE_OPT idl2,HIDDEN
    RETURN, self.error->Get_status()
END

FUNCTION HDF5_group::Get_error_message
COMPILE_OPT idl2,HIDDEN
    RETURN, self.error->Get_message()
END

FUNCTION HDF5_group::Get_error_call_stack
COMPILE_OPT idl2,HIDDEN
    RETURN, self.error->Get_call_stack()
END


;----------------------------------------------------------------------------
; HDF5_group::Read_attribute
;
; Purpose:
;  Returns the value corresponding to the specified name for an attribute attached
;  to the currently open group.
;
FUNCTION HDF5_group::Read_attribute, name
COMPILE_OPT idl2,HIDDEN
    attribute_id = H5A_OPEN_NAME(self.group_id, name)
    attribute = H5A_READ(attribute_id)
    H5A_CLOSE, attribute_id

    RETURN, attribute
END
;----------------------------------------------------------------------------
; HDF5_group::Write_attribute
;
; Purpose:
;  Returns the value corresponding to the specified name for an attribute attached
;  to the currently open group.
;
PRO HDF5_group::Write_attribute, name, data
COMPILE_OPT idl2,HIDDEN
    ; create a datatype
    datatype_id = H5T_IDL_CREATE(data)

    ; create a dataspace
    dimensions=size(data,/dimensions)
    IF (dimensions eq 0) THEN BEGIN
     dataspace_id = H5S_CREATE_SCALAR()
    ENDIF ELSE BEGIN
     dataspace_id = H5S_CREATE_SIMPLE(dimensions, MAX_DIMENSIONS=dimensions)
    ENDELSE

    ; create the attribute and write the data to it
    attribute_id = H5A_CREATE(self.group_id, name, datatype_id,dataspace_id)
    H5A_WRITE,attribute_id,data

    ; close identifiers
    H5T_CLOSE, datatype_id
    H5S_CLOSE, dataspace_id
    H5A_CLOSE, attribute_id

END

;----------------------------------------------------------------------------



;----------------------------------------------------------------------------
; HDF5_group::Read_group_names
;
; Purpose:
;  Returns the names of groups attached to the currently open group.
;
FUNCTION HDF5_group::Read_group_names
COMPILE_OPT idl2,HIDDEN

    RETURN, self->Read_object_names('GROUP')
END


;----------------------------------------------------------------------------
; HDF5_group::Read_dataset_names
;
; Purpose:
;  Returns the names of datasets attached to the currently open group.
;
FUNCTION HDF5_group::Read_dataset_names
COMPILE_OPT idl2,HIDDEN

    RETURN, self->Read_object_names('DATASET')
END


;----------------------------------------------------------------------------
; HDF5_group::Read_object_names
;
; Purpose:
;  Returns the names of objects attached to the currently open group of the
;  specified type.
;
FUNCTION HDF5_group::Read_object_names, type
COMPILE_OPT idl2,HIDDEN
    count = 0
    object_names = STRARR(100)

    member_count = H5G_GET_NMEMBERS(self.loc_id, self.name)
    FOR i = 0, member_count-1 DO BEGIN
         member_name = H5G_GET_MEMBER_NAME(self.loc_id, self.name, i)
         member_info = H5G_GET_OBJINFO(self.group_id, member_name)
         IF (member_info.TYPE EQ type) THEN BEGIN
              object_names[count] = member_name
              count = count + 1
         ENDIF
    ENDFOR

    IF (count EQ 0) THEN $
         object_names = STRARR(1) $
    ELSE $
         object_names = object_names[0:count-1]

    RETURN, object_names
END


;----------------------------------------------------------------------------
; HDF5_group::Read_dataset
;
; Purpose:
;  Returns the specified dataset in the form of a result structure as used by
;  H5_PARSE.  See p. 116 of "IDL Scientific Data Formats" (sdf.pdf) for details
;  on this data structure.  It is the same as what is returned by H5_BROWSER as well.
;
FUNCTION HDF5_group::Read_dataset, dataset_name
COMPILE_OPT idl2,HIDDEN

    dataset = H5_PARSE(self.group_id, dataset_name, /READ_DATA)
    RETURN, dataset
END

;----------------------------------------------------------------------------
; HDF5_group::Read_simple_float_dataset
;
; 07/19/2007 Steve Vincena
; Purpose:
;  Returns just the "._DATA" part of what is returned by the Read_dataset method.
;  The data are assumed to be capable of conversion to type 'float' without error.
;
FUNCTION HDF5_group::Read_simple_float_dataset, dataset_name
COMPILE_OPT idl2,HIDDEN

    dataset = H5_PARSE(self.group_id, dataset_name, /READ_DATA)
    RETURN, (dataset._data)
END
;----------------------------------------------------------------------------
; HDF5_group::DACS_NI7340_read_xy()
; 09/26/2008 Stephen Vincena
; Purpose: to return the xy values visited by the probe tip
; which was controlled by DACS v1.0 Module NI7340_XY
FUNCTION HDF5_group::DACS_NI7340_read_xy
COMPILE_OPT idl2,HIDDEN
    ;choose the first dataset, regardless of name
    ;this is for backward compatability for datasets with
    ;incorrectly named xy position datasets
    dataset_name = (self->Read_dataset_names())[0]
    data_struct = self->Read_simple_float_dataset(dataset_name)
    x=reform(data_struct[*].x)
    y=reform(data_struct[*].y)
    n=n_elements(x)
    xy = fltarr(2,n)
    xy[0,*] = x
    xy[1,*] = y
    RETURN, xy
END

;----------------------------------------------------------------------------
; HDF5_group::Read_tvs_shot
;
; 07/24/2007 Steve Vincena
; Purpose:
;  Return one timeseries, indexed by shot number (aka N-th one saved to disk)
;  for a logical channel of the TVS645A digitizer.
;  Returns a floating point array with the scale and offset already applied.
;  Note: the logical channel number is the order in which the channels
;  are saved in the file (starting at zero).
;
;  Limitations: It can only index by the order in which the dataset
;  appears under the digitizer group. There is no way to choose
;  by configuration name
;
FUNCTION HDF5_group::Read_tvs_shot, logical_channel, shotnumber
COMPILE_OPT idl2,HIDDEN
 dataset_name = (self->Read_dataset_names())[2*logical_channel]
 header_dataset_name = dataset_name+' headers'
 ; Open the file or group
   dataset_id = H5D_OPEN(self.group_id,dataset_name)

 ; Open up the dataspace
   dataspace_id = H5D_GET_SPACE(dataset_id)
   dims = H5S_GET_SIMPLE_EXTENT_DIMS(dataspace_id)
   IF (shotnumber GT dims[1]) THEN BEGIN
    print,'Warning: requested shot number is greater than the expected number of shots. Setting shotnumber to '+string(dims[1])
    shotnumber = dims[1]
   ENDIF

   datastart  = long([0,shotnumber])
   datacount  = long([dims[0],1])
   datastride = long([1,1])

   ; Now choose our hyperslab.
   ; Be sure to use /RESET to turn off all other selected elements.  
   H5S_SELECT_HYPERSLAB, dataspace_id, datastart, datacount,STRIDE=datastride,/RESET

   ; Create a simple dataspace to hold the result. If we didn't supply 
   ; the memory dataspace, then the result would be the same size 
   ; as the full dataspace, with zeros everywhere except our 
   ; hyperslab selection. 
   memory_space_id = H5S_CREATE_SIMPLE(datacount)
     
   ; Read in the actual data.
   data = H5D_READ(dataset_id, FILE_SPACE=dataspace_id, $ 
      MEMORY_SPACE=memory_space_id) 

   H5S_CLOSE, memory_space_id
   H5S_CLOSE, dataspace_id
   H5D_CLOSE, dataset_id

;--------------------------------
;  Now do the header


 ; Open the file or group
   header_dataset_id = H5D_OPEN(self.group_id,header_dataset_name)

 ; Open up the header dataspace
   header_dataspace_id = H5D_GET_SPACE(header_dataset_id)

 ; Only extracting one structure, not an array
   header_datastart  = long([shotnumber])
   header_datacount  = long([1])
   header_datastride = long([1])


 ; Select hyperslab of header informaiton
   H5S_SELECT_HYPERSLAB, header_dataspace_id, header_datastart, header_datacount,STRIDE=header_datastride,/RESET

 ; Gee, what could this do? Perhaps it creates the header memeory space id.
   header_memory_space_id = H5S_CREATE_SIMPLE(header_datacount)
     
   ; Read in the actual data.
   header_data = H5D_READ(header_dataset_id, FILE_SPACE=header_dataspace_id, $ 
      MEMORY_SPACE=header_memory_space_id) 

   H5S_CLOSE, header_memory_space_id
   H5S_CLOSE, header_dataspace_id
   H5D_CLOSE, header_dataset_id

   data = float(data)
   data *= float(header_data.scale)
   IF (header_data.offset NE 0.) THEN data -= float(header_data.offset)

   return,data
END
;----------------------------------------------------------------------------
; HDF5_group::Read_sis3302_shot
; Based on Read_sis_shot (the 3301 14 bit 100MHz original SIS digitizers)
;
; 10/09/2012 Steve Vincena
; Purpose:
;  Return one timeseries, indexed by shot number (aka N-th one saved to disk)
;  for a logical channel of the SIS3302 digitizer.
;  Returns a floating point array with the scale and offset already applied.
;
;  Limitations: only a fixed offset is used (-2.5V not the one in the header)
;  Reads data by 'board' and 'channel,' not 'logical channel' like the Read_sis_shot
;  however, the lapd_sis3302_configuration returns logical channel arrays of board/channel info
;  so that board_number for logical channel 17 = sis_struct.lc_board_number[17]
;
;  6/1/2015 added the ability to specify a timestep range, eg, trange=[200,300] for 101 points starting at 200
;           also added nshots keyword to return a given number of shots starting at shotnumber;
;           note that this allows a return of all shots at one position, or even every single shot in the dataset
;           This saves overhead of reading info and allocating/deallocating resources for every shot
; 3/4/2016 added keywords 'tstride' and 'shotstride' to provide the ability to implement the datastride capability of hyperslabs. 
;
;
FUNCTION HDF5_group::Read_sis3302_shot, board_number,channel_number, shotnumber, config_name=config_name,trange=trange,nshots=nshots,tstride=tstride,shotstride=shotstride
COMPILE_OPT idl2,HIDDEN

slot_number = board_number*2 + 3 ; the slot in the VME crate. this is fixed, based on the SIS_Crate being a single digitizing device

saved_config_names = self.Read_group_names() ;each group contains a configuration

IF (KEYWORD_SET(config_name)) THEN BEGIN
  prefix_name=config_name ;use configuration if given
ENDIF ELSE BEGIN
  prefix_name = (self.Read_group_names())[0]  ;otherwise use the first one
ENDELSE


dataset_name = prefix_name+' [Slot '+strcompress(string(slot_number)+':',/remove_all)+$
 ' SIS 3302 ch '+strcompress(string(channel_number)+']',/remove_all)


 ; Open the file or group
   dataset_id = H5D_OPEN(self.group_id,dataset_name)

 ; Open up the dataspace
   dataspace_id = H5D_GET_SPACE(dataset_id)
   dims = H5S_GET_SIMPLE_EXTENT_DIMS(dataspace_id)
   IF (shotnumber GT dims[1]) THEN BEGIN
    print,'Warning: requested shot number is greater than the expected number of shots. Setting shotnumber to '+string(dims[1])
    shotnumber = dims[1]
   ENDIF

   ns = KEYWORD_SET(nshots) ? nshots : 1

   IF KEYWORD_SET(trange) THEN BEGIN
     datastart  = long([trange[0],shotnumber])
     datacount  = long([(trange[1]-trange[0]+1),ns])
   ENDIF ELSE BEGIN
     datastart  = long([0,shotnumber])
     datacount  = long([dims[0],ns])
   ENDELSE
   datastride = long([1,1])

   IF KEYWORD_SET(tstride) THEN datastride[0] = tstride
   IF KEYWORD_SET(shotstride) THEN datastride[1] = shotstride


   ; Now choose our hyperslab.
   ; Be sure to use /RESET to turn off all other selected elements.  
   H5S_SELECT_HYPERSLAB, dataspace_id, datastart, datacount,STRIDE=datastride,/RESET

   ; Create a simple dataspace to hold the result. If we didn't supply 
   ; the memory dataspace, then the result would be the same size 
   ; as the full dataspace, with zeros everywhere except our 
   ; hyperslab selection. 
   memory_space_id = H5S_CREATE_SIMPLE(datacount)
     
   ; Read in the actual data.
   data = H5D_READ(dataset_id, FILE_SPACE=dataspace_id, $ 
      MEMORY_SPACE=memory_space_id) 

   H5S_CLOSE, memory_space_id
   H5S_CLOSE, dataspace_id
   H5D_CLOSE, dataset_id

;--------------------------------
;  Note, we don't handle the 'clipped' header information, nor
;  'min', nor 'max'.
; NOTE as of 10/9/2012, we don't handle the manual offsets.

   data = float(data)
   data *= 7.7241166e-5
   data -= 2.531 ; the default measured for these digitizers

   return,data
END
;----------------------------------------------------------------------------
; HDF5_group::Read_sis3305_shot
; Based on Read_sis3302_shot (whcih was based on Read_sis_shot)
;
; 10/22/2012 Steve Vincena
; Purpose:
;  Return one timeseries, indexed by shot number (aka N-th one saved to disk)
;  for a logical channel of the SIS3305 digitizer.
;  Returns a floating point array with the scale and offset already applied.
;
;  Limitations: only a fixed offset is used (-1.0V not the one in the header)
;  Reads data by 'board' and 'channel,' not 'logical channel' like the Read_sis_shot
;
; Changes:
;  05/31/2018 Steve Vincena
;  Added the ability to specify a timestep range, eg, trange=[200,300] for 101 points starting at 200
;  also added nshots keyword to return a given number of shots starting at shotnumber;
;  note that this allows a return of all shots at one position, or even every single shot in the dataset
;  This saves overhead of reading info and allocating/deallocating resources for every shot
;  Also added keywords 'tstride' and 'shotstride' to provide the ability to implement the datastride capability of hyperslabs. 
;


; 
;

FUNCTION HDF5_group::Read_sis3305_shot, board_number,channel_number, shotnumber, config_name=config_name,$
	trange=trange,nshots=nshots,tstride=tstride,shotstride=shotstride
COMPILE_OPT idl2,HIDDEN

slot_number = board_number*2 + 11
fpga_numbers = [1,1,1,1,2,2,2,2]
fpga_chan_numbers = [1,2,3,4,1,2,3,4]
fpga_number = fpga_numbers[channel_number-1]
fpga_chan_number = fpga_chan_numbers[channel_number-1]

saved_config_names = self.Read_group_names() ;each group contains a configuration

IF (KEYWORD_SET(config_name)) THEN BEGIN
  prefix_name=config_name
ENDIF ELSE BEGIN
  prefix_name = (self.Read_group_names())[0]
ENDELSE


dataset_name = prefix_name+' [Slot '+strcompress(string(slot_number)+':',/remove_all)+$
 ' SIS 3305 FPGA '+strcompress(string(fpga_number),/remove_all)+' ch '+strcompress(string(fpga_chan_number)+']',/remove_all)


 ; Open the file or group
   dataset_id = H5D_OPEN(self.group_id,dataset_name)

 ; Open up the dataspace
   dataspace_id = H5D_GET_SPACE(dataset_id)
   dims = H5S_GET_SIMPLE_EXTENT_DIMS(dataspace_id)
   IF (shotnumber GT dims[1]) THEN BEGIN
    print,'Warning: requested shot number is greater than the expected number of shots. Setting shotnumber to '+string(dims[1])
    shotnumber = dims[1]
   ENDIF
   
   ns = KEYWORD_SET(nshots) ? nshots : 1

   IF KEYWORD_SET(trange) THEN BEGIN
     datastart  = long([trange[0],shotnumber])
     datacount  = long([(trange[1]-trange[0]+1),ns])
   ENDIF ELSE BEGIN
     datastart  = long([0,shotnumber])
     datacount  = long([dims[0],ns])
   ENDELSE
   datastride = long([1,1])

   IF KEYWORD_SET(tstride) THEN datastride[0] = tstride
   IF KEYWORD_SET(shotstride) THEN datastride[1] = shotstride

   ; Now choose our hyperslab.
   ; Be sure to use /RESET to turn off all other selected elements.  
   H5S_SELECT_HYPERSLAB, dataspace_id, datastart, datacount,STRIDE=datastride,/RESET

   ; Create a simple dataspace to hold the result. If we didn't supply 
   ; the memory dataspace, then the result would be the same size 
   ; as the full dataspace, with zeros everywhere except our 
   ; hyperslab selection. 
   memory_space_id = H5S_CREATE_SIMPLE(datacount)

   ; Read in the actual data.
   data = H5D_READ(dataset_id, FILE_SPACE=dataspace_id, $
      MEMORY_SPACE=memory_space_id)

   H5S_CLOSE, memory_space_id
   H5S_CLOSE, dataspace_id
   H5D_CLOSE, dataset_id

;--------------------------------
;  Note, we don't handle the 'clipped' header information, nor
;  'min', nor 'max'.
; NOTE as of 10/22/2012, we don't handle any manual offsets.

   scale_factor = 2. / float(2.^10-1.0) ;10 bits (0 to 1023) and 2 Volt range

   data = float(data)
   data *= scale_factor
   data -= 1.0 

;As of 10/22/2012, the 3305 digtizer may record the last few samples as zero
;(more with higher digitization rate)
;This is a result of adjusting the jitter on the input trigger.
;This is a bug that will be addressed in the next release.

   return,data
END


;----------------------------------------------------------------------------
; HDF5_group::Read_sis_shot
;
; 07/31/2007 Steve Vincena
; Purpose:
;  Return one timeseries, indexed by shot number (aka N-th one saved to disk)
;  for a logical channel of the SIS3301 digitizer.
;  Returns a floating point array with the scale and offset already applied.
;  Note: the logical channel number is the order in which the channels
;  are saved in the file (starting at zero).
;
;  Limitations: It can only index by the order in which the dataset
;  appears under the digitizer group. There is no way to choose
;  by configuration name
;
;  12/10/2009 The above limitation has been removed. You can now specify
;  a configuration name, and the logical channel will now be with respect
;  to the block of datasets which share that configuration name.
;
;
FUNCTION HDF5_group::Read_sis_shot, logical_channel, shotnumber, config_name
COMPILE_OPT idl2,HIDDEN

sis_dataset_names = self->Read_dataset_names()

IF (N_PARAMS() EQ 3) THEN BEGIN
    ;configuration name supplied. adjust logical channels relative to the
    ;datasets that are part of the specified configuration
    n_datasets=N_ELEMENTS(sis_dataset_names)
    dataset_prefix_names=STRARR(n_datasets)

    FOR i=0,n_datasets-1 DO BEGIN
      temp_ds_name = reform(sis_dataset_names[i])
      dataset_prefix_names[i] = strmid(temp_ds_name,0,stregex(temp_ds_name,'\[')-1)
    ENDFOR
    ;Find those indices that match the supplied configuration name
    index_result = WHERE(dataset_prefix_names EQ config_name)
    ;Select out just the matching ones
    sis_dataset_names = sis_dataset_names[index_result]
    ;update the resulting number of datasets

ENDIF
;no configuration name supplied. assume the standard datarun type
dataset_name = sis_dataset_names[2*logical_channel]




 ; Open the file or group
   dataset_id = H5D_OPEN(self.group_id,dataset_name)

 ; Open up the dataspace
   dataspace_id = H5D_GET_SPACE(dataset_id)
   dims = H5S_GET_SIMPLE_EXTENT_DIMS(dataspace_id)
   IF (shotnumber GT dims[1]) THEN BEGIN
    print,'Warning: requested shot number is greater than the expected number of shots. Setting shotnumber to '+string(dims[1])
    shotnumber = dims[1]
   ENDIF

   datastart  = long([0,shotnumber])
   datacount  = long([dims[0],1])
   datastride = long([1,1])

   ; Now choose our hyperslab.
   ; Be sure to use /RESET to turn off all other selected elements.  
   H5S_SELECT_HYPERSLAB, dataspace_id, datastart, datacount,STRIDE=datastride,/RESET

   ; Create a simple dataspace to hold the result. If we didn't supply 
   ; the memory dataspace, then the result would be the same size 
   ; as the full dataspace, with zeros everywhere except our 
   ; hyperslab selection. 
   memory_space_id = H5S_CREATE_SIMPLE(datacount)
     
   ; Read in the actual data.
   data = H5D_READ(dataset_id, FILE_SPACE=dataspace_id, $ 
      MEMORY_SPACE=memory_space_id) 

   H5S_CLOSE, memory_space_id
   H5S_CLOSE, dataspace_id
   H5D_CLOSE, dataset_id

;--------------------------------
;  Unlike the TVS645A, the offset and scale are always
;  the same for this digitizer.
;  Note, we don't handle the 'clipped' header information, nor
;  'min', nor 'max'.
;  Actually, you can adjust the SIS offsets, but they  don't
;  appread to behave as expected:  you are always limited
;  to +/- 2.5 Volts, despite the offset


   data = float(data)
   data *= 3.0519441e-4
   data -= 2.5 ;  So, in rare occasions,this might not hold 

   return,data
END


;----------------------------------------------------------------------------
; HDF5_group::DACS_LCWave_read_shot
;
; 09/06/2008 Steve Vincena
; Purpose:
;  For the HDF5 data files of the Data Acquisition and Control System (DACS v 1.0).
;  Return one timeseries for the specified channel and shot number for the LeCroy Wave-Series scope digitizer
;  associated with the parent group.
;  Shots are indexed by shot number (aka N-th one saved to disk)
;  Returns a floating point array, assumed to be in unscaled volts.
;  are saved in the file (starting at zero).
;  Note, this can later be made into a general method for reading data from
;  other digitizer types
;
;
FUNCTION HDF5_group::DACS_LCWave_read_shot, channel, shotnumber
COMPILE_OPT idl2,HIDDEN

 dataset_name = strcompress('Channel'+string(channel),/remove_all)

 ; Open the dataset
   dataset_id = H5D_OPEN(self.group_id,dataset_name)

 ; Open up the dataspace
   dataspace_id = H5D_GET_SPACE(dataset_id)
   dims = H5S_GET_SIMPLE_EXTENT_DIMS(dataspace_id)
   IF (shotnumber GT dims[1]) THEN BEGIN
    print,'Warning: requested shot number is greater than the expected number of shots. Setting shotnumber to '+string(dims[1])
    shotnumber = dims[1]
   ENDIF

   datastart  = long([0,shotnumber])
   datacount  = long([dims[0],1])
   datastride = long([1,1])

   ; Now choose our hyperslab.
   ; Be sure to use /RESET to turn off all other selected elements.  
   H5S_SELECT_HYPERSLAB, dataspace_id, datastart, datacount,STRIDE=datastride,/RESET

   ; Create a simple dataspace to hold the result. If we didn't supply 
   ; the memory dataspace, then the result would be the same size 
   ; as the full dataspace, with zeros everywhere except our 
   ; hyperslab selection. 
   memory_space_id = H5S_CREATE_SIMPLE(datacount)
     
   ; Read in the actual data.
   data = H5D_READ(dataset_id, FILE_SPACE=dataspace_id, $ 
      MEMORY_SPACE=memory_space_id) 

   H5S_CLOSE, memory_space_id
   H5S_CLOSE, dataspace_id
   H5D_CLOSE, dataset_id

;   data = float(data)

   return,data
END

;----------------------------------------------------------------------------
; HDF5_group::Read_datasubset
;
; 04/26/2007 Steve Vincena
; Purpose:
;  Returns a subset of the specified dataset using H5S_SELECT_HYPERSLAB.
;  The form of the result in the form of a result structure as used by
;  H5_PARSE.  See p. 116 of "IDL Scientific Data Formats" (sdf.pdf) for details
;  on this data structure.  This form is the same to what is returned by H5_BROWSER as well.
;
FUNCTION HDF5_group::Read_datasubset, dataset_name , datastart, datacount, datastride, REFORMFLAG=reformflag
COMPILE_OPT idl2,HIDDEN

 ; Open the file or group
   dataset_id = H5D_OPEN(self.group_id,dataset_name)


 ; Open up the dataspace
   dataspace_id = H5D_GET_SPACE(dataset_id)

   ;If input stride for data not set then use a stride of 1
   ;in each dimension
   IF N_PARAMS(0) EQ 2 THEN datastride = INDEGN(N_ELEMENTS(datastart)+1)
     
   ; Now choose our hyperslab.
   ; Be sure to use /RESET to turn off all other  
   ; selected elements.  
   H5S_SELECT_HYPERSLAB, dataspace_id, datastart, datacount,STRIDE=datastride,/RESET;   STRIDE=[2, 2]
  
   ; Create a simple dataspace to hold the result. If we  
   ; didn't supply  
   ; the memory dataspace, then the result would be the same size  
   ; as the full dataspace, with zeros everywhere except our  
   ; hyperslab selection.  
   memory_space_id = H5S_CREATE_SIMPLE(datacount)  
     
   ; Read in the actual data.  
   datasubset = H5D_READ(dataset_id, FILE_SPACE=dataspace_id, $  
      MEMORY_SPACE=memory_space_id)  
  
   ; Close all our identifiers so we don't leak resources.  
   H5S_CLOSE, memory_space_id
   H5S_CLOSE, dataspace_id
   H5D_CLOSE, dataset_id

   IF KEYWORD_SET(REFORMFLAG) THEN datasubset = REFORM(TEMPORARY(datasubset))
   RETURN, datasubset


END


;----------------------------------------------------------------------------
; HDF5_group::Write_Maya_color_table
;  creates a custom color table  dataset for use with the LAPD Maya visualization HDF file spec,
;  attached to the currently open group, which should be 'Color tables'
;  Includes the required attribute of 'Type' equals '3-vector'--this method was created
;  as a primary workaround for attributes being easily assigned to Groups, but not
;  to datasets within the given HDF5 Group __define file.
;
PRO HDF5_group::Write_Maya_color_table, color_table_name, color_table_data
COMPILE_OPT idl2,HIDDEN

     ; create a datatype
     member_names = ['table_x','table_y','table_z']
     datatype_id = H5T_IDL_CREATE(color_table_data,MEMBER_NAMES=member_names)

     ; create a dataspace
     dimensions=size(color_table_data,/dimensions)
     dataspace_id = H5S_CREATE_SIMPLE(dimensions, MAX_DIMENSIONS=dimensions)

     ; create the dataset
     chunk_dims=[256]
     dataset_id = H5D_CREATE(self.group_id, color_table_name,$
       datatype_id, dataspace_id,CHUNK_DIMENSIONS=chunk_dims)

     ; write the data to the dataset
     H5D_WRITE,dataset_id,color_table_data

     ;Write the required attribute(s) to the dataset
     ; create a datatype
     attr_data = '3-vector'
     attr_datatype_id = H5T_IDL_CREATE(attr_data)
     attr_dataspace_id = H5S_CREATE_SCALAR()
     ; create the attribute and write the data to it
     attr_id = H5A_CREATE(dataset_id,'Type',attr_datatype_id,attr_dataspace_id)
     H5A_WRITE,attr_id,attr_data

     ;close attribute identifiers
     H5T_CLOSE, attr_datatype_id
     H5S_CLOSE, attr_dataspace_id
     H5A_CLOSE, attr_id



     ; close identifiers
     H5D_CLOSE, dataset_id
     H5S_CLOSE, dataspace_id
     H5T_CLOSE, datatype_id
END
;----------------------------------------------------------------------------
; HDF5_group::Write_dataset
;
; Purpose:
;  creates a dataset based on the data passed in, attached to the currently open
;  group, and with max_dimensions and chunk_dimensions as optionally specified.
;
PRO HDF5_group::Write_dataset, dataset_name, $
                               data, $
                               CHUNK_DIMENSIONS=chunk_dimensions, $
                               GZIP=gzip
COMPILE_OPT idl2,HIDDEN

     ; create a datatype
     datatype_id = H5T_IDL_CREATE(data)

     ; create a dataspace
     dimensions=size(data,/dimensions)
     dataspace_id = H5S_CREATE_SIMPLE(dimensions, MAX_DIMENSIONS=dimensions)

     ; create the dataset
     IF (N_ELEMENTS(chunk_dimensions) EQ 0) THEN $
          chunk_dimensions = dimensions
     IF (N_ELEMENTS(gzip) EQ 0) THEN $
          gzip = 0

     dataset_id = H5D_CREATE(self.group_id, dataset_name, datatype_id, dataspace_id, $
          CHUNK_DIMENSIONS=chunk_dimensions, GZIP=gzip)

     ; write the data to the dataset
     H5D_WRITE,dataset_id,data

     ; close identifiers
     H5D_CLOSE, dataset_id
     H5S_CLOSE, dataspace_id
     H5T_CLOSE, datatype_id

END
;
;
;----------------------------------------------------------------------------
; HDF5_group::Create_dataset
;
; Purpose:
;  creates a dataset in the current group based on the planned dimensions (required),
;  data type (optional; defaults to a scalar float),
;  chunking (optional), and gzip level (optional) specified
;data passed in, attached to the currently open
;  group, and with max_dimensions and chunk_dimensions as optionally specified.
;
PRO HDF5_group::Create_dataset, dataset_name, $
                               dims, TYPE=type,  $
                               CHUNK_DIMENSIONS=chunk_dimensions, $
                               GZIP=gzip
COMPILE_OPT idl2,HIDDEN

     ; create a datatype
     IF KEYWORD_SET(TYPE) THEN BEGIN
      datatype_id = H5T_IDL_CREATE(type)
     ENDIF ELSE BEGIN
      datatype_id = H5T_IDL_CREATE(float(0.))
     ENDELSE

     ; create a dataspace
     dataspace_id = H5S_CREATE_SIMPLE(dims, MAX_DIMENSIONS=dims)

     ; create the dataset
     IF (N_ELEMENTS(chunk_dimensions) EQ 0) THEN  chunk_dimensions = dims
     IF (N_ELEMENTS(gzip) EQ 0) THEN gzip = 0

     dataset_id = H5D_CREATE(self.group_id, dataset_name, datatype_id, dataspace_id, $
          CHUNK_DIMENSIONS=chunk_dimensions, GZIP=gzip)

     ; write the data to the dataset
;     H5D_WRITE,dataset_id,data

     ; close identifiers
     H5D_CLOSE, dataset_id
     H5S_CLOSE, dataspace_id
     H5T_CLOSE, datatype_id

END
;
;
;----------------------------------------------------------------------------
; HDF5_group__define
;
; Purpose:
;  Defines the object structure for an HDF5_group object.
;
PRO HDF5_group__define
COMPILE_OPT idl2
    struct = { HDF5_group, $
               loc_id: 0L, $
               group_id: 0L, $
               name: "", $
               error: OBJ_NEW('HDF5_error') $
             }
END
