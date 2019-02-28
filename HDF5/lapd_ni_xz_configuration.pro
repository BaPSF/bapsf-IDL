FUNCTION LAPD_NI_XZ_CONFIGURATION,input_file
COMPILE_OPT IDL2
;
;Returns an IDL structure containing the parsed information
;in the 'NI_XZ' group of an LAPD HDF5 file.
;
;Copied from LAPD_6K_CONFIGURATION and modified for NI_XZ on Feb 3, 2017
;by Steve Vincena
;
;Limitations:
;Assumes the runtime list contains only one Configuration Name
;
;Modification history:
;
;------------assign default geometry--------------
nx = ulong(1) & ny = ulong(1) & nz = ulong(1)
nr = nx
ntheta = nz
nwrites = ulong(1)
geometry='point'
xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz)
rvec = fltarr(nr)
thetavec = fltarr(ntheta)
xval = float(0.) & yval = float(0.) & zval = float(0.)
rval = float(0.) & thetaval = float(0.)
xz = fltarr(2,nx,nz)
rtheta = fltarr(2,nx,nz)
xyz = fltarr(3,nx,ny,nz)

xar=fltarr(nx,nz) & yar=fltarr(nx,nz) & zar=fltarr(nx,nz)
rar=fltarr(nr,ntheta) & thetaarr=fltarr(nr,ntheta)
mlist = {x:float(0.),y:float(0.),z:float(0.),nwrites:float(1),r:float(0.),theta:float(0.)}
;z_unique = float([0.])
;p_unique = ["Unknown"]
;-------------------------------------------------

; Open HDF5 file.
IF (input_file EQ '') THEN BEGIN
 input_file=''
 input_file=dialog_pickfile()
ENDIF
IF (input_file EQ '') THEN BEGIN
 out_message='Error associated with input file'
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
rac_group = HDF5_file.Open_group('Raw data + config')
rac_subgroup_names = rac_group.Read_group_names()
OBJ_DESTROY,rac_group
;-------------------------------------------------
;-------------process NI_XZ if it exists-------------------
motion_group_test = WHERE(rac_subgroup_names EQ 'NI_XZ')
IF (motion_group_test[0] NE -1) THEN BEGIN

 motion_group_name='/Raw data + config/NI_XZ'

 motion_group=HDF5_file.Open_group(motion_group_name) 
 motion_subgroup_names=motion_group.Read_group_names()
 motion_dataset_names=motion_group.Read_dataset_names()
 print,'Motion dataset names:'
 PM,motion_dataset_names

 ;-------------process NI_XZ runtime list ----------
 ;Open Runtime list of positions and angles at every shot number
 ;If there is a NI_XZ group, there must be a Runtime List. No error check here

CASE sw_version OF
  '1.2': BEGIN
         motion_rtl_dataset = HDF5_file.Read_dataset(motion_group_name+'/Run time list')
         END
;the NI_XZ drive was introduced starting with version 1.2 of the HDF5 file
;With the introduction of the real-time-translator (sw_version 1.2),
  ELSE: BEGIN ;assume version 1.2 or compatible
