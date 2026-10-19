CLASS zds1910_cl_trade_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_fixture,
             buyer_id              TYPE sysuuid_x16,
             seller_id             TYPE sysuuid_x16,
             traded_stardust_id    TYPE sysuuid_x16,
             expensive_stardust_id TYPE sysuuid_x16,
           END OF ty_fixture,

           BEGIN OF ty_state,
             buyer              TYPE zds1910_t_sfarer,
             seller             TYPE zds1910_t_sfarer,
             buyer_collection   TYPE zds1910_t_scoll,
             seller_collection  TYPE zds1910_t_scoll,
             traded_stardust    TYPE zds1910_t_sdust,
             expensive_stardust TYPE zds1910_t_sdust,
           END OF ty_state,

           ty_sf_commit_reported TYPE RESPONSE FOR REPORTED LATE zds1910_i_spacefarer,
           ty_sd_commit_reported TYPE RESPONSE FOR REPORTED LATE zds1910_i_stardust.

    CLASS-METHODS:
      create_fixture
        RETURNING VALUE(rs_fixture) TYPE ty_fixture
        RAISING   cx_uuid_error,

      read_state
        IMPORTING is_fixture      TYPE ty_fixture
        RETURNING VALUE(rs_state) TYPE ty_state,

      staged_purchase_is_valid
        IMPORTING is_fixture      TYPE ty_fixture
        RETURNING VALUE(rv_valid) TYPE abap_bool,

      saved_purchase_is_valid
        IMPORTING is_fixture      TYPE ty_fixture
                  is_before       TYPE ty_state
                  is_after        TYPE ty_state
        RETURNING VALUE(rv_valid) TYPE abap_bool,

      run_exchange_tests
        IMPORTING io_out            TYPE REF TO if_oo_adt_classrun_out
                  is_fixture        TYPE ty_fixture
                  is_before         TYPE ty_state
        RETURNING VALUE(rv_success) TYPE abap_bool,

      stardust_owners_are_valid
        IMPORTING is_fixture         TYPE ty_fixture
                  iv_traded_owner    TYPE sysuuid_x16
                  iv_expensive_owner TYPE sysuuid_x16
        RETURNING VALUE(rv_valid)    TYPE abap_bool,

      write_result
        IMPORTING io_out    TYPE REF TO if_oo_adt_classrun_out
                  is_result TYPE zds1910_if_trading=>ty_result,

      write_commit_messages
        IMPORTING io_out         TYPE REF TO if_oo_adt_classrun_out
                  is_sf_reported TYPE ty_sf_commit_reported
                  is_sd_reported TYPE ty_sd_commit_reported.

ENDCLASS.


