@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adv Project - Sdust Collection'
define view entity ZDS1910_I_COLLECTION
  as select from zds1910_t_scoll

  association        to parent ZDS1910_I_SPACEFARER as _Spacefarer on $projection.SpacefarerId = _Spacefarer.SpacefarerId

  association [0..*] to ZDS1910_I_STARDUST          as _Stardust   on $projection.SpacefarerId = _Stardust.CollectionOwnerId
{
  key spacefarer_id as SpacefarerId,
      @Semantics.user.createdBy: true
      created_by    as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at    as CreatedAt,
      @Semantics.user.lastChangedBy: true
      changed_by    as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changed_at    as ChangedAt,

      _Spacefarer,
      _Stardust

}
