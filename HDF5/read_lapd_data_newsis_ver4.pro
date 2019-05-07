;==================
;ABOUT THIS ROUTINE:
;==================
;This IDL routine is for reading the lapd hdf5 data files recorded using new SIS3302/3305 and old 
;SIS3301 digitizers. Make sure that the IDL PATH includes the folder 
;   "/usr/local/itt/local_lib/bapsf_hdf5:" 
;and routine "check_devices.pro (written by Bart)" is present in the library path.
;
;This routine assumes that the data was recorded in one of the following four configurations
;using only one xy motion plane. This routine does not work if multiple motion lists are used
;or if any other digitizer (e.g. fast TVS or DSOs) is used.
;
;daqconfig 0: standard lapd data run, data recorded in the following order, 
;             data 2D (time, channel) from daq -> nshots -> xmotion -> ymotion 
;
;daqconfig 1: standard lapd data run with an extra variable scan after performing the xy motion, 
;             data recorded in following sequence;    data (time,channel) from daq -> nshots -> 
;             xmotion -> ymotion -> extra variable steps (e.g. Bfield steps with pause)
;
;daqconfig 2: standard lapd data run with an extra variable scan before performing the xy motion, 
;             data recorded in following sequence;    data (time,channel) from daq -> nshots -> 
;             extra variable steps (e.g. Bfield steps with pause) -> xmotion -> ymotion  
;
;daqconfig 3: no motion list with extra variable scan, set nstep=1 if no variable scan. 
;             data recorded in following sequence;
;             data 2D (time,shot,chan,step) from daq -> nshots on all channels ->
;             extra variable steps 
;             nstep and nshots have to provided at the input while using this config.
;
;daqconfig 4: standard smpd data run, data recorded in the following order,
;             data 3D (time, channel) from daq -> nshots -> xmotion -> ymotion -> zmotion

;===============
;INPUT VARIABLES
;===============
;readfname  :name of the raw hdf5 file with complete path, string type
;nstep      :integer, must specify nstep for daqconfig 1 & 2 & 3. Nstep is the number of
;               steps in the extra variable specified above. Optional for daqconfig 0
;               If not set, default nstep = 1 is used.
;daqconfig  (optional): 0,1,2 or 3; see description above, default is 0
;trange     (optional): a two element long integer array containing range of time indices to
;               read e.g. [1,1000] will read t(1:1000); default read all t
;xrange     (optional): a two element integer array containing range of x indices to read e.g.
;               [1,3] will read x(1:3); default read all x
;yrange     (optional): a two element integer array containing range of y indices to read e.g.
;               [1,3] will read y(1:3); default read all y
;zrange     (optional): a two element integer array containing range of z indeces to read e.g.
;               [1,3] will read z(1:3); default read all z
;shotrange  (optional): a two element integer array containing range of shot indices to read e.g.
;               [1,3] will read shot(1:3); default read all shots
;readchan   (optional): an integer array containing channels to be read e.g. [0,3,5]; default read
;               all channels. Start counting channel '0' from the first channel on the first board
;               to the last channel on the last board that were used in the data run.
;tchannum   (optional): channel number to read the time series info (default is channel 0). This is
;               useful when channels share multiple sampling rates or number of samples.
;               In single call this routine returns dataset assuming channels in the dataset share
;               the time series "t". One can make multiple calls to this routine if multiple sampling
;               rates/numbers are used and use this argument to retrieve the correct "t" array.
;tstart     (optional): start trigger in second, default value is 0 sec.
;tstop      (optional): stop trigger in second, default value is time-range of acquired data in sec.
;sis        (optional): default '1' is  sis digitizer 3302 (100 MHz), set to '2' for sis 3305 (5GHz)
;               set to '3' for old sis digitizer (sis3301). If more than one digitizers are used,
;               call this routine multiple times with appropiate 'sis' settings.
;motiondevice (optional): default 'y'. Set it to 'n' and provide nx, ny, nz, x, y, z, nshots for
;                reading data when 2D motion (xy or xz) or 3D was performed using non-compumotor
;                motion devices. This is also useful if the run crashed without completing and
;                x, y, z array cannot be read properly.
;motionid   (optional) Set this keyword to an integer corresponding to the motion list of another
;               receptacle. This is usually done when the first motion list corresponds to a
;               stationary probe.

