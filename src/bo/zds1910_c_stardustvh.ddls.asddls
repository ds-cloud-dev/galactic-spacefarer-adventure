@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adventure - Stardust VH'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZDS1910_C_STARDUSTVH
  as select from    ZDS1910_I_STARDUST   as Stardust
    left outer join ZDS1910_I_SPACEFARER as Owner on Stardust.CollectionOwnerId = Owner.SpacefarerId
{
  key Stardust.StardustId,

      @ObjectModel.text.element: ['CollectionOwnerName']
      Stardust.CollectionOwnerId,

      @Search.defaultSearchElement: true
      Owner.Name as CollectionOwnerName,

      @Search.defaultSearchElement: true
      Stardust.Color,

      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      Stardust.Weight,

      Stardust.WeightUnit,

      @Search.defaultSearchElement: true
      Stardust.StateOfMatter,

      Stardust.StardustValue,

      Stardust._ReadAuthorization
}
