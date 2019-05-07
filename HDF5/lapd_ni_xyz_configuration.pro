;NAME:        lapd_ni_xyz_configuration.pro (adapted from lapd_ni_xz_configuration.pro)
;AUTHOR:      KKrynski / swjtang 
;DATE:        04 Sep 2018
;DESCRIPTION: Returns an IDL structure containing the parsed information in the 'NI_XYZ' group of an LAPD HDF5 file
;SYNTAX:      Result = LAPD_NI_XYZ_CONFIGURATION(input_file, motionid=motionid)
;CHANGELOG:   
;04 Sep 2018  => Checks if the total number of points matches the intended number of
;                of points. If it does not, return 'incomplete' geometry.
;Oct 17, 2018 => Added 'quiet' option to suppress non-critical print outputs. (not yet checked)

FUNCTION LAPD_NI_XYZ_CONFIGURATION, input_file, motion=motionid, quiet=quiet
COMPILE_OPT IDL2

;;;; ASSIGN DEFAULT VALUES FOR UNSPECIFIED GEOMETRY -----------------------------------------------
geometry='Unknown'
nx = ulong(1) & ny = ulong(1) & nz = ulong(1) & nr = ulong(1)
nwrites = ulong(1)
xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz) & rvec=fltarr(nr)
xval=float(0.)  & yval=float(0.) &  zval=float(0.)  & rval=float(0.)
xyz = fltarr(3,nx,ny,nz)
xyzr= fltarr(4,nx,ny,nz,nr)
xar= fltarr(nx,ny,nz) & yar=fltarr(nx,ny,nz) & zar=fltarr(nx,ny,nz) & rar=fltarr(nx,ny,nz)
mlist = {x:float(0.), y:float(0.), z:float(0.), r:float(0.), nwrites:float(1)}
r_unique = float([0.])
p_unique = ["Unknown"]

;;;; OPEN .HDF5 FILE ------------------------------------------------------------------------------
IF (input_file EQ '') THEN BEGIN
  input_file=''
  input_file=dialog_pickfile()
ENDIF
IF (input_file EQ '') THEN BEGIN
  out_message='Error associated with input file'
  GOTO, CLEANUP
ENDIF

;;;; CREATE THE OBJECT ----------------------------------------------------------------------------
HDF5_file = OBJ_NEW('HDF5_file')
IF (FILE_TEST(input_file) EQ 1) THEN BEGIN
     print,'--------------------------------------------------'
     print, 'Opening: ', input_file
     HDF5_file->Open, input_file
ENDIF

;;;; DETERMINE LAPD SOFTWARE VERSION --------------------------------------------------------------
sw_version = HDF5_file.Read_attribute('LaPD HDF5 software version')
IF quiet EQ 0 THEN print,'LaPD HDF5 software version = '+sw_version

;;;; OPEN RAW DATA AND CONFIGURATION GROUP --------------------------------------------------------
rac_group = HDF5_file.Open_group('Raw data + config')
rac_subgroup_names = rac_group.Read_group_names()
OBJ_DESTROY, rac_group

