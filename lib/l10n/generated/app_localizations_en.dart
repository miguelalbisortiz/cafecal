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
  String get syncTooltip => 'Sync';

  @override
  String get menuReport => 'Report';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuLogout => 'Sign out';

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
  String get authGuest => 'Explore the app without an account';

  @override
  String get authGuestHint => 'Guest mode: sample data stays only on this device and is not synced.';

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
}
