CLASS ltc_trade_pricing DEFINITION FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS: reputation_prices FOR TESTING,
             rounds_final_price FOR TESTING,
             accepts_amount_limits FOR TESTING,
             rejects_invalid_inputs FOR TESTING,

             assert_price
               IMPORTING iv_base_value        TYPE zds1910_t_sdust-value
                         iv_buyer_reputation  TYPE zds1910_t_sfarer-reputation
                         iv_seller_reputation TYPE zds1910_t_sfarer-reputation
                         iv_expected_price    TYPE decfloat34,

             assert_error
               IMPORTING iv_base_value        TYPE zds1910_t_sdust-value
                         iv_buyer_reputation  TYPE zds1910_t_sfarer-reputation
                         iv_seller_reputation TYPE zds1910_t_sfarer-reputation
                         iv_expected_message  TYPE symsgno.

ENDCLASS.


CLASS ltc_trade_pricing IMPLEMENTATION.

  METHOD reputation_prices.

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 30
      iv_expected_price    = '100'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 35
      iv_seller_reputation = 30
      iv_expected_price    = '99'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 35
      iv_expected_price    = '101'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 25
      iv_seller_reputation = 30
      iv_expected_price    = '101'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 25
      iv_expected_price    = '99'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 40
      iv_seller_reputation = 40
      iv_expected_price    = '99.96'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 34
      iv_seller_reputation = 30
      iv_expected_price    = '100'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 29
      iv_seller_reputation = 30
      iv_expected_price    = '100'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 29
      iv_expected_price    = '100'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 0
      iv_seller_reputation = 98
      iv_expected_price    = '119.78'
    ).

    assert_price(
      iv_base_value        = '100'
      iv_buyer_reputation  = 98
      iv_seller_reputation = 0
      iv_expected_price    = '81.78'
    ).

  ENDMETHOD.


  METHOD rounds_final_price.

    assert_price(
      iv_base_value        = '0.50'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 35
      iv_expected_price    = '0.51'
    ).

    assert_price(
      iv_base_value        = '0.50'
      iv_buyer_reputation  = 35
      iv_seller_reputation = 30
      iv_expected_price    = '0.50'
    ).

    assert_price(
      iv_base_value        = '0.50'
      iv_buyer_reputation  = 40
      iv_seller_reputation = 35
      iv_expected_price    = '0.49'
    ).

  ENDMETHOD.


  METHOD accepts_amount_limits.

    assert_price(
      iv_base_value        = '0'
      iv_buyer_reputation  = 98
      iv_seller_reputation = 0
      iv_expected_price    = '0'
    ).

    assert_price(
      iv_base_value        = '9999999999999.99'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 30
      iv_expected_price    = '9999999999999.99'
    ).

  ENDMETHOD.


  METHOD rejects_invalid_inputs.

    assert_error(
      iv_base_value        = '100'
      iv_buyer_reputation  = -1
      iv_seller_reputation = 30
      iv_expected_message  = '017'
    ).

    assert_error(
      iv_base_value        = '100'
      iv_buyer_reputation  = 99
      iv_seller_reputation = 30
      iv_expected_message  = '017'
    ).

    assert_error(
      iv_base_value        = '100'
      iv_buyer_reputation  = 30
      iv_seller_reputation = -1
      iv_expected_message  = '017'
    ).

    assert_error(
      iv_base_value        = '100'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 99
      iv_expected_message  = '017'
    ).

    assert_error(
      iv_base_value        = '-0.01'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 30
      iv_expected_message  = '018'
    ).

    assert_error(
      iv_base_value        = '9999999999999.99'
      iv_buyer_reputation  = 30
      iv_seller_reputation = 35
      iv_expected_message  = '019'
    ).

  ENDMETHOD.


  METHOD assert_price.

    DATA: lv_price   TYPE decfloat34,
          ls_result  TYPE zds1910_if_trading=>ty_result,
          lv_context TYPE string.

    "Simulate an error left over from a previous call
    ls_result-messages = VALUE #(
      ( severity       = zds1910_if_trading=>gc_severity_error
        message_id     = 'ZDS1910_MSG_GAP'
        message_number = '014' )
    ).

    zds1910_cl_trade_pricing=>calculate(
      EXPORTING iv_base_value        = iv_base_value
                iv_buyer_reputation  = iv_buyer_reputation
                iv_seller_reputation = iv_seller_reputation
      IMPORTING ev_price             = lv_price
                es_result            = ls_result
    ).

    lv_context = |Base { iv_base_value }, buyer { iv_buyer_reputation }, | && |seller { iv_seller_reputation }|.

    cl_abap_unit_assert=>assert_equals(
      act = lv_price
      exp = iv_expected_price
      msg = lv_context
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result
      exp = VALUE zds1910_if_trading=>ty_result(
        success = abap_true
      )
      msg = lv_context
    ).

  ENDMETHOD.


  METHOD assert_error.

    DATA: lv_price   TYPE decfloat34 VALUE '42',
          ls_result  TYPE zds1910_if_trading=>ty_result,
          lv_context TYPE string.

    "Simulate a successful result left over from a previous call
    ls_result-success = abap_true.

    zds1910_cl_trade_pricing=>calculate(
      EXPORTING iv_base_value        = iv_base_value
                iv_buyer_reputation  = iv_buyer_reputation
                iv_seller_reputation = iv_seller_reputation
      IMPORTING ev_price             = lv_price
                es_result            = ls_result
    ).

    lv_context = |Base { iv_base_value }, buyer { iv_buyer_reputation }, | && |seller { iv_seller_reputation }|.

    cl_abap_unit_assert=>assert_initial(
      act = lv_price
      msg = lv_context
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result
      exp = VALUE zds1910_if_trading=>ty_result(
        messages = VALUE #(
          ( severity       = zds1910_if_trading=>gc_severity_error
            message_id     = 'ZDS1910_MSG_GAP'
            message_number = iv_expected_message )
        )
      )
      msg = lv_context
    ).

  ENDMETHOD.

ENDCLASS.