;================
;OUTPUT VARIABLES
;================
;dataset = Array(nt,nx,ny,nshots,nchan) for daqconfig 0,  
;          Array(nt,nx,ny,nshots,nchan,nstep) for daqconfig 1 & 2,
;          Array(nt,nshots,nchan,nstep) for daqconfig 3,
;          Array(nt,nx,ny,nz,nshots,nchan) for daqconfig 4 
;nt      = number of time steps in the returned variable t
;nx      = number of x steps in the returned variable x
;ny      = number of y steps in the returned variable y
;nz      = number of z steps in the returned variable z
;nchan   = number of channels in the returned variable dataset
;nshots  = number of shot in the returned variable dataset
;x       = xarray in cm
;y       = yarray in cm
;z       = zarray in cm
;t       = time array in seconds
;theta   = an array containing probe angle in radian (angle probe makes with x-axis in xz plane)
;phi     = an array containing probe angle in radian (angle probe makes with x-axis in xy plane)

;================
;CHANGE LOG
;================
;Apr  3, 2013 => Written by Shreekrishna, based on Bart's and Steve Vincena's IDL routines
;Sep 25, 2013 => Added daqconfig 3 to read data when no motion lists are used, header section is 
;                  also modified
;Oct 25, 2013 => Removed bug that occurs in reading x & y info, when nx or ny = 1
;Oct 25, 2013 => Added optional variable "tchannum" to read data when multiple sampling rate/numbers
;                  are used
;Jun 24, 2015 => Added option to read data with 2D motion performed without compumotor device
;                  (see variable compumotor)
;Dec  8, 2015 => Added option to read data with old SIS3301 digitizer and optional input 'tstop'
;---- Edits by swjtang ----
;May 30, 2017 => Added "motionid" option to switch the motion list to that of another probe
;                   within the dataset
;Oct  3, 2017 => Added additional condition to read only the zeroth channel when readchan=[0]
;                      since this makes KEYWORD_SET=0
;Oct  4, 2017 => Added option to read XZ-planes with NI_XZ config
;Oct  9, 2017 => Added 'incomplete' option to read data as individual shots if the datarun
;                   is incomplete and cannot be reformed -> superceded by motiondevice
;May 24, 2018 => - Changed tchannum to read the first readchan index if readchan is specified.
;                - Bug fix: readchan reads channel 0 if readchan=[0] is specified.
;                - Update: readchan no longer reads duplicate channels.
;May 26, 2018 => Update: shotrange checks for the case where only one number is specified.
;May 29, 2018 => Update: Included a check and an error message for the case where the file is not
;                   found. Previously it was not possible to tell from the no motion list error
;                   message that the filepath is incorrect or the file does not exist.
;Jul 12, 2018 => Added channel numbers in front of the channel info
;Aug 11, 2018 => Added "motiondevice" option to read hdf5 datafiles generated by an incomplete 
;                  datarun. In this case x, y, z array need to be manually provided.
;Aug 17, 2018 => Added option to read XYZ-volume with NI_XYZ config (by kkrynski)
;Sep  6, 2018 => Added option to suppress print output
;Oct 17, 2018 => Added 'quiet' option to suppress non-critical print outputs. (not done for 3301)