;          IF (KEYWORD_SET(rt_index)) THEN BEGIN
;            motion_rtl_dataset = motion_group.Read_dataset(motion_dataset_names[rt_index])
;            print,'Specific dataset list index item requested for 6K runtime lists'
;            print,'Requested list corresponds to ',motion_dataset_names[rt_index]
;           recept_string=strcompress(string(long(recept_number),/remove_all)
;           print,'Receptacle '
;          ENDIF ELSE BEGIN
            motion_rtl_dataset = motion_group.Read_dataset(motion_dataset_names[0])
;          ENDELSE
        END
ENDCASE


xz_motion_shot_number = reform(ulong64(motion_rtl_dataset._DATA.SHOT_NUMBER))
xz_motion_xlist = reform(float(motion_rtl_dataset._DATA.X))
;xy_motion_ylist = reform(float(motion_rtl_dataset._DATA.Y))
xz_motion_rlist = reform(float(motion_rtl_dataset._DATA.R))
xz_motion_zlist = reform(float(motion_rtl_dataset._DATA.Z))
xz_motion_thetalist = reform(float(motion_rtl_dataset._DATA.THETA))
xz_motion_motion_index = reform(float(motion_rtl_dataset._DATA.MOTION_INDEX))
;xy_motion_philist = reform(float(motion_rtl_dataset._DATA.PHI))
;xy_motion_probe_name = reform(motion_rtl_dataset._DATA.PROBE_NAME)
;xy_motion_motion_list = reform(motion_rtl_dataset._DATA.CONFIGURATION_NAME)

;n_motion_lists=n_elements(uniq(xy_motion_motion_list,sort(xy_motion_motion_list)))
;n_probes=n_elements(uniq(xy_motion_probe_name,sort(xy_motion_probe_name)))

;z_unique = fltarr(n_probes)
;p_unique = strarr(n_probes)
;FOR i=0,n_probes-1 DO BEGIN
;  z_unique[i] = xy_motion_zlist[i]
;  p_unique[i] = xy_motion_probe_name[i]
;ENDFOR

;IF (n_probes GT 1) THEN BEGIN
;  PRINT,'Warning in --- lapd_process_xy_motion_list.pro ----'
;  PRINT,'More than one probe found. Program will assume that all probes are moving on the same grid!'
;  PRINT,'In the position arrays, the z location will be fixed to the first probe position listed.'
;  PRINT,'The tag "z_unique" in the motion list structure will contain the unique z locations'
;  PRINT,'The tag "p_unique" in the motion list structure will contain the corresponding probe names'
;  FOR i=0,n_probes-1 do begin
;    PRINT,strcompress('z location of probe, '+p_unique[i] +' is '+string(z_unique[i])+ ' cm')
;  ENDFOR
;Clense inputs
;n_probes = 1
;one_probe_indices = WHERE(xy_motion_probe_name EQ xy_motion_probe_name[0])
;xy_motion_shot_number = xy_motion_shot_number[one_probe_indices]
;xy_motion_xlist = xy_motion_xlist[one_probe_indices]
;xy_motion_ylist = xy_motion_ylist[one_probe_indices]
;xy_motion_zlist = xy_motion_zlist[one_probe_indices]
;xy_motion_thetalist = xy_motion_thetalist[one_probe_indices]
;xy_motion_philist = xy_motion_philist[one_probe_indices]
;xy_motion_probe_name =xy_motion_probe_name[one_probe_indices]
;xy_motion_motion_list = xy_motion_motion_list[one_probe_indices]



;;;;ENDIF

;IF ( (n_motion_lists GT 1) OR (n_probes GT 1) ) THEN BEGIN
; PRINT,'Warning: this program cannot properly parse coordinate information when a datarun has multiple motion lists or multiple probes moving with the same motion list.'
; PRINT,'...'
; PRINT,'Dividing the apparent number of writes by the number of motion lists in the hopes that this will solve the problem.'
;ENDIF
;
 ;-------------done with runtime list ------------



; motion_list_indexes=where(strmid(motion_subgroup_names,0,12) eq 'Motion list:')
; if (motion_list_indexes[0] eq -1) then begin
;  print,'6K Compumotor group exists, but no motion lists found.'
;  goto,no_motion_lists
; endif else begin
;  n_motion_lists = n_elements(motion_list_indexes)
  ;motion_list_names=motion_subgroup_names[motion_list_indexes]
  motion_list_names=motion_subgroup_names
; endelse

; probe_group_indexes=where(strmid(motion_subgroup_names,0,6) eq 'Probe:')

; if (probe_group_indexes[0] eq -1) then begin
;  print,'No probes found in this dataset'
;  n_probes=1
;  goto,no_motion_lists
; endif else begin
;  n_probes = n_elements(probe_group_indexes)
;  probe_names=motion_subgroup_names[probe_group_indexes]
;  print,'--------------'
;  print,strcompress(string(n_probes)+' probes found')
;  print,'Probes listed in this datarun:'
;  for i_probe = 0L, n_probes-1 do begin
;   print,probe_names[i_probe]
;  endfor
;  print,'--------------'
; endelse

; print,'Motion lists in this datarun:'
; for i_motion_list = 0L, n_motion_lists-1 do begin
;  print,motion_list_names[i_motion_list]
; endfor

 print,'Choosing first motion list'
 motion_list = motion_list_names[0]
 motion_list_group = motion_group.Open_group(motion_list)


 nx=ulong(motion_list_group.Read_attribute('Nx'))
 nz=ulong(motion_list_group.Read_attribute('Nz'))
 nr = nx
 ntheta = nz

 ml_dx = float(motion_list_group.Read_attribute('dx'))
 ml_dz = float(motion_list_group.Read_attribute('dz'))

 ml_x0 = float(motion_list_group.Read_attribute('x0'))
 ml_z0 = float(motion_list_group.Read_attribute('z0'))
 ml_z_port = float(motion_list_group.Read_attribute('z_port'))

 ml_fan_xz = string(motion_list_group.Read_attribute('fan_XZ'))
 if (ml_fan_xz EQ "FALSE") THEN ml_fan = 1 ELSE ml_fan=0

 nxnz = nx*nz
 nwrites = n_elements(xz_motion_xlist)/nxnz;/n_probes
 ntot = nxnz * nwrites
 
 geometry='Unknown'
 IF ( (nz GT 1) AND (nx GT 1) ) THEN geometry='xz-plane'
 IF ( (nz EQ 1) AND (nx GT 1) ) THEN geometry='x-line'
 IF ( (nz GT 1) AND (nx EQ 1) ) THEN geometry='z-line'
 IF ( (nz EQ 1) AND (nx EQ 1) ) THEN geometry='point'
 IF ((ml_fan eq 1) AND (geometry EQ 'xz-plane')) THEN geometry='rtheta-plane'


 print,'XZ Geometry for this motion list: '+ '"'+geometry+'"'


CASE geometry OF

 'xz-plane': BEGIN
          ny=1
;          xz_motion_zlist += lapd_port_to_z(ml_z_port)
          temp=reform(xz_motion_xlist,nwrites,nx,nz)
          xar = reform(temp[0,*,*])
          x   = reform(xar,nxnz)
          temp=reform(xz_motion_zlist,nwrites,nx,nz)
          zar = reform(temp[0,*,*])
          z   = reform(zar,nxnz)
          temp=reform(xz_motion_rlist,nwrites,nx,nz)
          rar = reform(temp[0,*,*])
          r   = reform(rar,nxnz)
          temp=reform(xz_motion_thetalist,nwrites,nx,nz)
          thetaar = reform(temp[0,*,*])
          theta   = reform(thetaar,nxnz)

          xvec = reform(xar[*,0])
          zvec = reform(zar[0,*])
          yvec = [0.]
          rvec = reform(rar[*,0])
          thetavec = reform(thetaar[0,*])

          xz = fltarr(2,nx,nz)
          xz[0,*,*] = xar[*,*]
          xz[1,*,*] = zar[*,*]

          rtheta = fltarr(2,nx,nz)
          rtheta[0,*,*] = rar[*,*]
          rtheta[1,*,*] = thetaar[*,*]

          y=0.

          xyz = fltarr(3,nx,nz,1)
          xyz[0,*,*,0] = xar[*,*]
          xyz[2,*,*,0] = zar[*,*]
          xyz[1,*,*,0] = y

          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',ml_dx,'dz',ml_dz,'x0',ml_x0,'z0',ml_z0,$
          'xlist',xz_motion_xlist,'zlist',xz_motion_zlist,$
          'thetalist',xz_motion_thetalist,$
          'x',x,'y',y,'z',z,'r',r,'theta',theta,$
          'xar',xar,'zar',zar,'rar',r,'thetaar',thetaar,$
          'xvec',xvec,'zvec',zvec,'rvec',rvec,'thetavec',thetavec,$
          'xz',xz,'xyz',xyz)

          END

 'point': BEGIN
          x=xz_motion_xlist[0]
          y=float(0)
          z=xz_motion_zlist[0]
          theta=xz_motion_thetalist[0]
          r=xz_motion_rlist[0]

          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',ml_dx,'dz',ml_dz,'x0',ml_x0,'z0',ml_z0,'z_port',ml_zport,$$
          'xlist',xz_motion_xlist,'zlist',xz_motion_zlist,$
          'rlist',xz_motion_rlist,'thetalist',xz_motion_thetalist,$
          'x',x,'y',y,'z',z,'r',r,'theta',theta)
          END

