@EndUserText.label: 'Galactic Adv Project - Sfarer Wealth'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZDS1910_C_WEALTH
  as select from ZDS1910_I_WEALTH
{
  key SpacefarerId,
      Name,
      Credits,
      CollectionValue,
      TotalWealth,

      _ReadAuthorization
}