PRO read_lapd_data_newsis_ver4, readfname, dataset, t, x, y, z, nt, nx, ny, nz, nshots, nchan $
    , theta=theta, phi=phi, sis=sis, trange=trange, xrange=xrange, yrange=yrange, zrange=zrange $
    , daqconfig=daqconfig, shotrange=shotrange, readchan=readchan, nstep=nstep $
    , tstart=tstart, tstop=tstop, tchannum=tchannum, motiondevice=motiondevice $
    , motionid=motionid, quiet=quiet;, incomplete=incomplete

    ; Checks if the hdf5 file exists in the directory
    IF FILE_TEST(readfname) EQ 0 THEN BEGIN
        print, '!!! File not found. Check filename for typos or if the file exists in the directory.'
        goto, exitflag
    ENDIF

    IF KEYWORD_SET(readchan) THEN readchan=readchan[UNIQ(readchan)] ;removes duplicate channels
    IF NOT KEYWORD_SET(nstep)        THEN nstep = 1
    IF NOT KEYWORD_SET(nx)           THEN nx = 1
    IF NOT KEYWORD_SET(ny)           THEN ny = 1
    IF NOT KEYWORD_SET(nz)           THEN nz = 1
    IF NOT KEYWORD_SET(nshots)       THEN nshots = 1
    IF NOT KEYWORD_SET(theta)        THEN theta = 1
    IF NOT KEYWORD_SET(sis)          THEN sis = 1
    IF NOT KEYWORD_SET(tstart)       THEN tstart = 0.0
    IF NOT KEYWORD_SET(tstop)        THEN tstop = 0.0
    IF NOT KEYWORD_SET(tchannum)     THEN BEGIN     ;automatically uses the first read channel
        IF KEYWORD_SET(readchan) THEN tchannum = readchan[0] ELSE tchannum = 0
    ENDIF
    IF NOT KEYWORD_SET(motiondevice) THEN motiondevice = 'y'
    IF NOT KEYWORD_SET(motionid)     THEN motionid = 0
    IF KEYWORD_SET(quiet)            THEN BEGIN 
        quiet=1
        print, "!!! Some print messages are being suppressed."
    ENDIF ELSE BEGIN
        quiet=0
    ENDELSE
    ;IF NOT KEYWORD_SET(incomplete)   THEN incomplete = 0 superceded by motiondevice

TIC ;timer start

device_check = check_devices(readfname) ;check which devices are being used

;;;; READ THE DATA PLANE CONFIGURATION ------------------------------------------------------------
CASE 1 OF
    device_check.active[0]:     plane_config='XY'           ; check if 6K compumotor was active
    device_check.active[6]:     plane_config='XZ'           ; check if NI_XZ was active
    device_check.active[7]:     plane_config='XYZ'          ; check if NI_XYZ was active
    ELSE:   IF NOT KEYWORD_SET(compumotor) THEN plane_config='no-motion' $
            ELSE plane_config='no-compumotor'
ENDCASE

geom = 'NA'
IF motiondevice NE 'y' THEN plane_config='manual'

