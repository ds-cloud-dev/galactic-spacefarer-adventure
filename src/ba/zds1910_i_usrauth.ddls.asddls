@EndUserText.label: 'Galactic Adventure - User Authorizations'
@AccessControl.authorizationCheck: #NOT_ALLOWED
define view entity ZDS1910_I_USRAUTH
  as select from zds1910_t_uauth
{
  key user_name as UserName,
  key activity  as Activity
}
