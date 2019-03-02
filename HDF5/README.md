# Files and their purpose:

Here is a brief description of each routine.  Examine the routine headers for detailed usage.

---

## hdf5_error__define.pro

<dl>
  <dt>Defines</dt>
  <dd>Object <code>HDF5_error</code></dd>
  <dt>Purpose</dt>
  <dd>This object manages error handling for any LaPD object. It is an internal object primarily but could be included in any IDL application if desired.</dd>
  <dt>Methods</dt>
  <dd><table>
    <tr><td><code>Get_status()</code></td>
      <td>get error properties</td></tr>
    <tr><td><code>Get_message()</code></td>
      <td>get error message</td></tr></td></tr>
    <tr><td><code>Get_call_stack()</code></td>
      <td>get error stack/traceback</td></tr>
    <tr><td><code>Handle_error, message</code></td>
      <td>handles the error (i.e. storing details, printing the message, and stopping)</td></tr>
  </table>
  </dd>
</dl>

---
## hdf5_file__define.pro

<dl>
  <dt>Defines</dt>
  <dd>Object <code>HDF5_file</code></dd>
  <dt>Purpose</dt>
  <dd>This object encapsulates various I/O operations on HDF5 files.</dd>
  <dt>Example</dt>
  <dd>
    <pre><code>HDF5_file = OBJ_NEW('HDF5_file') ; create file object
HDF5_file->Open, 'test.hdf5'     ; open file
...
HDF5_file->Close                 ; close file
OBJ_DESTROY, HDF5_file           ; destroy object
</code></pre>
  </dd>
  <dt>Methods</dt>
  <dd><table>
    <tr><td><code>Create_group(group_name)</code></td>
      <td>create and return group <code>group_name</code> under current group</td></tr></td></tr>
    <tr><td><code>Open_group(group_name)</code></td>
      <td>open and return sub-group <code>group_name</code> under current group</td></tr>
    <tr><td><code>Read_attribute(attr_name)</code></td>
      <td>read and return value for attribute <code>attr_name</code></td></tr>
    <tr><td><code>Read_dataset(dataset_name)</code></td>
      <td>read dataset <code>dataset_name</code></td></tr>
    <tr><td><code>Read_dataset_names()</code></td>
      <td>return names of datasets under current group</td></tr>
    <tr><td><code>Read_group_names()</code></td>
      <td>return names of sub-groups under current group</td></tr>
    <tr><td><code>Read_simple_float_dataset(dataset_name)</code></td>
      <td>read dataset <code>dataset_name</code> but return only the portion of <code>H5_PARSE</code> typecast as float</td></tr>
    <tr><td><code>Write_dataset, dataset_name, data</code></td>
      <td>write <code>data</code> to dataset <code>dataset_name</code></td></tr>

  </table>
  </dd>
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
  <dd>
    <pre><code>HDF5_group = OBJ_NEW('HDF5_group') ; create group object
HDF5_group->Open, loc_id, name    ; open group
                                  ; loc_id = ID of file
                                  ; name = name of group
...
HDF5_group->Close                 ; close file
OBJ_DESTROY, HDF5_group           ; destroy object
</code></pre>
  </dd>
  <dt>Methods</dt>
  <dd><table>
    <tr><td><code>Create_group(group_name)</code></td>
      <td>create and return group <code>group_name</code> under current group</td></tr></td></tr>
    <tr><td><code>DACS_LCWave_read_shot(channel, shotnumber)</code></td>
      <td>read time-series recorded by the LeCroy Wave-Series Scope digitizer</td></tr>
    <tr><td><code>DACS_NI7340_read_xy()</code></td>
      <td>return the xy values visited by the probe tip which was controlled by DACS v1.0 Module NI7340_XY</td></tr>
    <tr><td><code>Open_group(group_name)</code></td>
      <td>open and return sub-group <code>group_name</code> under current group</td></tr>
    <tr><td><code>Read_attribute(attr_name)</code></td>
      <td>read and return value for attribute <code>attr_name</code></td></tr>
    <tr><td><code>Read_dataset(dataset_name)</code></td>
      <td>read dataset <code>dataset_name</code></td></tr>
    <tr><td><code>Read_dataset_names()</code></td>
      <td>return names of datasets under current group</td></tr>
    <tr><td><code>Read_datasubset(dataset_name, datastart, datacount, datastride, REFORMLAG=reformlag)</code></td>
      <td>read a hyperslab/subset of dataset <code>dataset_name</code></td></tr>
    <tr><td><code>Read_group_names()</code></td>
      <td>return names of sub-groups under current group</td></tr>
    <tr><td><code>Read_object_names(type)</code></td>
      <td>get names of objects under current group of type <code>type</code></td></tr>
    <tr><td><code>Read_simple_float_dataset(dataset_name)</code></td>
      <td>read dataset <code>dataset_name</code> but return only the portion of <code>H5_PARSE</code> typecast as float</td></tr>
    <tr><td><code>Read_sis_shot(logical_channel, shotnumber, config_name)</code></td>
      <td>read time-series recorded by the SIS3301 digitizer and convert to voltage</td></tr>
    <tr><td><code>Read_sis3302_shot(board_number, channel_number, shotnumber, config_name=config_name, trange=trange, nshots=nshots, tstride=tstride, shotstride=shotstride)</code></td>
      <td>read time-series recorded by the SIS3302 digitizer and convert to voltage</td></tr>
    <tr><td><code>Read_sis3305_shot(board_number, channel_number, shotnumber, config_name=config_name, trange=trange, nshots=nshots, tstride=tstride, shotstride=shotstride)</code></td>
      <td>read time-series recorded by the SIS3305 digitizer and convert to voltage</td></tr>
    <tr><td><code>Read_tvs_shot(logical_channel, shotnumber)</code></td>
      <td>return time-series for shot number <code>shotnumber</code> for a logical channel <code>logical_channel</code> of the TVS645A digitizer</td></tr>
    <tr><td><code>Write_attribute, name, data</code></td>
      <td>write value <code>data</code> to attribute <code>name</code></td></tr>
    <tr><td><code>Write_dataset, dataset_name, data</code></td>
      <td>write <code>data</code> to dataset <code>dataset_name</code></td></tr>
    <tr><td><code>Write_Maya_color_table, color_table_name, color_table_data</code></td>
      <td>creates a custom color table dataset for use with the LaPD Maya visualization HDF file spec</td></tr>
  </table>
  </dd>