CASE 1 OF
    (plane_config EQ 'XY') OR (plane_config EQ 'XZ') OR (plane_config EQ 'XYZ'): BEGIN
        CASE plane_config OF 
            'XY' : BEGIN   
                mlist = lapd_6k_configuration(readfname, motion=motionid, quiet=quiet)
                ny    = mlist.ny        ; number of points in y
                IF ny GT 1 THEN y = mlist.yvec
                IF ny EQ 1 THEN y = mlist.ylist[0]
                dy    = mlist.dy      ; step size in y
                    z = 0
                geom  = mlist.geom
                END
            'XZ': BEGIN
                mlist = lapd_ni_xz_configuration(readfname, motion=motionid,quiet=quiet)
                nz    = mlist.nz        ; number of points in z
                IF nz GT 1 THEN z = mlist.zvec
                IF nz EQ 1 THEN z = mlist.zlist[0]
                dz    = mlist.dz      ; step size in z
                    y = 0
                geom  = mlist.geom
                END
           'XYZ': BEGIN
                mlist = lapd_ni_xyz_configuration(readfname, motion=motionid, quiet=quiet)
                ny    = mlist.ny    ;number of points in y
                nz    = mlist.nz    ;number of points in z
                IF nz GT 1 THEN z = mlist.zvec
                IF nz EQ 1 THEN z = mlist.zlist[0]
                IF ny GT 1 THEN y = mlist.yvec
                IF ny EQ 1 THEN y = mlist.ylist[0]
                dz    = mlist.dz    ;step size in z
                dy    = mlist.dy    ;step size in y
                geom  = mlist.geom
                daqconfig = 4
                END
        ENDCASE
        nshots  = mlist.nwrites   ; number of saved shots per position
        nx      = mlist.nx        ; number of points in x
            IF nx GT 1 THEN x = mlist.xvec
            IF nx EQ 1 THEN x = mlist.xlist[0]
        dx      = mlist.dx        ; step size in x
        theta   = mlist.theta     ; array with probe angle theta
        phi     = mlist.phi       ; array with probe angle phi
        nshots /= nstep
    END
    (plane_config EQ 'no-motion'): BEGIN
        nx=1 & ny=1 & nz=1 & x=0 & y=0 & z=0 & theta=0 & phi=0
        print, '!!! No motion lists detected, setting nshots ='+ strtrim(nshots,1) + $
            ' and nstep =',strtrim(nstep,1)
    END
    (plane_config EQ 'no-compumotor'): BEGIN
        print, '!!! No compumotor device, Using nx, ny, x, y, theta, phi from input parameters,'+ $
         ' nx, ny, nshots = ' + strtrim(Nx,1) + strtrim(Ny,1) + strtrim(nshots,1)
    END
    (plane_config EQ 'manual'): BEGIN
        theta=0 & phi=0
        print, '!!! No motion list used, using input x, y, z, setting nshots=' + strtrim(nshots,1) $
            + 'nstep =' + strtrim(nstep,1)
    END
    ELSE: BREAK
ENDCASE

;;;; READ THE SIS CRATE CONFIGURATION -------------------------------------------------------------
CASE sis OF
1: BEGIN
    IF device_check.active[2] THEN BEGIN
        sis3302list = lapd_sis3302_configuration(readfname, quiet=quiet)  ;Getting SIS 3302 digitizer information
        nchan       = sis3302list.nchannels
        dt          = sis3302list.lc_dt[tchannum]
        nt          = sis3302list.lc_samples[tchannum]
        boardlist   = sis3302list.lc_board_number
        chanlist    = sis3302list.lc_channel_number
        t           = findgen(nt)*dt + tstart
        IF quiet EQ 0 THEN BEGIN
            IF mean(sis3302list.lc_dt) NE dt THEN $
                PRINT,'SIS 3302, multiple sample rates across boards.'
            IF mean(sis3302list.lc_samples) NE nt THEN $
                PRINT,'SIS 3302, multiple number of samples across boards.'
            print, '----------- Channel Info ---------------------------'
            FOR indx=0,nchan-1 do print, '[',string(indx, format='(I2)'),'] Board: ', $
                strtrim(string(sis3302list.lc_board_number(indx)),2),', Channel ', $
                strtrim(string(sis3302list.lc_channel_number(indx)),2), ': ', $
                sis3302list.lc_datatype(indx)
            print, '----------------------------------------------------'
        ENDIF
    ENDIF ELSE BEGIN
        PRINT,'SIS 3302 not detected in the hdf5 file, try sis=2 (SIS 3305) or sis=3 (SIS 3301)?'
        GOTO, Cleanup
    ENDELSE
