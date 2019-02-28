FUNCTION LAPD_6K_CONFIGURATION,input_file,$
RECEPT_NUMBER=recept_number,RT_INDEX=rt_index
COMPILE_OPT IDL2
;
;Returns an IDL structure containing the parsed information
;in the '6k Compumotor' group of an LAPD HDF5 file.
;
;Written by Steve Vincena, 7/23/2007
;
;Modification history:
;9/1/2010 STV Updated to handle multiple probes using the same motion list
;8/28/2015 STV added quick fix to grab motion runtime list for a particular probe but just based on index of the dataset order.
;
;
;------------assign default geometry--------------
nx = ulong(1) & ny = ulong(1) & nz = ulong(1)
nwrites = ulong(1)
geometry='point'
xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz)
xval = float(0.) & yval = float(0.) & zval = float(0.)
xy = fltarr(2,nx,ny)
xyz = fltarr(3,nx,ny,nz)
xar=fltarr(nx,ny) & yar=fltarr(nx,ny) & zar=fltarr(nx,ny)
mlist = {x:float(0.),y:float(0.),z:float(0.),nwrites:float(1)}
z_unique = float([0.])
p_unique = ["Unknown"]
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
     HDF5_file->Open, input_file
ENDIF

;--Determine LaPD Software version---

sw_version = HDF5_file.Read_attribute('LaPD HDF5 software version')
print,'LaPD HDF5 software version='+sw_version



;------Attempt to open raw data and configuration group------------------
rac_group = HDF5_file.Open_group('Raw data + config')
rac_subgroup_names = rac_group.Read_group_names()
OBJ_DESTROY,rac_group
;-------------------------------------------------
;-------------process 6K Compumotor if it exists-------------------
motion_group_test = WHERE(rac_subgroup_names EQ '6K Compumotor')
IF (motion_group_test[0] NE -1) THEN BEGIN

 motion_group_name='/Raw data + config/6K Compumotor'

 motion_group=HDF5_file.Open_group(motion_group_name) 
 motion_subgroup_names=motion_group.Read_group_names()
 motion_dataset_names=motion_group.Read_dataset_names()
 print,'Motion dataset names:'
 PM,motion_dataset_names

 ;-------------process 6K runtime list ----------
 ;Open Runtime list of positions and angles at every shot number
 ;If there is a 6K group, there must be a Runtime List. No error check here

CASE sw_version OF
  '1.1': BEGIN
         motion_rtl_dataset = HDF5_file.Read_dataset(motion_group_name+'/Run time list')
         END
;With the introduction of the real-time-translator (sw_version 1.2),
;each probe gets its own dataset of probe motions.
; For now (10/22/2012) just grab the first one and re-use version 1.1 code
  ELSE: BEGIN ;assume version 1.2 or compatible
;; There is a future need to select motion lists for different receptacles. This is a start of that, but needs to be completed. For now, address via index into the order of the datasets, not the probe drive receptacles--assumes you know how to pick out the right one!
;          IF (KEYWORD_SET(recept_number)) THEN BEGIN
          IF (KEYWORD_SET(rt_index)) THEN BEGIN
            motion_rtl_dataset = motion_group.Read_dataset(motion_dataset_names[rt_index])
            print,'Specific dataset list index item requested for 6K runtime lists'
            print,'Requested list corresponds to ',motion_dataset_names[rt_index]
