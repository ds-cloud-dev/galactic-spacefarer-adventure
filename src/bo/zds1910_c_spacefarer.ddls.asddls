@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adventure Project - Spacefarer'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZDS1910_C_SPACEFARER
  provider contract transactional_query
  as projection on ZDS1910_I_SPACEFARER
{
  key SpacefarerId,
      Name,
      NavigationSkill,
      Reputation,
      OriginPlanet,
      SpacesuitColor,
      Credits,
      CreatedBy,
      CreatedAt,
      ChangedBy,
      ChangedAt,

      _Collection : redirected to composition child ZDS1910_C_COLLECTION,
      _Stardust   : redirected to ZDS1910_C_STARDUST,
      _ReadAuthorization
}