; 'x-line': BEGIN
;          xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz)
;          thetavec = fltarr(nx) & phiarr = fltarr(nx)
;          xval = float(0.) & yval = float(0.) & zval = float(0.)
;          xy = fltarr(2,nx,ny)
;          xyz = fltarr(3,nx,ny,nz)
;          xar=fltarr(nx,ny) & yar=fltarr(nx,ny) & zar=fltarr(nx,ny)
;
;          temp=reform(xy_motion_xlist,nwrites,nx)
;          x   = reform(temp[0,*])
;          xvec = x

;          temp=reform(xy_motion_ylist,nwrites,nx)
;          y   = reform(temp[0,*])
;          temp=reform(xy_motion_zlist,nwrites,nx)
;          z   = reform(temp[0,*])
;          temp=reform(xy_motion_thetalist,nwrites,nx)
;          theta   = reform(temp[0,*])
;          temp=reform(xy_motion_philist,nwrites,nx)
;          phi   = reform(temp[0,*])
;
;          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
;          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
;          'xlist',xy_motion_xlist,'ylist',xy_motion_ylist,'zlist',xy_motion_zlist,$
;          'thetalist',xy_motion_thetalist,'philist',xy_motion_philist,$
;          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,$
;          'xvec',xvec,'z_unique',z_unique,'p_unique',p_unique)


