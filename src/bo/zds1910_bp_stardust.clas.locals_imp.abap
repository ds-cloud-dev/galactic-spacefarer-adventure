CLASS lhc_Stardust DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Stardust RESULT result.

ENDCLASS.

CLASS lhc_Stardust IMPLEMENTATION.

  METHOD get_global_authorizations.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.

      DATA(ls_permissions) = zds1910_cl_authorization=>get_permissions( ).

      result-%update = COND #( WHEN ls_permissions-can_update = abap_true
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).

    ENDIF.

  ENDMETHOD.

ENDCLASS.
