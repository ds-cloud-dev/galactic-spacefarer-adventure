CLASS zds1910_cl_trade_pricing DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    CLASS-METHODS:
        calculate
            IMPORTING iv_base_value        TYPE zds1910_t_sdust-value
                      iv_buyer_reputation  TYPE zds1910_t_sfarer-reputation
                      iv_seller_reputation TYPE zds1910_t_sfarer-reputation
            EXPORTING ev_price             TYPE decfloat34
                      es_result            TYPE zds1910_if_trading=>ty_result.

ENDCLASS.


CLASS zds1910_cl_trade_pricing IMPLEMENTATION.

  METHOD calculate.

    CONSTANTS: lc_base_reputation TYPE i          VALUE 30,
               lc_reputation_step TYPE i          VALUE 5,
               lc_max_amount      TYPE decfloat34 VALUE '9999999999999.99'.

    DATA: lv_buyer_steps   TYPE i,
          lv_seller_steps  TYPE i,
          lv_buyer_factor  TYPE decfloat34,
          lv_seller_factor TYPE decfloat34,
          lv_price         TYPE decfloat34.

    CLEAR: ev_price,
           es_result.

    IF iv_buyer_reputation < 0
       OR iv_buyer_reputation > 98
       OR iv_seller_reputation < 0
       OR iv_seller_reputation > 98.

      APPEND VALUE #( severity       = zds1910_if_trading=>gc_severity_error
                      message_id     = 'ZDS1910_MSG_GAP'
                      message_number = '017'
      ) TO es_result-messages.

      RETURN.

    ENDIF.

    IF iv_base_value < 0.

      APPEND VALUE #( severity       = zds1910_if_trading=>gc_severity_error
                      message_id     = 'ZDS1910_MSG_GAP'
                      message_number = '018'
      ) TO es_result-messages.

      RETURN.

    ENDIF.

    lv_buyer_steps = abs( iv_buyer_reputation - lc_base_reputation ) DIV lc_reputation_step.

    lv_seller_steps = abs( iv_seller_reputation - lc_base_reputation ) DIV lc_reputation_step.

    IF iv_buyer_reputation < lc_base_reputation.
      lv_buyer_steps = - lv_buyer_steps.
    ENDIF.

    IF iv_seller_reputation < lc_base_reputation.
      lv_seller_steps = - lv_seller_steps.
    ENDIF.

    lv_buyer_factor = 1 - CONV decfloat34( lv_buyer_steps ) / 100.

    lv_seller_factor = 1 + CONV decfloat34( lv_seller_steps ) / 100.

    lv_price = round( val  = CONV decfloat34( iv_base_value ) * lv_seller_factor * lv_buyer_factor dec  = 2 mode = cl_abap_math=>round_half_up ).

    IF lv_price > lc_max_amount.

      APPEND VALUE #( severity       = zds1910_if_trading=>gc_severity_error
                      message_id     = 'ZDS1910_MSG_GAP'
                      message_number = '019'
      ) TO es_result-messages.

      RETURN.

    ENDIF.

    ev_price = lv_price.
    es_result-success = abap_true.

  ENDMETHOD.

ENDCLASS.
