@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adv Project - Sdust Collection'
define view entity ZDS1910_I_COLLECTION
  as select from    zds1910_t_scoll           as Collection
    left outer join ZDS1910_I_COLLECTIONVALUE as CollectionValue on Collection.spacefarer_id = CollectionValue.CollectionOwnerId

  association [0..1] to ZDS1910_I_USRAUTH           as _ReadAuthorization on  _ReadAuthorization.UserName = $session.user
                                                                          and _ReadAuthorization.Activity = '03'

  association        to parent ZDS1910_I_SPACEFARER as _Spacefarer        on  $projection.SpacefarerId = _Spacefarer.SpacefarerId

  association [0..*] to ZDS1910_I_STARDUST          as _Stardust          on  $projection.SpacefarerId = _Stardust.CollectionOwnerId
  
{

  key Collection.spacefarer_id                     as SpacefarerId,

      coalesce( CollectionValue.StardustCount, 0 ) as StardustCount,
      coalesce( CollectionValue.CollectionValue,
                cast( 0 as abap.dec(23,2) ) )      as CollectionValue,

      @Semantics.user.createdBy: true
      Collection.created_by                        as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      Collection.created_at                        as CreatedAt,
      @Semantics.user.lastChangedBy: true
      Collection.changed_by                        as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Collection.changed_at                        as ChangedAt,

      _Spacefarer,
      _ReadAuthorization,
      _Stardust
      
}
