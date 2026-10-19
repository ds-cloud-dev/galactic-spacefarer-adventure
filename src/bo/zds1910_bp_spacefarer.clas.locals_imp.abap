CLASS lcl_collection_check DEFINITION FINAL.

  PUBLIC SECTION.

    TYPES: ty_owner_ids       TYPE STANDARD TABLE OF sysuuid_x16 WITH EMPTY KEY,
           ty_nonempty_owners TYPE HASHED TABLE OF sysuuid_x16 WITH UNIQUE KEY table_line.

    CLASS-METHODS
      get_nonempty_owners
        IMPORTING it_owner_ids        TYPE ty_owner_ids
        RETURNING VALUE(rt_owner_ids) TYPE ty_nonempty_owners.

ENDCLASS.


CLASS lcl_collection_check IMPLEMENTATION.

  METHOD get_nonempty_owners.

    IF it_owner_ids IS INITIAL.
      RETURN.
    ENDIF.

    SELECT DISTINCT collection_owner_id
      FROM zds1910_t_sdust
      FOR ALL ENTRIES IN @it_owner_ids
      WHERE collection_owner_id = @it_owner_ids-table_line
      INTO TABLE @rt_owner_ids.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Spacefarer DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS: get_global_authorizations FOR GLOBAL AUTHORIZATION
                REQUEST requested_authorizations FOR Spacefarer RESULT result,

             validate_deletion FOR VALIDATE ON SAVE
                IMPORTING keys FOR Spacefarer~validateDeletion,

             validate_spacefarer FOR VALIDATE ON SAVE
                IMPORTING keys FOR Spacefarer~validateSpacefarer,

             buy FOR MODIFY
                IMPORTING keys FOR ACTION Spacefarer~Buy RESULT result.

ENDCLASS.

CLASS lhc_Spacefarer IMPLEMENTATION.

  METHOD get_global_authorizations.

    DATA(ls_permissions) = zds1910_cl_authorization=>get_permissions( ).

    IF requested_authorizations-%create = if_abap_behv=>mk-on.

      result-%create = COND #(
        WHEN ls_permissions-can_create = abap_true
        THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized
      ).

    ENDIF.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.

      result-%update = COND #(
        WHEN ls_permissions-can_update = abap_true
        THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized
      ).

    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.

      result-%delete = COND #(
        WHEN ls_permissions-can_delete = abap_true
        THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized
      ).

    ENDIF.