;           recept_string=strcompress(string(long(recept_number),/remove_all)
;           print,'Receptacle '
          ENDIF ELSE BEGIN
            motion_rtl_dataset = motion_group.Read_dataset(motion_dataset_names[0])
          ENDELSE
        END
ENDCASE


xy_motion_shot_number = reform(ulong64(motion_rtl_dataset._DATA.SHOT_NUMBER))
xy_motion_xlist = reform(float(motion_rtl_dataset._DATA.X))
xy_motion_ylist = reform(float(motion_rtl_dataset._DATA.Y))
xy_motion_zlist = reform(float(motion_rtl_dataset._DATA.Z))
xy_motion_thetalist = reform(float(motion_rtl_dataset._DATA.THETA))
xy_motion_philist = reform(float(motion_rtl_dataset._DATA.PHI))
xy_motion_probe_name = reform(motion_rtl_dataset._DATA.PROBE_NAME)
xy_motion_motion_list = reform(motion_rtl_dataset._DATA.MOTION_LIST)

n_motion_lists=n_elements(uniq(xy_motion_motion_list,sort(xy_motion_motion_list)))
n_probes=n_elements(uniq(xy_motion_probe_name,sort(xy_motion_probe_name)))

z_unique = fltarr(n_probes)
p_unique = strarr(n_probes)
FOR i=0,n_probes-1 DO BEGIN
  z_unique[i] = xy_motion_zlist[i]
  p_unique[i] = xy_motion_probe_name[i]
ENDFOR

IF (n_probes GT 1) THEN BEGIN
  PRINT,'Warning in --- lapd_process_xy_motion_list.pro ----'
  PRINT,'More than one probe found. Program will assume that all probes are moving on the same grid!'
  PRINT,'In the position arrays, the z location will be fixed to the first probe position listed.'
  PRINT,'The tag "z_unique" in the motion list structure will contain the unique z locations'
  PRINT,'The tag "p_unique" in the motion list structure will contain the corresponding probe names'
  FOR i=0,n_probes-1 do begin
    PRINT,strcompress('z location of probe, '+p_unique[i] +' is '+string(z_unique[i])+ ' cm')
  ENDFOR
;Clense inputs
n_probes = 1
one_probe_indices = WHERE(xy_motion_probe_name EQ xy_motion_probe_name[0])
xy_motion_shot_number = xy_motion_shot_number[one_probe_indices]
xy_motion_xlist = xy_motion_xlist[one_probe_indices]
xy_motion_ylist = xy_motion_ylist[one_probe_indices]
xy_motion_zlist = xy_motion_zlist[one_probe_indices]
xy_motion_thetalist = xy_motion_thetalist[one_probe_indices]
xy_motion_philist = xy_motion_philist[one_probe_indices]
xy_motion_probe_name =xy_motion_probe_name[one_probe_indices]
xy_motion_motion_list = xy_motion_motion_list[one_probe_indices]



ENDIF

IF ( (n_motion_lists GT 1) OR (n_probes GT 1) ) THEN BEGIN
 PRINT,'Warning: this program cannot properly parse coordinate information when a datarun has multiple motion lists or multiple probes moving with the same motion list.'
 PRINT,'...'
 PRINT,'Dividing the apparent number of writes by the number of motion lists in the hopes that this will solve the problem.'
ENDIF

 ;-------------done with runtime list ------------



 motion_list_indexes=where(strmid(motion_subgroup_names,0,12) eq 'Motion list:')
 if (motion_list_indexes[0] eq -1) then begin
  print,'6K Compumotor group exists, but no motion lists found.'
  goto,no_motion_lists
 endif else begin
  n_motion_lists = n_elements(motion_list_indexes)
  motion_list_names=motion_subgroup_names[motion_list_indexes]
 endelse

 probe_group_indexes=where(strmid(motion_subgroup_names,0,6) eq 'Probe:')

 if (probe_group_indexes[0] eq -1) then begin
  print,'No probes found in this dataset'
  n_probes=1
  goto,no_motion_lists
 endif else begin
  n_probes = n_elements(probe_group_indexes)
  probe_names=motion_subgroup_names[probe_group_indexes]
  print,'--------------'
  print,strcompress(string(n_probes)+' probes found')
  print,'Probes listed in this datarun:'
  for i_probe = 0L, n_probes-1 do begin
   print,probe_names[i_probe]
  endfor
  print,'--------------'
 endelse

 print,'Motion lists in this datarun:'
 for i_motion_list = 0L, n_motion_lists-1 do begin
  print,motion_list_names[i_motion_list]
 endfor

 print,'Choosing first motion list'
 motion_list = motion_list_names[0]
 motion_list_group = motion_group->Open_group(motion_list)


 nx=ulong(motion_list_group->Read_attribute('Nx'))
 ny=ulong(motion_list_group->Read_attribute('Ny'))

 ml_dx = float(motion_list_group->Read_attribute('Delta x'))
 ml_dy = float(motion_list_group->Read_attribute('Delta y'))

 ml_x0 = float(motion_list_group->Read_attribute('Grid center x'))
 ml_y0 = float(motion_list_group->Read_attribute('Grid center y'))

 nxny = nx*ny
 nwrites = n_elements(xy_motion_xlist)/nxny;/n_probes
 ntot = nxny * nwrites
 
 geometry='Unknown'
 IF ( (ny GT 1) AND (nx GT 1) ) THEN geometry='xy-plane'
 IF ( (ny EQ 1) AND (nx GT 1) ) THEN geometry='x-line'
 IF ( (ny GT 1) AND (nx EQ 1) ) THEN geometry='y-line'
 IF ( (ny EQ 1) AND (nx EQ 1) ) THEN geometry='point'


 print,'XY Geometry for this motion list: '+ '"'+geometry+'"'


CASE geometry OF

 'xy-plane': BEGIN

          temp=reform(xy_motion_xlist,nwrites,nx,ny)
          xar = reform(temp[0,*,*])
          x   = reform(xar,nxny)
          temp=reform(xy_motion_ylist,nwrites,nx,ny)
          yar = reform(temp[0,*,*])
          y   = reform(yar,nxny)
          temp=reform(xy_motion_zlist,nwrites,nx,ny)
          zar = reform(temp[0,*,*])
          z   = reform(zar,nxny)
          temp=reform(xy_motion_thetalist,nwrites,nx,ny)
          thetaar = reform(temp[0,*,*])
          theta   = reform(thetaar,nxny)
          temp=reform(xy_motion_philist,nwrites,nx,ny)
          phiar = reform(temp[0,*,*])
          phi   = reform(phiar,nxny)

          xvec = reform(xar[*,0])
          yvec = reform(yar[0,*])
          zvec = [zar[0]]

          xy = fltarr(2,nx,ny)
          xy[0,*,*] = xar[*,*]
          xy[1,*,*] = yar[*,*]

          xyz = fltarr(3,nx,ny,1)
          xyz[0,*,*,0] = xar[*,*]
          xyz[1,*,*,0] = yar[*,*]
          xyz[2,*,*,0] = zar[0]

          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
          'xlist',xy_motion_xlist,'ylist',xy_motion_ylist,'zlist',xy_motion_zlist,$
          'thetalist',xy_motion_thetalist,'philist',xy_motion_philist,$
          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,$
          'xar',xar,'yar',yar,'zar',zar,'thetaar',thetaar,'phiar',phiar,$
          'xvec',xvec,'yvec',yvec,'zvec',zvec,$
          'xy',xy,'xyz',xyz,'z_unique',z_unique,'p_unique',p_unique)

          END

 'point': BEGIN
          x=xy_motion_xlist[0]
          y=xy_motion_ylist[0]
          z=xy_motion_zlist[0]
          theta=xy_motion_thetalist[0]
          phi=xy_motion_philist[0]

          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
          'xlist',xy_motion_xlist,'ylist',xy_motion_ylist,'zlist',xy_motion_zlist,$
          'thetalist',xy_motion_thetalist,'philist',xy_motion_philist,$
          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,'z_unique',z_unique,'p_unique',p_unique)
          END

 'x-line': BEGIN
          xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz)
          thetavec = fltarr(nx) & phiarr = fltarr(nx)
          xval = float(0.) & yval = float(0.) & zval = float(0.)
          xy = fltarr(2,nx,ny)
          xyz = fltarr(3,nx,ny,nz)
          xar=fltarr(nx,ny) & yar=fltarr(nx,ny) & zar=fltarr(nx,ny)

          temp=reform(xy_motion_xlist,nwrites,nx)
          x   = reform(temp[0,*])
          xvec = x

          temp=reform(xy_motion_ylist,nwrites,nx)
          y   = reform(temp[0,*])
          temp=reform(xy_motion_zlist,nwrites,nx)
          z   = reform(temp[0,*])
          temp=reform(xy_motion_thetalist,nwrites,nx)
          theta   = reform(temp[0,*])
          temp=reform(xy_motion_philist,nwrites,nx)
          phi   = reform(temp[0,*])

          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
          'xlist',xy_motion_xlist,'ylist',xy_motion_ylist,'zlist',xy_motion_zlist,$
          'thetalist',xy_motion_thetalist,'philist',xy_motion_philist,$
          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,$
          'xvec',xvec,'z_unique',z_unique,'p_unique',p_unique)


          END

 'y-line': BEGIN
          print,'Y-lines not processed correctly yet'
          xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz)
          thetavec = fltarr(ny) & phivec = fltarr(ny)
          xval = float(0.) & yval = float(0.) & zval = float(0.)
          xy = fltarr(2,nx,ny)
          xyz = fltarr(3,nx,ny,nz)
          xar=fltarr(nx,ny) & yar=fltarr(nx,ny) & zar=fltarr(nx,ny)

          temp=reform(xy_motion_xlist,nwrites,ny)
          y   = reform(temp[0,*])
          yvec = y

          temp=reform(xy_motion_xlist,nwrites,ny)
          x   = reform(temp[0,*])
          temp=reform(xy_motion_zlist,nwrites,ny)
          z   = reform(temp[0,*])
          temp=reform(xy_motion_thetalist,nwrites,ny)
          theta   = reform(temp[0,*])
          temp=reform(xy_motion_philist,nwrites,ny)
          phi   = reform(temp[0,*])

          mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nwrites',nwrites,$
          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
          'xlist',xy_motion_xlist,'ylist',xy_motion_ylist,'zlist',xy_motion_zlist,$
          'thetalist',xy_motion_thetalist,'philist',xy_motion_philist,$
          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,$
          'yvec',yvec,'z_unique',z_unique,'p_unique',p_unique)
          END

 

 ELSE: PRINT,'Unknown error'

ENDCASE


 
 OBJ_DESTROY,motion_list_group


 no_motion_lists:
 print,'Nx=',nx
 print,'Ny=',ny

 print,'-------------------------------------------------'
 OBJ_DESTROY,motion_group
ENDIF ELSE BEGIN ;end there was a 6K group

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
          'dx',ml_dx,'dy',ml_dy,'x0',ml_x0,'y0',ml_y0,$
          'x',x,'y',y,'z',z,'theta',theta,'phi',phi,'z_unique',z_unique,'p_unique',p_unique)
ENDELSE

OBJ_DESTROY, HDF5_file

out_message='Done.'
CLEANUP:
print,out_message
RETURN,mlist

END
