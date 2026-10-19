CLASS zds1910_cl_demo_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zds1910_cl_demo_data IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA: lv_timestamp   TYPE abp_creation_tstmpl,
          lt_spacefarers TYPE STANDARD TABLE OF zds1910_t_sfarer WITH EMPTY KEY,
          lt_collections TYPE STANDARD TABLE OF zds1910_t_scoll WITH EMPTY KEY,
          lt_stardusts   TYPE STANDARD TABLE OF zds1910_t_sdust WITH EMPTY KEY.


    SELECT SINGLE spacefarer_id
        FROM zds1910_t_sfarer
        WHERE name = 'GAP Test - Beginner'
        INTO @DATA(lv_existing_id).

    IF sy-subrc = 0.
      out->write( 'Demo data already exists.' ).
      RETURN.
    ENDIF.

    GET TIME STAMP FIELD lv_timestamp.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    TRY.

        DATA(lv_beginner_id) = cl_system_uuid=>create_uuid_x16_static( ).
        DATA(lv_empty_id) = cl_system_uuid=>create_uuid_x16_static( ).
        DATA(lv_owner_id) = cl_system_uuid=>create_uuid_x16_static( ).

        lt_spacefarers = VALUE #(
          navigation_skill = 20
          reputation       = 30
          origin_planet    = 'Earth'
          spacesuit_color  = 'Blue'
          created_by       = lv_user
          created_at       = lv_timestamp
          changed_by       = lv_user
          changed_at       = lv_timestamp

          ( spacefarer_id = lv_beginner_id
            name          = 'GAP Test - Beginner'
            credits       = '100.00' )

          ( spacefarer_id = lv_empty_id
            name          = 'GAP Test - Empty Collection'
            credits       = '200.00' )

          ( spacefarer_id = lv_owner_id
            name          = 'GAP Test - Stardust Owner'
            credits       = '300.00' )
        ).

        lt_collections = VALUE #(
          created_by = lv_user
          created_at = lv_timestamp
          changed_by = lv_user
          changed_at = lv_timestamp

          ( spacefarer_id = lv_empty_id )
          ( spacefarer_id = lv_owner_id )
        ).

        lt_stardusts = VALUE #(
          collection_owner_id = lv_owner_id
          state_of_matter     = 'Solid'
          created_by          = lv_user
          created_at          = lv_timestamp
          changed_by          = lv_user
          changed_at          = lv_timestamp

          ( stardust_id = cl_system_uuid=>create_uuid_x16_static( )
            color       = 'Blue'
            weight      = '1.250'
            value       = '20.00' )

          ( stardust_id = cl_system_uuid=>create_uuid_x16_static( )
            color       = 'Red'
            weight      = '2.500'
            value       = '30.00' )

          ( stardust_id = cl_system_uuid=>create_uuid_x16_static( )
            color       = 'Green'
            weight      = '0.500'
            value       = '10.00' )

          ( stardust_id = cl_system_uuid=>create_uuid_x16_static( )
            color       = 'Purple'
            weight      = '0.750'
            value       = '40.00' )

          ( stardust_id = cl_system_uuid=>create_uuid_x16_static( )
            color       = 'Gold'
            weight      = '1.500'
            value       = '60.00' )

          ( stardust_id = cl_system_uuid=>create_uuid_x16_static( )
            color       = 'Silver'
            weight      = '3.000'
            value       = '80.00' )

          ( stardust_id = cl_system_uuid=>create_uuid_x16_static( )
            color       = 'Orange'
            weight      = '4.000'
            value       = '120.00' )

          ( stardust_id = cl_system_uuid=>create_uuid_x16_static( )
            color       = 'White'
            weight      = '5.000'
            value       = '200.00' )
        ).

        INSERT zds1910_t_sfarer FROM TABLE @lt_spacefarers.
        INSERT zds1910_t_scoll  FROM TABLE @lt_collections.
        INSERT zds1910_t_sdust  FROM TABLE @lt_stardusts.

        COMMIT WORK.

        out->write( 'Created 3 Spacefarers, 2 Collections and 8 Stardusts.' ).

      CATCH cx_root INTO DATA(lx_error).
        ROLLBACK WORK.
        out->write( lx_error->get_text( ) ).
    ENDTRY.


  ENDMETHOD.
ENDCLASS.
