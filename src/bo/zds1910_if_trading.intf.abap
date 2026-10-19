INTERFACE zds1910_if_trading
  PUBLIC.

   TYPES: ty_spacefarer_id TYPE sysuuid_x16,
          ty_stardust_id   TYPE sysuuid_x16,
          ty_severity      TYPE c LENGTH 1,

          BEGIN OF ty_message,
            severity       TYPE ty_severity,
            message_id     TYPE symsgid,
            message_number TYPE symsgno,
            message_v1     TYPE symsgv,
            message_v2     TYPE symsgv,
            message_v3     TYPE symsgv,
            message_v4     TYPE symsgv,
          END OF ty_message,

          tt_message TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY,

          BEGIN OF ty_result,
            success  TYPE abap_bool,
            messages TYPE tt_message,
          END OF ty_result.


  CONSTANTS:
    gc_severity_success TYPE ty_severity VALUE 'S',
    gc_severity_info    TYPE ty_severity VALUE 'I',
    gc_severity_warning TYPE ty_severity VALUE 'W',
    gc_severity_error   TYPE ty_severity VALUE 'E'.


  METHODS: buy
             IMPORTING iv_buyer_id    TYPE ty_spacefarer_id
                       iv_seller_id   TYPE ty_spacefarer_id
                       iv_stardust_id TYPE ty_stardust_id
             RETURNING VALUE(rs_result) TYPE ty_result,

           sell
             IMPORTING iv_seller_id   TYPE ty_spacefarer_id
                       iv_buyer_id    TYPE ty_spacefarer_id
                       iv_stardust_id TYPE ty_stardust_id
             RETURNING VALUE(rs_result) TYPE ty_result,

           exchange
             IMPORTING iv_first_spacefarer_id  TYPE ty_spacefarer_id
                       iv_second_spacefarer_id TYPE ty_spacefarer_id
                       iv_first_stardust_id    TYPE ty_stardust_id
                       iv_second_stardust_id   TYPE ty_stardust_id
             RETURNING VALUE(rs_result) TYPE ty_result.

ENDINTERFACE.
