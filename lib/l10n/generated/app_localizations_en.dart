import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mi Cafetal';

  @override
  String get appTitleFull => 'Mi Cafetal App';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabRegister => 'Record';

  @override
  String get tabHistory => 'History';

  @override
  String get nextStepTitle => 'Your next step';

  @override
  String get nextStepAction => 'Go';

  @override
  String get nextStepCropTitle => 'Create your first crop';

  @override
  String get nextStepCropSubtitle => 'Start by recording the crop you manage (Coffee, Plantain…).';

  @override
  String get nextStepCropSetupTitle => 'Set up your first crop';

  @override
  String get nextStepCropSetupSubtitle => 'Review Coffee, Plantain or Other, or create yours, and adjust stage and area.';

  @override
  String nextStepSowingTitle(String crop) {
    return 'Record the planting of $crop';
  }

  @override
  String get nextStepSowingSubtitle => 'This crop has no initial planting recorded yet.';

  @override
  String get nextStepExpensesTitle => 'Record your first expenses';

  @override
  String get nextStepExpensesSubtitle => 'Track what you invest each month.';

  @override
  String get nextStepSaleTitle => 'Record the sale of your harvest';

  @override
  String get nextStepSaleSubtitle => 'Logging it also records the harvested kilos for that crop.';

  @override
  String get nextStepGuideLink => 'View full guide';

  @override
  String get welcomeTitle => 'What do you grow?';

  @override
  String get welcomeSubtitle => 'Start with what you grow most. Add the rest later.';

  @override
  String get welcomeEmptyList => 'No crops yet';

  @override
  String get welcomeAddFirst => 'Add the first one';

  @override
  String get welcomeAddMore => 'Add another';

  @override
  String get welcomeEnter => 'Enter the app';

  @override
  String get welcomeIconLabel => 'Icon';

  @override
  String get welcomeDone => 'Done';

  @override
  String get welcomeComplete => 'Fill in details…';

  @override
  String get onboardingCropAddedTitle => 'Crop added';

  @override
  String get onboardingAnother => 'Add another';

  @override
  String get onboardingAnotherPrompt => 'Crop added. Do you want to register another crop already planted on your farm?';

  @override
  String get onboardingDone => 'Enter, I\'m done';

  @override
  String get sowingNewCropOption => '+ Create new crop…';

  @override
  String get sowingNewCropTitle => 'New crop';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpSectionGuide => 'Getting started guide';

  @override
  String get helpIntro => 'Mi Cafetal is the account book for your farm: you write down what you spend and what you sell, and the app does the math. In the end you know what really matters: whether your farm is making or losing money, and why.';

  @override
  String get helpWhyTitle => 'What it is for';

  @override
  String get helpWhyBody => 'To know whether you are making or losing money, how much each kilo you produce costs you, and how each crop and each month is doing. With those numbers you decide: what to plant, when to sell, where to cut costs.';

  @override
  String get helpDoesTitle => 'What it does';

  @override
  String get helpDoesBody => 'It adds up what you record —expenses, plantings, sales and your workers\' daily pay— and shows you the month, the year, the cash box, the cost per kilo and the kilos per hectare or per plant. It warns you when something is off and lets you export reports to PDF or Excel.';

  @override
  String get helpDataTitle => 'Your data is yours';

  @override
  String get helpDataBody => 'It is stored on your phone and the app works without internet. Nothing is made up: if a figure is missing, it is left blank instead of being filled with a zero. You can back it up to a file or sync it to see it from another device.';

  @override
  String get helpWhereTitle => 'Where do I enter each piece of data?';

  @override
  String get helpRowOverview => 'Your farm overview (income, expenses and balance)';

  @override
  String get helpRowCrops => 'Set up your farm\'s crops';

  @override
  String get helpRowSowings => 'Plant or replant';

  @override
  String get helpRowExpenses => 'Expenses (supplies, labor…)';

  @override
  String get helpRowIncome => 'Sales of your harvest';

  @override
  String get helpRowReport => 'See whether you made or lost money and get the report as PDF or Excel';

  @override
  String get helpRowWorkers => 'Save your workers and their pay per day';

  @override
  String get helpRowJornal => 'Log a day wage';

  @override
  String get helpRowLote => 'Create a plot (terreno) and say which crops go inside';

  @override
  String get helpRowSettings => 'Pick the language, the month\'s cash box, and get your backup';

  @override
  String get helpRowHistory => 'Look up what you logged and fix it';

  @override
  String get helpCaseTitle => 'Where do I start? Depends on your case';

  @override
  String get helpCaseATitle => 'Case A — I already have crops planted';

  @override
  String get helpCaseA1 => 'Crops: review Coffee and Plantain and set their stage to Producing (and, if you know it, area and live plants).';

  @override
  String get helpCaseA2 => 'Record: enter the month\'s expenses (supplies, labor).';

  @override
  String get helpCaseA3 => 'Record: when you sell, add an income with the kilos and the money you received; that crop\'s harvest is logged on its own from those kilos.';

  @override
  String get helpCaseA4 => 'Open Overview and check your numbers: harvested, cost per kilo and margin.';

  @override
  String get helpCaseAEnd => 'Check the Overview: balance and indicators start making sense.';

  @override
  String get helpCaseBTitle => 'I have nothing yet and I am starting';

  @override
  String get helpCaseB1 => 'Tell the app what you are going to plant: in Crops create your crop (coffee or plantain, for example) and set the stage to Not producing yet. Add the area if you know it.';

  @override
  String get helpCaseB2 => 'In Plantings, record how many plants you put in and on what area, and the cost if you want. If your crop is not in the list, pick \"Create new crop\" and you create it right there.';

  @override
  String get helpCaseB3 => 'While the crop is not producing yet the app does not flag losses: it is investment, not production.';

  @override
  String get helpCaseB4 => 'When it starts Producing, follow the Case A flow: the sales, and that is where your harvest comes from.';

  @override
  String get helpCaseCTitle => 'Renewing the whole plantation';

  @override
  String get helpCaseC1 => 'A full renewal is recorded as a new sowing of the same crop.';

  @override
  String get helpCaseC2 => 'That resets age, plants and area; old harvests stay in the history.';

  @override
  String get helpCaseC3 => 'If crops share the same plot (coffee with plantain, for example), the clearest way is to create a separate crop for each.';

  @override
  String get helpCaseCEnd => 'Nothing needs to be deleted: the history still counts what already happened.';

  @override
  String get helpUnitsTitle => 'Units';

  @override
  String get helpUnitsBody => 'Use kg, pounds (lb), arroba (12.5 kg), sacks or load (27.2 kg). The app converts everything to kg for comparison, using the sack weight you set in Settings.';

  @override
  String get helpUnitsTableTitle => 'Equivalences';

  @override
  String get helpUnitsKgRow => 'Kilogram (kg)';

  @override
  String get helpUnitsKgRowDesc => 'Base unit. Everything is converted to kg.';

  @override
  String get helpUnitsArrobaRow => 'Arroba';

  @override
  String get helpUnitsArrobaRowDesc => '12.5 kg. Common for coffee in Colombia.';

  @override
  String get helpUnitsSacoRow => 'Bag (saco)';

  @override
  String get helpUnitsSacoRowDesc => 'For coffee in sacks. Change the weight in Settings.';

  @override
  String get helpUnitsCargaRow => 'Load (carga)';

  @override
  String get helpUnitsCargaRowDesc => '27.2 kg (60 lbs). Colombian coffee unit.';

  @override
  String get helpUnitsLbRow => 'Pound (lb)';

  @override
  String get helpUnitsLbRowDesc => '0.45 kg. Common in some countries.';

  @override
  String get helpUnitsRacimoRow => 'Bunch';

  @override
  String get helpUnitsRacimoRowDesc => 'For plantain. Not weighed.';

  @override
  String get helpUnitsCajonRow => 'Crate';

  @override
  String get helpUnitsCajonRowDesc => 'For fruits and vegetables. Weight varies.';

  @override
  String get helpCaseAExampleTitle => 'Case A — coffee in production (2 ha, 3000 plants)';

  @override
  String get helpCaseAEx1 => 'Coffee, Producing, Perennial, 2 ha, 3000 plants';

  @override
  String get helpCaseAEx2 => 'COP 500,000 expense on Fertilizer';

  @override
  String get helpCaseAEx4 => 'COP 750,000 income from selling 50 kg (4 arrobas)';

  @override
  String get helpCaseAEx5 => 'Balance +COP 250,000 · Margin 33% · ROI 50%';

  @override
  String get helpCaseBExampleTitle => 'Case B — freshly planted plantain (500 plants on 0.5 ha)';

  @override
  String get helpCaseBEx1 => 'Plantain, Not producing yet, Perennial, 0.5 ha, 500 plants';

  @override
  String get helpCaseBEx2 => 'Initial planting, 500 plants, 0.5 ha, cost COP 200,000';

  @override
  String get helpCaseBEx3 => 'COP 100,000 labor and COP 150,000 fertilizer';

  @override
  String get helpCaseBEx4 => 'Investment COP 450,000. It does not say loss: it is an investment until it produces.';

  @override
  String get helpPerPlantTitle => 'And per plant? When does it start yielding?';

  @override
  String get helpPerPlantIntro => 'If you know how many live plants the crop has, the app also shows kilos per plant. It helps when you counted the plants but did not measure the land.';

  @override
  String get helpPerPlantOwn => 'Next to it you get your own average from previous years. It is nobody\'s table: the app measures against your own land.';

  @override
  String get helpPerPlantAlert => 'If you wrote when you expected the first harvest and that date passed with no harvest, the app warns you: “should be yielding since …”.';

  @override
  String get helpOtherTitle => 'The rest of what the app does';

  @override
  String get helpTerrenosTitle => 'Your plots (terrenos)';

  @override
  String get helpTerrenosIntro => 'A plot is the land where your crop sits. It does two things: keeps the plot\'s location and splits one expense that belongs to several crops together.';

  @override
  String get helpTerrenosWhere => 'In Crops, tap the mountain icon to create the plot: name, hectares if you measured them, which crops go inside, and the location if you want.';

  @override
  String get helpTerrenosLocation => 'You can take the location from the phone, type it by hand, or leave it empty. The app never re-measures it on its own.';

  @override
  String get helpTerrenosSplit => 'An expense for the whole plot (a clearing, the fertilizer) is logged on the plot and split by hectares. If a crop has no area, that part is not split and shows separately.';

  @override
  String get helpTerrenosReport => 'In Report a “Your plots · location” card appears only if some plot has a coordinate.';

  @override
  String get helpWorkersTitle => 'Workers and day wages';

  @override
  String get helpWorkersIntro => 'You save your workers so you don\'t type their pay each time.';

  @override
  String get helpWorkersWhere => 'In the ⋮ menu → Workers. Give a name and, if you want, their pay per day; if you leave it empty, you write it when logging each day wage.';

  @override
  String get helpWorkersJornal => 'The day wage is logged as a labor expense in Record: you pick the worker and the days. The name is saved with the record, so deleting a worker does not delete their history.';

  @override
  String get helpWorkersReport => 'In Report you see the period\'s payroll (who, how many days, the total) and the monthly timesheet.';

  @override
  String get helpCajaTitle => 'The month\'s cash box';

  @override
  String get helpCajaIntro => 'The cash box is the money you set aside each month for the farm: it covers day wages and small expenses (power, water, repairs).';

  @override
  String get helpCajaWhere => 'You set it in Settings → “Monthly cash contribution”. If you leave it empty, the card does not show.';

  @override
  String get helpCajaCarry => 'What you don\'t spend is not lost: it carries over to the next month. The bar turns green, amber, or red depending on how much you have spent.';

  @override
  String get helpReportTitle => 'The report and its files';

  @override
  String get helpReportIntro => 'In Report you pick the period (week, month, year, or year-to-date) and see whether you made or lost money, the cost per kilo, how each crop is doing, the month\'s cash box, and what is worth doing next.';

  @override
  String get helpReportExport => 'With the export buttons you take it as PDF or Excel, plus a balance template. Share it wherever you want.';

  @override
  String get helpBackupTitle => 'Your backup';

  @override
  String get helpBackupIntro => 'A backup is a file of your own with all your data: crops, plantings, expenses, sales, workers, and settings.';

  @override
  String get helpBackupWhere => 'In Settings → Backup you export it (and share it) and restore it whenever you want.';

  @override
  String get helpBackupAdditive => 'Restoring deletes nothing: what you already have stays and the file\'s data is added.';

  @override
  String get helpBackupVsSync => 'This is not the same as syncing. Syncing saves to the cloud so you can see it from another device.';

  @override
  String get helpLanguageTitle => 'Language and how numbers are read';

  @override
  String get helpLanguageIntro => 'The app speaks Spanish and English: you pick it in Settings → “Language”.';

  @override
  String get helpLanguageNumbers => 'Numbers are read the way your language does: in Spanish COP 1.500 and in English COP 1,500.';

  @override
  String get helpLanguageCurrency => 'The currency is picked once and always read with its code (COP), never with a symbol.';

  @override
  String get helpGlossaryTitle => 'Glossary';

  @override
  String get helpGlossaryBody => 'Seedlings: young plantation in establishment. Area: crop surface. Live plants: current total (planting − losses + replanting). Sold vs harvested: how much of the harvest has already gone out as a sale. Sync: saves to the cloud to log in from any device. Alert: automatic notice on the Overview.';

  @override
  String get helpGlossaryFinance => 'View financial glossary';

  @override
  String get helpPerHaTitle => 'What does per-hectare mean?';

  @override
  String get helpPerHaIntro => 'Normalizing per hectare makes your data comparable: you can tell whether one plot outperforms another even when their sizes differ.';

  @override
  String get helpPerHaTitleYield => 'Yield (kg/ha)';

  @override
  String get helpPerHaYield => 'Harvests in the period ÷ crop area. The same standard as your exports.';

  @override
  String get helpPerHaTitleVentas => 'Sales per ha';

  @override
  String get helpPerHaRevenue => 'Income in the period ÷ area. How much money your land produces.';

  @override
  String get helpPerHaTitleGastos => 'Expenses per ha';

  @override
  String get helpPerHaCost => 'Expenses in the period ÷ area. How much each hectare costs to produce.';

  @override
  String get helpPerHaTitleMargen => 'Margin per ha';

  @override
  String get helpPerHaMargin => 'Sales − expenses, per hectare. Positive = the hectare leaves profit.';

  @override
  String get helpPerHaWhy => 'Why normalize? A 3 ha plot selling COP 9,000,000 does not compete with a 1 ha plot selling COP 5,000,000: per hectare, the second one wins. The panel divides by area so you compare by the same rule.';

  @override
  String get helpPaybackTitle => 'How is the establishment investment recovered?';

  @override
  String get helpPaybackIntro => 'When editing a crop you can record the Total investment: what you invested in planting and raising the crop (seedlings, labor, initial fertilization…).';

  @override
  String get helpPaybackTitlePercent => '% recovered';

  @override
  String get helpPaybackPercent => 'The app divides the crop\'s accumulated margin (sales − expenses) by that investment. 100% = you have paid it off.';

  @override
  String get helpPaybackTitleYears => 'Payback in N years (approx.)';

  @override
  String get helpPaybackYears => 'Average of the measured annual margin. It is an average of your real data, not a harvest promise.';

  @override
  String get helpPaybackTitleNotLoss => 'It is not a loss: it is an investment';

  @override
  String get helpPaybackNotLoss => 'If you invest COP 1,000,000 planting coffee and have not sold yet, you did not lose COP 1,000,000. You invested COP 1,000,000. When you start selling, the recovery percentage starts to rise.';

  @override
  String get helpFlowTitle => 'The order of the app';

  @override
  String get helpFlowIntro => 'Think of it as a chain: first you tell it what you grow, then how much you planted, then what you spent, and finally what you sold — that is where your harvest is logged.';

  @override
  String get helpFlowStep1Title => 'Define the crop';

  @override
  String get helpFlowStep1Body => 'What you manage (coffee, plantain…).';

  @override
  String get helpFlowStep2Title => 'Record the planting';

  @override
  String get helpFlowStep2Body => 'How many plants you put in.';

  @override
  String get helpFlowStep3Title => 'Log expenses';

  @override
  String get helpFlowStep3Body => 'What you invested.';

  @override
  String get helpFlowStep4Title => 'Record the sale';

  @override
  String get helpFlowStep4Body => 'Who you sold to, how much and the kilos: that is where your harvest comes from.';

  @override
  String get helpFlowHint => 'The \"Your next step\" card on the Overview tells you exactly which record you need next. Once you have logged your expenses and your sales, the card disappears on its own.';

  @override
  String get helpCommonTitle => 'Common mistakes (and how to fix them)';

  @override
  String get helpCommonAmount => 'I entered the wrong amount';

  @override
  String get helpCommonAmountFix => 'Go to History, find the record, edit or delete it';

  @override
  String get helpCommonAssigned => 'I did not assign a crop to an expense';

  @override
  String get helpCommonAssignedFix => 'In History you will see \"X records without a crop\". Press \"Assign crops now\" and pick which crop it belongs to';

  @override
  String get helpCommonType => 'I mixed up expense and income';

  @override
  String get helpCommonTypeFix => 'Open the record and switch the type from Expense to Income (or the other way)';

  @override
  String get helpCommonCurrency => 'Can I change the currency?';

  @override
  String get helpCommonCurrencyFix => 'No. It is chosen once, when you start, and cannot be changed — so all your amounts always match';

  @override
  String get helpCommonArea => 'I cannot see the \"Per hectare\" panel';

  @override
  String get helpCommonAreaFix => 'Set the crop area: in Crops edit the crop and enter the hectares';

  @override
  String get syncTooltip => 'Sync';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncRetry => 'Retry';

  @override
  String get syncErrorTooltip => 'Some data has not synced. Tap for details';

  @override
  String get menuReport => 'Report';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuLogout => 'Sign out';

  @override
  String get menuSowings => 'Plantings';

  @override
  String get menuHarvests => 'Harvests';

  @override
  String get menuHelp => 'Help';

  @override
  String get unitRacimo => 'Bunches';

  @override
  String get unitCajon => 'Crates';

  @override
  String get defaultUnitLabel => 'Preferred unit';

  @override
  String get defaultUnitNone => 'No preference';

  @override
  String get cycleLabel => 'Cycle';

  @override
  String get cyclePerenne => 'Perennial';

  @override
  String get cycleAnual => 'Annual';

  @override
  String get phaseLabel => 'How is it doing?';

  @override
  String get phaseEstablecimiento => 'Not producing yet';

  @override
  String get phaseProduccion => 'Producing';

  @override
  String get phaseRenovacion => 'To renew';

  @override
  String get phaseHelp => 'Not producing yet = planted and growing, but no harvest yet. The app will not flag losses at this stage.';

  @override
  String get helpUnit => 'What unit do you sell in: kg, lb, arroba (≈12.5 kg), sack, load (≈27.2 kg), bunch (plantain) or crate?';

  @override
  String get helpCycle => 'Perennial = lives many years (coffee, plantain). Annual = planted and harvested in the same year (tomato, corn).';

  @override
  String get helpArea => '1 hectare = 10,000 m² (≈ 1 soccer field). Leave blank if unsure.';

  @override
  String get helpPlants => 'How many plants of this crop do you have. Approximate if unsure.';

  @override
  String get helpEstablishment => 'What you invested to get this crop ready. Used to know when it pays off. If you leave it empty, the app sums it from your initial planting expenses (excluding replanting).';

  @override
  String get areaHaLabel => 'Area (hectares)';

  @override
  String get livePlantsLabel => 'Live plants';

  @override
  String get establishmentCostLabel => 'Total investment';

  @override
  String get expectedYieldLabel => 'Annual goal (kg/ha)';

  @override
  String get helpExpectedYield => 'What you want to get from this lot per year. It\'s YOUR number, not someone else\'s table: the app doesn\'t measure you against Cenicafé or anyone else, it measures against what you set. Empty = nothing is compared.';

  @override
  String get firstHarvestLabel => 'When do you expect the first harvest?';

  @override
  String get firstHarvestEmpty => 'No estimated date';

  @override
  String firstHarvestSoon(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months left',
      one: '$count month left',
      zero: 'this month',
    );
    return 'est. first harvest: $date · $_temp0';
  }

  @override
  String firstHarvestOverdue(String date) {
    return 'should be yielding since $date';
  }

  @override
  String get cropLockedHint => 'Calculated from your sowings';

  @override
  String get cropLossRegister => 'Record loss';

  @override
  String cropLossCurrent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plants',
      one: '$count plant',
    );
    return 'Right now the app calculates $_temp0';
  }

  @override
  String get cropLossRemainingLabel => 'Plants remaining';

  @override
  String get cropLossRemainingHelp => 'Count the ones you see in the field and enter the total.';

  @override
  String get cropLossInvalid => 'Enter a valid number of plants.';

  @override
  String get cropLossNoChange => 'That is the number already there: nothing changes.';

  @override
  String cropLossPreviewDied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plants lost',
      one: '$count plant lost',
    );
    return '$_temp0';
  }

  @override
  String cropLossPreviewAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count extra plants',
      one: '$count extra plant',
    );
    return '$_temp0';
  }

  @override
  String get cropLossSaved => 'Loss recorded';

  @override
  String get plantedAtLabel => 'When was it planted?';

  @override
  String get helpPlantedAtShort => 'Optional. Leave it empty if you don\'t remember.';

  @override
  String get plantedAtEmpty => 'No date';

  @override
  String get plantedAtClear => 'Clear the date';

  @override
  String cropAge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
      zero: 'Less than a year',
    );
    return '$_temp0';
  }

  @override
  String get editCropTitle => 'Edit crop';

  @override
  String get sowingTitle => 'Plantings';

  @override
  String get sowingEmpty => 'No plantings recorded yet.';

  @override
  String get sowingAdd => 'New planting';

  @override
  String get sowingKindLabel => 'Type';

  @override
  String get sowingKindSiembra => 'Initial planting';

  @override
  String get sowingKindResiembra => 'Replanting';

  @override
  String get helpSowingKind => 'Planting = first time planting. Replanting = replacing dead or damaged plants.';

  @override
  String get sowingPlantsLabel => 'Number of plants';

  @override
  String get helpSowingPlants => 'How many plants are you putting in. Approximate if unsure.';

  @override
  String get sowingLostPlantsLabel => 'Lost plants (losses)';

  @override
  String get sowingMissingLossesTitle => 'You entered new plants without losses';

  @override
  String get sowingMissingLossesBody => 'In a replant, it helps to record how many plants were lost: that is what lowers the crop count. You can save as is and complete it later.';

  @override
  String get sowingMissingLossesEnter => 'Enter losses';

  @override
  String get sowingMissingLossesSave => 'Save as is';

  @override
  String get helpSowingLostPlants => 'How many plants died or were lost (pests, weather, etc.).';

  @override
  String get sowingReasonLabel => 'Reason (optional)';

  @override
  String get sowingAreaLabel => 'Area (hectares, optional)';

  @override
  String get helpSowingArea => '1 hectare = 10,000 m² (≈ 1 soccer field).';

  @override
  String get sowingCostLabel => 'Cost (optional)';

  @override
  String get sowingCostHint => 'If you record a cost, a linked expense is created for this planting or replanting.';

  @override
  String get sowingCostInvalid => 'Enter a valid cost (numbers only).';

  @override
  String get helpUnitShort => 'Unit you harvest or sell this crop in.';

  @override
  String get helpCycleShort => 'Perennial or annual';

  @override
  String get phaseHelpShort => 'Crop phase';

  @override
  String get helpAreaShort => 'Optional, in ha';

  @override
  String get helpPlantsShort => 'Approximate';

  @override
  String get helpEstablishmentShort => 'Filled from your planting expenses';

  @override
  String get helpExpectedYieldShort => 'Optional, your own goal';

  @override
  String get helpFirstHarvestShort => 'Optional. It\'s YOUR date: the app just does the calendar math.';

  @override
  String get helpSowingPlantsShort => 'Approximate';

  @override
  String get helpSowingLostPlantsShort => 'Dead or damaged';

  @override
  String get helpSowingAreaShort => 'In hectares';

  @override
  String get sowingCostHintShort => 'Creates linked expense';

  @override
  String get plantsInvalid => 'Enter a valid number of plants';

  @override
  String get sowingPlantsOrLost => 'Enter the plants you sowed or the ones that died.';

  @override
  String get sowingRecordSaved => 'Planting saved';

  @override
  String get sowingRecordUpdated => 'Planting updated';

  @override
  String get sowingRecordDeleted => 'Planting deleted';

  @override
  String get sowingConfirmDelete => 'Delete this planting?';

  @override
  String get harvestTitle => 'Harvests';

  @override
  String get harvestEmpty => 'No harvests recorded yet.';

  @override
  String get harvestAdd => 'New harvest';

  @override
  String get harvestAmountLabel => 'Quantity';

  @override
  String get harvestUnitLabel => 'Unit';

  @override
  String get harvestDestinationLabel => 'Destination';

  @override
  String get harvestDstVendido => 'Sold';

  @override
  String get harvestDstAlmacenado => 'Stored';

  @override
  String get harvestDstPerdida => 'Loss';

  @override
  String get harvestAmountInvalid => 'Enter a quantity greater than 0';

  @override
  String get harvestRecordSaved => 'Harvest saved';

  @override
  String get harvestRecordUpdated => 'Harvest updated';

  @override
  String get harvestRecordDeleted => 'Harvest deleted';

  @override
  String get harvestConfirmDelete => 'Delete this harvest?';

  @override
  String get expenseLinkHarvestLabel => 'Link to harvest (optional)';

  @override
  String get expenseLinkHarvestNone => 'Not linked';

  @override
  String get unitPreferenceHint => 'Your preferred unit is used if you have not picked one.';

  @override
  String get reportHarvestSection => 'Harvests of the period';

  @override
  String get reportHarvestedTotal => 'Total harvested per crop';

  @override
  String get reportHarvestKg => 'Kg (normalized)';

  @override
  String get reportHarvestDestinations => 'By destination';

  @override
  String reportPendingWeightHarvests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count harvests without weight',
      one: '$count harvest without weight',
    );
    return '$_temp0';
  }

  @override
  String reportPendingWeightSales(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales without weight',
      one: '$count sale without weight',
    );
    return '$_temp0';
  }

  @override
  String get reportPendingWeightTitle => 'Missing weight (not counted in kilos)';

  @override
  String get reportPendingWeightHint => 'Enter the total weight so they count toward kilos.';

  @override
  String get reportPickupCostPerKg => 'Picking cost per kg';

  @override
  String get reportTotalCostPerKg => 'Total cost per kg';

  @override
  String get reportInvestmentEstablecimiento => 'Accumulated investment (establishment)';

  @override
  String get reportYieldPerArea => 'Yield per area for the period (kg/ha)';

  @override
  String get reportYieldPerPlant => 'Yield per plant for the period (kg/plant)';

  @override
  String get reportApprox => '(approximate)';

  @override
  String get reportSoldVsHarvested => 'Sold vs harvested';

  @override
  String get reportSoldKg => 'Sold (kg)';

  @override
  String get reportHarvestedKg => 'Harvested (kg)';

  @override
  String soldVsHarvestedMismatch(Object pct) {
    return 'You sold $pct% more than you harvested this period. This is usually a harvest from earlier months or one you have not recorded.';
  }

  @override
  String get soldVsHarvestedNoHarvest => 'You recorded no harvest for this crop in this period. The sale may come from a harvest in earlier months.';

  @override
  String get reportSowingsSection => 'Sowings';

  @override
  String get reportSowingsNow => 'What do I have planted today?';

  @override
  String get reportSowingsPlantOne => 'plant';

  @override
  String get reportSowingsPlantMany => 'plants';

  @override
  String get reportSowingsTotal => 'Total planted';

  @override
  String get reportSowingsLosses => 'Accumulated losses';

  @override
  String reportSowingsInPeriod(Object period) {
    return 'Sowings in $period';
  }

  @override
  String get reportSowingsKindSiembra => 'sowing';

  @override
  String get reportSowingsKindResiembra => 'replanting';

  @override
  String reportSowingsLostLine(Object count, Object reason) {
    return '↳ $count lost · $reason';
  }

  @override
  String reportSowingsLostOnly(Object count) {
    return '↳ $count lost';
  }

  @override
  String get reportSowingsNoPeriod => 'You did not record sowings in this period.';

  @override
  String get reportWhatsNext => 'What to do next';

  @override
  String get reportNoRecommendations => 'No recommendations for this period.';

  @override
  String get reportNoHarvestData => 'No harvest data in this period.';

  @override
  String get harvestWorkersLabel => 'No. of workers';

  @override
  String get harvestWorkersHint => 'Optional. People who worked on this harvest.';

  @override
  String get harvestWorkersInvalid => 'Enter an integer greater than or equal to 0.';

  @override
  String harvestWorkersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workers',
      one: '$count worker',
    );
    return '$_temp0';
  }

  @override
  String get harvestEquivalentKgLabel => 'Total weight (kg)';

  @override
  String get harvestEquivalentKgHint => 'Required: what the bunches or boxes weighed together.';

  @override
  String get harvestEquivalentKgInvalid => 'Enter a number greater than 0.';

  @override
  String get harvestEquivalentKgRequired => 'Enter the total weight so the kilos can be counted.';

  @override
  String harvestPriceLabel(String unit) {
    return 'Price per $unit';
  }

  @override
  String get harvestPriceHint => 'If you already got paid, write it here and the app records the sale for you. Leave it empty if you haven\'t been paid yet.';

  @override
  String get harvestPriceInvalid => 'Enter a valid price (numbers only).';

  @override
  String harvestSalePreview(String amount) {
    return 'Sale recorded: $amount';
  }

  @override
  String get reportPayrollSection => 'Payroll of the period';

  @override
  String get reportPayrollBudgetNote => 'This is what was spent per task; the cash budget is a single one.';

  @override
  String get reportPayrollWorker => 'Worker';

  @override
  String get reportPayrollDays => 'Days';

  @override
  String get reportPayrollSubtotal => 'Subtotal';

  @override
  String get reportPayrollTotal => 'Total payroll';

  @override
  String reportPayrollEmployees(int count) {
    return 'Distinct workers: $count';
  }

  @override
  String get reportPayrollUnnamed => 'Unnamed';

  @override
  String get reportCashBoxBudget => 'Budget';

  @override
  String get reportCashBoxBalance => 'Balance';

  @override
  String get reportHarvestStaff => 'Staff and kilos';

  @override
  String get reportEquivalentKg => 'Equivalent kilos';

  @override
  String get perHaSection => 'Per hectare';

  @override
  String get perHaNoAreaHint => 'Set the area of your crops (edit the crop) to see their per-hectare performance: normalized yield, income and expenses.';

  @override
  String get perHaYieldLabel => 'Yield for the period';

  @override
  String get perHaYieldPlantLabel => 'Yield per plant for the period';

  @override
  String get perHaPerPlantNote => 'kg/plant is the crop average; it includes plants that are not producing yet.';

  @override
  String yieldAvgHaLabel(int years) {
    return 'Your annual average ($years years)';
  }

  @override
  String yieldAvgPlantLabel(int years) {
    return 'Your per-plant average ($years years)';
  }

  @override
  String get yieldGoalLabel => 'Annual goal';

  @override
  String get perHaRevenueLabel => 'Sales per ha';

  @override
  String get perHaCostLabel => 'Expenses per ha';

  @override
  String get perHaMarginLabel => 'Margin per ha';

  @override
  String get perHaInvestmentLabel => 'Establishment investment';

  @override
  String get perHaRecoveredLabel => 'Recovered';

  @override
  String get perHaRecoveryPending => 'Pending recovery';

  @override
  String get perHaPaybackLabel => 'Payback in';

  @override
  String perHaPaybackYears(String years) {
    return '$years years (approx.)';
  }

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String get conjAnd => 'and';

  @override
  String get sectionThisMonth => 'This month';

  @override
  String sectionInYear(int year) {
    return 'In $year';
  }

  @override
  String get incomeLabel => 'Income';

  @override
  String get expensesLabel => 'Expenses';

  @override
  String get resultLabel => 'Result';

  @override
  String summaryVsPrev(String month) {
    return 'vs. $month';
  }

  @override
  String summaryVsPrevNote(String month) {
    return 'Compared with the same days of $month.';
  }

  @override
  String summaryResultBetter(String amount) {
    return 'improved $amount';
  }

  @override
  String summaryResultWorse(String amount) {
    return 'worsened $amount';
  }

  @override
  String get summaryEmptyTitle => 'You haven\'t recorded any movements yet';

  @override
  String get summaryEmptyBody => 'Once you note down an expense or a sale, this is where you\'ll see how much you earned, how much you spent, and what was left.';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsTooltip => 'What do these alerts mean?';

  @override
  String get glossaryTitle => 'What do these terms mean?';

  @override
  String get glossaryGotIt => 'Got it';

  @override
  String get glossaryRoiTerm => 'ROI (Return on Investment)';

  @override
  String get glossaryRoiDef => 'Measures how much you recover for every dollar invested in a crop. It is calculated as (Income − Expenses) ÷ Expenses. A negative ROI means the crop spends more than it recovers: for example, an ROI of −70% means that for every \$100 invested only \$30 come back.';

  @override
  String get glossaryBalanceTerm => 'Balance / Result';

  @override
  String get glossaryBalanceDef => 'Income minus Expenses in a period. If the result is positive you have a gain; if negative, a loss.';

  @override
  String get glossaryMarginTerm => 'Margin on sales';

  @override
  String get glossaryMarginDef => 'Of every \$100 you sell, how much remains as profit after covering expenses. A margin of 20% means that for every \$100 sold, \$20 remain.';

  @override
  String get glossaryRatioTerm => 'Expenses vs income';

  @override
  String get glossaryRatioDef => 'What percentage of your income goes to expenses. For example, 80% means that for every \$100 that come in, \$80 are spent and \$20 remain.';

  @override
  String get glossaryAvgTerm => 'Monthly historical average';

  @override
  String get glossaryAvgDef => 'The average of what you spend per month in a category (for example, labor). It serves as a reference to detect unusual increases in your expenses.';

  @override
  String get glossaryYieldAreaTerm => 'Yield per area (kg/ha)';

  @override
  String get glossaryYieldAreaDef => 'How many kilos you get from one hectare. It lets you compare plots of different sizes: if one gives 1,200 kg/ha and another 800 kg/ha, the first yields more from the same land.';

  @override
  String get glossaryYieldPlantTerm => 'Yield per plant (kg/plant)';

  @override
  String get glossaryYieldPlantDef => 'How many kilos each plant produces. It helps you tell whether the problem is the number of plants or how the crop is being cared for.';

  @override
  String get glossaryCostPerKgTerm => 'Total cost per kg';

  @override
  String get glossaryCostPerKgDef => 'Everything it cost you to produce each kilo (establishment, labor and the period\'s expenses) divided by the kilos harvested. If you sell below this number, you lose money.';

  @override
  String get glossaryPickupCostTerm => 'Picking cost per kg';

  @override
  String get glossaryPickupCostDef => 'What you pay to pick one kilo: day labor and collection, not counting what you invested in planting. It is the immediate cost of each harvest.';

  @override
  String get glossaryEstablishmentTerm => 'Establishment investment';

  @override
  String get glossaryEstablishmentDef => 'What you invested to start the crop: seedlings, initial fertilizer and the labor of planting. It is not a loss, it is an investment you recover through sales.';

  @override
  String get glossaryPaybackTerm => 'Payback (recovery)';

  @override
  String get glossaryPaybackDef => 'How long it takes you to recover what you invested in establishment. 100% means you have already paid it off completely with what you sold.';

  @override
  String get glossarySubtotalTerm => 'Subtotal';

  @override
  String get glossarySubtotalDef => 'A partial sum of a group of rows before the grand total. In payroll it is what each worker is paid before the period total.';

  @override
  String get glossaryYtdTerm => 'Year to date (YTD)';

  @override
  String get glossaryYtdDef => 'What has accumulated from January 1 of this year until today, no matter which month you are looking at.';

  @override
  String get glossaryPayrollTerm => 'Payroll for the period';

  @override
  String get glossaryPayrollDef => 'What was paid for labor in the period: people, days worked and day labor. It does not include what you invest in planting.';

  @override
  String get glossaryCashBoxTerm => 'Petty cash';

  @override
  String get glossaryCashBoxDef => 'Money available for small monthly expenses: transport, tools and emergencies. It is compared against the budget you set so you do not overspend.';

  @override
  String get glossarySoldVsHarvestedTerm => 'Sold vs harvested';

  @override
  String get glossarySoldVsHarvestedDef => 'Compares the kilos you sold with the kilos you harvested in the same period. If you sold more, it is usually a harvest from earlier months or one you have not recorded.';

  @override
  String get glossaryRoiTooltip => 'What does ROI mean?';

  @override
  String get authSubtitleSignup => 'Create an account to manage your finances';

  @override
  String get authSubtitleWelcome => 'Welcome back';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authInvalidEmail => 'Enter a valid email';

  @override
  String get authPasswordTooShort => 'At least 6 characters';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authNoAccount => 'No account? Register';

  @override
  String get authCreatedMsg => 'Account created. Check your email (including spam) to confirm, then sign in.';

  @override
  String get authCreateError => 'Error creating the account';

  @override
  String get authSignInError => 'Error signing in';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authResetSent => 'We sent you a link to reset your password. Check your email (including spam).';

  @override
  String get registerEditTitle => 'Edit movement';

  @override
  String get expenseTypeLabel => 'Expense';

  @override
  String get incomeTypeLabel => 'Income';

  @override
  String get cropFieldLabel => 'Crop or plot (optional)';

  @override
  String get cropUnspecified => 'Not specified';

  @override
  String get cropNewOption => '+ New crop…';

  @override
  String get cropGroupHint => 'Tap “+ New crop…” to create a new crop; the ones you already have are in the list. Transactions for the same crop are added together in the report.';

  @override
  String get commonCosts => 'Common costs';

  @override
  String get commonCostsHint => 'It\'s a farm-wide expense (fence, road, electricity). It doesn\'t affect any crop\'s cost/kg, but it does affect the bottom line.';

  @override
  String get expenseSplitTitle => 'Split between crops';

  @override
  String get expenseSplitBody => 'The expense serves several crops. Separate expenses are saved, one per crop, and they add up to the total.';

  @override
  String get expenseSplitHint => 'The expense is split between crops: separate expenses are saved and they add up to the total.';

  @override
  String get expenseSplitUseAreas => 'Use areas';

  @override
  String expenseSplitSum(String percent) {
    return 'Total: $percent %';
  }

  @override
  String get expenseSplitMustSum => 'The percentages must add up to 100 %.';

  @override
  String get expenseSplitZero => 'Every crop you choose needs a percentage above 0.';

  @override
  String get expenseSplitFew => 'Choose at least two crops.';

  @override
  String get expenseSplitNoAreas => 'To use areas, at least two crops need their area entered.';

  @override
  String expenseSplitChosen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split between $count crops',
      one: 'Split between $count crop',
    );
    return '$_temp0';
  }

  @override
  String get expenseSplitChange => 'Change';

  @override
  String get expenseSplitClear => 'Remove split';

  @override
  String get expenseSplitNeedAmount => 'Enter the expense amount first.';

  @override
  String expenseSplitPercent(String percent) {
    return '$percent %';
  }

  @override
  String get noCropLabel => 'No crop';

  @override
  String get noCropHint => 'It doesn\'t belong to any crop. It stays in the farm\'s overall result.';

  @override
  String loteNoRepartido(String name) {
    return '$name · not split';
  }

  @override
  String get sowingCategoryHint => 'If this is for a crop, pick its name below: the expense will count as its investment and show up in its cost/kg. If the crop doesn\'t exist yet, tap “+ New crop…”.';

  @override
  String get harvestCategoryHint => 'What the harvest itself costs: bags, supplies and moving the coffee. If you paid someone to pick it, that payment goes under Labor, not here.';

  @override
  String get laborCategoryHint => 'What you pay people, even for picking, fertilizing or weeding. Here you note who worked and how many days.';

  @override
  String get seedsCategoryHint => 'What you spend during the season: seeds, bags and other supplies. If it\'s seedlings or plants for a crop, switch to Planting: there it counts as investment and shows in its cost/kg.';

  @override
  String get irrigationCategoryHint => 'The system that carries water to the crops: pump, drip line, tank. The water bill goes under Water and the electricity bill under Energy.';

  @override
  String get waterCategoryHint => 'The farm\'s water service, just like electricity. The bill belongs here; the irrigation system —pump, drip line, tank— goes under Irrigation.';

  @override
  String get deductionSwitchLabel => 'The buyer deducted before paying';

  @override
  String get deductionHint => 'Coffee isn\'t always paid in full: impurity, moisture or stones.';

  @override
  String get deductionQtyLabel => 'Deducted quantity';

  @override
  String get deductionQtyInvalid => 'Enter the quantity they deducted';

  @override
  String get deductionReasonLabel => 'Reason for the deduction';

  @override
  String get deductionReasonHint => 'impurity, moisture, stones…';

  @override
  String get deductionRegisteredLabel => 'Delivered';

  @override
  String get deductionDeductedLabel => 'Deducted';

  @override
  String get deductionPaidLabel => 'Paid';

  @override
  String get deductionOverQuantity => 'They deducted more than you delivered: check the quantity.';

  @override
  String get paidStatusTitle => 'Payment status';

  @override
  String get paidStatusPaid => 'Paid';

  @override
  String get paidStatusPending => 'Unpaid';

  @override
  String get categoryFieldLabel => 'Category';

  @override
  String get amountFieldLabel => 'Amount';

  @override
  String get amountInvalid => 'Enter a valid amount';

  @override
  String get dateFieldLabel => 'Date';

  @override
  String get datePickerHelp => 'Transaction date';

  @override
  String get descriptionFieldLabel => 'Description (optional)';

  @override
  String get saveRecord => 'Save record';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get expenseFootnote => 'You are recording an EXPENSE. The amount will be used in your monthly summary.';

  @override
  String get incomeFootnote => 'You are recording an INCOME. The amount will be used in your monthly summary.';

  @override
  String get prodSectionTitle => 'Production data';

  @override
  String get quantityFieldLabel => 'Quantity sold';

  @override
  String get unitFieldLabel => 'Unit';

  @override
  String get unitKg => 'Kilograms (kg)';

  @override
  String get unitArroba => 'Arrobas (12.5 kg)';

  @override
  String get unitSaco => 'Bags';

  @override
  String get unitLb => 'Pounds (lb)';

  @override
  String get unitCarga => 'Loads (27.2 kg)';

  @override
  String get clientFieldLabel => 'Client / buyer (optional)';

  @override
  String get providerFieldLabel => 'Supplier / seller (optional)';

  @override
  String get pricePerUnitLabel => 'Price per';

  @override
  String get pricePerUnitHint => 'Calculated automatically: amount ÷ quantity';

  @override
  String get lowPriceThresholdLabel => 'Minimum sale price per kg';

  @override
  String get lowPriceThresholdHelper => 'Optional. Alert when selling coffee below this price (per kg). Leave empty to use only your history.';

  @override
  String get sacoKgLabel => 'Weight of a sack (kg)';

  @override
  String get sacoKgHelper => 'Converts sacks to kilograms in reports, PDF and alerts. The coffee standard is 70.';

  @override
  String get excelColQty => 'Quantity';

  @override
  String get excelColUnit => 'Unit';

  @override
  String get excelColPricePerUnit => 'Price per unit';

  @override
  String get excelColClient => 'Client';

  @override
  String get excelColProvider => 'Supplier';

  @override
  String get excelColCurrency => 'Currency';

  @override
  String get excelColBalance => 'Balance';

  @override
  String get excelMonthlyTitle => 'Income and expenses by month';

  @override
  String get excelCrossExpensesTitle => 'Expenses by category and crop';

  @override
  String get topClientsTitle => 'Top buyers';

  @override
  String get topProvidersTitle => 'Top suppliers';

  @override
  String get recordSaved => 'Record saved';

  @override
  String get recordUpdated => 'Movement updated';

  @override
  String get recordDeleted => 'Movement deleted';

  @override
  String get deleteDialogTitle => 'Delete movement';

  @override
  String get deleteDialogBody => 'This action deletes the record. Do you confirm?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get newCropDialogTitle => 'New crop';

  @override
  String get welcomeCompleteTitle => 'Complete the crop';

  @override
  String get save => 'Save';

  @override
  String get cropNameLabel => 'Crop name';

  @override
  String get cropNameRequired => 'Type the crop name.';

  @override
  String get cropNameTaken => 'A crop with that name already exists. Type a different one.';

  @override
  String get newCropDuplicateTitle => 'You already have a crop with that name';

  @override
  String newCropDuplicateBody(String name) {
    return '“$name” is already in your crop list. What would you like to do?';
  }

  @override
  String get newCropUseExisting => 'Use the one you have';

  @override
  String get newCropCreateAnother => 'Create another one';

  @override
  String cropLotTag(int n) {
    return 'lot $n';
  }

  @override
  String get cropPhaseNoYield => 'not yielding yet · first harvest pending';

  @override
  String get sowingRenovacionCheckbox => 'This replanting renewed the crop — change its phase to renewal';

  @override
  String get sowingRestartCheckbox => 'This planting restarted the crop — put it back to \"Not producing yet\" and clear the first-harvest date';

  @override
  String get sowingWhatHappensOldPlants => 'What happens to the plants you already have?';

  @override
  String get sowingExpandOption => 'I\'m expanding: nothing is replaced';

  @override
  String get sowingRenewOption => 'I\'m renewing part of it';

  @override
  String get sowingRenewHint => 'The old lot\'s plants go down and the new ones add up. The total doesn\'t inflate.';

  @override
  String get sowingReplaceCohortLabel => 'Lot I\'m renewing';

  @override
  String get sowingReplacePlantsLabel => 'Plants being replaced';

  @override
  String get sowingReplacePlantsRequired => 'Enter how many plants you\'re replacing.';

  @override
  String sowingReplacePlantsPrefill(int plants, int live) {
    return 'Estimated by area: $plants of $live';
  }

  @override
  String get sowingReplaceNoArea => 'The old lot has no area: tell me how many plants you\'re replacing.';

  @override
  String sowingReplaceAll(int live) {
    return 'All ($live)';
  }

  @override
  String sowingReplaceTooMany(int live) {
    return 'That lot has $live living plants: you can\'t replace more.';
  }

  @override
  String get sowingReplaceAreaLabel => 'Area being replaced (ha)';

  @override
  String sowingCohortOption(String date, int plants) {
    return '$date · $plants plants';
  }

  @override
  String get sowingCohortLabel => 'Lot';

  @override
  String get sowingCohortNoneTitle => 'There\'s no living lot';

  @override
  String get sowingCohortNoneBody => 'This crop has no living plants to replant into. If you\'re starting over, record it as a sowing.';

  @override
  String get sowingCohortNoneSaveAs => 'Record as sowing';

  @override
  String get sowingNoCohortTag => 'No lot';

  @override
  String sowingDeleteCohortBody(int total) {
    return 'Another sowing takes plants away from this lot. If you delete it, those replacements stop applying and the crop total becomes $total plants.';
  }

  @override
  String cohortsCount(int count) {
    return '$count ages';
  }

  @override
  String get cohortOpen => 'Open';

  @override
  String get cohortRenewed => 'Renewed';

  @override
  String cohortRenewedOn(String date) {
    return 'Renewed on $date';
  }

  @override
  String get cohortsHistoryTitle => 'Renewed lots';

  @override
  String get cohortsAreaFallback => 'Not every lot has an area: the crop area is the one you entered.';

  @override
  String cohortsAreaMismatch(String sum, String manual) {
    return 'The lots with an area add up to $sum ha; the crop says $manual ha.';
  }

  @override
  String get cohortsNoLivingPlants => 'This crop has no living plants.';

  @override
  String get helpCohortsRenewTitle => 'Renewing part of a lot';

  @override
  String get helpCohortsRenew => 'Renewing part of a lot subtracts those plants from the old lot and opens a new one with its own age. The old history isn\'t erased.';

  @override
  String perHaAgesAverage(int count) {
    return 'average of $count ages';
  }

  @override
  String get sowingAreaMissingWarning => 'Without an area you cannot see costs per hectare. You can still save.';

  @override
  String get cropSetupPrompt => 'Your crop is ready to use. Do you want to complete its details (phase, area, plants, unit)?';

  @override
  String get cropSetupComplete => 'Complete';

  @override
  String get cropSetupLater => 'Not now';

  @override
  String get deleteCropTitle => 'Delete crop?';

  @override
  String deleteCropBody(int sowings, int harvests, String name) {
    return 'The sowings ($sowings) and harvests ($harvests) of \"$name\" will be deleted. Expenses and sales will remain without a crop.';
  }

  @override
  String deleteCropBodyEmpty(Object name) {
    return '\"$name\" has no sowings or harvests yet. Expenses and sales will remain without a crop.';
  }

  @override
  String get expenseGroupProduccion => 'Production costs';

  @override
  String get expenseGroupVenta => 'Selling costs';

  @override
  String get expenseGroupFijos => 'Fixed costs';

  @override
  String get expenseGroupOtros => 'Other costs';

  @override
  String get menuCrops => 'Crops';

  @override
  String get cropsEmpty => 'No crops yet. Add the first one.';

  @override
  String get menuWorkers => 'Workers';

  @override
  String get workersEmpty => 'No workers yet. Add the first one.';

  @override
  String get workerNewOption => '+ New worker…';

  @override
  String get newWorkerDialogTitle => 'New worker';

  @override
  String get editWorkerTitle => 'Edit worker';

  @override
  String get workerNameLabel => 'Name';

  @override
  String get workerNameRequired => 'Type the worker\'s name.';

  @override
  String get workerDayRateLabel => 'Day rate (optional)';

  @override
  String get workerDayRateShort => 'Day rate';

  @override
  String get helpWorkerDayRate => 'Autofilled when you record day labor. Leave blank if you prefer to type it each time.';

  @override
  String get workerConfirmDelete => 'Delete worker';

  @override
  String get workerDeleted => 'Worker deleted';

  @override
  String get workerWorkedIn => 'Worked in';

  @override
  String get workerNoJornales => 'No day-labor records yet';

  @override
  String get workerNoRate => 'No day rate set';

  @override
  String get jornalSectionTitle => 'Day labor';

  @override
  String get jornalWorkerLabel => 'Worker';

  @override
  String get jornalWorkerHint => 'Create your workers from the ⋮ menu, or pick “Other name”.';

  @override
  String get jornalWorkerRequired => 'Choose the worker.';

  @override
  String get jornalOtherNameOption => 'Other name…';

  @override
  String get jornalCreateOption => 'Create worker…';

  @override
  String get jornalDaysLabel => 'Days worked';

  @override
  String get jornalDaysRequired => 'Enter the days (integer greater than 0).';

  @override
  String get jornalRateRequired => 'Enter the day rate.';

  @override
  String get jornalTotalLabel => 'Total';

  @override
  String get jornalTotalHint => 'Calculated: days × day rate.';

  @override
  String get jornalHarvestedKgLabel => 'Harvested kilos (optional)';

  @override
  String get jornalHarvestedKgHelp => 'To compare what you harvested with what you sold.';

  @override
  String get jornalHarvestedKgNoCrop => 'Select the crop to record the kilos.';

  @override
  String get jornalHarvestedKgInvalid => 'Enter the harvested kilos (greater than 0).';

  @override
  String get cashBoxLabel => 'Monthly cash contribution';

  @override
  String get cashBoxHelp => 'What you take out of the farm each month: it covers day labor and small expenses. Whatever you don\'t spend isn\'t lost — it rolls over to next month. The contribution starts this month: previous months are not recalculated.';

  @override
  String get cashBoxCarry => 'Carried over from previous months';

  @override
  String get cashBoxMonthly => 'This month\'s contribution';

  @override
  String get cashBoxTitle => 'Cash box';

  @override
  String cashBoxOf(String used, String total) {
    return '$used of $total';
  }

  @override
  String get cashBoxRemaining => 'Remaining';

  @override
  String get cashBoxLabor => 'Day labor';

  @override
  String get cashBoxExtras => 'Extras';

  @override
  String get workBudgetTitle => 'Work budget';

  @override
  String workBudgetOf(String used, String total) {
    return '$used of $total';
  }

  @override
  String get workBudgetRemaining => 'Remaining';

  @override
  String get workBudgetBalance => 'Work balance';

  @override
  String get taskFieldLabel => 'What work';

  @override
  String get taskFieldHint => 'What was done?';

  @override
  String get taskOtherOption => '✏️ Other…';

  @override
  String get taskOtherLabel => 'Task name';

  @override
  String get taskOtherHint => 'Write it your way';

  @override
  String get workSheetTitle => 'Monthly timesheet';

  @override
  String get workSheetWorkers => 'people';

  @override
  String get workSheetDayPlural => 'day';

  @override
  String get workSheetDayOther => 'days';

  @override
  String get workSheetUnlabeled => 'No task';

  @override
  String get workSheetNoTasks => 'You haven\'t logged a task on any day labor yet. When you record one, pick “What work” and it will show up here.';

  @override
  String get segMonth => 'Month';

  @override
  String get segYear => 'Year';

  @override
  String get segAll => 'All';

  @override
  String get segYearToDate => 'Year to date';

  @override
  String yearLabel(int year) {
    return 'Year $year';
  }

  @override
  String get allMovementsLabel => 'All transactions';

  @override
  String get noMovements => 'No transactions in this period.';

  @override
  String confirmDeleteExpense(String amount) {
    return 'Expense of $amount — confirm?';
  }

  @override
  String confirmDeleteIncome(String amount) {
    return 'Income of $amount — confirm?';
  }

  @override
  String reportPeriodMonth(String monthName, int year) {
    return '$monthName $year';
  }

  @override
  String reportChipMonth(String monthName, int year) {
    return '$monthName $year';
  }

  @override
  String reportPeriodYtd(int year) {
    return '$year to date';
  }

  @override
  String reportChipYtd(int year) {
    return '$year · to date';
  }

  @override
  String get segWeek => 'Week';

  @override
  String reportPeriodWeek(int week, int year) {
    return 'Week $week, $year';
  }

  @override
  String reportChipWeek(int week) {
    return 'W$week';
  }

  @override
  String get harvestCargasLabel => 'loads';

  @override
  String get harvestCargasNote => '1 load ≈ 60 lbs ≈ 27.2 kg';

  @override
  String get incomeStatementTitle => 'Income statement';

  @override
  String get noIncomePeriod => 'No income in this period';

  @override
  String get operatingExpensesLabel => 'Operating expenses';

  @override
  String get noExpensesPeriod => 'No expenses in this period.';

  @override
  String get resultPeriodLabel => 'PERIOD RESULT';

  @override
  String get marginLabel => 'Margin on sales';

  @override
  String get ratioLabel => 'Expenses vs income';

  @override
  String get metricMarginGood => 'Good margin: you keep \$20 or more of every \$100 sold.';

  @override
  String get metricMarginFair => 'Tight margin: you keep between \$10 and \$20 of every \$100 sold.';

  @override
  String get metricMarginLow => 'Low margin: you keep less than \$10 of every \$100 sold.';

  @override
  String get metricMarginLoss => 'Loss: your expenses are higher than what you sold.';

  @override
  String get metricMarginBreakEven => 'Neither gain nor loss: expenses exactly cover what you sold.';

  @override
  String get metricNoSales => 'No sales in this period: it cannot be calculated.';

  @override
  String get metricRatioHealthy => 'Good control: of every \$100 that comes in, up to \$70 goes to expenses.';

  @override
  String get metricRatioHigh => 'You spend quite a bit: of every \$100 that comes in, between \$70 and \$90 goes to expenses.';

  @override
  String get metricRatioCritical => 'You spend almost everything you earn: more than \$90 of every \$100 goes to expenses.';

  @override
  String get metricCostPriceLabel => 'Sale price per kg';

  @override
  String get metricMarginPerKgLabel => 'Margin per kg';

  @override
  String get metricMarginPerKgGood => 'You sell above what it cost you to produce it.';

  @override
  String get metricMarginPerKgBad => 'You sell below what it cost you to produce it: every kilo sold takes away.';

  @override
  String get metricMarginPerKgZero => 'You sell at cost: neither gain nor loss per kg.';

  @override
  String get metricReceivablesLabel => 'Unpaid sales';

  @override
  String get metricReceivablesNote => 'They have not paid you yet: that money is not in the cash box.';

  @override
  String get metricLaborShareLabel => 'Labor as a share of spending';

  @override
  String get metricLaborShareNote => 'This is the part of everything you spent in the period that went to labor.';

  @override
  String metricCostPriceAbove(String cost) {
    return 'It costs you $cost per kg. You sell above your cost.';
  }

  @override
  String metricCostPriceBelow(String cost) {
    return 'It costs you $cost per kg. You sell below your cost: every kg sold subtracts.';
  }

  @override
  String metricCostPriceEqual(String cost) {
    return 'It costs you $cost per kg and you sell at that same price: neither gain nor loss.';
  }

  @override
  String get metricCostPriceNoCost => 'Nothing harvested this period: there is still no cost per kg to compare.';

  @override
  String metricCostPriceNoQty(String cost) {
    return 'It costs you $cost per kg, but your sales do not record kg: it cannot be compared.';
  }

  @override
  String cropBreakdownTitle(String period) {
    return 'Breakdown by crop — $period';
  }

  @override
  String get cropBreakdownSummaryG => 'Expenses';

  @override
  String get cropBreakdownInvestment => 'Initial investment';

  @override
  String get cropBreakdownOperation => 'Operating costs this period';

  @override
  String get cropBreakdownSummaryI => 'Income';

  @override
  String get cropBreakdownSummaryR => 'Net result';

  @override
  String get cropBreakdownRoiHint => 'How to read ROI: for every \$1 invested you recover the profit plus the capital. E.g., ROI 516% → \$6.16 back per \$1 (5.16 profit + 1 of capital).';

  @override
  String get noCropData => 'No crop data in this period.';

  @override
  String get exportPdf => 'Export PDF and share';

  @override
  String get generating => 'Generating…';

  @override
  String get exportExcel => 'Export to Excel and share';

  @override
  String get exportBalance => 'Balance template (Excel)';

  @override
  String movementsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movements',
      one: '$count movement',
    );
    return '$_temp0';
  }

  @override
  String get reportGeneratedSnack => 'Report generated.';

  @override
  String exportError(String error) {
    return 'Could not export: $error';
  }

  @override
  String get exportNeedsNetworkOnce => 'The first time, you need a connection to prepare the export. Check your connection and try again.';

  @override
  String pdfShareSubject(int year) {
    return 'Mi Cafetal — Report $year';
  }

  @override
  String get farmNameLabel => 'Farm name';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get currencyDisplayLabel => 'Currency';

  @override
  String get currencyDisplayHelper => 'The one and only currency of your account and all your records.';

  @override
  String get currencyLockedHelper => 'You picked this currency when you started and it cannot be changed, so all your amounts always match.';

  @override
  String get currencyGateTitle => 'Which currency do you manage your accounts in?';

  @override
  String get currencyGateBody => 'This will be the only currency in your account and it cannot be changed later.';

  @override
  String currencyGateCta(String currency) {
    return 'Start with $currency';
  }

  @override
  String get currencyGateRequired => 'You need to pick a currency before you can record your first data.';

  @override
  String currencyRegisterHint(String currency) {
    return 'Recorded in $currency.';
  }

  @override
  String currencyMixedHint(int count) {
    return 'Showing in $count currencies';
  }

  @override
  String cropMixedCurrencyNote(int count) {
    return 'This crop has $count currencies: each one is shown separately and ROI is not calculated.';
  }

  @override
  String currencyMixedByCurrencyNote(int count) {
    return 'In $count currencies: each amount shows its own currency; they are not added up or compared with each other.';
  }

  @override
  String currencyConvertedTotal(String currency, String amount) {
    return 'Total in $currency: $amount';
  }

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get saveButton => 'Save';

  @override
  String get converting => 'Converting…';

  @override
  String get rateErrorMsg => 'Could not get the exchange rate. Check your connection and try again.';

  @override
  String currencyChangedMsg(String currency) {
    return 'Report currency changed to $currency. Amounts you already saved stay in the currency you recorded them in; totals are now shown in $currency.';
  }

  @override
  String get currencyRateNote => 'Total at today\'s rate. Each entry stays in its own currency.';

  @override
  String get settingsSavedMsg => 'Settings saved';

  @override
  String get noIncomesPeriod => 'No income in this period.';

  @override
  String get recordExpense => 'Record expense';

  @override
  String get recordIncome => 'Record income';

  @override
  String get expensesByCategory => 'Expenses by category';

  @override
  String get incomesByCategory => 'Income by category';

  @override
  String categoryBreakdownTotal(Object total) {
    return 'Period total: $total';
  }

  @override
  String categoryBreakdownShowMore(Object count) {
    return 'Show $count more';
  }

  @override
  String get categoryBreakdownShowLess => 'Show less';

  @override
  String get assignCropsTitle => 'Assign crops';

  @override
  String get assignCropsSubtitle => 'Pick a crop for each record. All changes are saved together.';

  @override
  String get assignCropsUnassigned => 'No crop';

  @override
  String get assignCropsNewCrop => 'New crop…';

  @override
  String get assignCropsSave => 'Save changes';

  @override
  String assignCropsSaved(Object count) {
    return '$count records updated';
  }

  @override
  String get assignCropsEmpty => 'No unassigned records left. All done!';

  @override
  String assignCropsBanner(Object count) {
    return '$count records without an assigned crop';
  }

  @override
  String get assignCropsNow => 'Assign crops now';

  @override
  String get insightsTitle => 'Period conclusion';

  @override
  String get insightNoActivity => 'No movements were recorded in this period.';

  @override
  String insightBalanceNoIncome(Object spent) {
    return 'Period result: $spent in expenses and no sales in this period.';
  }

  @override
  String insightBalancePositive(Object balance, Object margin) {
    return 'Period result: $balance gain with $margin margin over sales.';
  }

  @override
  String insightBalanceNegative(Object loss, Object margin) {
    return 'Period result: $loss with $margin margin over sales.';
  }

  @override
  String insightVsPrev(String month, String incChange, String expChange) {
    return 'Compared to $month: sales $incChange and expenses $expChange.';
  }

  @override
  String insightVsPrevPartial(String month, String incChange, String expChange) {
    return 'Compared to $month (same days): sales $incChange and expenses $expChange.';
  }

  @override
  String insightChangeUp(Object pct) {
    return 'went up $pct';
  }

  @override
  String insightChangeDown(Object pct) {
    return 'went down $pct';
  }

  @override
  String get insightChangeFlat => 'unchanged';

  @override
  String insightTopExpense(String category, String amount, String pct) {
    return 'Your biggest expense was $category ($amount, $pct of the total).';
  }

  @override
  String insightTopExpenseDependency(Object category) {
    return 'You concentrate more than half of your expenses in $category: review that recurring cost before it keeps growing.';
  }

  @override
  String insightTopIncome(String category, String amount, String pct) {
    return 'Your best income was $category ($amount, $pct of the total).';
  }

  @override
  String insightLowPrice(String recent, String history) {
    return 'You sell cheaper than your historical average: recent average $recent vs $history per kg. Check price, packaging or sales channel.';
  }

  @override
  String insightBestMonth(String salesMonth, String salesAmount, String costMonth, String costAmount) {
    return 'Your best sales month was $salesMonth ($salesAmount); your lowest monthly expense was $costMonth ($costAmount).';
  }

  @override
  String chartTitle(int year) {
    return 'Expenses vs income — $year';
  }

  @override
  String chartCumulativeTitle(int year) {
    return 'Your money in $year — running total';
  }

  @override
  String get chartCumulativeSubtitle => 'Income minus expenses, month by month. Tap a point to see where you stood.';

  @override
  String get chartStartLabel => 'where you started';

  @override
  String chartAccumDelta(String amount) {
    return '$amount since January 1';
  }

  @override
  String chartCumulativeEmpty(int year) {
    return 'No movements recorded in $year yet.';
  }

  @override
  String alertExcessTitle(String category) {
    return 'Your $category spending nearly doubled';
  }

  @override
  String alertExcessMessage(String current, String category, String avg) {
    return 'The problem: this month you have $current in $category, versus an average of $avg per month.';
  }

  @override
  String get alertExcessSuggestion => 'Check what caused the increase. If it was a large one-off expense, record it in parts so it does not distort your averages.';

  @override
  String get alertNoIncomeTitle => 'Expenses recorded, but zero sales';

  @override
  String alertNoIncomeMessage(String spent) {
    return 'The problem: there are $spent in expenses and no sales, so the balance is at a loss.';
  }

  @override
  String get alertNoIncomeSuggestion => 'When you sell your harvest, record it as income so the balance shows your real profit.';

  @override
  String alertNoSalesTitle(int days) {
    return 'No sales recorded for $days days';
  }

  @override
  String alertNoSalesMessage(String date) {
    return 'The problem: you have not sold since $date. Your income has been stagnant since then.';
  }

  @override
  String get alertNoSalesSuggestion => 'Record the last harvested crop sold or the most recent sale to keep the income statement up to date.';

  @override
  String alertLossesTitle(int count) {
    return '$count consecutive months with losses (expenses > income)';
  }

  @override
  String alertLossesMessage(String months) {
    return 'The problem: in $months you spent more than you earned.';
  }

  @override
  String get alertLossesSuggestion => 'Review your fixed costs (labor, fertilizer, transport) and look to reduce expenses or improve the sales price.';

  @override
  String get alertLowPriceTitle => 'Your recent sales yield less than your average';

  @override
  String alertLowPriceMessage(String recentAvg, String histAvg) {
    return 'The problem: in the last 30 days you sell at $recentAvg per kg, below your historical average of $histAvg per kg.';
  }

  @override
  String get alertLowPriceSuggestion => 'Compare prices with other buyers and consider waiting for a better moment to sell part of the harvest.';

  @override
  String get alertLowPriceManualTitle => 'You sold coffee below your minimum price';

  @override
  String alertLowPriceManualMessage(String date, String price, String threshold) {
    return 'On $date you sold at $price per kg, below your minimum price of $threshold. Consider negotiating a better price or waiting.';
  }

  @override
  String alertDeficitNoCropTitle(String roi) {
    return 'Unassigned-crop expenses are not recovering (ROI $roi)';
  }

  @override
  String alertDeficitNoCropMessage(String count, String spent, String sold, String recovery) {
    return 'The problem: you have $count records without an assigned crop totaling $spent in expenses and $sold in sales, recovering only $recovery of what was invested.';
  }

  @override
  String alertDeficitNoCropSuggestion(Object count) {
    return 'Edit those $count records and assign their crop (Coffee, Banana…) so their cost counts in the right crop, and this alert will disappear.';
  }

  @override
  String alertDeficitTitle(String crop, String roi) {
    return '$crop is losing money (ROI $roi)';
  }

  @override
  String alertDeficitMessage(String spent, String crop, String sold, String recovery) {
    return 'The problem: you invested $spent in $crop and have only recovered $sold ($recovery of what you invested).';
  }

  @override
  String alertDeficitSuggestion(String crop) {
    return 'Consider lowering the costs of $crop, improving the sales price, or deciding whether it is worth continuing to invest in that crop.';
  }

  @override
  String pdfIncomeStatement(String period) {
    return 'Income Statement — $period';
  }

  @override
  String pdfGeneratedOn(String date, String currency) {
    return 'Generated on $date · Currency: $currency';
  }

  @override
  String get pdfIncomesHeader => 'INCOME';

  @override
  String get pdfNoIncomeSub => '    No income in this period';

  @override
  String get pdfExpensesHeader => 'OPERATING EXPENSES';

  @override
  String get pdfNoExpensesSub => '    No expenses in this period';

  @override
  String pdfCropBreakdown(String period) {
    return 'Breakdown by crop — $period';
  }

  @override
  String pdfYearAnnex(int year) {
    return 'Annex — Accumulated for $year';
  }

  @override
  String get pdfRoiFootnote => 'ROI = (Income − Expenses) / Expenses. Negative above 30% suggests reviewing the crop.';

  @override
  String get pdfColCrop => 'Crop';

  @override
  String get pdfColMov => 'Mov.';

  @override
  String get pdfColExpenses => 'Expenses';

  @override
  String get pdfColIncomes => 'Income';

  @override
  String get pdfColResult => 'Result';

  @override
  String get pdfColRoi => 'ROI';

  @override
  String get pdfFileNamePrefix => 'report';

  @override
  String get excelSheetSummary => 'Summary';

  @override
  String get excelSheetCrops => 'By crop';

  @override
  String get excelSheetMovements => 'Movements';

  @override
  String get excelSheetHarvests => 'Harvests';

  @override
  String get pdfColDate => 'Date';

  @override
  String get pdfColType => 'Type';

  @override
  String get pdfColCategory => 'Category';

  @override
  String get pdfColDescription => 'Description';

  @override
  String get pdfColAmount => 'Amount';

  @override
  String balanceTemplateTitle(String period) {
    return 'BALANCE TEMPLATE — $period';
  }

  @override
  String balanceTemplateFarm(String farm, String date) {
    return '$farm — Generated on $date';
  }

  @override
  String get balanceAssetsTitle => 'ASSETS';

  @override
  String get balanceRowCash => 'Cash / bank';

  @override
  String get balanceRowReceivables => 'Accounts receivable';

  @override
  String get balanceRowInventory => 'Coffee inventory';

  @override
  String get balanceRowMachinery => 'Machinery & equipment';

  @override
  String get balanceRowLand => 'Land / plantations';

  @override
  String get balanceRowOtherAssets => 'Other assets';

  @override
  String get balanceTotalAssets => 'TOTAL ASSETS';

  @override
  String get balanceLiabilitiesTitle => 'LIABILITIES';

  @override
  String get balanceRowLoans => 'Loans / debt';

  @override
  String get balanceRowPayables => 'Accounts payable';

  @override
  String get balanceRowTaxes => 'Taxes payable';

  @override
  String get balanceTotalLiabilities => 'TOTAL LIABILITIES';

  @override
  String get balanceEquityTitle => 'EQUITY';

  @override
  String get balanceRowCapital => 'Initial capital';

  @override
  String get balanceRowAccumulated => 'Retained earnings';

  @override
  String balanceRowNetIncome(int year) {
    return 'Net income ($year)';
  }

  @override
  String get balanceTotalEquity => 'TOTAL EQUITY';

  @override
  String get balanceCheckLabel => 'CHECK — Assets = Liabilities + Equity (0 = balanced)';

  @override
  String get balanceCheckFormula => '=B11-B17-B23';

  @override
  String get balanceNote => 'Fill in the amounts per item in Excel. The check cell uses formulas: it must show 0 when the balance is balanced.';

  @override
  String balanceMixedCurrencyNote(int count) {
    return 'This year has entries in $count currencies: profit is listed per currency and balance totals are not calculated, because adding different currencies would give a false figure.';
  }

  @override
  String get catSiembra => 'Planting';

  @override
  String get catCercasPreparacion => 'Fences & land prep';

  @override
  String get catSemillasInsumos => 'Seeds & supplies';

  @override
  String get catFertilizante => 'Fertilizer';

  @override
  String get catManoObra => 'Labor';

  @override
  String get catCosecha => 'Harvesting';

  @override
  String get catPlagas => 'Pest control';

  @override
  String get catRiego => 'Irrigation';

  @override
  String get catEnergia => 'Energy';

  @override
  String get catAgua => 'Water';

  @override
  String get catEmpaque => 'Packaging & sales';

  @override
  String get catTransporte => 'Transport';

  @override
  String get catEquipo => 'Equipment';

  @override
  String get catMantenimiento => 'Maintenance';

  @override
  String get catArriendo => 'Land rental';

  @override
  String get catImpuestos => 'Taxes & fees';

  @override
  String get catCreditoIntereses => 'Credit & interest';

  @override
  String get catSeguros => 'Insurance';

  @override
  String get catOtro => 'Other';

  @override
  String get catVentaCafe => 'Coffee sales';

  @override
  String get catVentaPlatano => 'Plantain sales';

  @override
  String get catSubvenciones => 'Subsidies & support';

  @override
  String get catVentaOtro => 'Other sales';

  @override
  String get catVenta => 'Sale';

  @override
  String catVentaCrop(String crop) {
    return '$crop sales';
  }

  @override
  String alertCropEstablishmentTitle(String crop) {
    return '$crop is not producing yet: it is investment, not loss';
  }

  @override
  String alertCropEstablishmentMessage(String investment, String crop) {
    return 'The problem: you have $investment invested in $crop and no income yet. That is normal at this stage: the plantation is growing and the first harvest arrives when it starts Producing.';
  }

  @override
  String alertCropEstablishmentSuggestion(String crop) {
    return 'Keep recording the expenses of $crop. When the crop starts Producing, the app will evaluate its normal profitability.';
  }

  @override
  String alertHarvestVsSalesTitle(String crop) {
    return 'You sold more than you harvested in $crop';
  }

  @override
  String alertHarvestVsSalesMessage(String soldKg, String crop, String harvestedKg) {
    return 'The problem: in the last 12 months you sold $soldKg of $crop, but only recorded $harvestedKg of harvest. Check whether a harvest is missing, or whether the harvest and the sale use the same unit.';
  }

  @override
  String alertHarvestVsSalesSuggestion(String crop) {
    return 'Compare your $crop records: make sure each harvest and each sale uses the same unit to avoid mismatches.';
  }

  @override
  String get alertRecentlyPlantedTitle => 'You recorded a recent planting';

  @override
  String alertRecentlyPlantedMessage(String crop, String date) {
    return 'You recorded a planting or replanting of $crop on $date. Check that the crop\'s updated live-plant count matches the real count.';
  }

  @override
  String get alertRecentlyPlantedSuggestion => 'Edit the crop to adjust its live plants if the count changed after planting.';

  @override
  String alertFirstHarvestTitle(String crop) {
    return '$crop should be yielding by now';
  }

  @override
  String alertFirstHarvestMessage(String crop, String date) {
    return 'You estimated the first harvest of $crop for $date and haven\'t recorded any harvest yet.';
  }

  @override
  String get alertFirstHarvestSuggestion => 'Check the crop: if something changed or that date no longer fits, edit it. If you already sold, record that sale with the kilos and the money you were paid: with those kilos the app already knows you harvested and this notice goes away.';

  @override
  String get alertMissingQtyTitle => 'You have sales without recorded kilos';

  @override
  String alertMissingQtyMessage(int count) {
    return 'The problem: in the last 90 days you recorded $count sales without the sold quantity. Without that figure, the app cannot calculate your price per kilo or your profitability.';
  }

  @override
  String get alertMissingQtySuggestion => 'Edit those sales and enter the kilos sold. That way your price and profitability reports become reliable.';

  @override
  String get alertUnpaidTitle => 'Sales still unpaid';

  @override
  String alertUnpaidMessage(int count, String amount, int days) {
    return 'The problem: $count sales add up to $amount that hasn\'t been paid yet, the oldest one $days days old.';
  }

  @override
  String get alertUnpaidSuggestion => 'Collect before it slips: once the money arrives, edit the sale and switch its status to “Paid”.';

  @override
  String alertCashBoxWarningTitle(String month, String percent) {
    return 'The $month cash box is at $percent';
  }

  @override
  String alertCashBoxWarningMessage(String used, String total, String remaining) {
    return 'The problem: this month you have $used of $total in day labor and extras. You have $remaining left before it runs out.';
  }

  @override
  String get alertCashBoxWarningSuggestion => 'Review extra expenses and keep only what\'s necessary until the month ends.';

  @override
  String alertCashBoxDangerTitle(String month) {
    return 'Cash box exhausted in $month';
  }

  @override
  String alertCashBoxDangerMessage(String used, String total, String percent) {
    return 'The problem: this month you have $used of $total in day labor and extras ($percent). There is no budget left.';
  }

  @override
  String get alertCashBoxDangerSuggestion => 'Review extra expenses and consider reducing workers this month.';

  @override
  String alertCashBoxDebtMessage(String used, String carry) {
    return 'The problem: this month you have $used in day labor and extras, and the cash box closed the previous months in the red: the carryover is $carry.';
  }

  @override
  String get backupSectionTitle => 'Backup';

  @override
  String get backupSectionSubtitle => 'Save all your farm data to a file and load it back whenever you need it.';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupRestore => 'Restore backup';

  @override
  String get backupShareSubject => 'Mi Cafetal — Data backup';

  @override
  String get backupExportDoneMsg => 'Backup ready to share.';

  @override
  String get backupConfirmTitle => 'Restore this backup?';

  @override
  String backupConfirmMessage(String counts) {
    return 'This will add: $counts. What you already have is kept as is; nothing is deleted.';
  }

  @override
  String get backupConfirmAccept => 'Restore';

  @override
  String get backupAccountDiffers => 'Warning: this backup comes from another account. Its data will be added to what you already have here.';

  @override
  String backupCountCrops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count crops',
      one: '$count crop',
    );
    return '$_temp0';
  }

  @override
  String backupCountSowings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantings',
      one: '$count planting',
    );
    return '$_temp0';
  }

  @override
  String backupCountHarvests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count harvests',
      one: '$count harvest',
    );
    return '$_temp0';
  }

  @override
  String backupCountEmployees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workers',
      one: '$count worker',
    );
    return '$_temp0';
  }

  @override
  String backupSummary(int added, int existing) {
    return 'Backup restored: $added added and $existing you already had.';
  }

  @override
  String backupOrphans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items were not linked to their crops or harvests',
      one: '$count item was not linked to its crop or harvest',
    );
    return '$_temp0';
  }

  @override
  String get backupInvalidFile => 'That file is not a valid backup.';

  @override
  String get backupUnknownFormat => 'That file is not a Mi Cafetal backup.';

  @override
  String get backupUnsupportedVersion => 'This backup was made with a newer version of the app. Update the app to restore it.';

  @override
  String get backupRestoreError => 'The backup could not be restored. Please try again.';

  @override
  String get terrenosSection => 'Your plots';

  @override
  String get terrenoNew => 'New plot';

  @override
  String get terrenoEdit => 'Edit plot';

  @override
  String get terrenoDelete => 'Delete plot';

  @override
  String get terrenoNameLabel => 'Plot name';

  @override
  String get terrenoAreaLabel => 'Hectares of the plot';

  @override
  String get helpTerrenoArea => 'Optional. Only if you have measured them; otherwise leave it empty.';

  @override
  String get terrenoCropsLabel => 'Which crops go here?';

  @override
  String get helpTerrenoCrops => 'Tick the ones you want in this plot. One plot can hold coffee, plantain and shade at the same time.';

  @override
  String get terrenoCropsEmpty => 'You do not have crops yet. You can create the plot and assign them later.';

  @override
  String get terrenoNameRequired => 'Give the plot a name.';

  @override
  String get terrenoNameTaken => 'There is already a plot with that name.';

  @override
  String get terrenoAreaInvalid => 'That number of hectares cannot be read.';

  @override
  String get terrenoLocationSection => 'Plot location';

  @override
  String get terrenoLocationButton => 'Get my location';

  @override
  String get terrenoLocationHelper => 'The point where the plot is. Take it from your phone or type it in. The app never re-measures it on its own: moving the land silently would be inventing data.';

  @override
  String get terrenoLatLabel => 'Latitude';

  @override
  String get terrenoLngLabel => 'Longitude';

  @override
  String terrenoLocationDate(Object date) {
    return 'Recorded on $date';
  }

  @override
  String get terrenoLocationInvalid => 'Latitude goes from -90 to 90 and longitude from -180 to 180.';

  @override
  String get terrenoLocationHalf => 'Both coordinates must go together: one alone says nothing about where anything is.';

  @override
  String get terrenoLocationFailed => 'Could not get the location. Type it in or try again.';

  @override
  String get reportTerrenosTitle => 'Your plots · location';

  @override
  String get reportTerrenosHint => 'The coordinate of each plot, as you recorded it. It is never re-measured on its own.';

  @override
  String get associatedCropsCostTitle => 'Costs between associated crops';

  @override
  String get associatedCropsCostNote => 'Several crops share the same plot: the same labor or fertilizer can serve several. That expense is split between them by hectares; if one is missing its area, it shows separately. So each crop\'s cost is an approximation, but the farm total does add up.';

  @override
  String terrenoCropCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count crops',
      one: '$count crop',
    );
    return '$_temp0';
  }

  @override
  String terrenoAreaAssigned(String assigned, String total) {
    return '$assigned of $total ha assigned';
  }

  @override
  String terrenoAreaOver(String assigned, String total) {
    return 'Areas add up to $assigned ha and the plot has $total';
  }

  @override
  String terrenoAreaWithoutArea(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count crops without area',
      one: '$count crop without area',
    );
    return '$_temp0';
  }

  @override
  String cropAreaShareHelp(String terreno, String assigned, String total) {
    return 'In $terreno: $assigned of $total ha assigned';
  }

  @override
  String get deleteTerrenoTitle => 'Delete the plot?';

  @override
  String deleteTerrenoBody(String name) {
    return '“$name” will be deleted. Your crops are not deleted: they just lose their plot.';
  }

  @override
  String get cropTerrenoLabel => 'Which plot is it in?';

  @override
  String get cropTerrenoNone => 'No plot';

  @override
  String get helpCropTerreno => 'The plot where it is planted. You can leave it empty.';

  @override
  String get terrenoGroupLabel => 'Plots';

  @override
  String get terrenoGroupHint => 'The expense serves several crops in the same plot, like shared weeding. It is split between them by hectares; if one is missing its area, it shows separately.';
}
