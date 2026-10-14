@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adventure Project - Spacefarer'
define root view entity ZDS1910_I_SPACEFARER
  as select from zds1910_t_sfarer
  
  composition [0..1] of ZDS1910_I_COLLECTION as _Collection
{
  key spacefarer_id    as SpacefarerId,
      name             as Name,
      navigation_skill as NavigationSkill,
      reputation       as Reputation,
      origin_planet    as OriginPlanet,
      spacesuit_color  as SpacesuitColor,
      credits          as Credits,
      @Semantics.user.createdBy: true
      created_by       as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at       as CreatedAt,
      @Semantics.user.lastChangedBy: true
      changed_by       as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changed_at       as ChangedAt,

      _Collection
}
