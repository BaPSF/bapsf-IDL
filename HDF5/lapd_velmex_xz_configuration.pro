FUNCTION lapd_velmex_xz_configuration,input_file
COMPILE_OPT IDL2
;
;Returns an IDL structure containing the parsed information
;in the 'Velmex XZ' device group of an LAPD HDF5 file.
;
;Written by Steve Vincena, 2014-07-01
;
;based on lapd_6k_configuration.pro
;
;Modification history:
;
;
;------------assign default geometry--------------
nx = ulong(1) & ny = ulong(1) & nz = ulong(1)
nwrites = ulong(1)
geometry='point'
xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz)
xval = float(0.) & yval = float(0.) & zval = float(0.)
xz = fltarr(2,nx,nz)
xyz = fltarr(3,nx,ny,nz)
xar=fltarr(nx,nz) & yar=fltarr(nx,nz) & zar=fltarr(nx,nz)
mlist = {x:float(0.),y:float(0.),z:float(0.),nwrites:float(1)}
;z_unique = float([0.])
p_unique = ["Unknown"]
;-------------------------------------------------

; Open HDF5 file.
IF (input_file EQ '') THEN BEGIN
 input_file=''
 input_file=dialog_pickfile()
ENDIF
IF (input_file EQ '') THEN BEGIN
 out_message='LAPD_VELMEX_XZ_CONFIGURATION: Error associated with input file'
 GOTO,CLEANUP
ENDIF

; Create the object.
HDF5_file = OBJ_NEW('HDF5_file')
IF (FILE_TEST(input_file) EQ 1) THEN BEGIN
     print,'-------------------------------------------------'
     print, 'Opening: ', input_file
     HDF5_file.Open, input_file
ENDIF

;--Determine LaPD Software version---

sw_version = HDF5_file.Read_attribute('LaPD HDF5 software version')
print,'LaPD HDF5 software version='+sw_version



;------Attempt to open raw data and configuration group------------------
;If this isn't here, there is something seriously wrong
rac_group = HDF5_file.Open_group('Raw data + config')
rac_subgroup_names = rac_group.Read_group_names()
OBJ_DESTROY,rac_group
;-------------------------------------------------
;-------------process 6K Compumotor if it exists-------------------
velmex_group_test = WHERE(rac_subgroup_names EQ 'Velmex_XZ')
IF (velmex_group_test[0] NE -1) THEN BEGIN

 velmex_group_name='/Raw data + config/Velmex_XZ'

 velmex_group=HDF5_file.Open_group(velmex_group_name) 
 configuration_subgroup_names=velmex_group.Read_group_names()
 velmex_dataset_names=velmex_group.Read_dataset_names()
 print,'Velmex_XZ dataset names:'
 PM,velmex_dataset_names

 ;-------------process Velmex_XZ runtime list ----------
 ;Open Runtime list of positions and angles at every shot number
 ;If there is a Velmex_XZ group, there must be a 'Run time list.' No error check here

CASE sw_version OF
  '1.1': BEGIN
         velmex_rtl_dataset = HDF5_file.Read_dataset(velmex_group_name+'/Run time list')
         END
;With the introduction of the real-time-translator (sw_version 1.2),
;each probe gets its own dataset of probe motions.
; For now (10/22/2012) just grab the first one and re-use version 1.1 code
  ELSE: BEGIN ;assume version 1.2 or compatible
         velmex_rtl_dataset = velmex_group.Read_dataset(velmex_dataset_names[0])
         END
ENDCASE


