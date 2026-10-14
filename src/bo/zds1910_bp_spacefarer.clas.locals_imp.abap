CLASS lhc_Spacefarer DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Spacefarer RESULT result.

    METHODS validateDeletion FOR VALIDATE ON SAVE
       keys FOR Spacefarer~validateDeletion.

    METHODS validateSpacefarer FOR VALIDATE ON SAVE
       keys FOR Spacefarer~validateSpacefarer.

ENDCLASS.

CLASS lhc_Spacefarer IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD validateDeletion.
  ENDMETHOD.

  METHOD validateSpacefarer.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Collection DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS validateDeletion FOR VALIDATE ON SAVE
       keys FOR Collection~validateDeletion.

ENDCLASS.

CLASS lhc_Collection IMPLEMENTATION.

  METHOD validateDeletion.
  ENDMETHOD.

ENDCLASS.
