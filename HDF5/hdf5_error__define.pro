; NAME:
;   HDF5_error
;
; PURPOSE:
;   This object manages error handling for any LaPD object.  It is an internal object primarily
;   but could be included in any IDL application if desired.
;
;   Currently, when an error is hit information is stored and displayed, then execution
;   is halted.  This is also how the underlying HDF5 functions and procedures operate.
;   Great caution must be exercised if this behavior is ever changed because the calling code in
;   many places depends on the execution halting.
;
; CALLING SEQUENCE:
;     HDF5_error_obj = OBJ_NEW('HDF5_error')       ; initially creates the object
;     HDF5_error_obj->Handle_error, message        ; handles an error
;
;     status = HDF5_error_obj->Get_status()        ; gets the error properties
;     status = HDF5_error_obj->Get_message()       ;
;     status = HDF5_error_obj->Get_call_stack()    ;
;
;     OBJ_DESTROY, HDF5_error_obj                  ; destroys the object
;
; KEYWORD PARAMETERS:
;   None
;
; EXAMPLE:
;   Handle an error:
;     HDF5_error_obj->Handle_error, 'Unknown file version: ' + version
;
; ERROR HANDLING:
;   None
;
; MODIFICATION HISTORY:
;   Written by:  Jim Bamber  July, 2005.
;


;----------------------------------------------------------------------------
; HDF5_error::Init
;
; Purpose:
;  Initializes the HDF5_error object.
;
FUNCTION HDF5_error::Init

    self.status = 1
    self.message = ''
    self.call_stack = STRING('', INDGEN(100))
    self.call_count = 0

    RETURN, 1
END


;----------------------------------------------------------------------------
; HDF5_error::Cleanup
;
; Purpose:
;  Cleans up all memory associated with the HDF5_error object.
;
PRO HDF5_error::Cleanup

END


;----------------------------------------------------------------------------
; HDF5_error::Handle_error
;
; Purpose:
;  Handles the error.  Currently, this means storing the details, printing the
;  message, and stopping.
;
PRO HDF5_error::Handle_error, message

    self.status = 0
    self.message = message
    self.call_stack = STRING('', INDGEN(100))

    print, '%                      ERROR'
    print, '%                      ' + message

    HELP, CALLS = callers
    self.call_count = N_ELEMENTS(callers)-1
    FOR i = 1, self.call_count DO BEGIN
         self.call_stack[i-1] = callers[i]
         print, '%                      ' + self.call_stack[i-1]
    ENDFOR

    STOP,  '%                      '
END


;----------------------------------------------------------------------------
; HDF5_error::Get_<property>
;
; Purpose:
;  This is a series of functions to return various internal properties.
;
FUNCTION HDF5_error::Get_status
    RETURN, self.status
END

FUNCTION HDF5_error::Get_message
    RETURN, self.message
END

FUNCTION HDF5_error::Get_call_stack
    IF (self.call_count EQ 0) THEN $
         RETURN, STRING('', INDGEN(0)) $
    ELSE $
         RETURN, self.call_stack[0:self.call_count-1]
END


;----------------------------------------------------------------------------
; HDF5_error__define
;
; Purpose:
;  Defines the object structure for an HDF5_error object.
;
PRO HDF5_error__define
    struct = { HDF5_error, $
               status: 1, $
               message: "", $
               call_stack: STRARR(100), $
               call_count: 0 $
             }
END







