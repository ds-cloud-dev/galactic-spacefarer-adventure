CLASS zds1910_cl_trading DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zds1910_if_trading.

  PRIVATE SECTION.

    TYPES: ty_spacefarer_id TYPE zds1910_if_trading=>ty_spacefarer_id,
           ty_stardust_id   TYPE zds1910_if_trading=>ty_stardust_id,
           ty_result        TYPE zds1910_if_trading=>ty_result,
           tt_message       TYPE zds1910_if_trading=>tt_message,
           ty_sf_reported   TYPE RESPONSE FOR REPORTED EARLY zds1910_i_spacefarer,
           ty_sd_reported   TYPE RESPONSE FOR REPORTED EARLY zds1910_i_stardust.

    METHODS:
      transfer
        IMPORTING iv_buyer_id      TYPE ty_spacefarer_id
                  iv_seller_id     TYPE ty_spacefarer_id
                  iv_stardust_id   TYPE ty_stardust_id
        RETURNING VALUE(rs_result) TYPE ty_result,

      exchange_stardusts
        IMPORTING iv_first_spacefarer_id  TYPE ty_spacefarer_id
                  iv_second_spacefarer_id TYPE ty_spacefarer_id
                  iv_first_stardust_id    TYPE ty_stardust_id
                  iv_second_stardust_id   TYPE ty_stardust_id
        RETURNING VALUE(rs_result)        TYPE ty_result.

    CLASS-METHODS:
      error
        IMPORTING iv_number        TYPE symsgno
                  iv_v1            TYPE symsgv OPTIONAL
        RETURNING VALUE(rs_result) TYPE ty_result,

      spacefarer_failure
        IMPORTING is_reported      TYPE ty_sf_reported
                  iv_number        TYPE symsgno
                  iv_v1            TYPE symsgv OPTIONAL
        RETURNING VALUE(rs_result) TYPE ty_result,

      stardust_failure
        IMPORTING is_reported      TYPE ty_sd_reported
                  iv_number        TYPE symsgno
                  iv_v1            TYPE symsgv OPTIONAL
        RETURNING VALUE(rs_result) TYPE ty_result,

      append_rap_message
        IMPORTING io_message  TYPE REF TO if_abap_behv_message
        CHANGING  ct_messages TYPE tt_message.

ENDCLASS.