;;;; PROCESS NI_XYZ IF IT EXISTS -------------------------------------------------------------------
motion_group_test = WHERE(rac_subgroup_names EQ 'NI_XYZ')
IF (motion_group_test[0] NE -1) THEN BEGIN

    motion_group_name= '/Raw data + config/NI_XYZ'

    motion_group= HDF5_file.Open_group(motion_group_name) 
    motion_subgroup_names= motion_group.Read_group_names()
    motion_dataset_names = motion_group.Read_dataset_names()
    IF quiet EQ 0 THEN BEGIN
      print, 'Motion dataset names:'
      counter=1
      PM, '#'+strtrim(counter++,1)+': ', motion_dataset_names
    ENDIF

    ;;; PROCESS NI_XYZ RUNTIME LIST ----------------------------------------------------------------
    ; Open Runtime list of positions and angles at every shot number
    ; If there is a NI_XYZ group, there must be a Runtime List. No error check here

    CASE sw_version OF
    '1.1': BEGIN
        motion_rtl_dataset = HDF5_file.Read_dataset(motion_group_name+'/Run time list')
        END
    ; With the introduction of the real-time-translator (sw_version 1.2),
    ; each probe gets its own dataset of probe motions.
    ; For now (10/22/2012) just grab the first one and re-use version 1.1 code <---------- this....
    ELSE: BEGIN ;assume version 1.2 or compatible
        IF keyword_set(motionid) THEN ind=motionid ELSE ind=0     ;changable index so we can use other probe motion lists
        IF quiet EQ 0 THEN print, ' -> Chosen motion dataset: #', strtrim(ind+1,1)
        motion_rtl_dataset = motion_group.Read_dataset(motion_dataset_names[ind])
        END
    ENDCASE

    xyz_motion_shot_number = reform(ulong64(motion_rtl_dataset._DATA.SHOT_NUMBER))
    xyz_motion_xlist = reform(float(motion_rtl_dataset._DATA.X))
    xyz_motion_ylist = reform(float(motion_rtl_dataset._DATA.Y))
    xyz_motion_zlist = reform(float(motion_rtl_dataset._DATA.Z))
    xyz_motion_rlist = reform(float(motion_rtl_dataset._DATA.R))
    xyz_motion_thetalist = reform(float(motion_rtl_dataset._DATA.THETA))
    xyz_motion_philist   = reform(float(motion_rtl_dataset._DATA.PHI))
    xyz_motion_config_name = reform(motion_rtl_dataset._DATA.CONFIGURATION_NAME)

 ;???? do we really need the following???
  n_motion_lists=n_elements(uniq(xyz_motion_config_name,sort(xyz_motion_config_name)))
  n_probes=n_motion_lists

  ; r_unique = fltarr(n_probes)
  ; p_unique = strarr(n_probes)
  ; FOR i=0, n_probes-1 DO BEGIN
  ;   r_unique[i] = xz_motion_rlist[i]
  ;   p_unique[i] = xz_motion_config_name[i]
  ; ENDFOR

   IF (n_probes GT 1) THEN BEGIN
    PRINT,'Warning in --- LAPD_NI_XYZ_CONFIGURATION.pro ----'
    PRINT,'More than one probe found. Program will assume that all probes are moving on the same grid!'
    PRINT,'In the position arrays, the z location will be fixed to the first probe position listed.'      ;;;;;;<---????????
    ; PRINT,'The tag "r_unique" in the motion list structure will contain the unique z locations'
    ; PRINT,'The tag "p_unique" in the motion list structure will contain the corresponding probe names'
    ; FOR i=0, n_probes-1 do begin
    ;   PRINT,strcompress('z location of probe, '+p_unique[i] +' is '+string(r_unique[i])+ ' cm')
    ; ENDFOR
  ;;;; CLENSE INPUTS
    n_probes = 1
    one_probe_index = WHERE(xyz_motion_config_name EQ xyz_motion_config_name[0])
    xyz_motion_shot_number = xyz_motion_shot_number[one_probe_index]
    xyz_motion_xlist = xyz_motion_xlist[one_probe_index]
    xyz_motion_ylist = xyz_motion_ylist[one_probe_index]
    xyz_motion_zlist = xyz_motion_zlist[one_probe_index]
    xyz_motion_rlist = xyz_motion_rlist[one_probe_index]
    xyz_motion_thetalist = xyz_motion_thetalist[one_probe_index]
    xyz_motion_philist = xyz_motion_philist[one_probe_index]
    xyz_motion_config_name = xyz_motion_config_name[one_probe_index]
  ENDIF

  IF ( (n_motion_lists GT 1) OR (n_probes GT 1) ) THEN BEGIN
   PRINT,'Warning: this program cannot properly parse coordinate information when a datarun'+ $
      ' has multiple motion lists or multiple probes moving with the same motion list.'
   PRINT,'...'
   PRINT,'Dividing the apparent number of writes by the number of motion lists in the hopes'+ $
      ' that this will solve the problem.'
  ENDIF
 ;-------------done with runtime list ------------

    ;;;; there are only motion lists in the subgroup
    motion_list_indexes=where(motion_subgroup_names);strmid(motion_subgroup_names,0,1) eq 'p')
    IF (motion_list_indexes[0] eq -1) THEN BEGIN
        print,'!!! NI_XYZ group exists, but no probes / motion lists found.'
        goto, no_motion_lists
    ENDIF ELSE BEGIN
        n_motion_lists = n_elements(motion_list_indexes)
        motion_list_names=motion_subgroup_names[motion_list_indexes]
    ENDELSE

    IF quiet EQ 0 THEN BEGIN
      print, '--------------------------------------------------'
      print,'All probes & motion lists found in this datarun:'
      FOR i_motion_list=0L, n_motion_lists-1 DO BEGIN
          current_motion_list = motion_list_names[i_motion_list]

          motion_list_group = motion_group->Open_group(current_motion_list)
          probe_name = motion_list_group->Read_attribute('probe_name')
          print, '#', strtrim(i_motion_list+1,1),': ', current_motion_list+' / '+probe_name
      ENDFOR
      print, '--------------------------------------------------'
    ENDIF

    motion_list = motion_list_names[0]
    IF quiet EQ 0 THEN print, 'Now choosing the first motion list ('+motion_list+')'
    motion_list_group = motion_group->Open_group(motion_list)

    nx = ulong(motion_list_group->Read_attribute('Nx'))
    ny = ulong(motion_list_group->Read_attribute('Ny'))
    nz = ulong(motion_list_group->Read_attribute('Nz'))

    ml_dx = float(motion_list_group->Read_attribute('dx'))
    ml_dy = float(motion_list_group->Read_attribute('dy'))
    ml_dz = float(motion_list_group->Read_attribute('dz'))

    ml_x0 = float(motion_list_group->Read_attribute('x0'))
    ml_y0 = float(motion_list_group->Read_attribute('y0'))
    ml_z0 = float(motion_list_group->Read_attribute('z0'))

    zport = float(motion_list_group->Read_attribute('z_port'))
    fanXYZ = motion_list_group->Read_attribute('fan_XYZ')   ; if points are on a fanned surface !!!Reads opposite
    minZ = float(motion_list_group->Read_attribute('min_zdrive_steps'))
    maxZ = float(motion_list_group->Read_attribute('max_zdrive_steps'))
    minY = float(motion_list_group->Read_attribute('min_ydrive_steps'))
    maxY = float(motion_list_group->Read_attribute('max_ydrive_steps'))

    nxnynz = nx*nz*ny
    nwrites = n_elements(xyz_motion_xlist)/nxnynz;/n_probes

    geometry='Unknown'
    IF ( (nz GT 1) AND (nx GT 1) AND (ny GT 1)  ) THEN geometry='xyz-volume'  ;added
    IF ( (nz EQ 1) AND (nx GT 1) AND (ny GT 1)  ) THEN geometry='xy-plane'    ;added
    IF ( (nz GT 1) AND (nx GT 1) AND (ny EQ 1)  ) THEN geometry='xz-plane'    ;adjusted
    IF ( (nz GT 1) AND (nx EQ 1) AND (ny GT 1)  ) THEN geometry='yz-plane'    ;added
    IF ( (nz EQ 1) AND (nx GT 1) AND (ny EQ 1)  ) THEN geometry='x-line'      ;adjusted
    IF ( (nz EQ 1) AND (nx EQ 1) AND (ny GT 1)  ) THEN geometry='y-line'      ;added
    IF ( (nz GT 1) AND (nx EQ 1) AND (ny EQ 1)  ) THEN geometry='z-line'      ;adjusted
    IF ( (nz EQ 1) AND (nx EQ 1) AND (ny EQ 1)  ) THEN geometry='point'       ;adjusted
    
    IF n_elements(xyz_motion_xlist) MOD nxnynz NE 0 THEN BEGIN
        out_message= "!!! Datarun is incomplete."
        geometry='incomplete'
    ENDIF

    print,'... and the XYZ geometry is: '+ '"'+geometry+'"'

  CASE geometry OF
      'xyz-volume': BEGIN
        temp= reform(xyz_motion_xlist,nwrites,nx,ny,nz)
        xar = reform(temp[0,*,*,*])
        x   = reform(xar,nxnynz)
        temp= reform(xyz_motion_ylist,nwrites,nx,ny,nz)
        yar = reform(temp[0,*,*,*])
        y   = reform(yar,nxnynz)
        temp= reform(xyz_motion_zlist,nwrites,nx,ny,nz)
        zar = reform(temp[0,*,*,*])
        z   = reform(zar,nxnynz)
        temp= reform(xyz_motion_rlist,nwrites,nx,ny,nz)
        rar = reform(temp[0,*,*,*])
        r   = reform(rar,nxnynz)
        temp= reform(xyz_motion_thetalist,nwrites,nx,ny,nz)
        thetaar = reform(temp[0,*,*,*])
        theta   = reform(thetaar,nxnynz)
        temp= reform(xyz_motion_philist,nwrites,nx,ny,nz)
        phiar=reform(temp[0,*,*,*])
        phi  =reform(phiar,nxnynz)
        xvec = reform(xar[*,1,1])
        yvec = reform(yar[1,*,1])
        zvec = reform(zar[1,1,*])
        rvec = [rar[0]]

        xyz = fltarr(3,nx,ny,nz)
        xyz[0,*,*,*] = xar[*,*,*]
        xyz[1,*,*,*] = yar[*,*,*]
        xyz[2,*,*,*] = zar[*,*,*]

        xyzr = fltarr(4,nx,ny,nz,1)
        xyzr[0,*,*,*,0] = xar[*,*,*]
        xyzr[1,*,*,*,0] = yar[*,*,*]
        xyzr[2,*,*,*,0] = zar[*,*,*]
        xyzr[3,*,*,*,0] = rar[0]

        mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
          'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0, 'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,$
          'minY',minY,'maxY',maxY,'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,$
          'thetalist',xyz_motion_thetalist,'philist',xyz_motion_philist,$
          'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,$
          'xar',xar,'yar',yar,'zar',zar,'rar',rar,'thetaar',thetaar,'phiar',phiar,$
          'xvec',xvec,'yvec',yvec,'zvec',zvec,'rvec',rvec,$
          'xyz',xyz,'xyzr',xyzr,'r_unique',r_unique,'p_unique',p_unique)
      END

   'xy-plane': BEGIN
        temp= reform(xyz_motion_xlist,nwrites,nx,ny)
        xar = reform(temp[0,*,*])
        x   = reform(xar,nxnynz)
        temp= reform(xyz_motion_ylist,nwrites,nx,ny)
        yar = reform(temp[0,*,*])
        y   = reform(yar,nxnynz)
        temp= reform(xyz_motion_zlist,nwrites,nx,ny)
        zar = reform(temp[0,*,*])
        z   = reform(zar,nxnynz)
        temp= reform(xyz_motion_rlist,nwrites,nx,ny)
        rar = reform(temp[0,*,*])
        r   = reform(rar,nxnynz)
        temp= reform(xyz_motion_thetalist,nwrites,nx,ny)
        thetaar = reform(temp[0,*,*])
        theta   = reform(thetaar,nxnynz)
        temp= reform(xyz_motion_philist,nwrites,nx,ny)
        phiar=reform(temp[0,*,*])
        phi  =reform(phiar,nxnynz)
        xvec = reform(xar[*,0])
        yvec = reform(yar[0,*])
        rvec = [rar[0]]

        xy = fltarr(2,nx,ny)
        xy[0,*,*] = xar[*,*]
        xy[1,*,*] = yar[*,*]

        xyr = fltarr(3,nx,ny,1)
        xyr[0,*,*,0] = xar[*,*]
        xyr[1,*,*,0] = yar[*,*]
        xyr[2,*,*,0] = rar[0]

        mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
          'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0, 'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,$
          'minY',minY,'maxY',maxY,'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,$
          'thetalist',xyz_motion_thetalist,'philist',xyz_motion_philist,$
          'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,$
          'xar',xar,'yar',yar,'zar',zar,'rar',rar,'thetaar',thetaar,'phiar',phiar,$
          'xvec',xvec,'yvec',yvec,'rvec',rvec,$
          'xy',xy,'xyr',xyr,'r_unique',r_unique,'p_unique',p_unique)
      END

        'xz-plane': BEGIN
            temp= reform(xyz_motion_xlist,nwrites,nx,nz)
            xar = reform(temp[0,*,*])
            x   = reform(xar,nxnynz)
            temp= reform(xyz_motion_ylist,nwrites,nx,nz)
            yar = reform(temp[0,*,*])
            y   = reform(yar,nxnynz)
            temp= reform(xyz_motion_zlist,nwrites,nx,nz)
            zar = reform(temp[0,*,*])
            z   = reform(zar,nxnynz)
            temp= reform(xyz_motion_rlist,nwrites,nx,nz)
            rar = reform(temp[0,*,*])
            r   = reform(rar,nxnynz)
            temp= reform(xyz_motion_thetalist,nwrites,nx,nz)
            thetaar = reform(temp[0,*,*])
            theta   = reform(thetaar,nxnynz)
            temp= reform(xyz_motion_philist,nwrites,nx,nz)
            phiar=reform(temp[0,*,*])
            phi  =reform(phiar,nxnynz)
            xvec = reform(xar[*,0])
            zvec = reform(zar[0,*])
            rvec = [rar[0]]

            xz = fltarr(2,nx,nz)
            xz[0,*,*] = xar[*,*]
            xz[1,*,*] = zar[*,*]

            xzr = fltarr(3,nx,nz,1)
            xzr[0,*,*,0] = xar[*,*]
            xzr[1,*,*,0] = zar[*,*]
            xzr[2,*,*,0] = rar[0]

            mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
            'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0, 'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,$
            'minY',minY,'maxY',maxY,'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,$
            'thetalist',xyz_motion_thetalist,'philist',xyz_motion_philist,$
            'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,$
            'xar',xar,'yar',yar,'zar',zar,'rar',rar,'thetaar',thetaar,'phiar',phiar,$
            'xvec',xvec,'zvec',zvec,'rvec',rvec,$
            'xz',xz,'xzr',xzr,'r_unique',r_unique,'p_unique',p_unique)
            END
            
      'yz-plane': BEGIN
              temp= reform(xyz_motion_xlist,nwrites,ny,nz)
              xar = reform(temp[0,*,*])
              x   = reform(xar,nxnynz)
              temp= reform(xyz_motion_ylist,nwrites,ny,nz)
              yar = reform(temp[0,*,*])
              y   = reform(yar,nxnynz)
              temp= reform(xyz_motion_zlist,nwrites,ny,nz)
              zar = reform(temp[0,*,*])
              z   = reform(zar,nxnynz)
              temp= reform(xyz_motion_rlist,nwrites,ny,nz)
              rar = reform(temp[0,*,*])
              r   = reform(rar,nxnynz)
              temp= reform(xyz_motion_thetalist,nwrites,ny,nz)
              thetaar = reform(temp[0,*,*])
              theta   = reform(thetaar,nxnynz)
              temp= reform(xyz_motion_philist,nwrites,ny,nz)
              phiar=reform(temp[0,*,*])
              phi  =reform(phiar,nxnynz)
              yvec = reform(yar[*,0])
              zvec = reform(zar[0,*])
              rvec = [rar[0]]

              yz = fltarr(2,ny,nz)
              yz[0,*,*] = yar[*,*]
              yz[1,*,*] = zar[*,*]

              yzr = fltarr(3,ny,nz,1)
              yzr[0,*,*,0] = yar[*,*]
              yzr[1,*,*,0] = zar[*,*]
              yzr[2,*,*,0] = rar[0]

              mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
                'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0, 'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,$
                'minY',minY,'maxY',maxY,'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,$
                'thetalist',xyz_motion_thetalist,'philist',xyz_motion_philist,$
                'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,$
                'xar',xar,'yar',yar,'zar',zar,'rar',rar,'thetaar',thetaar,'phiar',phiar,$
                'yvec',yvec,'zvec',zvec,'rvec',rvec,$
                'yz',yz,'yzr',yzr,'r_unique',r_unique,'p_unique',p_unique)
         END            


        'x-line': BEGIN
              xvec=fltarr(nx) & zvec=fltarr(nz) & rvec=fltarr(nr)
              thetavec = fltarr(nx)
              xval=float(0.)  & zval=float(0.)  & rval=float(0.)
              xz  = fltarr(2,nx,nz)
              xzr = fltarr(3,nx,nz,nr)
              xar = fltarr(nx,nz) & zar=fltarr(nx,nz) & rar=fltarr(nx,nz)

              temp = reform(xyz_motion_xlist,nwrites,nx)
              x    = reform(temp[0,*])
              xvec = x

              temp = reform(xyz_motion_ylist,nwrites,nx)
              y    = reform(temp[0,*])
              

              temp = reform(xyz_motion_zlist,nwrites,nx)
              z    = reform(temp[0,*])
              temp = reform(xyz_motion_rlist,nwrites,nx)
              r    = reform(temp[0,*])
              temp = reform(xyz_motion_thetalist,nwrites,nx)
              theta= reform(temp[0,*])
              temp = reform(xyz_motion_philist,nwrites,nx)
              phi  = reform(temp[0,*])

              mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
              'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0,'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,$
              'minY',minY,'maxY',maxY,'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,$
              'thetalist',xyz_motion_thetalist,'philist',xyz_motion_philist,$
              'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,$
              'xvec',xvec,'r_unique',r_unique,'p_unique',p_unique)
              END

    'y-line': BEGIN
                xvec=fltarr(nx) & yvec=fltarr(ny) & zvec=fltarr(nz) & rvec=fltarr(nr)
                thetavec = fltarr(nx)
                xval=float(0.)  & yval=float(0.) & zval=float(0.)  & rval=float(0.)

                temp = reform(xyz_motion_xlist,nwrites,ny)
                x    = reform(temp[0,*])

                temp = reform(xyz_motion_ylist,nwrites,ny)
                y    = reform(temp[0,*])
                yvec = y

                temp = reform(xyz_motion_zlist,nwrites,ny)
                z    = reform(temp[0,*])
                temp = reform(xyz_motion_rlist,nwrites,ny)
                r    = reform(temp[0,*])
                temp = reform(xyz_motion_thetalist,nwrites,ny)
                theta= reform(temp[0,*])
                temp = reform(xyz_motion_philist,nwrites,ny)
                phi  = reform(temp[0,*])

                mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
                  'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0,'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,$
                  'minY',minY,'maxY',maxY,'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,$
                  'thetalist',xyz_motion_thetalist,'philist',xyz_motion_philist,$
                  'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,$
                  'yvec',yvec,'r_unique',r_unique,'p_unique',p_unique)
             END



        'z-line': BEGIN
              xvec=fltarr(nx) & zvec=fltarr(nz) & rvec=fltarr(nr)
              thetavec = fltarr(nz)
              xval=float(0.)  & zval=float(0.)  & rval=float(0.)

              temp = reform(xyz_motion_zlist,nwrites,nz)
              z    = reform(temp[0,*])
              zvec = z
              
              temp = reform(xyz_motion_ylist,nwrites,nz)
              y    = reform(temp[0,*])

              temp = reform(xyz_motion_xlist,nwrites,nz)
              x    = reform(temp[0,*])
              
              temp = reform(xyz_motion_rlist,nwrites,nz)
              r    = reform(temp[0,*])
              temp = reform(xyz_motion_thetalist,nwrites,nz)
              theta= reform(temp[0,*])
              temp = reform(xyz_motion_philist,nwrites,nz)
              phi  = reform(temp[0,*])


              mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
              'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0,'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,$
              'minY',minY,'maxY',maxY,'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,'thetalist',xyz_motion_thetalist,$
              'philist',xyz_motion_philist,'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,$
              'zvec',zvec,'r_unique',r_unique,'p_unique',p_unique)
              END
              
              
        'point': BEGIN
                x=xyz_motion_xlist[0]
                y=xyz_motion_ylist[0]
                z=xyz_motion_zlist[0]
                r=xyz_motion_rlist[0]
                theta=xyz_motion_thetalist[0]
                phi=xyz_motion_philist[0]

                mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
                  'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0,'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,$
                  'minY',minY,'maxY',maxY,'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,$
                  'thetalist',xyz_motion_thetalist,'philist',xyz_motion_philist,$
                  'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,'r_unique',r_unique,'p_unique',p_unique)
              END

        'incomplete': BEGIN
            print, '!!! The data could not be completely segmented. The datarun may be incomplete.'
            print, '!!! Resegmenting the remaining data as individual shots'
            ;;; if the data run stops halfway its not possible to know both the number of 
            ;;; shots/pos or the number of z-pos from the data itself
            nx=1 & ny=1 & nz=1 & nwrites=n_elements(xyz_motion_xlist)
            x=xyz_motion_xlist[0]
            y=xyz_motion_ylist[0]
            z=xyz_motion_zlist[0]
            r=xyz_motion_rlist[0]
            theta=xyz_motion_thetalist[0]
            phi=xyz_motion_philist[0]

            mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,$
            'nwrites',nwrites,'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_z0,'z0',ml_z0,$
            'zport', zport, 'fanXYZ', fanXYZ, 'minZ', minZ,'maxZ',maxZ,'minY',minY,'maxY',maxY,$
            'xlist',xyz_motion_xlist,'ylist',xyz_motion_ylist,'zlist',xyz_motion_zlist,'rlist',xyz_motion_rlist,$
            'thetalist',xyz_motion_thetalist,'philist',xyz_motion_philist,$
            'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,'r_unique',r_unique,'p_unique',p_unique)
            END

              
        ELSE: PRINT,'Unknown geometry'
    ENDCASE
 
    OBJ_DESTROY, motion_list_group

    no_motion_lists:
    IF quiet EQ 0 THEN BEGIN
      print,'Nx = ', strtrim(nx,1)
      print,'Ny = ', strtrim(ny,1)
      print,'Nz = ', strtrim(nz,1)
      print,'--------------------------------------------------'
    ENDIF
    OBJ_DESTROY, motion_group
ENDIF ELSE BEGIN ;end there was a NI_XYZ group
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
        r=float(0.)
        ml_x0 = float(0.) & ml_y0 = float(0.) & ml_z0 = float(0.)
        theta=float(0.)
        phi=float(0.)
        nx = ulong(1) & ny = ulong(1) & nz = ulong(1) & nr = ulong(1)

        mlist = CREATE_STRUCT('motionlist',motion_list,'geom',geometry,'nx',nx,'ny',ny,'nz',nz,'nr',nr,'nwrites',nwrites,$
        'dx',ml_dx,'dy',ml_dy,'dz',ml_dz,'x0',ml_x0,'y0',ml_y0,'z0',ml_z0,$
        'x',x,'y',y,'z',z,'r',r,'theta',theta,'phi',phi,'r_unique',r_unique,'p_unique',p_unique)
    ENDELSE

OBJ_DESTROY, HDF5_file

out_message='NI XYZ done.'
CLEANUP:

print, out_message
RETURN, mlist
END
