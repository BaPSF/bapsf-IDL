# Files and their purpose:

Here is a brief description of each routine.  Examine the routine headers for detailed usage.

---

## hdf5_error__define.pro

<dl>
  <dt>Defines</dt>
  <dd>Object <code>HDF5_error</code></dd>
  <dt>Purpose</dt>
  <dd>This object manages error handling for any LaPD object. It is an internal object primarily but could be included in any IDL application if desired.</dd>
</dl>

---
## hdf5_file__define.pro

<dl>
  <dt>Defines</dt>
  <dd>Object <code>HDF5_file</code></dd>
  <dt>Purpose</dt>
  <dd>This object encapsulates various I/O operations on HDF5 files.</dd>
  <dt>Example</dt>
  <dd><pre><code>HDF5_file = OBJ_NEW('HDF5_file') ; create file object
HDF5_file->Open, 'test.hdf5'     ; open file
HDF5_file->Close                 ; close file
OBJ_DESTROY, HDF5_file           ; destroy object
</code></pre></dd>
</dl>

---
## hdf5_file_example.pro

<dl>
  <dt>Defines</dt>
  <dd>PRO <code>HDF5_file_example</code></dd>
  <dt>Purpose</dt>
  <dd>Example IDL program to use the <code>HDF5_file</code> object.</dd>
</dl>

---
## hdf5_group__define.pro

<dl>
  <dt>Defines</dt>
  <dd>Object <code>HDF5_group</code></dd>
  <dt>Purpose</dt>
  <dd>This object encapsulates operations pertaining to a HDF5 group.</dd>
  <dt>Example</dt>
  <dd><pre><code>HDF5_group = OBJ_NEW('HDF5_group') ; create group object
HDF5_group->Open, loc_id, name    ; open group
                                  ; loc_id = ID of file
                                  ; name = name of group
HDF5_group->Close                 ; close file
OBJ_DESTROY, HDF5_group           ; destroy object
</code></pre></dd>
</dl>

---
## hdf5_lapd__define.pro

<dl>
  <dt>Defines</dt>
  <dd>Object <code>HDF5_lapd</code></dd>
  <dt>Purpose</dt>
  <dd>This object encapsulates various I/O operations on LaPD raw data/config files stored in HDF5 format.</dd>
  <dt>Example</dt>
  <dd><pre><code>HDF5_lapd = OBJ_NEW('HDF5_lapd') ; create file object
HDF5_lapd->Open, filename        ; open file
HDF5_lapd->Close                 ; close file
OBJ_DESTROY, HDF5_lapd           ; destroy object
</code></pre></dd>
</dl>

---
## hdf5_lapd_example.pro

<dl>
  <dt>Defines</dt>
  <dd>PRO <code>HDF5_LaPD_example</code></dd>
  <dt>Purpose</dt>
  <dd>Example IDL program to use the <code>HDF5_lapd</code> object.</dd>
</dl>

---
