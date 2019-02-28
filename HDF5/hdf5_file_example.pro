;This is an example IDL program to use the HDF5_file object.

pro HDF5_file_example

root_path='/bapsf/data8'
hdf5_path=root_path+'/hdf5'
!PATH = hdf5_path + ' ' + !PATH  ; the separation character ';' is for Windows
test_data = FINDGEN(100, 100)

; Create the object.
HDF5_file = OBJ_NEW('HDF5_file')

; Create/open an HDF5 file.
filepath = DIALOG_PICKFILE(PATH=hdf5_path)
IF (filepath EQ '') THEN GOTO, Cleanup

print, ''
print, '*********************************************************'
IF (FILE_TEST(filepath) EQ 1) THEN BEGIN
     print, 'Opening: ', filepath
     HDF5_file->Open, filepath
ENDIF $
ELSE BEGIN
     print, 'Creating: ', filepath
     HDF5_file->Create, filepath
ENDELSE

;List attached groups
print, ''
print, 'Groups:'
print, '-------'
group_names = HDF5_file->Read_group_names()

IF (group_names[0] NE '') THEN BEGIN
     FOR i=0, N_ELEMENTS(group_names)-1 DO print, group_names[i]

     ;Open a group
     group_name = ''
     READ, group_name, PROMPT='Enter name of group to open: '
     group = HDF5_file->Open_group(group_name)

     ;Write a dataset in this group
     dataset_name = ''
     READ, dataset_name, PROMPT='Now enter name of dataset to write under ' + group_name + ': '
     group->Write_dataset, dataset_name, test_data, $
          CHUNK_DIMENSIONS=[50, 50], GZIP=9

     ;List attached datasets
     print, ''
     print, 'Datasets under ' + group_name + ':'
     print, '----------------------------------'
     dataset_names = group->Read_dataset_names()
     FOR i=0, N_ELEMENTS(dataset_names)-1 DO print, dataset_names[i]

     ;Read a dataset
     dataset_name = ''
     READ, dataset_name, PROMPT='Enter name of dataset to read under ' + group_name + ': '
     dataset = group->Read_dataset(dataset_name)
     plot, dataset._DATA[*,0]
     OBJ_DESTROY, group
ENDIF

;Create a group in the file
group_name = ''
READ, group_name, PROMPT='Enter name of group to create: '
group = HDF5_file->Create_group(group_name)

     ;Create a sub-group under this group
     subgroup_name = ''
     READ, subgroup_name, PROMPT='Now enter name of sub-group to create under ' + group_name + ': '
     subgroup = group->Create_group(subgroup_name)
     OBJ_DESTROY, subgroup  ;normally you would do something with the sub-group before destroying it

     ;List sub-groups under this group
     print, ''
     print, 'Sub-groups under ' + group_name + ':'
     print, '------------------------------------'
     subgroup_names = group->Read_group_names()
     FOR i=0, N_ELEMENTS(subgroup_names)-1 DO print, subgroup_names[i]

     ;Open an existing sub-group under this group
     subgroup_name = ''
     READ, subgroup_name, PROMPT='Enter name of sub-group to open under ' + group_name + ': '
     subgroup = group->Open_group(subgroup_name)
     OBJ_DESTROY, subgroup  ;normally you would do something with the sub-group before destroying it

OBJ_DESTROY, group


;List datasets attached to the file
print, ''
print, 'Datasets:'
print, '---------'
dataset_names = HDF5_file->Read_dataset_names()

IF (dataset_names[0] NE '') THEN BEGIN
     FOR i=0, N_ELEMENTS(dataset_names)-1 DO print, dataset_names[i]

     ;Read a dataset
     dataset_name = ''
     READ, dataset_name, PROMPT='Enter name of dataset to open: '
     dataset = HDF5_file->Read_dataset(dataset_name)
     plot, dataset._DATA[*,0]
ENDIF

;Write a dataset
dataset_name = ''
READ, dataset_name, PROMPT='Enter name of dataset to create: '
HDF5_file->Write_dataset, dataset_name, test_data, $
     CHUNK_DIMENSIONS=[50, 50], GZIP=9

; Destroy the object.
Cleanup:
OBJ_DESTROY, HDF5_file

val=''
READ, val, PROMPT='Hit <ENTER> to continue'


end
