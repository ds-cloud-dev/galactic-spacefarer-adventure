@EndUserText.label: 'Galactic Adventure - Buy Parameters'
define abstract entity ZDS1910_A_BUY
{

  @EndUserText.label: 'Seller'
  @Consumption.valueHelpDefinition: [
    { entity : { name: 'ZDS1910_C_SPACEFARERVH', element: 'SpacefarerId' } }
  ]
  SellerId   : sysuuid_x16;

  @EndUserText.label: 'Stardust'
  @Consumption.valueHelpDefinition: [
    { entity : { name: 'ZDS1910_C_STARDUSTVH', element: 'StardustId' } ,
      additionalBinding: [
        { localElement: 'SellerId', element: 'CollectionOwnerId', usage: #FILTER }
      ] }
  ]
  StardustId : sysuuid_x16;

}