velmex_shot_number = reform(ulong64(velmex_rtl_dataset._DATA.SHOT_NUMBER))
velmex_configuration_list = reform(velmex_rtl_dataset._DATA.CONFIGURATION_NAME)
velmex_command_index = reform(velmex_rtl_dataset._DATA.COMMAND_INDEX)
velmex_xlist = reform(float(velmex_rtl_dataset._DATA.X))
velmex_zlist = reform(float(velmex_rtl_dataset._DATA.Z))
velmex_zlist_lapd = reform(float(velmex_rtl_dataset._DATA.Z_LAPD))
velmex_philist = reform(float(velmex_rtl_dataset._DATA.TIP_PHI_WRT_B0))



 configuration_names=(configuration_subgroup_names)
 n_configurations = n_elements(configuration_names)
 if (n_elements(configurations) lt 0) then begin
  print,'Velmex_XZ group exists, but no configurations found.'
  goto,no_configurations
 endif


 print,'Velmex_XZ configurations in this datarun:'
 for i_config = 0L, n_configurations-1 do begin
  print,configuration_names[i_config]
 endfor

 print,'Choosing first configuration'
 configuration = configuration_names[0]
 config_group  = velmex_group.Open_group(configuration)


 nx=ulong64(config_group.Read_attribute('nx'))
 nz=ulong64(config_group.Read_attribute('nz'))

 dx = float(config_group.Read_attribute('dx_cm'))
 dz = float(config_group.Read_attribute('dz_cm'))

 x0 = float(config_group.Read_attribute('x_geometry_center'))
 z0 = float(config_group.Read_attribute('z_geometry_center'))

 lapd_port = float(config_group.Read_attribute('LAPD Port number'))

 x0_lapd = float(config_group.Read_attribute('x_scale_LAPD_center'))
 z0_lapd = float(config_group.Read_attribute('z_scale_at_LAPD_center')) ;yes, a goof

;These are the desired (configured) values. the reported values are in the 'Run time list' dataset
;They should be the same apart from << 1mm changes, but as of 2014-07-01, they can be larger!
 xc_list = float(config_group.Read_attribute('Velmex_XZ_x_list'))
 zc_list = float(config_group.Read_attribute('Velmex_XZ_z list')) ;another goof

 nxnz = nx*nz
 nwrites = n_elements(velmex_xlist)/nxnz;/n_probes
 ntot = nxnz * nwrites
 
;Note, we only account for the xz plane case as of 2014-07-01
 geometry='Unknown'
 IF ( (nz GT 1) AND (nx GT 1) ) THEN geometry='xz-plane'
 IF ( (nz EQ 1) AND (nx GT 1) ) THEN geometry='x-line'
 IF ( (nz GT 1) AND (nx EQ 1) ) THEN geometry='z-line'
 IF ( (nz EQ 1) AND (nx EQ 1) ) THEN geometry='point'


 print,'XZ Geometry for this configuration: '+ '"'+geometry+'"'


CASE geometry OF

 'xz-plane': BEGIN
          ;these are CONFIGURED values
          xar = reform(xc_list,nx,nz)
          xvec   = reform(xar[*,0])
          xvals  = xvec
          zar = reform(zc_list,nx,nz)
          zvec   = reform(zar[0,*])
          zvals  = zvec
          ;phiar = fltarr(nx,nz); this isn't configurable by itself, so not part of the config.
          ;there wouldn't be a vector for phi


          xz = fltarr(2,nx,nz)
          xz[0,*,*] = xar[*,*]
          xz[1,*,*] = zar[*,*]

          xyz = fltarr(3,nx,nz,1) ; for AVS or programs using computational space 0=fastest,1=next
          xyz[0,*,*,0] = xar[*,*]
          xyz[1,*,*,0] = zar[*,*]
          xyz[2,*,*,0] = 0.0

          mlist = CREATE_STRUCT('configuration',configuration,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',dx,'dz',dz,'x0',x0,'z0',z0,$
          'x_list',velmex_xlist,'z_list',velmex_zlist,'phi_list',velmex_philist,$
          'z_list_lapd',velmex_zlist_lapd,'shotnum_list',velmex_shot_number,$
          'config_list',velmex_configuration_list,'com_index_list',velmex_command_index,$
          'xar',xar,'zar',zar,$
          'xvec',xvec,'xvals',xvals,'zvec',zvec,'zvals',zvals,$
          'xz',xz,'xyz',xyz,'lapd_port',lapd_port)

          END

