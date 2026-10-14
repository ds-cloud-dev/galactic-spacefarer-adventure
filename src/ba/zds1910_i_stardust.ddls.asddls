@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Galactic Adventure Project - Sdust View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZDS1910_I_STARDUST
  as select from zds1910_t_sdust
{
  key stardust_id         as StardustId,
      collection_owner_id as CollectionOwnerId,
      color               as Color,
      weight              as Weight,
      state_of_matter     as StateOfMatter,
      value               as StardustValue,
      @Semantics.user.createdBy: true
      created_by          as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at          as CreatedAt,
      @Semantics.user.lastChangedBy: true
      changed_by          as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changed_at          as ChangedAt
}