*    "Kept for a possible switch to business-role-based authorization.
*    "The required role assignment was not available in the BTP trial setup,
*    "so the application currently checks permissions using its own table.
*    IF requested_authorizations-%create = if_abap_behv=>mk-on.
*
*      AUTHORITY-CHECK OBJECT 'ZDS1910_AO'
*        ID 'ACTVT' FIELD '01'.
*
*      result-%create = COND #(
*        WHEN sy-subrc = 0
*        THEN if_abap_behv=>auth-allowed
*        ELSE if_abap_behv=>auth-unauthorized
*      ).
*
*    ENDIF.
*
*    IF requested_authorizations-%update = if_abap_behv=>mk-on.
*
*      AUTHORITY-CHECK OBJECT 'ZDS1910_AO'
*        ID 'ACTVT' FIELD '02'.
*
*      result-%update = COND #(
*        WHEN sy-subrc = 0
*        THEN if_abap_behv=>auth-allowed
*        ELSE if_abap_behv=>auth-unauthorized
*      ).
*
*    ENDIF.
*
*    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
*
*      AUTHORITY-CHECK OBJECT 'ZDS1910_AO'
*        ID 'ACTVT' FIELD '06'.
*
*      result-%delete = COND #(
*        WHEN sy-subrc = 0
*        THEN if_abap_behv=>auth-allowed
*        ELSE if_abap_behv=>auth-unauthorized
*      ).
*
*    ENDIF.

  ENDMETHOD.


  METHOD validate_deletion.

    DATA(lt_nonempty_owners) = lcl_collection_check=>get_nonempty_owners( VALUE #( FOR ls_key IN keys ( ls_key-SpacefarerId ) ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      IF NOT line_exists( lt_nonempty_owners[ table_line = <ls_key>-SpacefarerId ] ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-spacefarer.

      APPEND VALUE #(
        %tky = <ls_key>-%tky
        %msg = new_message(
          id       = 'ZDS1910_MSG_GAP'
          number   = '008'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-spacefarer.

    ENDLOOP.

  ENDMETHOD.


  METHOD validate_spacefarer.

    DATA: lv_message_number TYPE symsgno,
          ls_reported       LIKE LINE OF reported-spacefarer.

    READ ENTITIES OF zds1910_i_spacefarer IN LOCAL MODE
      ENTITY Spacefarer
        FIELDS (
          Name
          NavigationSkill
          Reputation
          OriginPlanet
          SpacesuitColor
          Credits
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_spacefarers)
        FAILED DATA(ls_read_failed)
        REPORTED DATA(ls_read_reported).

    failed-spacefarer = CORRESPONDING #( BASE ( failed-spacefarer ) ls_read_failed-spacefarer ).
    reported-spacefarer = CORRESPONDING #( BASE ( reported-spacefarer ) ls_read_reported-spacefarer ).


    LOOP AT lt_spacefarers INTO DATA(ls_spacefarer).

      CLEAR: lv_message_number,
             ls_reported.

      ls_reported-%tky = ls_spacefarer-%tky.

      IF ls_spacefarer-Name IS INITIAL.

        lv_message_number = '001'.
        ls_reported-%element-Name = if_abap_behv=>mk-on.

      ELSEIF ls_spacefarer-OriginPlanet IS INITIAL.

        lv_message_number = '002'.
        ls_reported-%element-OriginPlanet = if_abap_behv=>mk-on.

      ELSEIF ls_spacefarer-SpacesuitColor IS INITIAL.

        lv_message_number = '003'.
        ls_reported-%element-SpacesuitColor = if_abap_behv=>mk-on.

      ELSEIF ls_spacefarer-NavigationSkill < 0
          OR ls_spacefarer-NavigationSkill > 98.

        lv_message_number = '004'.
        ls_reported-%element-NavigationSkill = if_abap_behv=>mk-on.

      ELSEIF ls_spacefarer-Reputation < 0
          OR ls_spacefarer-Reputation > 98.

        lv_message_number = '005'.
        ls_reported-%element-Reputation = if_abap_behv=>mk-on.

      ELSEIF ls_spacefarer-NavigationSkill
           + ls_spacefarer-Reputation >= 99.

        lv_message_number = '006'.
        ls_reported-%element-NavigationSkill = if_abap_behv=>mk-on.
        ls_reported-%element-Reputation = if_abap_behv=>mk-on.

      ELSEIF ls_spacefarer-Credits < 0.

        lv_message_number = '007'.
        ls_reported-%element-Credits = if_abap_behv=>mk-on.

      ENDIF.

      IF lv_message_number IS INITIAL.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky = ls_spacefarer-%tky ) TO failed-spacefarer.

      ls_reported-%msg = new_message( id       = 'ZDS1910_MSG_GAP'
                                      number   = lv_message_number
                                      severity = if_abap_behv_message=>severity-error ).

      APPEND ls_reported TO reported-spacefarer.

    ENDLOOP.

  ENDMETHOD.


  METHOD buy.

    DATA: lv_error_found TYPE abap_bool,
          lv_severity    TYPE if_abap_behv_message=>t_severity,
          ls_trade       TYPE zds1910_if_trading=>ty_result,
          lo_trading     TYPE REF TO zds1910_if_trading.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    IF lines( keys ) <> 1.

      LOOP AT keys INTO DATA(ls_rejected_key).
        APPEND VALUE #( %tky = ls_rejected_key-%tky
                        %action-Buy = if_abap_behv=>mk-on
                        %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-spacefarer.

        APPEND VALUE #( %tky = ls_rejected_key-%tky
                        %op-%action-Buy = if_abap_behv=>mk-on
                        %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                            number = '016'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'Execute Buy for one spacefarer at a time.' ) ) TO reported-spacefarer.
      ENDLOOP.

      RETURN.

    ENDIF.

    DATA(ls_key) = keys[ 1 ].

    READ ENTITIES OF zds1910_i_spacefarer IN LOCAL MODE
      ENTITY Spacefarer
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_spacefarers)
        FAILED DATA(ls_read_failed).

    IF ls_read_failed IS NOT INITIAL OR lt_spacefarers IS INITIAL.

      APPEND VALUE #( %tky = ls_key-%tky
                      %action-Buy = if_abap_behv=>mk-on
                      %fail-cause = if_abap_behv=>cause-not_found ) TO failed-spacefarer.

      APPEND VALUE #( %tky = ls_key-%tky
                      %op-%action-Buy = if_abap_behv=>mk-on
                      %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                          number = '016'
                                          severity = if_abap_behv_message=>severity-error
                                          v1 = 'The buyer spacefarer could not be read.' ) ) TO reported-spacefarer.
      RETURN.

    ENDIF.

    lo_trading = NEW zds1910_cl_trading( ).
    ls_trade = lo_trading->buy( iv_buyer_id = ls_key-SpacefarerId
                               iv_seller_id = ls_key-%param-SellerId
                               iv_stardust_id = ls_key-%param-StardustId ).

    LOOP AT ls_trade-messages INTO DATA(ls_message).

      lv_severity = SWITCH #( ls_message-severity WHEN zds1910_if_trading=>gc_severity_success THEN if_abap_behv_message=>severity-success
                                                  WHEN zds1910_if_trading=>gc_severity_warning THEN if_abap_behv_message=>severity-warning
                                                  WHEN zds1910_if_trading=>gc_severity_info THEN if_abap_behv_message=>severity-information
                                                  ELSE if_abap_behv_message=>severity-error ).

      IF lv_severity = if_abap_behv_message=>severity-error.
        lv_error_found = abap_true.
      ENDIF.

      APPEND VALUE #( %tky = ls_key-%tky
                      %op-%action-Buy = if_abap_behv=>mk-on
                      %msg = new_message( id = ls_message-message_id
                                          number = ls_message-message_number
                                          severity = lv_severity
                                          v1 = ls_message-message_v1
                                          v2 = ls_message-message_v2
                                          v3 = ls_message-message_v3
                                          v4 = ls_message-message_v4 ) ) TO reported-spacefarer.

    ENDLOOP.

    IF ls_trade-success = abap_false OR lv_error_found = abap_true.

      APPEND VALUE #( %tky = ls_key-%tky
                      %action-Buy = if_abap_behv=>mk-on
                      %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-spacefarer.

      IF lv_error_found = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky
                        %op-%action-Buy = if_abap_behv=>mk-on
                        %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                            number = '016'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'The purchase could not be completed.' ) ) TO reported-spacefarer.
      ENDIF.
      RETURN.

    ENDIF.

    result = VALUE #( ( %tky = ls_key-%tky %param = lt_spacefarers[ 1 ] ) ).


  ENDMETHOD.