; 'point': BEGIN x=velmex_xlist[0] y=velmex_ylist[0] z=velmex_zlist[0] theta=velmex_thetalist[0]
;          phi=velmex_philist[0]

;          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
;          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
;          'xlist',velmex_xlist,'ylist',velmex_ylist,'zlist',velmex_zlist,$
;          'thetalist',velmex_thetalist,'philist',velmex_philist,$
;          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,'z_unique',z_unique,'p_unique',p_unique)
;          END

 'x-line': BEGIN
          ;these are CONFIGURED values
          xvec   = xc_list
          xvals  = xvec
          zvec   = zc_list
          zvals  = zvec
          ;phiar = fltarr(nx,nz); this isn't configurable by itself, so not part of the config.
          ;there wouldn't be a vector for phi


          mlist = CREATE_STRUCT('configuration',configuration,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',dx,'dz',dz,'x0',x0,'z0',z0,$
          'x_list',velmex_xlist,'z_list',velmex_zlist,'phi_list',velmex_philist,$
          'z_list_lapd',velmex_zlist_lapd,'shotnum_list',velmex_shot_number,$
          'config_list',velmex_configuration_list,'com_index_list',velmex_command_index,$
          'xvec',xvec,'xvals',xvals,'zvec',zvec,'zvals',zvals,$
          'lapd_port',lapd_port)

          END
;
; 'y-line': BEGIN
;          print,'Y-lines not processed correctly yet'
;          xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz)
;          thetavec = fltarr(ny) & phivec = fltarr(ny)
;          xval = float(0.) & yval = float(0.) & zval = float(0.)
;          xy = fltarr(2,nx,ny)
;          xyz = fltarr(3,nx,ny,nz)
;          xar=fltarr(nx,ny) & yar=fltarr(nx,ny) & zar=fltarr(nx,ny)
;
;          temp=reform(velmex_xlist,nwrites,ny)
;          y   = reform(temp[0,*])
;          yvec = y
;
;          temp=reform(velmex_xlist,nwrites,ny)
;          x   = reform(temp[0,*])
;          temp=reform(velmex_zlist,nwrites,ny)
;          z   = reform(temp[0,*])
;          temp=reform(velmex_thetalist,nwrites,ny)
;          theta   = reform(temp[0,*])
;          temp=reform(velmex_philist,nwrites,ny)
;          phi   = reform(temp[0,*])
;
;          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
;          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
;          'xlist',velmex_xlist,'ylist',velmex_ylist,'zlist',velmex_zlist,$
;          'thetalist',velmex_thetalist,'philist',velmex_philist,$
;          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,$
;          'yvec',yvec,'z_unique',z_unique,'p_unique',p_unique)
;          END
;
 

 ELSE: PRINT,'Unknown error'

ENDCASE


 
 OBJ_DESTROY,config_group


 no_configurations:
 print,'Nx=',nx
 print,'Nz=',nz

 print,'-------------------------------------------------'
 OBJ_DESTROY,velmex_group
ENDIF ELSE BEGIN ;end there was a 6K group

print,'No velmex_xz configuration for this file'
print,'Asigning "point" geometry'
print,'Warning: unable to determine number of writes without a motion list.'
print,'Setting nwrites=1'
          nwrites=ulong64(1)
          configuration='NONE'
          geometry='point'
          x=float(0.) & dx = float(0.)
          z=float(0.) & dz = float(0.)
          x0 = float(0.) & ml_x0 = float(0.)
          phi=float(0.)
          nx = ulong64(1) & ny = ulong64(1) & nz = ulong64(1)

          mlist = CREATE_STRUCT('configuration',configuration,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',dx,'dz',dz,'z0',x0,'z0',z0,$
          'x',x,'z',z,'phi',phi)
ENDELSE

OBJ_DESTROY, HDF5_file

out_message='Done.'
CLEANUP:
print,out_message
RETURN,mlist

END
