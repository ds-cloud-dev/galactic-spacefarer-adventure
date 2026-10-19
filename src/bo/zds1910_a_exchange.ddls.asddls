@EndUserText.label: 'Galactic Adventure - Exchange Parameters'
define abstract entity ZDS1910_A_EXCHANGE
{

  @UI.hidden: true
  FirstOwnerId : sysuuid_x16;

  @EndUserText.label: 'Exchange Partner'
  @Consumption.valueHelpDefinition: [
    { entity: { name: 'ZDS1910_C_SPACEFARERVH', element: 'SpacefarerId' } }
  ]
  CounterpartyId : sysuuid_x16;

  @EndUserText.label: 'Stardust to Give'
  @Consumption.valueHelpDefinition: [
    { entity: { name: 'ZDS1910_C_STARDUSTVH', element: 'StardustId' },
      additionalBinding: [
        { localElement: 'FirstOwnerId', element: 'CollectionOwnerId', usage: #FILTER }
      ] }
  ]
  OwnStardustId : sysuuid_x16;

  @EndUserText.label: 'Stardust to Receive'
  @Consumption.valueHelpDefinition: [
    { entity: { name: 'ZDS1910_C_STARDUSTVH', element: 'StardustId' },
      additionalBinding: [
        { localElement: 'CounterpartyId', element: 'CollectionOwnerId', usage: #FILTER }
      ] }
  ]
  CounterpartyStardustId : sysuuid_x16;
  
}