END
2: BEGIN
    IF device_check.active[3] THEN BEGIN
        sis3305list = lapd_sis3305_configuration(readfname, quiet=quiet) ;Getting SIS 3305 digitizer information
        nchan       = sis3305list.nchannels
        dt          = sis3305list.lc_dt[tchannum]
        nt          = sis3305list.lc_samples[tchannum]
        boardlist   = sis3305list.lc_board_number
        chanlist    = sis3305list.lc_channel_number
        t           = findgen(nt)*dt + tstart
        IF quiet EQ 0 THEN BEGIN
            IF mean(sis3305list.lc_dt) NE dt THEN $
                PRINT,'SIS 3305, multiple sampling rates across boards!'
            IF mean(sis3305list.lc_samples) NE nt THEN $
                PRINT,'SIS 3305, multiple number of samples across boards!'
            print, '----------- Channel Info ---------------------------'
            FOR indx=0,nchan-1 DO print,'[',string(indx, format='(I2)'),'] Board: ', $
                strtrim(string(sis3305list.lc_board_number(indx)),2),', Channel ', $
                strtrim(string(sis3305list.lc_channel_number(indx)),2), ': ', $
                sis3305list.lc_datatype(indx)
            print, '----------------------------------------------------'
        ENDIF
    ENDIF ELSE BEGIN
        PRINT, 'SIS 3305 not detected in the hdf5 file, try sis=1 (SIS 3302) or sis=3 (SIS 3301)?'
        GOTO, Cleanup
    ENDELSE
END
3: BEGIN
    IF device_check.active[4] THEN BEGIN
        sislist   = lapd_sis_configuration(readfname)  ;Getting SIS 3301 digitizer information
        nchan     = sislist.nchan ; number of channels
        dt        = sislist.dt[0] ; time step in seconds
        nt        = sislist.nt[0] ; number of time samples
        t         = findgen(nt)*dt + tstart
        IF tstop NE 0 THEN t=(findgen(nt)-nt+1)*dt + tstop
    ENDIF ELSE BEGIN
        PRINT, 'SIS 3301 not detected in the hdf5 file, try sis=1 (SIS 3302) or sis=2 (SIS 3305)?'
        GOTO, Cleanup
    ENDELSE
END
ENDCASE

