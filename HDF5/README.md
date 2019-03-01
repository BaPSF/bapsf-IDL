# Files and their purpose:

<dl>
  <dt>hdf5_error__define.pro</dt>
  <dd>
    <dl>
      <dt>Defines</dt>
      <dd>Object `HDF5_error`</dd>
      <dt>Purpose</dt>
      <dd>This object manages error handling for any LaPD object. It is an internal object primarily but could be included in any IDL application if desired.</dd>
    </dl>
  </dd>

  <dt>hdf5_file__define.pro</dt>
  <dd>
    <dl>
      <dt>Defines</dt>
      <dd>Object `HDF5_file`</dd>
      <dt>Purpose</dt>
      <dd>This object encapsulates various I/O operations on HDF5 files.</dd>
      <dt>Example</dt>
      <dd><pre><code>HDF5_file = OBJ_NEW('HDF5_file') ; create file object
HDF5_file->Open, 'test.hdf5'     ; open file
HDF5_file->Close                 ; close file
OBJ_DESTROY, HDF5_file           ; destroy object
</code></pre></dd>
    </dl>
  </dd>
</dl>
