@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Galactic Adventure - Spacefarer VH'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZDS1910_C_SPACEFARERVH
  as select from ZDS1910_I_SPACEFARER
{
      @ObjectModel.text.element: ['Name']
  key SpacefarerId,

      @Search.defaultSearchElement: true
      Name,

      @Search.defaultSearchElement: true
      OriginPlanet,

      _ReadAuthorization
}
