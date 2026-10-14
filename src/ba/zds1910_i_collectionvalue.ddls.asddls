@EndUserText.label: 'Galactic Adventure Project - Coll. Value'
@AccessControl.authorizationCheck: #CHECK
define view entity ZDS1910_I_COLLECTIONVALUE
  as select from zds1910_t_sdust
{

  key collection_owner_id                    as CollectionOwnerId,
      sum( cast( value as abap.dec(23,2) ) ) as CollectionValue

}
group by
  collection_owner_id
