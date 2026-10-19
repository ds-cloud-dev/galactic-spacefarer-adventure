@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adventure Project - Stardust'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZDS1910_C_STARDUST
  provider contract transactional_query
  as projection on ZDS1910_I_STARDUST
{
  key StardustId,
      @ObjectModel.text.element: ['CollectionOwnerName']
      CollectionOwnerId,
      _CollectionOwner.Name as CollectionOwnerName,
      Color,
      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      Weight,
      WeightUnit,
      StateOfMatter,
      StardustValue,
      CreatedBy,
      CreatedAt,
      ChangedBy,
      ChangedAt,

      _ReadAuthorization
}