</dl>

---
## hdf5_lapd__define.pro

<dl>
  <dt>Defines</dt>
  <dd>Object <code>HDF5_lapd</code></dd>
  <dt>Purpose</dt>
  <dd>This object encapsulates various I/O operations on LaPD raw data/config files stored in HDF5 format.</dd>
  <dt>Example</dt>
  <dd>
    <pre><code>HDF5_lapd = OBJ_NEW('HDF5_lapd') ; create file object
HDF5_lapd->Open, filename        ; open file
...
HDF5_lapd->Close                 ; close file
OBJ_DESTROY, HDF5_lapd           ; destroy object
</code></pre>
  </dd>
  <dt>Methods</dt>
  <dd><table>
    <tr><td><code>Read_dataset(device_name, dataset_name)</code></td>
      <td>read dataset <code>dataset_name</code> under device <code>device_name</code> </td></tr>
    <tr><td><code>Read_dataset_names(device_name)</code></td>
      <td>returns array of dataset names for device <code>device_name</code></td></tr>
    <tr><td><code>Read_device_names()</code></td>
      <td>returns array of named device in the data run </td></tr>
  </table>
  </dd>
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
## hdf5_lapd_msi__define.pro

<dl>
  <dt>Defines</dt>
  <dd>Object <code>HDF5_LaPD_MSI</code></dd>
  <dt>Purpose</dt>
  <dd>This object encapsulates various operations on the LaPD Machine State Information (MSI) stored in HDF5 format.</dd>
  <dt>Example</dt>
  <dd>
    <pre><code>HDF5_LaPD_MSI = OBJ_NEW('HDF5_LaPD_MSI') ; create object
HDF5_LaPD_MSI->Open, filepath            ; open the LaPD HDF5 file
...
HDF5_LaPD_MSI->Close                     ; close file
OBJ_DESTROY, HDF5_LaPD_MSI               ; destroy object
</code></pre></dd>
  <dt>Methods</dt>
  <dd><table>
    <tr><td><code>Read_dataset(device_name, dataset_name)</code></td>
      <td>read dataset <code>dataset_name</code> under MSI device <code>device_name</code> </td></tr>
    <tr><td><code>Read_dataset_names(device_name)</code></td>
      <td>returns array of dataset names for MSI device <code>device_name</code></td></tr>
    <tr><td><code>Read_system_names()</code></td>
      <td>returns array of MSI device names</td></tr>
  </table>
  </dd>
</dl>

---
## lapd_6k_configuration.pro

<dl>
  <dt>Defines</dt>
  <dd>FUNC <code>LAPD_6K_CONFIGURATION(input_file, RECEPT_NUMBER=recept_number, RT_INDEX=rt_index)</code></dd>
  <dt>Purpose</dt>
  <dd>Returns an IDL structure containing the parsed information in the '6k Compumotor' group of an LAPD HDF5 file.
  <dd>
</dl>

---
## lapd_extract_msi.pro

<dl>
  <dt>Defines</dt>
  <dd>n/a</dd>
  <dt>Purpose</dt>
  <dd>Script to read, print, and plot all recorded MSI data.
  <dd>
</dl>

---
## lapd_n5700_configuration.pro

<dl>
  <dt>Defines</dt>
  <dd>FUNC <code>lapd_n5700_configuration(input_file)</code></dd>
  <dt>Purpose</dt>
  <dd>Returns an IDL structure containing the parsed information in the 'N5700_PS' Agilent programmable power supply configuration group of an LAPD HDF5 file.
  <dd>
</dl>

---