CLASS zds1910_cl_trade_test IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA: ls_permissions        TYPE zds1910_cl_authorization=>ty_permissions,
          ls_fixture            TYPE ty_fixture,
          ls_initial            TYPE ty_state,
          ls_after              TYPE ty_state,
          ls_saved              TYPE ty_state,
          ls_expected           TYPE ty_state,
          ls_result             TYPE zds1910_if_trading=>ty_result,
          lo_trading            TYPE REF TO zds1910_if_trading,
          ls_sf_commit_failed   TYPE RESPONSE FOR FAILED LATE zds1910_i_spacefarer,
          ls_sf_commit_reported TYPE ty_sf_commit_reported,
          ls_sd_commit_failed   TYPE RESPONSE FOR FAILED LATE zds1910_i_stardust,
          ls_sd_commit_reported TYPE ty_sd_commit_reported,
          lv_commit_subrc       TYPE i,
          lt_wealth             TYPE STANDARD TABLE OF zds1910_i_wealth WITH EMPTY KEY,
          ls_buyer_wealth       TYPE zds1910_i_wealth,
          ls_seller_wealth      TYPE zds1910_i_wealth,
          lx_uuid               TYPE REF TO cx_uuid_error,
          lx_sql                TYPE REF TO cx_sy_open_sql_db,
          lx_technical          TYPE REF TO cx_root.

    ls_permissions = zds1910_cl_authorization=>get_permissions( ).

    IF ls_permissions-can_update = abap_false.
      out->write( 'Test requires read (03) and update (02) permissions.' ).
      RETURN.
    ENDIF.

    TRY.

        "Dedicated test data: four new UUIDs, no existing records are overwritten
        ls_fixture = create_fixture( ).
        COMMIT WORK.

        out->write( 'Fresh test data created. These records remain available for inspection.' ).
        out->write( ls_fixture ).

        ls_initial = read_state( is_fixture = ls_fixture ).
        lo_trading = NEW zds1910_cl_trading( ).

        "Test 1: staged changes must not be committed by the trading class
        ls_result = lo_trading->buy( iv_buyer_id = ls_fixture-buyer_id
                                     iv_seller_id = ls_fixture-seller_id
                                     iv_stardust_id = ls_fixture-traded_stardust_id ).

        IF ls_result-success = abap_false.
          ROLLBACK ENTITIES.
          out->write( 'FAIL 1: purchase could not be staged.' ).
          write_result( io_out = out is_result = ls_result ).
          RETURN.
        ENDIF.

        IF staged_purchase_is_valid( is_fixture = ls_fixture ) = abap_false.
          ROLLBACK ENTITIES.
          out->write( 'FAIL 1: staged balances, Collection or owner are incorrect.' ).
          RETURN.
        ENDIF.

        ls_after = read_state( is_fixture = ls_fixture ).

        IF ls_after <> ls_initial.
          ROLLBACK ENTITIES.
          out->write( 'FAIL 1: the trading class persisted changes before the caller committed.' ).
          RETURN.
        ENDIF.

        ROLLBACK ENTITIES.
        ls_after = read_state( is_fixture = ls_fixture ).

        IF ls_after <> ls_initial.
          out->write( 'FAIL 1: persisted fixture differs after rollback.' ).
          RETURN.
        ENDIF.

        IF staged_purchase_is_valid( is_fixture = ls_fixture ) = abap_true.
          ROLLBACK ENTITIES.
          out->write( 'FAIL 1: the staged purchase is still visible after rollback.' ).
          RETURN.
        ENDIF.

        "Clear any read buffer created by the preceding verification
        ROLLBACK ENTITIES.
        out->write( 'PASS 1: staged purchase and new Collection were rolled back.' ).

        "Test 2: repeat the purchase, then let this caller complete the transaction
        ls_result = lo_trading->buy( iv_buyer_id = ls_fixture-buyer_id
                                     iv_seller_id = ls_fixture-seller_id
                                     iv_stardust_id = ls_fixture-traded_stardust_id ).

        IF ls_result-success = abap_false.
          ROLLBACK ENTITIES.
          out->write( 'FAIL 2: purchase could not be staged.' ).
          write_result( io_out = out is_result = ls_result ).
          RETURN.
        ENDIF.

        COMMIT ENTITIES
          RESPONSE OF zds1910_i_spacefarer
            FAILED ls_sf_commit_failed
            REPORTED ls_sf_commit_reported
          RESPONSE OF zds1910_i_stardust
            FAILED ls_sd_commit_failed
            REPORTED ls_sd_commit_reported.

        lv_commit_subrc = sy-subrc.

        IF lv_commit_subrc <> 0
           OR ls_sf_commit_failed IS NOT INITIAL
           OR ls_sd_commit_failed IS NOT INITIAL.

          ROLLBACK ENTITIES.
          out->write( |FAIL 2: commit rejected, sy-subrc = { lv_commit_subrc }.| ).
          write_commit_messages( io_out = out
                                   is_sf_reported = ls_sf_commit_reported
                                   is_sd_reported = ls_sd_commit_reported ).
          RETURN.

        ENDIF.

        ls_saved = read_state( is_fixture = ls_fixture ).

        IF saved_purchase_is_valid( is_fixture = ls_fixture
                                      is_before = ls_initial
                                      is_after = ls_saved ) = abap_false.
          out->write( 'FAIL 2: committed balances, ownership or unchanged fields are incorrect.' ).
          RETURN.
        ENDIF.

        SELECT *
          FROM zds1910_i_wealth
          WHERE SpacefarerId = @ls_fixture-buyer_id OR SpacefarerId = @ls_fixture-seller_id
          INTO TABLE @lt_wealth.

        READ TABLE lt_wealth INTO ls_buyer_wealth WITH KEY SpacefarerId = ls_fixture-buyer_id.

        IF sy-subrc <> 0.
          out->write( 'FAIL 2: buyer Wealth row is missing.' ).
          RETURN.
        ENDIF.

        READ TABLE lt_wealth INTO ls_seller_wealth WITH KEY SpacefarerId = ls_fixture-seller_id.

        IF sy-subrc <> 0.
          out->write( 'FAIL 2: seller Wealth row is missing.' ).
          RETURN.
        ENDIF.

        IF ls_buyer_wealth-Credits <> 80
           OR ls_buyer_wealth-CollectionValue <> 20
           OR ls_buyer_wealth-TotalWealth <> 100
           OR ls_seller_wealth-Credits <> 320
           OR ls_seller_wealth-CollectionValue <> 200
           OR ls_seller_wealth-TotalWealth <> 520.

          out->write( 'FAIL 2: committed Wealth values are incorrect.' ).
          out->write( lt_wealth ).
          RETURN.

        ENDIF.

        out->write( 'PASS 2: purchase committed; balances, owner, Collection and Wealth are correct.' ).
        out->write( lt_wealth ).

        "Test 3: buyer has 80 credits, while the remaining Stardust costs 200
        ls_result = lo_trading->buy( iv_buyer_id = ls_fixture-buyer_id
                                     iv_seller_id = ls_fixture-seller_id
                                     iv_stardust_id = ls_fixture-expensive_stardust_id ).

        ROLLBACK ENTITIES.

        IF ls_result-success <> abap_false
           OR NOT line_exists( ls_result-messages[ severity = zds1910_if_trading=>gc_severity_error
                                                   message_id = 'ZDS1910_MSG_GAP'
                                                   message_number = '014' ] ).

          out->write( 'FAIL 3: insufficient credits did not produce the expected rejection.' ).
          write_result( io_out = out is_result = ls_result ).
          RETURN.

        ENDIF.

        ls_after = read_state( is_fixture = ls_fixture ).

        IF ls_after <> ls_saved.
          out->write( 'FAIL 3: rejected purchase left persisted changes.' ).
          RETURN.
        ENDIF.

        out->write( 'PASS 3: insufficient credits rejected; persisted state is unchanged.' ).
        write_result( io_out = out is_result = ls_result ).
        out->write( 'All 3 purchase integration tests passed.' ).

        "Test 4: sell the purchased Stardust back to its original owner
        ls_result = lo_trading->sell( iv_seller_id = ls_fixture-buyer_id
                                      iv_buyer_id = ls_fixture-seller_id
                                      iv_stardust_id = ls_fixture-traded_stardust_id ).

        IF ls_result-success = abap_false.
          ROLLBACK ENTITIES.
          out->write( 'FAIL 4: sale could not be staged.' ).
          write_result( io_out = out is_result = ls_result ).
          RETURN.
        ENDIF.

        CLEAR: ls_sf_commit_failed, ls_sf_commit_reported, ls_sd_commit_failed, ls_sd_commit_reported.

        COMMIT ENTITIES
          RESPONSE OF zds1910_i_spacefarer
            FAILED ls_sf_commit_failed
            REPORTED ls_sf_commit_reported
          RESPONSE OF zds1910_i_stardust
            FAILED ls_sd_commit_failed
            REPORTED ls_sd_commit_reported.

        lv_commit_subrc = sy-subrc.

        IF lv_commit_subrc <> 0
           OR ls_sf_commit_failed IS NOT INITIAL
           OR ls_sd_commit_failed IS NOT INITIAL.

          ROLLBACK ENTITIES.
          out->write( |FAIL 4: commit rejected, sy-subrc = { lv_commit_subrc }.| ).
          write_commit_messages( io_out = out
                                 is_sf_reported = ls_sf_commit_reported
                                 is_sd_reported = ls_sd_commit_reported ).
          RETURN.

        ENDIF.

        ls_after = read_state( is_fixture = ls_fixture ).
        ls_expected = ls_saved.
        ls_expected-buyer-credits = 100.
        ls_expected-seller-credits = 300.
        ls_expected-traded_stardust-collection_owner_id = ls_fixture-seller_id.

        "Only the three updated rows may receive new change metadata
        ls_expected-buyer-changed_by = ls_after-buyer-changed_by.
        ls_expected-buyer-changed_at = ls_after-buyer-changed_at.
        ls_expected-seller-changed_by = ls_after-seller-changed_by.
        ls_expected-seller-changed_at = ls_after-seller-changed_at.
        ls_expected-traded_stardust-changed_by = ls_after-traded_stardust-changed_by.
        ls_expected-traded_stardust-changed_at = ls_after-traded_stardust-changed_at.

        IF ls_after <> ls_expected.
          out->write( 'FAIL 4: committed sale changed unexpected data or produced incorrect balances or ownership.' ).
          RETURN.
        ENDIF.

        CLEAR: lt_wealth, ls_buyer_wealth, ls_seller_wealth.

        SELECT *
          FROM zds1910_i_wealth
          WHERE SpacefarerId = @ls_fixture-buyer_id OR SpacefarerId = @ls_fixture-seller_id
          INTO TABLE @lt_wealth.

        READ TABLE lt_wealth INTO ls_buyer_wealth WITH KEY SpacefarerId = ls_fixture-buyer_id.

        IF sy-subrc <> 0.
          out->write( 'FAIL 4: original buyer Wealth row is missing.' ).
          RETURN.
        ENDIF.

        READ TABLE lt_wealth INTO ls_seller_wealth WITH KEY SpacefarerId = ls_fixture-seller_id.

        IF sy-subrc <> 0.
          out->write( 'FAIL 4: original seller Wealth row is missing.' ).
          RETURN.
        ENDIF.

        IF ls_buyer_wealth-Credits <> 100
           OR ls_buyer_wealth-CollectionValue <> 0
           OR ls_buyer_wealth-TotalWealth <> 100
           OR ls_seller_wealth-Credits <> 300
           OR ls_seller_wealth-CollectionValue <> 220
           OR ls_seller_wealth-TotalWealth <> 520.

          out->write( 'FAIL 4: committed sale Wealth values are incorrect.' ).
          out->write( lt_wealth ).
          RETURN.

        ENDIF.

        ls_saved = ls_after.
        out->write( 'PASS 4: sale committed; balances, owner, existing Collections and Wealth are correct.' ).
        out->write( lt_wealth ).

        "Test 5: the original buyer no longer owns this Stardust
        ls_result = lo_trading->sell( iv_seller_id = ls_fixture-buyer_id
                                      iv_buyer_id = ls_fixture-seller_id
                                      iv_stardust_id = ls_fixture-traded_stardust_id ).

        ROLLBACK ENTITIES.

        IF ls_result-success <> abap_false
           OR NOT line_exists( ls_result-messages[ severity = zds1910_if_trading=>gc_severity_error
                                                   message_id = 'ZDS1910_MSG_GAP'
                                                   message_number = '013' ] ).

          out->write( 'FAIL 5: selling another owner''s Stardust did not produce the expected rejection.' ).
          write_result( io_out = out is_result = ls_result ).
          RETURN.

        ENDIF.

        ls_after = read_state( is_fixture = ls_fixture ).

        IF ls_after <> ls_saved.
          out->write( 'FAIL 5: rejected sale left persisted changes.' ).
          RETURN.
        ENDIF.

        out->write( 'PASS 5: incorrect seller rejected; persisted state is unchanged.' ).
        write_result( io_out = out is_result = ls_result ).
        out->write( 'All 5 purchase and sale integration tests passed.' ).

        IF run_exchange_tests( io_out = out is_fixture = ls_fixture is_before = ls_saved ) = abap_false.
          ROLLBACK ENTITIES.
          RETURN.
        ENDIF.

        out->write( 'All 9 trading integration tests passed.' ).

      CATCH cx_uuid_error INTO lx_uuid.
        ROLLBACK ENTITIES.
        out->write( |TECHNICAL FAILURE - UUID: { lx_uuid->get_text( ) }| ).

      CATCH cx_sy_open_sql_db INTO lx_sql.
        ROLLBACK ENTITIES.
        out->write( |TECHNICAL FAILURE - SQL: { lx_sql->get_text( ) }| ).

      CATCH cx_root INTO lx_technical.
        ROLLBACK ENTITIES.
        out->write( |UNEXPECTED TECHNICAL FAILURE: { lx_technical->get_text( ) }| ).

    ENDTRY.

  ENDMETHOD.


  METHOD create_fixture.

    DATA: lt_spacefarers TYPE STANDARD TABLE OF zds1910_t_sfarer WITH EMPTY KEY,
          lt_collections TYPE STANDARD TABLE OF zds1910_t_scoll WITH EMPTY KEY,
          lt_stardusts   TYPE STANDARD TABLE OF zds1910_t_sdust WITH EMPTY KEY,
          lv_user        TYPE zds1910_t_sfarer-created_by,
          lv_timestamp   TYPE timestampl.

    rs_fixture-buyer_id = cl_system_uuid=>create_uuid_x16_static( ).
    rs_fixture-seller_id = cl_system_uuid=>create_uuid_x16_static( ).
    rs_fixture-traded_stardust_id = cl_system_uuid=>create_uuid_x16_static( ).
    rs_fixture-expensive_stardust_id = cl_system_uuid=>create_uuid_x16_static( ).

    lv_user = cl_abap_context_info=>get_user_technical_name( ).
    GET TIME STAMP FIELD lv_timestamp.

    lt_spacefarers = VALUE #(
      client = sy-mandt
      navigation_skill = 20
      reputation = 30
      origin_planet = 'Earth'
      spacesuit_color = 'Blue'
      created_by = lv_user
      created_at = lv_timestamp
      changed_by = lv_user
      changed_at = lv_timestamp
      ( spacefarer_id = rs_fixture-buyer_id
        name = |GAP Trade Test Buyer { rs_fixture-buyer_id }|
        credits = 100 )
      ( spacefarer_id = rs_fixture-seller_id
        name = |GAP Trade Test Seller { rs_fixture-seller_id }|
        credits = 300 )
    ).

    lt_collections = VALUE #(
      ( client = sy-mandt
        spacefarer_id = rs_fixture-seller_id
        created_by = lv_user
        created_at = lv_timestamp
        changed_by = lv_user
        changed_at = lv_timestamp )
    ).

    lt_stardusts = VALUE #(
      client = sy-mandt
      collection_owner_id = rs_fixture-seller_id
      state_of_matter = 'Solid'
      created_by = lv_user
      created_at = lv_timestamp
      changed_by = lv_user
      changed_at = lv_timestamp
      ( stardust_id = rs_fixture-traded_stardust_id color = 'Blue' weight = '1.000' value = 20 )
      ( stardust_id = rs_fixture-expensive_stardust_id color = 'Red' weight = '2.000' value = 200 )
    ).

    INSERT zds1910_t_sfarer FROM TABLE @lt_spacefarers.
    INSERT zds1910_t_scoll FROM TABLE @lt_collections.
    INSERT zds1910_t_sdust FROM TABLE @lt_stardusts.

  ENDMETHOD.


  METHOD read_state.

    SELECT SINGLE * FROM zds1910_t_sfarer
      WHERE spacefarer_id = @is_fixture-buyer_id INTO @rs_state-buyer.

    SELECT SINGLE * FROM zds1910_t_sfarer
      WHERE spacefarer_id = @is_fixture-seller_id INTO @rs_state-seller.

    SELECT SINGLE * FROM zds1910_t_scoll
      WHERE spacefarer_id = @is_fixture-buyer_id INTO @rs_state-buyer_collection.

    SELECT SINGLE * FROM zds1910_t_scoll
      WHERE spacefarer_id = @is_fixture-seller_id INTO @rs_state-seller_collection.

    SELECT SINGLE * FROM zds1910_t_sdust
      WHERE stardust_id = @is_fixture-traded_stardust_id INTO @rs_state-traded_stardust.

    SELECT SINGLE * FROM zds1910_t_sdust
      WHERE stardust_id = @is_fixture-expensive_stardust_id INTO @rs_state-expensive_stardust.

  ENDMETHOD.


  METHOD staged_purchase_is_valid.

    DATA: lt_spacefarers TYPE TABLE FOR READ RESULT zds1910_i_spacefarer,
          lt_collections TYPE TABLE FOR READ RESULT zds1910_i_collection,
          lt_stardusts   TYPE TABLE FOR READ RESULT zds1910_i_stardust,
          ls_buyer       LIKE LINE OF lt_spacefarers,
          ls_seller      LIKE LINE OF lt_spacefarers,
          ls_sf_failed   TYPE RESPONSE FOR FAILED EARLY zds1910_i_spacefarer,
          ls_sd_failed   TYPE RESPONSE FOR FAILED EARLY zds1910_i_stardust.

    READ ENTITIES OF zds1910_i_spacefarer
      ENTITY Spacefarer
      FIELDS ( Credits )
      WITH VALUE #( ( SpacefarerId = is_fixture-buyer_id ) ( SpacefarerId = is_fixture-seller_id ) )
      RESULT lt_spacefarers
      ENTITY Collection
      FIELDS ( SpacefarerId )
      WITH VALUE #( ( SpacefarerId = is_fixture-buyer_id ) )
      RESULT lt_collections
      FAILED ls_sf_failed.

    IF ls_sf_failed IS NOT INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF zds1910_i_stardust
      ENTITY Stardust
      FIELDS ( CollectionOwnerId )
      WITH VALUE #( ( StardustId = is_fixture-traded_stardust_id ) )
      RESULT lt_stardusts
      FAILED ls_sd_failed.

    IF ls_sd_failed IS NOT INITIAL.
      RETURN.
    ENDIF.

    READ TABLE lt_spacefarers INTO ls_buyer WITH KEY id COMPONENTS SpacefarerId = is_fixture-buyer_id.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    READ TABLE lt_spacefarers INTO ls_seller WITH KEY id COMPONENTS SpacefarerId = is_fixture-seller_id.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rv_valid = xsdbool(
      ls_buyer-Credits = 80
      AND ls_seller-Credits = 320
      AND line_exists( lt_collections[ KEY id COMPONENTS SpacefarerId = is_fixture-buyer_id ] )
      AND line_exists( lt_stardusts[ KEY id COMPONENTS StardustId = is_fixture-traded_stardust_id
                                               CollectionOwnerId = is_fixture-buyer_id ] )
    ).

  ENDMETHOD.


  METHOD saved_purchase_is_valid.

    DATA: ls_expected TYPE ty_state.

    ls_expected = is_before.
    ls_expected-buyer-credits = 80.
    ls_expected-seller-credits = 320.
    ls_expected-traded_stardust-collection_owner_id = is_fixture-buyer_id.

    ls_expected-buyer-changed_by = is_after-buyer-changed_by.
    ls_expected-buyer-changed_at = is_after-buyer-changed_at.
    ls_expected-seller-changed_by = is_after-seller-changed_by.
    ls_expected-seller-changed_at = is_after-seller-changed_at.
    ls_expected-traded_stardust-changed_by = is_after-traded_stardust-changed_by.
    ls_expected-traded_stardust-changed_at = is_after-traded_stardust-changed_at.

    ls_expected-buyer_collection = is_after-buyer_collection.

    rv_valid = xsdbool(
      is_after = ls_expected
      AND is_after-buyer_collection-spacefarer_id = is_fixture-buyer_id
      AND is_after-buyer_collection-created_by = is_before-buyer-created_by
      AND is_after-buyer_collection-created_at IS NOT INITIAL
    ).

  ENDMETHOD.


  METHOD run_exchange_tests.

    DATA: lo_trading            TYPE REF TO zds1910_if_trading,
          ls_result             TYPE zds1910_if_trading=>ty_result,
          ls_after              TYPE ty_state,
          ls_ready              TYPE ty_state,
          ls_expected           TYPE ty_state,
          ls_sf_commit_failed   TYPE RESPONSE FOR FAILED LATE zds1910_i_spacefarer,
          ls_sf_commit_reported TYPE ty_sf_commit_reported,
          ls_sd_commit_failed   TYPE RESPONSE FOR FAILED LATE zds1910_i_stardust,
          ls_sd_commit_reported TYPE ty_sd_commit_reported,
          lv_commit_subrc       TYPE i,
          lt_wealth             TYPE STANDARD TABLE OF zds1910_i_wealth WITH EMPTY KEY,
          ls_buyer_wealth       TYPE zds1910_i_wealth,
          ls_seller_wealth      TYPE zds1910_i_wealth.

    lo_trading = NEW zds1910_cl_trading( ).

    "Test 6: the first offering is valid, the second belongs to the wrong participant.
    "After test 5 both Stardusts belong to the original seller, both Collections exist
    ls_result = lo_trading->exchange( iv_first_spacefarer_id = is_fixture-seller_id
                                      iv_second_spacefarer_id = is_fixture-buyer_id
                                      iv_first_stardust_id = is_fixture-traded_stardust_id
                                      iv_second_stardust_id = is_fixture-expensive_stardust_id ).

    IF ls_result-success <> abap_false
       OR NOT line_exists( ls_result-messages[ severity = zds1910_if_trading=>gc_severity_error
                                               message_id = 'ZDS1910_MSG_GAP'
                                               message_number = '013' ] ).
      ROLLBACK ENTITIES.
      io_out->write( 'FAIL 6: invalid second owner did not produce the expected rejection.' ).
      write_result( io_out = io_out is_result = ls_result ).
      RETURN.
    ENDIF.

    IF stardust_owners_are_valid( is_fixture = is_fixture
                                 iv_traded_owner = is_fixture-seller_id
                                 iv_expensive_owner = is_fixture-seller_id ) = abap_false.
      ROLLBACK ENTITIES.
      io_out->write( 'FAIL 6: rejected exchange staged an ownership change.' ).
      RETURN.
    ENDIF.

    ROLLBACK ENTITIES.
    ls_after = read_state( is_fixture = is_fixture ).

    IF ls_after <> is_before.
      io_out->write( 'FAIL 6: rejected exchange left persisted changes.' ).
      RETURN.
    ENDIF.

    io_out->write( 'PASS 6: invalid second owner rejected; neither Stardust was transferred.' ).

    "Test 7: a Stardust cannot be exchanged for itself.
    ls_result = lo_trading->exchange( iv_first_spacefarer_id = is_fixture-seller_id
                                      iv_second_spacefarer_id = is_fixture-buyer_id
                                      iv_first_stardust_id = is_fixture-traded_stardust_id
                                      iv_second_stardust_id = is_fixture-traded_stardust_id ).

    ROLLBACK ENTITIES.

    IF ls_result-success <> abap_false
       OR NOT line_exists( ls_result-messages[ severity = zds1910_if_trading=>gc_severity_error
                                               message_id = 'ZDS1910_MSG_GAP'
                                               message_number = '021' ] ).
      io_out->write( 'FAIL 7: duplicate Stardust did not produce the expected rejection.' ).
      write_result( io_out = io_out is_result = ls_result ).
      RETURN.
    ENDIF.

    ls_after = read_state( is_fixture = is_fixture ).

    IF ls_after <> is_before.
      io_out->write( 'FAIL 7: rejected duplicate Stardust exchange left persisted changes.' ).
      RETURN.
    ENDIF.

    io_out->write( 'PASS 7: duplicate Stardust rejected; persisted state is unchanged.' ).

    "Arrange a valid exchange using the public buy API: one Stardust for each participant
    ls_result = lo_trading->buy( iv_buyer_id = is_fixture-buyer_id
                                 iv_seller_id = is_fixture-seller_id
                                 iv_stardust_id = is_fixture-traded_stardust_id ).

    IF ls_result-success = abap_false.
      ROLLBACK ENTITIES.
      io_out->write( 'FAIL exchange setup: purchase could not be staged.' ).
      write_result( io_out = io_out is_result = ls_result ).
      RETURN.
    ENDIF.

    COMMIT ENTITIES
      RESPONSE OF zds1910_i_spacefarer
        FAILED ls_sf_commit_failed
        REPORTED ls_sf_commit_reported
      RESPONSE OF zds1910_i_stardust
        FAILED ls_sd_commit_failed
        REPORTED ls_sd_commit_reported.

    lv_commit_subrc = sy-subrc.

    IF lv_commit_subrc <> 0
       OR ls_sf_commit_failed IS NOT INITIAL
       OR ls_sd_commit_failed IS NOT INITIAL.
      ROLLBACK ENTITIES.
      io_out->write( |FAIL exchange setup: commit rejected, sy-subrc = { lv_commit_subrc }.| ).
      write_commit_messages( io_out = io_out
                             is_sf_reported = ls_sf_commit_reported
                             is_sd_reported = ls_sd_commit_reported ).
      RETURN.
    ENDIF.

    ls_ready = read_state( is_fixture = is_fixture ).

    IF saved_purchase_is_valid( is_fixture = is_fixture
                                is_before = is_before
                                is_after = ls_ready ) = abap_false.
      io_out->write( 'FAIL exchange setup: committed purchase state is incorrect.' ).
      RETURN.
    ENDIF.

    "Test 8: both ownership changes must be staged together and disappear on rollback
    ls_result = lo_trading->exchange( iv_first_spacefarer_id = is_fixture-buyer_id
                                      iv_second_spacefarer_id = is_fixture-seller_id
                                      iv_first_stardust_id = is_fixture-traded_stardust_id
                                      iv_second_stardust_id = is_fixture-expensive_stardust_id ).

    IF ls_result-success = abap_false.
      ROLLBACK ENTITIES.
      io_out->write( 'FAIL 8: exchange could not be staged.' ).
      write_result( io_out = io_out is_result = ls_result ).
      RETURN.
    ENDIF.

    IF stardust_owners_are_valid( is_fixture = is_fixture
                                 iv_traded_owner = is_fixture-seller_id
                                 iv_expensive_owner = is_fixture-buyer_id ) = abap_false.
      ROLLBACK ENTITIES.
      io_out->write( 'FAIL 8: both ownership changes are not visible in the RAP buffer.' ).
      RETURN.
    ENDIF.

    ls_after = read_state( is_fixture = is_fixture ).

    IF ls_after <> ls_ready.
      ROLLBACK ENTITIES.
      io_out->write( 'FAIL 8: exchange persisted changes before the caller committed.' ).
      RETURN.
    ENDIF.

    ROLLBACK ENTITIES.

    IF stardust_owners_are_valid( is_fixture = is_fixture
                                 iv_traded_owner = is_fixture-buyer_id
                                 iv_expensive_owner = is_fixture-seller_id ) = abap_false.
      ROLLBACK ENTITIES.
      io_out->write( 'FAIL 8: rollback did not restore both buffered owners.' ).
      RETURN.
    ENDIF.

    ROLLBACK ENTITIES.
    ls_after = read_state( is_fixture = is_fixture ).

    IF ls_after <> ls_ready.
      io_out->write( 'FAIL 8: persisted fixture differs after exchange rollback.' ).
      RETURN.
    ENDIF.

    io_out->write( 'PASS 8: both ownership changes were staged and rolled back; persisted state is unchanged.' ).

    "Test 9: commit the exchange, only ownership and managed Stardust change metadata may change
    ls_result = lo_trading->exchange( iv_first_spacefarer_id = is_fixture-buyer_id
                                      iv_second_spacefarer_id = is_fixture-seller_id
                                      iv_first_stardust_id = is_fixture-traded_stardust_id
                                      iv_second_stardust_id = is_fixture-expensive_stardust_id ).

    IF ls_result-success = abap_false.
      ROLLBACK ENTITIES.
      io_out->write( 'FAIL 9: exchange could not be staged.' ).
      write_result( io_out = io_out is_result = ls_result ).
      RETURN.
    ENDIF.

    CLEAR: ls_sf_commit_failed, ls_sf_commit_reported, ls_sd_commit_failed, ls_sd_commit_reported.

    COMMIT ENTITIES
      RESPONSE OF zds1910_i_spacefarer
        FAILED ls_sf_commit_failed
        REPORTED ls_sf_commit_reported
      RESPONSE OF zds1910_i_stardust
        FAILED ls_sd_commit_failed
        REPORTED ls_sd_commit_reported.

    lv_commit_subrc = sy-subrc.

    IF lv_commit_subrc <> 0
       OR ls_sf_commit_failed IS NOT INITIAL
       OR ls_sd_commit_failed IS NOT INITIAL.
      ROLLBACK ENTITIES.
      io_out->write( |FAIL 9: commit rejected, sy-subrc = { lv_commit_subrc }.| ).
      write_commit_messages( io_out = io_out
                             is_sf_reported = ls_sf_commit_reported
                             is_sd_reported = ls_sd_commit_reported ).
      RETURN.
    ENDIF.

    ls_after = read_state( is_fixture = is_fixture ).
    ls_expected = ls_ready.
    ls_expected-traded_stardust-collection_owner_id = is_fixture-seller_id.
    ls_expected-expensive_stardust-collection_owner_id = is_fixture-buyer_id.
    ls_expected-traded_stardust-changed_by = ls_after-traded_stardust-changed_by.
    ls_expected-traded_stardust-changed_at = ls_after-traded_stardust-changed_at.
    ls_expected-expensive_stardust-changed_by = ls_after-expensive_stardust-changed_by.
    ls_expected-expensive_stardust-changed_at = ls_after-expensive_stardust-changed_at.

    IF ls_after <> ls_expected.
      io_out->write( 'FAIL 9: committed exchange has incorrect ownership or changed unexpected fields.' ).
      RETURN.
    ENDIF.

    SELECT *
      FROM zds1910_i_wealth
      WHERE SpacefarerId = @is_fixture-buyer_id OR SpacefarerId = @is_fixture-seller_id
      INTO TABLE @lt_wealth.

    READ TABLE lt_wealth INTO ls_buyer_wealth WITH KEY SpacefarerId = is_fixture-buyer_id.

    IF sy-subrc <> 0.
      io_out->write( 'FAIL 9: original buyer Wealth row is missing.' ).
      RETURN.
    ENDIF.

    READ TABLE lt_wealth INTO ls_seller_wealth WITH KEY SpacefarerId = is_fixture-seller_id.

    IF sy-subrc <> 0.
      io_out->write( 'FAIL 9: original seller Wealth row is missing.' ).
      RETURN.
    ENDIF.

    IF ls_buyer_wealth-Credits <> 80
       OR ls_buyer_wealth-CollectionValue <> 200
       OR ls_buyer_wealth-TotalWealth <> 280
       OR ls_seller_wealth-Credits <> 320
       OR ls_seller_wealth-CollectionValue <> 20
       OR ls_seller_wealth-TotalWealth <> 340.
      io_out->write( 'FAIL 9: committed exchange Wealth values are incorrect.' ).
      io_out->write( lt_wealth ).
      RETURN.
    ENDIF.

    io_out->write( 'PASS 9: exchange committed; both owners, unchanged business fields and Wealth are correct.' ).
    io_out->write( lt_wealth ).
    rv_success = abap_true.

  ENDMETHOD.


  METHOD stardust_owners_are_valid.

    DATA: lt_stardusts TYPE TABLE FOR READ RESULT zds1910_i_stardust,
          ls_failed    TYPE RESPONSE FOR FAILED EARLY zds1910_i_stardust.

    READ ENTITIES OF zds1910_i_stardust
      ENTITY Stardust
      FIELDS ( CollectionOwnerId )
      WITH VALUE #( ( StardustId = is_fixture-traded_stardust_id )
                    ( StardustId = is_fixture-expensive_stardust_id ) )
      RESULT lt_stardusts
      FAILED ls_failed.

    rv_valid = xsdbool(
      ls_failed IS INITIAL
      AND lines( lt_stardusts ) = 2
      AND line_exists( lt_stardusts[ KEY id COMPONENTS StardustId = is_fixture-traded_stardust_id
                                                       CollectionOwnerId = iv_traded_owner ] )
      AND line_exists( lt_stardusts[ KEY id COMPONENTS StardustId = is_fixture-expensive_stardust_id
                                                       CollectionOwnerId = iv_expensive_owner ] )
    ).

  ENDMETHOD.


  METHOD write_result.

    DATA: ls_message TYPE zds1910_if_trading=>ty_message,
          lv_text    TYPE string.

    LOOP AT is_result-messages INTO ls_message.

      MESSAGE ID ls_message-message_id TYPE 'S' NUMBER ls_message-message_number
        WITH ls_message-message_v1 ls_message-message_v2 ls_message-message_v3 ls_message-message_v4
        INTO lv_text.

      io_out->write( |{ ls_message-severity }: { lv_text }| ).

    ENDLOOP.

  ENDMETHOD.


  METHOD write_commit_messages.

    DATA: lo_message    TYPE REF TO if_abap_behv_message,
          ls_spacefarer LIKE LINE OF is_sf_reported-spacefarer,
          ls_collection LIKE LINE OF is_sf_reported-collection,
          ls_stardust   LIKE LINE OF is_sd_reported-stardust.

    LOOP AT is_sf_reported-%other INTO lo_message.
      IF lo_message IS BOUND.
        io_out->write( lo_message->if_message~get_text( ) ).
      ENDIF.
    ENDLOOP.

    LOOP AT is_sd_reported-%other INTO lo_message.
      IF lo_message IS BOUND.
        io_out->write( lo_message->if_message~get_text( ) ).
      ENDIF.
    ENDLOOP.

    LOOP AT is_sf_reported-spacefarer INTO ls_spacefarer.
      IF ls_spacefarer-%msg IS BOUND.
        io_out->write( ls_spacefarer-%msg->if_message~get_text( ) ).
      ENDIF.
    ENDLOOP.

    LOOP AT is_sf_reported-collection INTO ls_collection.
      IF ls_collection-%msg IS BOUND.
        io_out->write( ls_collection-%msg->if_message~get_text( ) ).
      ENDIF.
    ENDLOOP.

    LOOP AT is_sd_reported-stardust INTO ls_stardust.
      IF ls_stardust-%msg IS BOUND.
        io_out->write( ls_stardust-%msg->if_message~get_text( ) ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