CLASS zds1910_cl_trading IMPLEMENTATION.

  METHOD zds1910_if_trading~buy.

    rs_result = transfer( iv_buyer_id = iv_buyer_id
                          iv_seller_id = iv_seller_id
                          iv_stardust_id = iv_stardust_id ).

  ENDMETHOD.


  METHOD zds1910_if_trading~sell.

    rs_result = transfer( iv_buyer_id = iv_buyer_id
                          iv_seller_id = iv_seller_id
                          iv_stardust_id = iv_stardust_id ).

  ENDMETHOD.


  METHOD zds1910_if_trading~exchange.

    rs_result = exchange_stardusts( iv_first_spacefarer_id = iv_first_spacefarer_id
                                    iv_second_spacefarer_id = iv_second_spacefarer_id
                                    iv_first_stardust_id = iv_first_stardust_id
                                    iv_second_stardust_id = iv_second_stardust_id ).

  ENDMETHOD.


  METHOD transfer.

    CONSTANTS: lc_max_amount TYPE decfloat34 VALUE '9999999999999.99'.

    DATA: ls_permissions    TYPE zds1910_cl_authorization=>ty_permissions,
          lt_spacefarer_ids TYPE SORTED TABLE OF ty_spacefarer_id WITH UNIQUE KEY table_line,
          lv_spacefarer_id  TYPE ty_spacefarer_id,
          lt_spacefarers    TYPE TABLE FOR READ RESULT zds1910_i_spacefarer,
          ls_buyer          LIKE LINE OF lt_spacefarers,
          ls_seller         LIKE LINE OF lt_spacefarers,
          lt_stardusts      TYPE TABLE FOR READ RESULT zds1910_i_stardust,
          ls_stardust       LIKE LINE OF lt_stardusts,
          lt_collections    TYPE TABLE FOR READ RESULT zds1910_i_collection,
          ls_sf_failed      TYPE RESPONSE FOR FAILED EARLY zds1910_i_spacefarer,
          ls_sf_reported    TYPE ty_sf_reported,
          ls_sd_failed      TYPE RESPONSE FOR FAILED EARLY zds1910_i_stardust,
          ls_sd_reported    TYPE ty_sd_reported,
          ls_price_result   TYPE ty_result,
          lv_price          TYPE decfloat34,
          lv_buyer_credits  TYPE decfloat34,
          lv_seller_credits TYPE decfloat34,
          lv_message_number TYPE symsgno.

    ls_permissions = zds1910_cl_authorization=>get_permissions( ).

    IF ls_permissions-can_update = abap_false.
      rs_result = error( iv_number = '009' ).
      RETURN.
    ENDIF.

    IF iv_buyer_id IS INITIAL OR iv_seller_id IS INITIAL OR iv_buyer_id = iv_seller_id.
      rs_result = error( iv_number = '012' ).
      RETURN.
    ENDIF.

    IF iv_stardust_id IS INITIAL.
      rs_result = error( iv_number = '020' ).
      RETURN.
    ENDIF.

    lt_spacefarer_ids = VALUE #( ( iv_buyer_id ) ( iv_seller_id ) ).

    LOOP AT lt_spacefarer_ids INTO lv_spacefarer_id.

      CLEAR: ls_sf_failed, ls_sf_reported.

      SET LOCKS OF zds1910_i_spacefarer
        ENTITY Spacefarer
        FROM VALUE #( ( SpacefarerId = lv_spacefarer_id ) )
        FAILED ls_sf_failed
        REPORTED ls_sf_reported.

      IF ls_sf_failed IS NOT INITIAL.

        lv_message_number = '015'.

        IF ls_sf_failed-spacefarer IS NOT INITIAL.
          IF ls_sf_failed-spacefarer[ 1 ]-%fail-cause = if_abap_behv=>cause-not_found.
            lv_message_number = '010'.
          ENDIF.
        ENDIF.

        rs_result = spacefarer_failure( is_reported = ls_sf_reported
                                         iv_number = lv_message_number
                                         iv_v1 = CONV #( lv_spacefarer_id ) ).
        RETURN.

      ENDIF.

    ENDLOOP.

    CLEAR: ls_sd_failed, ls_sd_reported.

    SET LOCKS OF zds1910_i_stardust
      ENTITY Stardust
      FROM VALUE #( ( StardustId = iv_stardust_id ) )
      FAILED ls_sd_failed
      REPORTED ls_sd_reported.

    IF ls_sd_failed IS NOT INITIAL.

      lv_message_number = '015'.

      IF ls_sd_failed-stardust IS NOT INITIAL.
        IF ls_sd_failed-stardust[ 1 ]-%fail-cause = if_abap_behv=>cause-not_found.
          lv_message_number = '011'.
        ENDIF.
      ENDIF.

      rs_result = stardust_failure( is_reported = ls_sd_reported
                                    iv_number = lv_message_number
                                    iv_v1 = CONV #( iv_stardust_id ) ).
      RETURN.

    ENDIF.

    CLEAR: ls_sf_failed, ls_sf_reported.

    READ ENTITIES OF zds1910_i_spacefarer
      ENTITY Spacefarer
      FIELDS ( Credits Reputation )
      WITH VALUE #( ( SpacefarerId = iv_buyer_id ) ( SpacefarerId = iv_seller_id ) )
      RESULT lt_spacefarers
      FAILED ls_sf_failed
      REPORTED ls_sf_reported.

    IF ls_sf_failed IS NOT INITIAL.
      rs_result = spacefarer_failure( is_reported = ls_sf_reported
                                      iv_number = '016'
                                      iv_v1 = 'Reading the trading Spacefarers.' ).
      RETURN.
    ENDIF.

    READ TABLE lt_spacefarers INTO ls_buyer WITH KEY id COMPONENTS SpacefarerId = iv_buyer_id.

    IF sy-subrc <> 0.
      rs_result = error( iv_number = '010' iv_v1 = CONV #( iv_buyer_id ) ).
      RETURN.
    ENDIF.

    READ TABLE lt_spacefarers INTO ls_seller WITH KEY id COMPONENTS SpacefarerId = iv_seller_id.

    IF sy-subrc <> 0.
      rs_result = error( iv_number = '010' iv_v1 = CONV #( iv_seller_id ) ).
      RETURN.
    ENDIF.

    CLEAR: ls_sd_failed, ls_sd_reported.

    READ ENTITIES OF zds1910_i_stardust
      ENTITY Stardust
      FIELDS ( CollectionOwnerId StardustValue )
      WITH VALUE #( ( StardustId = iv_stardust_id ) )
      RESULT lt_stardusts
      FAILED ls_sd_failed
      REPORTED ls_sd_reported.

    IF ls_sd_failed IS NOT INITIAL.
      rs_result = stardust_failure( is_reported = ls_sd_reported
                                    iv_number = '016'
                                    iv_v1 = 'Reading the traded Stardust.' ).
      RETURN.
    ENDIF.

    READ TABLE lt_stardusts INTO ls_stardust INDEX 1.

    IF sy-subrc <> 0.
      rs_result = error( iv_number = '011' iv_v1 = CONV #( iv_stardust_id ) ).
      RETURN.
    ENDIF.

    IF ls_stardust-CollectionOwnerId <> iv_seller_id.
      rs_result = error( iv_number = '013' ).
      RETURN.
    ENDIF.

    zds1910_cl_trade_pricing=>calculate(
                                         EXPORTING iv_base_value        = ls_stardust-StardustValue
                                                   iv_buyer_reputation  = ls_buyer-Reputation
                                                   iv_seller_reputation = ls_seller-Reputation
                                         IMPORTING ev_price             = lv_price
                                                   es_result            = ls_price_result
                                        ).

    IF ls_price_result-success = abap_false.
      rs_result = ls_price_result.
      RETURN.
    ENDIF.

    IF ls_buyer-Credits < lv_price.
      rs_result = error( iv_number = '014' ).
      RETURN.
    ENDIF.

    lv_buyer_credits = CONV decfloat34( ls_buyer-Credits ) - lv_price.
    lv_seller_credits = CONV decfloat34( ls_seller-Credits ) + lv_price.

    IF lv_buyer_credits < 0 OR lv_seller_credits < 0 OR lv_seller_credits > lc_max_amount.
      rs_result = error( iv_number = '019' ).
      RETURN.
    ENDIF.

    CLEAR: ls_sf_failed, ls_sf_reported.

    READ ENTITIES OF zds1910_i_spacefarer
      ENTITY Spacefarer BY \_Collection
      FIELDS ( SpacefarerId )
      WITH VALUE #( ( SpacefarerId = iv_buyer_id ) )
      RESULT lt_collections
      FAILED ls_sf_failed
      REPORTED ls_sf_reported.

    IF ls_sf_failed IS NOT INITIAL.
      rs_result = spacefarer_failure( is_reported = ls_sf_reported
                                       iv_number = '016'
                                       iv_v1 = 'Reading the buyer collection.' ).
      RETURN.
    ENDIF.

    IF lt_collections IS INITIAL.

      CLEAR: ls_sf_failed, ls_sf_reported.

      MODIFY ENTITIES OF zds1910_i_spacefarer
        ENTITY Spacefarer
        CREATE BY \_Collection FROM VALUE #(
          ( SpacefarerId = iv_buyer_id
            %target = VALUE #( ( %cid = 'TRADE_COLLECTION' ) ) )
        )
        FAILED ls_sf_failed
        REPORTED ls_sf_reported.

      IF ls_sf_failed IS NOT INITIAL.
        rs_result = spacefarer_failure( is_reported = ls_sf_reported
                                         iv_number = '016'
                                         iv_v1 = 'Creating the buyer collection.' ).
        RETURN.
      ENDIF.

    ENDIF.

    CLEAR: ls_sf_failed, ls_sf_reported.

    MODIFY ENTITIES OF zds1910_i_spacefarer
      ENTITY Spacefarer
      UPDATE FIELDS ( Credits ) WITH VALUE #( ( SpacefarerId = iv_buyer_id Credits = CONV #( lv_buyer_credits ) )
                                              ( SpacefarerId = iv_seller_id Credits = CONV #( lv_seller_credits ) ) )
      FAILED ls_sf_failed
      REPORTED ls_sf_reported.

    IF ls_sf_failed IS NOT INITIAL.
      rs_result = spacefarer_failure( is_reported = ls_sf_reported
                                      iv_number = '016'
                                      iv_v1 = 'Updating the credit balances.' ).
      RETURN.
    ENDIF.

    CLEAR: ls_sd_failed, ls_sd_reported.

    MODIFY ENTITIES OF zds1910_i_stardust
      ENTITY Stardust
      UPDATE FIELDS ( CollectionOwnerId ) WITH VALUE #(
        ( StardustId = iv_stardust_id CollectionOwnerId = iv_buyer_id ) )
      FAILED ls_sd_failed
      REPORTED ls_sd_reported.

    IF ls_sd_failed IS NOT INITIAL.
      rs_result = stardust_failure( is_reported = ls_sd_reported
                                    iv_number = '016'
                                    iv_v1 = 'Transferring Stardust ownership.' ).
      RETURN.
    ENDIF.

    rs_result-success = abap_true.

  ENDMETHOD.


  METHOD exchange_stardusts.

    DATA: ls_permissions     TYPE zds1910_cl_authorization=>ty_permissions,
          lt_spacefarer_ids  TYPE SORTED TABLE OF ty_spacefarer_id WITH UNIQUE KEY table_line,
          lt_stardust_ids    TYPE SORTED TABLE OF ty_stardust_id WITH UNIQUE KEY table_line,
          lv_spacefarer_id   TYPE ty_spacefarer_id,
          lv_stardust_id     TYPE ty_stardust_id,
          lt_spacefarers     TYPE TABLE FOR READ RESULT zds1910_i_spacefarer,
          lt_collections     TYPE TABLE FOR READ RESULT zds1910_i_collection,
          lt_stardusts       TYPE TABLE FOR READ RESULT zds1910_i_stardust,
          ls_first_stardust  LIKE LINE OF lt_stardusts,
          ls_second_stardust LIKE LINE OF lt_stardusts,
          ls_sf_failed       TYPE RESPONSE FOR FAILED EARLY zds1910_i_spacefarer,
          ls_sf_reported     TYPE ty_sf_reported,
          ls_sd_failed       TYPE RESPONSE FOR FAILED EARLY zds1910_i_stardust,
          ls_sd_reported     TYPE ty_sd_reported,
          lv_message_number  TYPE symsgno.

    ls_permissions = zds1910_cl_authorization=>get_permissions( ).

    IF ls_permissions-can_update = abap_false.
      rs_result = error( iv_number = '009' ).
      RETURN.
    ENDIF.

    IF iv_first_spacefarer_id IS INITIAL
       OR iv_second_spacefarer_id IS INITIAL
       OR iv_first_spacefarer_id = iv_second_spacefarer_id.
      rs_result = error( iv_number = '012' ).
      RETURN.
    ENDIF.

    IF iv_first_stardust_id IS INITIAL OR iv_second_stardust_id IS INITIAL.
      rs_result = error( iv_number = '020' ).
      RETURN.
    ENDIF.

    IF iv_first_stardust_id = iv_second_stardust_id.
      rs_result = error( iv_number = '021' ).
      RETURN.
    ENDIF.

    lt_spacefarer_ids = VALUE #( ( iv_first_spacefarer_id ) ( iv_second_spacefarer_id ) ).
    lt_stardust_ids = VALUE #( ( iv_first_stardust_id ) ( iv_second_stardust_id ) ).

    ""We use the same lock hierarchy as buy/sell -> Spacefarers first, then Stardusts.
    LOOP AT lt_spacefarer_ids INTO lv_spacefarer_id.

      CLEAR: ls_sf_failed, ls_sf_reported.

      SET LOCKS OF zds1910_i_spacefarer
        ENTITY Spacefarer
        FROM VALUE #( ( SpacefarerId = lv_spacefarer_id ) )
        FAILED ls_sf_failed
        REPORTED ls_sf_reported.

      IF ls_sf_failed IS NOT INITIAL.

        lv_message_number = '015'.

        IF ls_sf_failed-spacefarer IS NOT INITIAL.
          IF ls_sf_failed-spacefarer[ 1 ]-%fail-cause = if_abap_behv=>cause-not_found.
            lv_message_number = '010'.
          ENDIF.
        ENDIF.

        rs_result = spacefarer_failure( is_reported = ls_sf_reported
                                       iv_number = lv_message_number
                                       iv_v1 = CONV #( lv_spacefarer_id ) ).
        RETURN.

      ENDIF.

    ENDLOOP.

    LOOP AT lt_stardust_ids INTO lv_stardust_id.

      CLEAR: ls_sd_failed, ls_sd_reported.

      SET LOCKS OF zds1910_i_stardust
        ENTITY Stardust
        FROM VALUE #( ( StardustId = lv_stardust_id ) )
        FAILED ls_sd_failed
        REPORTED ls_sd_reported.

      IF ls_sd_failed IS NOT INITIAL.

        lv_message_number = '015'.

        IF ls_sd_failed-stardust IS NOT INITIAL.
          IF ls_sd_failed-stardust[ 1 ]-%fail-cause = if_abap_behv=>cause-not_found.
            lv_message_number = '011'.
          ENDIF.
        ENDIF.

        rs_result = stardust_failure( is_reported = ls_sd_reported
                                     iv_number = lv_message_number
                                     iv_v1 = CONV #( lv_stardust_id ) ).
        RETURN.

      ENDIF.

    ENDLOOP.

    CLEAR: ls_sf_failed, ls_sf_reported.

    READ ENTITIES OF zds1910_i_spacefarer
      ENTITY Spacefarer
      FIELDS ( SpacefarerId )
      WITH VALUE #( ( SpacefarerId = iv_first_spacefarer_id )
                    ( SpacefarerId = iv_second_spacefarer_id ) )
      RESULT lt_spacefarers
      ENTITY Spacefarer BY \_Collection
      FIELDS ( SpacefarerId )
      WITH VALUE #( ( SpacefarerId = iv_first_spacefarer_id )
                    ( SpacefarerId = iv_second_spacefarer_id ) )
      RESULT lt_collections
      FAILED ls_sf_failed
      REPORTED ls_sf_reported.

    IF ls_sf_failed IS NOT INITIAL.
      rs_result = spacefarer_failure( is_reported = ls_sf_reported
                                     iv_number = '016'
                                     iv_v1 = 'Reading the exchange participants.' ).
      RETURN.
    ENDIF.

    LOOP AT lt_spacefarer_ids INTO lv_spacefarer_id.

      IF NOT line_exists( lt_spacefarers[ KEY id COMPONENTS SpacefarerId = lv_spacefarer_id ] ).
        rs_result = error( iv_number = '010' iv_v1 = CONV #( lv_spacefarer_id ) ).
        RETURN.
      ENDIF.

      IF NOT line_exists( lt_collections[ KEY id COMPONENTS SpacefarerId = lv_spacefarer_id ] ).
        rs_result = error( iv_number = '016' iv_v1 = 'An exchange participant has no Collection.' ).
        RETURN.
      ENDIF.

    ENDLOOP.

    CLEAR: ls_sd_failed, ls_sd_reported.

    READ ENTITIES OF zds1910_i_stardust
      ENTITY Stardust
      FIELDS ( CollectionOwnerId )
      WITH VALUE #( ( StardustId = iv_first_stardust_id )
                    ( StardustId = iv_second_stardust_id ) )
      RESULT lt_stardusts
      FAILED ls_sd_failed
      REPORTED ls_sd_reported.

    IF ls_sd_failed IS NOT INITIAL.
      rs_result = stardust_failure( is_reported = ls_sd_reported
                                   iv_number = '016'
                                   iv_v1 = 'Reading the exchanged Stardusts.' ).
      RETURN.
    ENDIF.

    READ TABLE lt_stardusts INTO ls_first_stardust WITH KEY id COMPONENTS StardustId = iv_first_stardust_id.

    IF sy-subrc <> 0.
      rs_result = error( iv_number = '011' iv_v1 = CONV #( iv_first_stardust_id ) ).
      RETURN.
    ENDIF.

    READ TABLE lt_stardusts INTO ls_second_stardust WITH KEY id COMPONENTS StardustId = iv_second_stardust_id.

    IF sy-subrc <> 0.
      rs_result = error( iv_number = '011' iv_v1 = CONV #( iv_second_stardust_id ) ).
      RETURN.
    ENDIF.

    IF ls_first_stardust-CollectionOwnerId <> iv_first_spacefarer_id
       OR ls_second_stardust-CollectionOwnerId <> iv_second_spacefarer_id.
      rs_result = error( iv_number = '013' ).
      RETURN.
    ENDIF.

    CLEAR: ls_sd_failed, ls_sd_reported.

    MODIFY ENTITIES OF zds1910_i_stardust
      ENTITY Stardust
      UPDATE FIELDS ( CollectionOwnerId ) WITH VALUE #(
        ( StardustId = iv_first_stardust_id CollectionOwnerId = iv_second_spacefarer_id )
        ( StardustId = iv_second_stardust_id CollectionOwnerId = iv_first_spacefarer_id ) )
      FAILED ls_sd_failed
      REPORTED ls_sd_reported.

    IF ls_sd_failed IS NOT INITIAL.
      rs_result = stardust_failure( is_reported = ls_sd_reported
                                    iv_number = '016'
                                    iv_v1 = 'Exchanging Stardust ownership.' ).
      RETURN.
    ENDIF.

    rs_result-success = abap_true.

  ENDMETHOD.


  METHOD error.

    rs_result = VALUE #( success = abap_false
                         messages = VALUE #( ( severity       = zds1910_if_trading=>gc_severity_error
                                               message_id     = 'ZDS1910_MSG_GAP'
                                               message_number = iv_number
                                               message_v1     = iv_v1
                                              )
                                           )
                       ).

  ENDMETHOD.


  METHOD spacefarer_failure.

    DATA: lo_message    TYPE REF TO if_abap_behv_message,
          ls_spacefarer LIKE LINE OF is_reported-spacefarer,
          ls_collection LIKE LINE OF is_reported-collection.

    rs_result = error( iv_number = iv_number iv_v1 = iv_v1 ).

    LOOP AT is_reported-%other INTO lo_message.
      append_rap_message( EXPORTING io_message = lo_message CHANGING ct_messages = rs_result-messages ).
    ENDLOOP.

    LOOP AT is_reported-spacefarer INTO ls_spacefarer.
      append_rap_message( EXPORTING io_message = ls_spacefarer-%msg CHANGING ct_messages = rs_result-messages ).
    ENDLOOP.

    LOOP AT is_reported-collection INTO ls_collection.
      append_rap_message( EXPORTING io_message = ls_collection-%msg CHANGING ct_messages = rs_result-messages ).
    ENDLOOP.

  ENDMETHOD.


  METHOD stardust_failure.

    DATA: lo_message  TYPE REF TO if_abap_behv_message,
          ls_stardust LIKE LINE OF is_reported-stardust.

    rs_result = error( iv_number = iv_number iv_v1 = iv_v1 ).

    LOOP AT is_reported-%other INTO lo_message.
      append_rap_message( EXPORTING io_message = lo_message CHANGING ct_messages = rs_result-messages ).
    ENDLOOP.

    LOOP AT is_reported-stardust INTO ls_stardust.
      append_rap_message( EXPORTING io_message = ls_stardust-%msg CHANGING ct_messages = rs_result-messages ).
    ENDLOOP.

  ENDMETHOD.


  METHOD append_rap_message.

    DATA: ls_message TYPE zds1910_if_trading=>ty_message.

    IF io_message IS NOT BOUND.
      RETURN.
    ENDIF.

    CASE io_message->m_severity.
      WHEN if_abap_behv_message=>severity-success.

        ls_message-severity = zds1910_if_trading=>gc_severity_success.

      WHEN if_abap_behv_message=>severity-warning.

        ls_message-severity = zds1910_if_trading=>gc_severity_warning.

      WHEN if_abap_behv_message=>severity-information.

        ls_message-severity = zds1910_if_trading=>gc_severity_info.

      WHEN OTHERS.

        ls_message-severity = zds1910_if_trading=>gc_severity_error.

    ENDCASE.

    IF io_message->if_t100_message~t100key-msgid IS NOT INITIAL.

      ls_message-message_id = io_message->if_t100_message~t100key-msgid.
      ls_message-message_number = io_message->if_t100_message~t100key-msgno.
      ls_message-message_v1 = io_message->if_t100_dyn_msg~msgv1.
      ls_message-message_v2 = io_message->if_t100_dyn_msg~msgv2.
      ls_message-message_v3 = io_message->if_t100_dyn_msg~msgv3.
      ls_message-message_v4 = io_message->if_t100_dyn_msg~msgv4.

    ELSE.

      ls_message-message_id = 'ZDS1910_MSG_GAP'.
      ls_message-message_number = '016'.
      ls_message-message_v1 = io_message->if_message~get_text( ).

    ENDIF.

    APPEND ls_message TO ct_messages.

  ENDMETHOD.

ENDCLASS.

