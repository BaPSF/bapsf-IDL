;This is an example IDL program to use the HDF5_LaPD object.

pro HDF5_LaPD_example

!PATH = 'C:\ACQ II home\HDF5\IDL' + ';' + !PATH  ; the separation character ';' is for Windows

; Create the object.
HDF5_LaPD = OBJ_NEW('HDF5_LaPD')

; Open the LAPD raw HDF5 file.
filepath = DIALOG_PICKFILE(PATH='C:\Data')
IF (filepath EQ '') THEN GOTO, Cleanup

print, ''
print, '*********************************************************'
print, 'Opening: ', filepath
HDF5_LaPD->Open, filepath

; List the devices attached
print, ''
print, 'Devices:'
print, '--------'
device_names = HDF5_LaPD->Read_device_names()
IF (device_names[0] EQ '') THEN GOTO, Cleanup

FOR i=0, N_ELEMENTS(device_names)-1 DO print, device_names[i]

; List datasets for a selected device
device_name = ''
READ, device_name, PROMPT='Select a device name: '
print, ''
print, 'Datasets:'
print, '---------'
dataset_names = HDF5_LaPD->Read_dataset_names(device_name)
IF (dataset_names[0] EQ '') THEN GOTO, Cleanup

FOR i=0, N_ELEMENTS(dataset_names)-1 DO print, dataset_names[i]

; Open selected dataset
dataset_name = ''
READ, dataset_name, PROMPT='Select a dataset name: '
dataset = HDF5_LaPD->Read_dataset(device_name, dataset_name)
IF (STREGEX(dataset_name, 'headers$') NE -1) THEN $
     plot, dataset._DATA[*].shot_number $
ELSE $
     plot, dataset._DATA[*,0]

; Destroy the object.
Cleanup:
OBJ_DESTROY, HDF5_LaPD
val=''
READ, val, PROMPT='Hit <ENTER> to continue: '


end