ENDCLASS.


CLASS lhc_Collection DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS: validate_deletion FOR VALIDATE ON SAVE
              IMPORTING keys FOR Collection~validateDeletion,

             buy FOR MODIFY
              IMPORTING keys FOR ACTION Collection~Buy RESULT result,

             sell FOR MODIFY
              IMPORTING keys FOR ACTION Collection~Sell RESULT result,

             get_defaults_for_sell FOR READ
              IMPORTING keys FOR FUNCTION Collection~GetDefaultsForSell RESULT result,

             exchange FOR MODIFY
              IMPORTING keys FOR ACTION Collection~Exchange RESULT result,

             get_defaults_for_exchange FOR READ
              IMPORTING keys FOR FUNCTION Collection~GetDefaultsForExchange RESULT result.

ENDCLASS.


CLASS lhc_Collection IMPLEMENTATION.

  METHOD validate_deletion.

    DATA(lt_nonempty_owners) = lcl_collection_check=>get_nonempty_owners( VALUE #( FOR ls_key IN keys ( ls_key-SpacefarerId ) ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      IF NOT line_exists( lt_nonempty_owners[ table_line = <ls_key>-SpacefarerId ] ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-collection.

      APPEND VALUE #( %tky     = <ls_key>-%tky
                      %msg     = new_message(
                      id       = 'ZDS1910_MSG_GAP'
                      number   = '008'
                      severity = if_abap_behv_message=>severity-error ) ) TO reported-collection.

    ENDLOOP.

  ENDMETHOD.

  METHOD buy.

    DATA: lv_error_found TYPE abap_bool,
          lv_severity    TYPE if_abap_behv_message=>t_severity,
          ls_trade       TYPE zds1910_if_trading=>ty_result,
          lo_trading     TYPE REF TO zds1910_if_trading.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    IF lines( keys ) <> 1.
      LOOP AT keys INTO DATA(ls_rejected_key).
        APPEND VALUE #( %tky = ls_rejected_key-%tky
                        %action-Buy = if_abap_behv=>mk-on
                        %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-collection.

        APPEND VALUE #( %tky = ls_rejected_key-%tky
                        %op-%action-Buy = if_abap_behv=>mk-on
                        %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                            number = '016'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'Execute Buy for one collection at a time.' ) ) TO reported-collection.
      ENDLOOP.
      RETURN.
    ENDIF.

    DATA(ls_key) = keys[ 1 ].

    READ ENTITIES OF zds1910_i_spacefarer IN LOCAL MODE
      ENTITY Collection
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_collections)
        FAILED DATA(ls_read_failed).

    IF ls_read_failed IS NOT INITIAL OR lt_collections IS INITIAL.
      APPEND VALUE #( %tky = ls_key-%tky
                      %action-Buy = if_abap_behv=>mk-on
                      %fail-cause = if_abap_behv=>cause-not_found ) TO failed-collection.

      APPEND VALUE #( %tky = ls_key-%tky
                      %op-%action-Buy = if_abap_behv=>mk-on
                      %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                          number = '016'
                                          severity = if_abap_behv_message=>severity-error
                                          v1 = 'The buyer collection could not be read.' ) ) TO reported-collection.
      RETURN.
    ENDIF.

    lo_trading = NEW zds1910_cl_trading( ).
    ls_trade = lo_trading->buy( iv_buyer_id = ls_key-SpacefarerId
                               iv_seller_id = ls_key-%param-SellerId
                               iv_stardust_id = ls_key-%param-StardustId ).

    LOOP AT ls_trade-messages INTO DATA(ls_message).
      lv_severity = SWITCH #( ls_message-severity
        WHEN zds1910_if_trading=>gc_severity_success THEN if_abap_behv_message=>severity-success
        WHEN zds1910_if_trading=>gc_severity_warning THEN if_abap_behv_message=>severity-warning
        WHEN zds1910_if_trading=>gc_severity_info THEN if_abap_behv_message=>severity-information
        ELSE if_abap_behv_message=>severity-error ).

      IF lv_severity = if_abap_behv_message=>severity-error.
        lv_error_found = abap_true.
      ENDIF.

      APPEND VALUE #( %tky = ls_key-%tky
                      %op-%action-Buy = if_abap_behv=>mk-on
                      %msg = new_message( id = ls_message-message_id
                                          number = ls_message-message_number
                                          severity = lv_severity
                                          v1 = ls_message-message_v1
                                          v2 = ls_message-message_v2
                                          v3 = ls_message-message_v3
                                          v4 = ls_message-message_v4 ) ) TO reported-collection.
    ENDLOOP.

    IF ls_trade-success = abap_false OR lv_error_found = abap_true.
      APPEND VALUE #( %tky = ls_key-%tky
                      %action-Buy = if_abap_behv=>mk-on
                      %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-collection.

      IF lv_error_found = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky
                        %op-%action-Buy = if_abap_behv=>mk-on
                        %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                            number = '016'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'The purchase could not be completed.' ) ) TO reported-collection.
      ENDIF.
      RETURN.
    ENDIF.

    result = VALUE #( ( %tky = ls_key-%tky %param = lt_collections[ 1 ] ) ).

  ENDMETHOD.

  METHOD sell.

    DATA: lv_severity    TYPE if_abap_behv_message=>t_severity,
          lv_error_found TYPE abap_bool,
          ls_trade       TYPE zds1910_if_trading=>ty_result,
          lo_trading     TYPE REF TO zds1910_if_trading.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    IF lines( keys ) <> 1.

      LOOP AT keys INTO DATA(ls_rejected_key).
        APPEND VALUE #( %tky = ls_rejected_key-%tky
                        %action-Sell = if_abap_behv=>mk-on
                        %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-collection.

        APPEND VALUE #( %tky = ls_rejected_key-%tky
                        %op-%action-Sell = if_abap_behv=>mk-on
                        %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                            number = '016'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'Execute Sell for one collection at a time.' ) ) TO reported-collection.
      ENDLOOP.

      RETURN.

    ENDIF.

    DATA(ls_key) = keys[ 1 ].

    READ ENTITIES OF zds1910_i_spacefarer IN LOCAL MODE
      ENTITY Collection
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_collections)
        FAILED DATA(ls_read_failed).

    IF ls_read_failed IS NOT INITIAL OR lt_collections IS INITIAL.

      APPEND VALUE #( %tky = ls_key-%tky
                      %action-Sell = if_abap_behv=>mk-on
                      %fail-cause = if_abap_behv=>cause-not_found ) TO failed-collection.

      APPEND VALUE #( %tky = ls_key-%tky
                      %op-%action-Sell = if_abap_behv=>mk-on
                      %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                          number = '016'
                                          severity = if_abap_behv_message=>severity-error
                                          v1 = 'The seller collection could not be read.' ) ) TO reported-collection.
      RETURN.

    ENDIF.

    lo_trading = NEW zds1910_cl_trading( ).
    ls_trade = lo_trading->sell( iv_buyer_id = ls_key-%param-BuyerId
                               iv_seller_id = ls_key-SpacefarerId
                               iv_stardust_id = ls_key-%param-StardustId ).

    LOOP AT ls_trade-messages INTO DATA(ls_message).

      lv_severity = SWITCH #( ls_message-severity WHEN zds1910_if_trading=>gc_severity_success THEN if_abap_behv_message=>severity-success
                                                  WHEN zds1910_if_trading=>gc_severity_warning THEN if_abap_behv_message=>severity-warning
                                                  WHEN zds1910_if_trading=>gc_severity_info THEN if_abap_behv_message=>severity-information
                                                  ELSE if_abap_behv_message=>severity-error ).

      IF lv_severity = if_abap_behv_message=>severity-error.
        lv_error_found = abap_true.
      ENDIF.

      APPEND VALUE #( %tky = ls_key-%tky
                      %op-%action-Sell = if_abap_behv=>mk-on
                      %msg = new_message( id = ls_message-message_id
                                          number = ls_message-message_number
                                          severity = lv_severity
                                          v1 = ls_message-message_v1
                                          v2 = ls_message-message_v2
                                          v3 = ls_message-message_v3
                                          v4 = ls_message-message_v4 ) ) TO reported-collection.

    ENDLOOP.

    IF ls_trade-success = abap_false OR lv_error_found = abap_true.

      APPEND VALUE #( %tky = ls_key-%tky
                      %action-Sell = if_abap_behv=>mk-on
                      %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-collection.

      IF lv_error_found = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky
                        %op-%action-Sell = if_abap_behv=>mk-on
                        %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                            number = '016'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'The sale could not be completed.' ) ) TO reported-collection.
      ENDIF.

      RETURN.

    ENDIF.

    result = VALUE #( ( %tky = ls_key-%tky %param = lt_collections[ 1 ] ) ).

  ENDMETHOD.

  METHOD get_defaults_for_sell.

    READ ENTITIES OF zds1910_i_spacefarer IN LOCAL MODE
      ENTITY Collection
        FIELDS ( SpacefarerId ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_collections)
        FAILED failed
        REPORTED reported.

    result = VALUE #( FOR ls_collection IN lt_collections
                      ( %tky = ls_collection-%tky
                        %param-SellerId = ls_collection-SpacefarerId ) ).

  ENDMETHOD.

  METHOD exchange.

    DATA: lv_error_found TYPE abap_bool,
          lv_severity    TYPE if_abap_behv_message=>t_severity,
          ls_trade       TYPE zds1910_if_trading=>ty_result,
          lo_trading     TYPE REF TO zds1910_if_trading.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    IF lines( keys ) <> 1.

      LOOP AT keys INTO DATA(ls_rejected_key).
        APPEND VALUE #( %tky = ls_rejected_key-%tky
                        %action-Exchange = if_abap_behv=>mk-on
                        %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-collection.

        APPEND VALUE #( %tky = ls_rejected_key-%tky
                        %op-%action-Exchange = if_abap_behv=>mk-on
                        %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                            number = '016'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'Execute Exchange for one collection at a time.' ) ) TO reported-collection.
      ENDLOOP.

      RETURN.

    ENDIF.

    DATA(ls_key) = keys[ 1 ].

    READ ENTITIES OF zds1910_i_spacefarer IN LOCAL MODE
      ENTITY Collection
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_collections)
        FAILED DATA(ls_read_failed).

    IF ls_read_failed IS NOT INITIAL OR lt_collections IS INITIAL.

      APPEND VALUE #( %tky = ls_key-%tky
                      %action-Exchange = if_abap_behv=>mk-on
                      %fail-cause = if_abap_behv=>cause-not_found ) TO failed-collection.

      APPEND VALUE #( %tky = ls_key-%tky
                      %op-%action-Exchange = if_abap_behv=>mk-on
                      %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                          number = '016'
                                          severity = if_abap_behv_message=>severity-error
                                          v1 = 'The selected collection could not be read.' ) ) TO reported-collection.
      RETURN.

    ENDIF.

    lo_trading = NEW zds1910_cl_trading( ).
    ls_trade = lo_trading->exchange( iv_first_spacefarer_id = ls_key-SpacefarerId
                                     iv_second_spacefarer_id = ls_key-%param-CounterpartyId
                                     iv_first_stardust_id = ls_key-%param-OwnStardustId
                                     iv_second_stardust_id = ls_key-%param-CounterpartyStardustId ).

    LOOP AT ls_trade-messages INTO DATA(ls_message).

      lv_severity = SWITCH #( ls_message-severity WHEN zds1910_if_trading=>gc_severity_success THEN if_abap_behv_message=>severity-success
                                                  WHEN zds1910_if_trading=>gc_severity_warning THEN if_abap_behv_message=>severity-warning
                                                  WHEN zds1910_if_trading=>gc_severity_info THEN if_abap_behv_message=>severity-information
                                                  ELSE if_abap_behv_message=>severity-error ).

      IF lv_severity = if_abap_behv_message=>severity-error.
        lv_error_found = abap_true.
      ENDIF.

      APPEND VALUE #( %tky = ls_key-%tky
                      %op-%action-Exchange = if_abap_behv=>mk-on
                      %msg = new_message( id = ls_message-message_id
                                          number = ls_message-message_number
                                          severity = lv_severity
                                          v1 = ls_message-message_v1
                                          v2 = ls_message-message_v2
                                          v3 = ls_message-message_v3
                                          v4 = ls_message-message_v4 ) ) TO reported-collection.

    ENDLOOP.

    IF ls_trade-success = abap_false OR lv_error_found = abap_true.

      APPEND VALUE #( %tky = ls_key-%tky
                      %action-Exchange = if_abap_behv=>mk-on
                      %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-collection.

      IF lv_error_found = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky
                        %op-%action-Exchange = if_abap_behv=>mk-on
                        %msg = new_message( id = 'ZDS1910_MSG_GAP'
                                            number = '016'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'The exchange could not be completed.' ) ) TO reported-collection.
      ENDIF.

      RETURN.

    ENDIF.

    result = VALUE #( ( %tky = ls_key-%tky %param = lt_collections[ 1 ] ) ).

  ENDMETHOD.


  METHOD get_defaults_for_exchange.

    READ ENTITIES OF zds1910_i_spacefarer IN LOCAL MODE
  ENTITY Collection
    FIELDS ( SpacefarerId ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_collections)
    FAILED failed
    REPORTED reported.

    result = VALUE #( FOR ls_collection IN lt_collections
                      ( %tky = ls_collection-%tky
                        %param-FirstOwnerId = ls_collection-SpacefarerId ) ).

  ENDMETHOD.

ENDCLASS.
