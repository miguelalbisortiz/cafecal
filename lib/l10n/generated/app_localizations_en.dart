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
  String get nextStepSowingSubtitle => 'A crop in establishment needs its initial planting recorded.';

  @override
  String get nextStepExpensesTitle => 'Record your first expenses';

  @override
  String get nextStepExpensesSubtitle => 'Track what you invest each month.';

  @override
  String get nextStepHarvestTitle => 'Record your first harvest';

  @override
  String get nextStepHarvestSubtitle => 'Note how much you collected and its destination.';

  @override
  String get nextStepSaleTitle => 'Record the sale of your harvest';

  @override
  String get nextStepSaleSubtitle => 'Link the sale to the harvest to see your real profit.';

  @override
  String get nextStepGuideLink => 'View full guide';

  @override
  String get welcomeTitle => 'Welcome, set up your farm';

  @override
  String get welcomeSubtitle => 'Tell us how your farm looks today so we can guide you:';

  @override
  String get welcomeExistingTitle => 'I already have plants producing';

  @override
  String get welcomeExistingSubtitle => 'Coffee, plantain or another crop already growing on my farm that I manage.';

  @override
  String get welcomeExistingAction => 'Add existing crops';

  @override
  String get welcomeNewTitle => 'I want to start something new';

  @override
  String get welcomeNewSubtitle => 'I\'m planting now or planted recently. The app records the planting and creates the crop.';

  @override
  String get welcomeNewAction => 'Record my plantings';

  @override
  String get welcomeHint => 'It doesn\'t matter which you choose first: both guide you well and the app creates everything it needs automatically.';

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
  String get helpIntro => 'Mi Cafetal keeps track of your farm: how much you invest, produce and sell, per crop, per month and per year.';

  @override
  String get helpIntroPromesa => 'The app never guesses your production: the numbers come from what you record. The more complete your records, the more useful the results.';

  @override
  String get helpWhereTitle => 'Where do I enter each piece of data?';

  @override
  String get helpRowOverview => 'Your farm overview (income, expenses and balance)';

  @override
  String get helpRowCrops => 'Set up your farm\'s crops';

  @override
  String get helpRowSowings => 'Plant or replant';

  @override
  String get helpRowHarvests => 'Record what you collected';

  @override
  String get helpRowExpenses => 'Expenses (supplies, labor…)';

  @override
  String get helpRowIncome => 'Sales of your harvest';

  @override
  String get helpCaseTitle => 'Where do I start? Depends on your case';

  @override
  String get helpCaseATitle => 'Case A — I already have crops planted';

  @override
  String get helpCaseA1 => 'Crops: review Coffee and Plantain and set their stage to Production (and, if you know it, area and live plants).';

  @override
  String get helpCaseA2 => 'Record: enter the month\'s expenses (supplies, labor).';

  @override
  String get helpCaseA3 => 'Harvests: when you collect, record the harvest with its destination.';

  @override
  String get helpCaseA4 => 'Record: when you sell, record the sale income.';

  @override
  String get helpCaseAEnd => 'Check the Overview: balance and indicators start making sense.';

  @override
  String get helpCaseBTitle => 'Case B — I\'m going to plant something new';

  @override
  String get helpCaseB1 => 'Crops: create your crop with stage Establishment (cycle Annual or Perennial).';

  @override
  String get helpCaseB2 => 'Plantings: record the initial planting (plants and area; you can link its cost).';

  @override
  String get helpCaseB3 => 'In establishment the app does not flag losses: it is investment, not production.';

  @override
  String get helpCaseB4 => 'When it reaches Production, follow the Case A flow of harvests and sales.';

  @override
  String get helpUnitsTitle => 'Units';

  @override
  String get helpUnitsBody => 'Use kg, or arroba (12.5 kg) and bag (70 kg) for coffee. The app converts everything to kg for comparison.';

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
  String get helpUnitsSacoRowDesc => '70 kg. For coffee in bags.';

  @override
  String get helpUnitsRacimoRow => 'Bunch';

  @override
  String get helpUnitsRacimoRowDesc => 'For plantain. Not weighed.';

  @override
  String get helpUnitsCajonRow => 'Crate';

  @override
  String get helpUnitsCajonRowDesc => 'For fruits and vegetables. Weight varies.';

  @override
  String get helpExampleTitle => 'What does it look like in practice? Examples with numbers';

  @override
  String get helpCaseAExampleTitle => 'Case A — coffee in production (2 ha, 3000 plants)';

  @override
  String get helpCaseAEx1 => 'Coffee, Production, Perennial, 2 ha, 3000 plants';

  @override
  String get helpCaseAEx2 => '\$500,000 expense on Fertilizer';

  @override
  String get helpCaseAEx3 => '4 arrobas (50 kg), Sold';

  @override
  String get helpCaseAEx4 => '\$750,000 income from the sale';

  @override
  String get helpCaseAEx5 => 'Balance +\$250,000 · Margin 33% · ROI 50%';

  @override
  String get helpCaseBExampleTitle => 'Case B — new plantain (500 plants on 0.5 ha)';

  @override
  String get helpCaseBEx1 => 'Plantain, Establishment, Perennial, 0.5 ha, 500 plants';

  @override
  String get helpCaseBEx2 => 'Initial planting, 500 plants, 0.5 ha, cost \$200,000';

  @override
  String get helpCaseBEx3 => '\$100,000 labor and \$150,000 fertilizer';

  @override
  String get helpCaseBEx4 => 'Investment \$450,000. It does not say loss: it is an investment until it produces.';

  @override
  String get helpGlossaryTitle => 'Glossary';

  @override
  String get helpGlossaryBody => 'Seedlings: young plantation in establishment. Area: crop surface. Live plants: current total (planting − losses + replanting). Destination: sold, stored or loss. Sync: saves to the cloud to log in from any device. Alert: automatic notice on the Overview.';

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
  String get helpPerHaWhy => 'Why normalize? A 3 ha plot selling \$9M does not compete with a 1 ha plot selling \$5M: per hectare, the second one wins. The panel divides by area so you compare by the same rule.';

  @override
  String get helpPaybackTitle => 'How is the establishment investment recovered?';

  @override
  String get helpPaybackIntro => 'When editing a crop you can record the Establishment cost: what you invested in planting and raising the crop (seedlings, labor, initial fertilization…).';

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
  String get helpPaybackNotLoss => 'If you invest \$1,000,000 planting coffee and have not sold yet, you did not lose \$1,000,000. You invested \$1,000,000. When you start selling, the recovery percentage starts to rise.';

  @override
  String get helpFlowTitle => 'The order of the app';

  @override
  String get helpFlowIntro => 'Think of it as a chain: first you tell it what you grow, then how much you planted, then what you spent, then what you harvested, and finally how much you sold for.';

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
  String get helpFlowStep4Title => 'Record the harvest';

  @override
  String get helpFlowStep4Body => 'What you collected.';

  @override
  String get helpFlowStep5Title => 'Record the sale';

  @override
  String get helpFlowStep5Body => 'Who you sold to and for how much.';

  @override
  String get helpFlowHint => 'The \"Your next step\" card on the Overview tells you exactly which record you need next. When you have done it all, the card disappears on its own.';

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
  String get helpCommonCurrency => 'I want to change the currency';

  @override
  String get helpCommonCurrencyFix => 'Go to Settings and select the currency (COP, USD, EUR). Amounts convert automatically';

  @override
  String get helpCommonArea => 'I cannot see the \"Per hectare\" panel';

  @override
  String get helpCommonAreaFix => 'Set the crop area: in Crops edit the crop and enter the hectares';

  @override
  String get syncTooltip => 'Sync';

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
  String get phaseLabel => 'Life stage';

  @override
  String get phaseEstablecimiento => 'Establishment';

  @override
  String get phaseProduccion => 'Production';

  @override
  String get phaseRenovacion => 'Renewal';

  @override
  String get phaseHelp => 'Establishment = young plantation that does not produce yet (seedlings). The app will not flag losses in this stage.';

  @override
  String get areaHaLabel => 'Area (hectares)';

  @override
  String get livePlantsLabel => 'Live plants';

  @override
  String get establishmentCostLabel => 'Establishment cost (\$)';

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
  String get sowingPlantsLabel => 'Number of plants';

  @override
  String get sowingLostPlantsLabel => 'Lost plants (losses)';

  @override
  String get sowingReasonLabel => 'Reason (optional)';

  @override
  String get sowingAreaLabel => 'Area (hectares, optional)';

  @override
  String get sowingCostLabel => 'Cost (optional)';

  @override
  String get sowingCostHint => 'If you record a cost, a linked expense is created for this planting.';

  @override
  String get plantsInvalid => 'Enter a valid number of plants';

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
  String get reportPickupCostPerKg => 'Picking cost per kg';

  @override
  String get reportTotalCostPerKg => 'Total cost per kg';

  @override
  String get reportInvestmentEstablecimiento => 'Accumulated investment (establishment)';

  @override
  String get reportYieldPerArea => 'Yield per area (kg/ha)';

  @override
  String get reportYieldPerPlant => 'Yield per plant (kg/plant)';

  @override
  String get reportApprox => '(approximate)';

  @override
  String get reportSoldVsHarvested => 'Sold vs harvested';

  @override
  String get reportSoldKg => 'Sold (kg)';

  @override
  String get reportHarvestedKg => 'Harvested (kg)';

  @override
  String get reportWhatsNext => 'What to do next';

  @override
  String get reportNoRecommendations => 'No recommendations for this period.';

  @override
  String get reportNoHarvestData => 'No harvest data in this period.';

  @override
  String get perHaSection => 'Per hectare';

  @override
  String get perHaNoAreaHint => 'Set the area of your crops (edit the crop) to see their per-hectare performance: normalized yield, income and expenses.';

  @override
  String get perHaYieldLabel => 'Yield';

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
  String get cropFieldLabel => 'Crop (optional)';

  @override
  String get cropUnspecified => 'Not specified';

  @override
  String get cropNewOption => '+ New crop…';

  @override
  String get cropGroupHint => 'Transactions for the same crop are added together in the report.';

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
  String get unitSaco => 'Bags (70 kg)';

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
  String get add => 'Add';

  @override
  String get newCropDialogTitle => 'New crop';

  @override
  String get cropNameLabel => 'Crop name';

  @override
  String get cropNameRequired => 'Type the crop name.';

  @override
  String get menuCrops => 'Crops';

  @override
  String get cropsEmpty => 'No crops yet. Add the first one.';

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
  String cropBreakdownTitle(String period) {
    return 'Breakdown by crop — $period';
  }

  @override
  String get cropBreakdownSummaryG => 'Expenses';

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
  String pdfShareSubject(int year) {
    return 'Mi Cafetal — Report $year';
  }

  @override
  String get farmNameLabel => 'Farm name';

  @override
  String get currencyLabel => 'Currency';

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
    return 'Currency changed to $currency. Amounts converted at the current rate.';
  }

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
    return 'You recorded $spent in expenses and no sales in this period.';
  }

  @override
  String insightBalancePositive(Object balance, Object margin) {
    return 'Positive result: $balance with $margin margin over sales.';
  }

  @override
  String insightBalanceNegative(Object loss, Object margin) {
    return 'Negative result: $loss with $margin margin over sales.';
  }

  @override
  String insightVsPrev(Object expChange, Object incChange, Object month) {
    return 'Compared to $month: sales $incChange and expenses $expChange.';
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
  String insightTopExpense(Object amount, Object category, Object pct) {
    return 'Your biggest expense was $category ($amount, $pct of the total).';
  }

  @override
  String insightTopExpenseDependency(Object category) {
    return 'You concentrate more than half of your expenses in $category: review that recurring cost before it keeps growing.';
  }

  @override
  String insightTopIncome(Object amount, Object category, Object pct) {
    return 'Your best income was $category ($amount, $pct of the total).';
  }

  @override
  String insightLowPrice(Object history, Object recent) {
    return 'You sell for lower amounts than your average: recent average $recent vs $history per sale. Check price, packaging or sales channel.';
  }

  @override
  String insightBestMonth(Object costAmount, Object costMonth, Object salesAmount, Object salesMonth) {
    return 'Your best sales month was $salesMonth ($salesAmount); your lowest monthly expense was $costMonth ($costAmount).';
  }

  @override
  String chartTitle(int year) {
    return 'Expenses vs income — $year';
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
    return 'The problem: there are $spent in expenses and \$0 in sales, so the balance is at a loss.';
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
    return 'The problem: in the last 30 days each sale brings in $recentAvg on average, below your historical average per sale ($histAvg).';
  }

  @override
  String get alertLowPriceSuggestion => 'Compare prices with other buyers and consider waiting for a better moment to sell part of the harvest.';

  @override
  String get alertLowPriceManualTitle => 'You sold coffee below your minimum price';

  @override
  String alertLowPriceManualMessage(String price, String threshold, String date) {
    return 'On $date you sold at $price per kg, below your minimum price of $threshold. Consider negotiating a better price or waiting.';
  }

  @override
  String alertDeficitNoCropTitle(String roi) {
    return 'Unassigned-crop expenses are not recovering (ROI $roi)';
  }

  @override
  String alertDeficitNoCropMessage(String spent, String sold, String recovery, Object count) {
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
  String get catSiembra => 'Planting';

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
  String alertCropEstablishmentTitle(String crop) {
    return '$crop is in establishment: it is investment, not loss';
  }

  @override
  String alertCropEstablishmentMessage(String investment, String crop) {
    return 'The problem: you have $investment invested in $crop and no income yet. That is normal at this stage: the plantation is growing and the first harvest arrives when it reaches production.';
  }

  @override
  String alertCropEstablishmentSuggestion(String crop) {
    return 'Keep recording the expenses of $crop. When the crop reaches production, the app will evaluate its normal profitability.';
  }

  @override
  String alertHarvestVsSalesTitle(String crop) {
    return 'You sold more than you harvested in $crop';
  }

  @override
  String alertHarvestVsSalesMessage(String soldKg, String harvestedKg, String crop) {
    return 'The problem: in the last 12 months you sold $soldKg of $crop, but only recorded $harvestedKg of harvest. Check whether there is stored inventory or a recording error.';
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
  String get alertMissingQtyTitle => 'You have sales without recorded kilos';

  @override
  String alertMissingQtyMessage(int count) {
    return 'The problem: in the last 90 days you recorded $count sales without the sold quantity. Without that figure, the app cannot calculate your price per kilo or your profitability.';
  }

  @override
  String get alertMissingQtySuggestion => 'Edit those sales and enter the kilos sold. That way your price and profitability reports become reliable.';
}
