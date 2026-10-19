@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adventure Project - Sdust View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZDS1910_I_STARDUST
  as select from zds1910_t_sdust
  association [0..1] to ZDS1910_I_USRAUTH    as _ReadAuthorization on  _ReadAuthorization.UserName = $session.user
                                                                   and _ReadAuthorization.Activity = '03'
  association [0..1] to ZDS1910_I_SPACEFARER as _CollectionOwner   on  $projection.CollectionOwnerId = _CollectionOwner.SpacefarerId
{
  key stardust_id                  as StardustId,
      collection_owner_id          as CollectionOwnerId,
      color                        as Color,
      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      weight                       as Weight,
      cast( 'KG' as abap.unit(3) ) as WeightUnit,
      state_of_matter              as StateOfMatter,
      value                        as StardustValue,
      @Semantics.user.createdBy: true
      created_by                   as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                   as CreatedAt,
      @Semantics.user.lastChangedBy: true
      changed_by                   as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changed_at                   as ChangedAt,

      _ReadAuthorization,
      _CollectionOwner
}
