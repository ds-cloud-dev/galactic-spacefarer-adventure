@EndUserText.label: 'Galactic Adv Project - Sfarer Wealth'
@AccessControl.authorizationCheck: #CHECK
define view entity ZDS1910_I_WEALTH
  as select from    zds1910_t_sfarer          as Spacefarer

    left outer join ZDS1910_I_COLLECTIONVALUE as CollectionValue on Spacefarer.spacefarer_id = CollectionValue.CollectionOwnerId
{
  key Spacefarer.spacefarer_id                as SpacefarerId,
      Spacefarer.name                         as Name,
      Spacefarer.credits                      as Credits,

      coalesce( CollectionValue.CollectionValue,
                cast( 0 as abap.dec(23,2) ) ) as CollectionValue,

      cast( Spacefarer.credits as abap.dec(23,2) ) + coalesce( CollectionValue.CollectionValue,
          cast( 0 as abap.dec(23,2) ) )       as TotalWealth
}