;;;; SPECIFY DEFAULT VARIABLE VALUES --------------------------------------------------------------
    IF NOT KEYWORD_SET(daqconfig)  THEN daqconfig = 0
    IF NOT KEYWORD_SET(trange)     THEN trange = [0L,long(nt)-1L]
    IF NOT KEYWORD_SET(xrange)     THEN xrange = [0,nx-1]
    IF NOT KEYWORD_SET(yrange)     THEN yrange = [0,ny-1]
    IF NOT KEYWORD_SET(zrange)     THEN zrange = [0,nz-1]
    ;checks if only one shot number is specified and if it is [0]
    IF NOT KEYWORD_SET(shotrange) THEN BEGIN
        IF (n_elements(shotrange) EQ 1) THEN shotrange=[0,0] ELSE shotrange = [0,nshots-1]
    ENDIF ELSE BEGIN
        IF (n_elements(shotrange) EQ 1) THEN shotrange=[shotrange[0],shotrange[0]]
    ENDELSE
    IF NOT KEYWORD_SET(readchan)   THEN BEGIN
        IF (n_elements(readchan) EQ 1) THEN BEGIN
            readchan = [0]              ; read the 0th channel if zero is the only channel specified
        ENDIF ELSE BEGIN
            readchan = indgen(nchan)    ; otherwise read all channels by default
        ENDELSE
    ENDIF
   
    ;;; If the geometry is incomplete, overwrite any (x/y/z)range values.
    IF geom EQ 'incomplete' THEN BEGIN
        IF quiet EQ 0 THEN BEGIN
            print, '!!! The datarun is incomplete. Individual shots will be processed.'
            print, '!!! (nx=1, ny=1, nz=1)'
        ENDIF
        xrange=[0,0] & yrange=[0,0] & zrange=[0,0]
    ENDIF

    print,'Read Channels = ', readchan
    print,'Shot range    = ', strtrim(shotrange[0],1),' to ', strtrim(shotrange[1],1)
    print,'X value range = ', strtrim(xrange[0],1),' to ', strtrim(xrange[1],1)
    CASE plane_config OF
        'XZ' :  BEGIN
            ;;;; XZ WILL USE COORDINATES 'X' & 'Y' (2D CASE). COORDINATES RESTORED AT THE END.
            mem_y=y & mem_ny=ny & mem_yrange=yrange         ; store in memory
            y=z & ny=nz & yrange=zrange                     ; now all y-variables contain z-values
            print, 'Z value range = ', strtrim(zrange[0],1),' to ', strtrim(zrange[1],1)
        END
        'XYZ':  BEGIN
                print, 'Y value range = ', strtrim(yrange[0],1),' to ', strtrim(yrange[1],1)
                print, 'Z value range = ', strtrim(zrange[0],1),' to ', strtrim(zrange[1],1)
        END
        ELSE :  print, 'Y value range = ', strtrim(yrange[0],1),' to ', strtrim(yrange[1],1)
    ENDCASE

    ntt=nt & nxx=nx & nyy=ny & nzz=nz & nchann=nchan & nshotss=nshots   ;store values from hdf data

        t   = t[trange[0]:trange[1]] ; reduced range of the t, x, y variables
        x   = x[xrange[0]:xrange[1]]
        y   = y[yrange[0]:yrange[1]]
        z   = z[zrange[0]:zrange[1]]
   
        nt = n_elements(t) & nx = n_elements(x) & ny = n_elements(y) & nz = n_elements(z)
    nshots = shotrange[1]-shotrange[0]+1
    nchan  = n_elements(readchan)

    mem_req=long64(nt)*nx*ny*nz*nshots*nchan*nstep*4.0e-9 
    print,'Estimated memory to read the data (GB):', mem_req
    IF mem_req GT 100 THEN BEGIN 
      print,'!!! Please reduce the data size to keep the required memory below 100 GB' 
      GOTO, Cleanup
    ENDIF

    CASE daqconfig OF
        0:      dataset=fltarr(nt,nx,ny,nshots,nchan)       ;<< standard lapd data run
        1:      dataset=fltarr(nt,nx,ny,nshots,nchan,nstep) ;<< extra steps
        2:      dataset=fltarr(nt,nx,ny,nshots,nchan,nstep)
        3:      dataset=fltarr(nt,nshots,nchan,nstep)       ;<< no xy motion, no extra steps
        4:      dataset=fltarr(nt,nx,ny,nz,nshots,nchan)    ;<< standard 3D data run
    ENDCASE
    print,'Dynamic memory used after data variable creation (GB):', string(memory(/current)*1e-9, $
        format='(f7.3)')

        hdf = obj_new('HDF5_file')
        hdf -> Open, readfname

    CASE 1 OF
        (sis EQ 1) OR (sis EQ 2):   sis_group = hdf->Open_group('/Raw data + config/SIS crate')
        (sis EQ 3):                 sis_group = hdf->Open_group('/Raw data + config/SIS 3301')
    ENDCASE

