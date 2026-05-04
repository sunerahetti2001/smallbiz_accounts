import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String>? _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<void> load() async {
    String jsonString = await rootBundle.loadString(
      'assets/lang/${locale.languageCode}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  String translate(String key) {
    return _localizedStrings?[key] ?? key;
  }

  // Convenience getters for common strings
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get hi => translate('hi');
  String get login => translate('login');
  String get signUp => translate('sign_up');
  String get guestMode => translate('guest_mode');
  String get home => translate('home');
  String get categories => translate('categories');
  String get compare => translate('compare');
  String get analysis => translate('analysis');
  String get statements => translate('statements');
  String get income => translate('income');
  String get expense => translate('expense');
  String get creditSale => translate('credit_sale');
  String get creditPayment => translate('credit_payment');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get profile => translate('profile');
  String get logout => translate('logout');
  String get balance => translate('balance');
  String get todaySummary => translate('today_summary');
  String get recentActivity => translate('recent_activity');
  String get viewAll => translate('view_all');
  String get noTransactions => translate('no_transactions');
  String get addTransaction => translate('add_transaction');
  String get selectLanguage => translate('select_language');
  String get english => translate('english');
  String get sinhala => translate('sinhala');
  String get languageChanged => translate('language_changed');
  String get settings => translate('settings');
  String get loading => translate('loading');
  String get pleaseWait => translate('please_wait');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');
  String get ok => translate('ok');
  String get yes => translate('yes');
  String get no => translate('no');
  String get back => translate('back');
  String get next => translate('next');
  String get submit => translate('submit');
  String get search => translate('search');
  String get filter => translate('filter');
  String get clear => translate('clear');
  String get confirm => translate('confirm');
  String get areYouSure => translate('are_you_sure');
  String get pending => translate('pending');
  String get overdue => translate('overdue');
  String get paid => translate('paid');
  String get unpaid => translate('unpaid');
  String get total => translate('total');
  String get amount => translate('amount');
  String get description => translate('description');
  String get date => translate('date');
  String get customer => translate('customer');
  String get phone => translate('phone');
  String get email => translate('email');
  String get password => translate('password');
  String get name => translate('name');
  String get businessName => translate('business_name');
  String get currency => translate('currency');
  String get openingBalance => translate('opening_balance');
  String get accountType => translate('account_type');
  String get termsAndConditions => translate('terms_and_conditions');
  String get agreeToTerms => translate('agree_to_terms');
  String get createAccount => translate('create_account');
  String get welcomeBack => translate('welcome_back');
  String get startJourney => translate('start_journey');
  String get completeSetup => translate('complete_setup');
  String get getStarted => translate('get_started');
  String get skip => translate('skip');
  String get or => translate('or');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get continueWithGoogle => translate('continue_with_google');
  String get signUpWithGoogle => translate('sign_up_with_google');
  String get guestWarning => translate('guest_warning');
  String get connectAccount => translate('connect_account');
  String get connect => translate('connect');
  String get updateProfile => translate('update_profile');
  String get editProfile => translate('edit_profile');
  String get logoutWarning => translate('logout_warning');
  String get logoutClear => translate('logout_clear');
  String get generateStatement => translate('generate_statement');
  String get monthlyStatement => translate('monthly_statement');
  String get quarterlyStatement => translate('quarterly_statement');
  String get yearlyStatement => translate('yearly_statement');
  String get summary => translate('summary');
  String get details => translate('details');
  String get profit => translate('profit');
  String get loss => translate('loss');
  String get margin => translate('margin');
  String get incomeBreakdown => translate('income_breakdown');
  String get expenseBreakdown => translate('expense_breakdown');
  String get pendingCredits => translate('pending_credits');
  String get thisMonth => translate('this_month');
  String get lastMonth => translate('last_month');
  String get monthToMonth => translate('month_to_month');
  String get monthlyBreakdown => translate('monthly_breakdown');
  String get paymentMethod => translate('payment_method');
  String get cash => translate('cash');
  String get bank => translate('bank');
  String get card => translate('card');
  String get items => translate('items');
  String get item => translate('item');
  String get quantity => translate('quantity');
  String get price => translate('price');
  String get totalAmount => translate('total_amount');
  String get dueDate => translate('due_date');
  String get setDueDate => translate('set_due_date');
  String get selectCustomer => translate('select_customer');
  String get selectCategory => translate('select_category');
  String get addItem => translate('add_item');
  String get recordSale => translate('record_sale');
  String get recordPayment => translate('record_payment');
  String get saveIncome => translate('save_income');
  String get saveExpense => translate('save_expense');
  String get saveChanges => translate('save_changes');
  String get selectTransactionType => translate('select_transaction_type');
  String get incomeDescription => translate('income_description');
  String get expenseDescription => translate('expense_description');
  String get creditSaleDescription => translate('credit_sale_description');
  String get creditPaymentDescription => translate('credit_payment_description');
  String get noStatements => translate('no_statements');
  String get noDataAnalysis => translate('no_data_analysis');
  String get noCategories => translate('no_categories');
  String get addCategory => translate('add_category');
  String get editCategory => translate('edit_category');
  String get categoryName => translate('category_name');
  String get defaultCategory => translate('default_category');
  String get customCategory => translate('custom_category');
  String get manageCategories => translate('manage_categories');
  String get yourFinanceHub => translate('your_finance_hub');
  String get createAccountDesc => translate('create_account_desc');
  String get businessDetails => translate('business_details');
  String get businessNameQuestion => translate('business_name_question');
  String get businessNameHint => translate('business_name_hint');
  String get businessNameDesc => translate('business_name_desc');
  String get setupStartingCash => translate('setup_starting_cash');
  String get setupStartingCashDesc => translate('setup_starting_cash_desc');
  String get account => translate('account');
  String get enterOpeningBalance => translate('enter_opening_balance');
  String get addFirstTransaction => translate('add_first_transaction');
  String get availableBalance => translate('available_balance');
  String get creditOutstanding => translate('credit_outstanding');
  String get incomeToday => translate('income_today');
  String get expenseToday => translate('expense_today');
  String get pendingPayments => translate('pending_payments');
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get moreTransactions => translate('more_transactions');
  String get noPendingCredits => translate('no_pending_credits');
  String get statementGenerated => translate('statement_generated');
  String get selectPeriod => translate('select_period');
  String get previousStatements => translate('previous_statements');
  String get generateNewStatement => translate('generate_new_statement');
  String get profileUpdated => translate('profile_updated');
  String get pleaseEnterName => translate('please_enter_name');
  String get pleaseEnterBusinessName => translate('please_enter_business_name');
  String get pleaseEnterAmount => translate('please_enter_amount');
  String get pleaseEnterDescription => translate('please_enter_description');
  String get pleaseAgreeTerms => translate('please_agree_terms');
  String get pleaseSelectCategory => translate('please_select_category');
  String get pleaseSelectCustomer => translate('please_select_customer');
  String get welcomeMessage => translate('welcome_message');
  String get trackSmarter => translate('track_smarter');
  String get financialStatement => translate('financial_statement');
  String get generatedOn => translate('generated_on');
  String get computerGenerated => translate('computer_generated');
  String get addNewTransaction => translate('add_new_transaction');
  String get receivePayment => translate('receive_payment');
  String get selectIcon => translate('select_icon');
  String get threeMonthAnalysis => translate('three_month_analysis');
  String get last3Months => translate('last_3_months');
  String get performance => translate('performance');
  String get transactions => translate('transactions');
  String get creditGiven => translate('credit_given');
  String get netProfit => translate('net_profit');
  String get totalIncome => translate('total_income');
  String get totalExpense => translate('total_expense');
  String get closingBalance => translate('closing_balance');
  String get profitMargin => translate('profit_margin');
  String get incomeVsExpense => translate('income_vs_expense');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'si'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}