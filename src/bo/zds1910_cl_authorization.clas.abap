CLASS zds1910_cl_authorization DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_permissions,
        can_read   TYPE abap_bool,
        can_create TYPE abap_bool,
        can_update TYPE abap_bool,
        can_delete TYPE abap_bool,
      END OF ty_permissions.

    CLASS-METHODS
        get_permissions RETURNING VALUE(rs_permissions) TYPE ty_permissions.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zds1910_cl_authorization IMPLEMENTATION.

  METHOD get_permissions.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    IF lv_user IS INITIAL.
      RETURN.
    ENDIF.

    SELECT activity
      FROM zds1910_t_uauth
      WHERE user_name = @lv_user
      INTO TABLE @DATA(lt_activities).

    IF NOT line_exists( lt_activities[ activity = '03' ] ).
      RETURN.
    ENDIF.

    rs_permissions-can_read = abap_true.

    rs_permissions-can_create = xsdbool( line_exists( lt_activities[ activity = '01' ] ) ).

    rs_permissions-can_update = xsdbool( line_exists( lt_activities[ activity = '02' ] ) ).

    rs_permissions-can_delete = xsdbool( line_exists( lt_activities[ activity = '06' ] ) ).

  ENDMETHOD.

ENDCLASS.