FOR step = 0, nstep-1 DO BEGIN
    FOR iz = zrange[0], zrange[1] DO BEGIN
    FOR iy = yrange[0], yrange[1] DO BEGIN
    FOR ix = xrange[0], xrange[1] DO BEGIN
    FOR ishot = shotrange[0], shotrange[1] DO BEGIN
        ; if read everything as single shot then print a progress bar
        IF geom EQ 'incomplete' THEN BEGIN  
            outprint='!!! Processing: shot '+string(ishot-shotrange[0]+1, format='(I6)') $
                +' of '+string(nshots,format='(I6)')
            print, string(13b), outprint, format='(A,A,$)'
            IF ishot EQ shotrange[1] THEN PRINT, '  '
        ENDIF ELSE BEGIN
           IF nstep GT 1 THEN BEGIN
               outprint='(Step/Shot/XX/YY/ZZ) = ('+strtrim(step+1,1)+'/' $
                   + strtrim(ishot-shotrange[0]+1,1) +'/'+ strtrim(ix-xrange[0]+1,1) + '/' $
                   + strtrim(iy-yrange[0]+1,1) + '/'+ strtrim(iz-zrange[0]+1,1) + ') of ('$
                   + strtrim(nstep,1)+'/'+ strtrim(nshots,1)+'/'+strtrim(nx,1)+'/' $
                   + strtrim(ny,1)+'/' + strtrim(nz,1)+ ')...'
           ENDIF ELSE BEGIN
               outprint='(Shot/XX/YY/ZZ) = (' $
                   + strtrim(ishot-shotrange[0]+1,1) +'/'+ strtrim(ix-xrange[0]+1,1) + '/' $
                   + strtrim(iy-yrange[0]+1,1) + '/'+ strtrim(iz-zrange[0]+1,1) + ') of ('$
                   + strtrim(nshots,1)+'/'+strtrim(nx,1)+'/' $
                   + strtrim(ny,1)+'/' + strtrim(nz,1)+ ')...'
           ENDELSE
           print, string(13b), outprint, format='(A,A,$)'
           ;IF ix EQ 8 AND iy EQ 10 AND ishot EQ 1 THEN goto, skipshot ;;; enable when reading SFR54
        ENDELSE
        CASE daqconfig OF
            ;data loop >> nshots -> xmotion -> ymotion 
                0: index= ishot + nshotss*(ix + nxx*iy)
            ;data loop >> nshots -> xmotion -> ymotion -> extra variable steps            
                1: index= ishot + nshotss*(ix + nxx*(iy + nyy*step))
            ;data loop >> nshots -> extra variable steps -> xmotion -> ymotion 
                2: index= ishot + nshotss*(step + nstep*(ix + nxx*iy))
            ;data loop >> nshots
                3: index= ishot + nshotss*steps
            ;data loop >> nshots -> xmotion -> ymotion -> zmotion                        
                4: index= ishot + nshotss*(ix + nxx*iy + nxx*nyy*iz)   
        ENDCASE
        FOR ichan=0, nchan-1 DO BEGIN
            CASE sis OF
                1:  dattemp = sis_group->read_sis3302_shot(boardlist(readchan[ichan]), $
                        chanlist(readchan[ichan]),index)
                2:  dattemp = sis_group->read_sis3305_shot(boardlist(readchan[ichan]), $
                        chanlist(readchan[ichan]),index)
                3:  dattemp = sis_group->read_sis_shot(readchan[ichan],index)
            ENDCASE
            CASE daqconfig OF
                0:  dataset[*,ix-xrange[0],iy-yrange[0],ishot-shotrange[0],ichan] $
                            = dattemp[trange[0]:trange[1]]
                1:  dataset[*,ix-xrange[0],iy-yrange[0],ishot-shotrange[0],ichan,step] $
                            = dattemp[trange[0]:trange[1]]
                2:  dataset[*,ix-xrange[0],iy-yrange[0],ishot-shotrange[0],ichan,step] $
                            = dattemp[trange[0]:trange[1]]
                3:  dataset[*,ishot-shotrange[0],ichan,step] $
                            = dattemp[trange[0]:trange[1]]
                4:  dataset[*,ix-xrange[0],iy-yrange[0],iz-zrange[0],ishot-shotrange[0],ichan] $
                            = dattemp[trange[0]:trange[1]]
            ENDCASE
        ENDFOR; loop for channels
        skipshot:
    ENDFOR; loop for shots
    ENDFOR; loop for x
    ENDFOR; loop for y
    ENDFOR; loop for z
ENDFOR; loop for steps
print, ' '

; ;;;; RESTORE VARIABLES IF XZ WAS USED
IF plane_config EQ 'XZ' THEN BEGIN
     z=y & nz=ny & zrange=yrange                     ; pass all z-values to the z-variables
     y=mem_y & ny=mem_ny & yrange=mem_yrange         ; restore y-values from memory
END

OBJ_DESTROY, sis_group
OBJ_DESTROY, hdf

print, 'Completed reading raw data: ',systime(0)
TOC ;timer end

cleanup: PRINT,' '
    print, 'Read LAPD Data complete'
    help, dataset

exitflag:
END