;          END

; 'y-line': BEGIN
;          print,'Y-lines not processed correctly yet'
;          xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz)
;          thetavec = fltarr(ny) & phivec = fltarr(ny)
;          xval = float(0.) & yval = float(0.) & zval = float(0.)
;          xy = fltarr(2,nx,ny)
;          xyz = fltarr(3,nx,ny,nz)
;          xar=fltarr(nx,ny) & yar=fltarr(nx,ny) & zar=fltarr(nx,ny)

;          temp=reform(xy_motion_xlist,nwrites,ny)
;          y   = reform(temp[0,*])
;          yvec = y

;          temp=reform(xy_motion_xlist,nwrites,ny)
;          x   = reform(temp[0,*])
;          temp=reform(xy_motion_zlist,nwrites,ny)
;          z   = reform(temp[0,*])
;          temp=reform(xy_motion_thetalist,nwrites,ny)
;          theta   = reform(temp[0,*])
;          temp=reform(xy_motion_philist,nwrites,ny)
;          phi   = reform(temp[0,*])
;
;          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
;          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
;          'xlist',xy_motion_xlist,'ylist',xy_motion_ylist,'zlist',xy_motion_zlist,$
;          'thetalist',xy_motion_thetalist,'philist',xy_motion_philist,$
;          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,$
;          'yvec',yvec,'z_unique',z_unique,'p_unique',p_unique)
;          END

 

 ELSE: PRINT,'Unknown error'

ENDCASE


 
 OBJ_DESTROY,motion_list_group


 no_motion_lists:
 print,'Nx=',nx
 print,'Nz=',nz

 print,'-------------------------------------------------'
 OBJ_DESTROY,motion_group
ENDIF ELSE BEGIN ;end there was an NI_XZ group

print,'No motion list for this file'
print,'Asigning "point" geometry'
print,'Warning: unable to determine number of writes without a motion list.'
print,'Setting nwrites=1'
          nwrites=ulong(1)
          motion_list='NONE'
          geometry='point'
          x=float(0.) & ml_dx = float(0.)
          y=float(0.) & ml_dy = float(0.)
          z=float(0.) & ml_dz = float(0.)
          ml_x0 = float(0.) & ml_y0 = float(0.)
          theta=float(0.)
          phi=float(0.)
          nx = ulong(1) & ny = ulong(1) & nz = ulong(1)

          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',ml_dx,'dy',ml_dz,'x0',ml_x0,'z0',ml_z0,$
          'x',x,'y',y,'z',z,'r',r,'theta',theta)
ENDELSE

OBJ_DESTROY, HDF5_file

out_message='Done.'
CLEANUP:
print,out_message
RETURN,mlist

END
