@EndUserText.label: 'Galactic Adventure - Sell Parameters'
define abstract entity ZDS1910_A_SELL
{

  @UI.hidden : true
  SellerId   : sysuuid_x16;

  @EndUserText.label: 'Buyer'
  @Consumption.valueHelpDefinition: [
    { entity : { name: 'ZDS1910_C_SPACEFARERVH', element: 'SpacefarerId' } }
  ]
  BuyerId    : sysuuid_x16;

  @EndUserText.label: 'Stardust'
  @Consumption.valueHelpDefinition: [
    { entity : { name: 'ZDS1910_C_STARDUSTVH', element: 'StardustId' },
    additionalBinding: [
      { localElement: 'SellerId', element: 'CollectionOwnerId', usage: #FILTER }
    ]  }
  ]
  StardustId : sysuuid_x16;
  
}
