@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adventure Project - Collection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZDS1910_C_COLLECTION
  as projection on ZDS1910_I_COLLECTION
{
  key SpacefarerId,
      _Spacefarer.Name as SpacefarerName,
      StardustCount,
      CollectionValue,
      CreatedBy,
      CreatedAt,
      ChangedBy,
      ChangedAt,

      _ReadAuthorization,
      _Spacefarer : redirected to parent ZDS1910_C_SPACEFARER,
      _Stardust   : redirected to ZDS1910_C_STARDUST
}
