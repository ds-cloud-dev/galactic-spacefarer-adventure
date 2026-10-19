CLASS zds1910_cl_auth_setup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zds1910_cl_auth_setup IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    "true - grant the listed activities
    "false - revoke the listed activities
    CONSTANTS lc_grant_permissions TYPE abap_bool VALUE abap_true.
*    CONSTANTS lc_grant_permissions TYPE abap_bool VALUE abap_false.

    DATA: lv_user           TYPE zds1910_t_uauth-user_name,
          lv_timestamp      TYPE timestampl,
          lv_affected       TYPE i,
          lt_activities     TYPE STANDARD TABLE OF zds1910_t_uauth-activity WITH EMPTY KEY,
          lt_authorizations TYPE STANDARD TABLE OF zds1910_t_uauth WITH EMPTY KEY.

    lv_user = cl_abap_context_info=>get_user_technical_name( ).

    IF lv_user IS INITIAL.
      out->write( 'No technical user could be determined.' ).
      RETURN.
    ENDIF.

    "01 = create, 02 = update/trading, 03 = read, 06 = delete
    lt_activities = VALUE #( ( '01' ) ( '02' ) ( '03' ) ( '06' ) ).

    "Authorization test alternatives: activate only ONE assignment
*    lt_activities = VALUE #( ( '03' ) ). "Read permission only
*    lt_activities = VALUE #( ( '02' ) ). "Update/trading permission only

    IF lc_grant_permissions = abap_true.

      GET TIME STAMP FIELD lv_timestamp.

      LOOP AT lt_activities INTO DATA(lv_activity).

        APPEND VALUE #(
          user_name  = lv_user
          activity   = lv_activity
          created_by = lv_user
          created_at = lv_timestamp
          changed_by = lv_user
          changed_at = lv_timestamp
        ) TO lt_authorizations.

      ENDLOOP.

      INSERT zds1910_t_uauth
        FROM TABLE @lt_authorizations
        ACCEPTING DUPLICATE KEYS. "Existing grants remain unchanged when setup is rerun

      lv_affected = sy-dbcnt.

      out->write( |Granted permissions: { lv_affected }| ).

    ELSE.

      LOOP AT lt_activities INTO lv_activity.

        DELETE FROM zds1910_t_uauth
          WHERE user_name = @lv_user
            AND activity  = @lv_activity.

        lv_affected = lv_affected + sy-dbcnt.

      ENDLOOP.

      out->write( |Revoked permissions: { lv_affected }| ).

    ENDIF.

    COMMIT WORK.

    SELECT activity
      FROM zds1910_t_uauth
      WHERE user_name = @lv_user
      ORDER BY activity
      INTO TABLE @DATA(lt_current_permissions).

    out->write( |Technical user: { lv_user }| ).
    out->write( 'Current permissions:' ).
    out->write( lt_current_permissions ).

  ENDMETHOD.

ENDCLASS.
