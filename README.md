# Galactic Spacefarer Adventure 🚀

My solution to the Galactic Spacefarer Adventure exercise, built on SAP BTP ABAP Environment using the ABAP RESTful Application Programming Model (RAP). It includes Spacefarer maintenance, Collection and Wealth views, and Stardust trading through an ABAP API and Fiori Elements actions.

**[Data model and package layout](docs/DATA_MODEL.md)** — Entity–relationship diagram and a short explanation of the model.

## Getting started

An ABAP Environment and Eclipse with ABAP Development Tools are required.

1. Import the repository through abapGit into `ZDS1910_P_GAP`, including the `_BA` and `_BO` subpackages, and activate the objects.
2. Run `ZDS1910_CL_AUTH_SETUP` as an ABAP console application. Its default settings grant the current technical user create (`01`), update/trading (`02`), read (`03`) and delete (`06`) permissions.
3. Run `ZDS1910_CL_DEMO_DATA` to create the initial sample data: three Spacefarers, two Collections and eight Stardusts. It skips initialization if `GAP Test - Beginner` already exists - it is not a data-reset utility.
4. Open service binding `ZDS1910_UI_GAP_O2`, publish it in the target system and launch the preview. The service definition is `ZDS1910_UI_GAP`.

The repository contains source objects; application data and user permissions must be initialized separately. I tested the application in my development trial system. An import into a second, clean system has not been tested.

## Trying the application

Open `GAP Test - Beginner` in the Spacefarer preview and choose **Acquire Stardust**. Select `GAP Test - Stardust Owner` as seller and its Blue Stardust, valued at 20 Credits. With the initial reputations, the buyer's balance changes from 100 to 80 Credits and the seller's from 300 to 320. The buyer's first Collection is created during the purchase.

In the Collection view, the selected row determines whose behalf the action is performed on:

| Action | Selected Collection owner | Input |
| --- | --- | --- |
| Buy | Buyer | Seller and seller's Stardust |
| Sell | Seller | Buyer and own Stardust |
| Exchange | First exchange partner | Other partner and one Stardust from each Collection |

Exchange swaps the two items without a credit payment. The SAP user acts as an operator and can trade for different Spacefarers, subject to application permissions.

## Authorization

The tested trial solution uses `ZDS1910_T_UAUTH`: DCL restricts reads, and RAP checks create, update/trading and delete permissions. Read permission is also required for changes.

To test a denial, set `lc_grant_permissions` to `abap_false` in `ZDS1910_CL_AUTH_SETUP` and select only the activity to revoke in `lt_activities`, for example `02`. Activate and run, then reload the preview. To restore it, run with `abap_true`. Only listed activities are changed; granting `03` alone does not remove other grants. After testing, restore `abap_true` and the full `01/02/03/06` list. Keep one constant declaration and one activity assignment active. This helper sets application permissions, not SAP login or service-access roles.

## Tests

- Run ABAP Unit for `ZDS1910_CL_TRADE_PRICING`: four test methods cover 22 pricing cases.
- Optional: run `ZDS1910_CL_TRADE_TEST` as an ABAP console application in ADT after completing authorization setup. It executes nine trading integration tests and creates its own test data, which remains in the database after execution.
- These tests passed in the development system. I also checked UI validation, authorization denial, concurrent locking and stale-version handling manually.
