// lib/localization/translation_keys.dart

/// Central repository for all translation keys used in the app
/// This prevents typos and makes refactoring easier
class TranslationKeys {
  // ════════════════════════════════════════════════════════════════════════════
  // APP GENERAL
  // ════════════════════════════════════════════════════════════════════════════

  static const String appName = 'app_name';
  static const String appTagline = 'app_tagline';
  static const String welcome = 'welcome';
  static const String welcomeBack = 'welcome_back';
  static const String error = 'error';
  static const String success = 'success';
  static const String warning = 'warning';
  static const String info = 'info';
  static const String loading = 'loading';
  static const String pleaseWait = 'please_wait';
  static const String tryAgain = 'try_again';
  static const String retry = 'retry';
  static const String noData = 'no_data';
  static const String noResults = 'no_results';
  static const String comingSoon = 'coming_soon';
  static const String underMaintenance = 'under_maintenance';

  // ════════════════════════════════════════════════════════════════════════════
  // COMMON ACTIONS
  // ════════════════════════════════════════════════════════════════════════════

  static const String ok = 'ok';
  static const String cancel = 'cancel';
  static const String yes = 'yes';
  static const String no = 'no';
  static const String save = 'save';
  static const String delete = 'delete';
  static const String edit = 'edit';
  static const String update = 'update';
  static const String add = 'add';
  static const String remove = 'remove';
  static const String close = 'close';
  static const String back = 'back';
  static const String next = 'next';
  static const String previous = 'previous';
  static const String submit = 'submit';
  static const String confirm = 'confirm';
  static const String continue_ = 'continue';
  static const String skip = 'skip';
  static const String done = 'done';
  static const String finish = 'finish';
  static const String apply = 'apply';
  static const String reset = 'reset';
  static const String clear = 'clear';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String sort = 'sort';
  static const String share = 'share';
  static const String download = 'download';
  static const String upload = 'upload';
  static const String viewAll = 'view_all';
  static const String seeMore = 'see_more';
  static const String seeLess = 'see_less';
  static const String refresh = 'refresh';
  static const String reload = 'reload';
  static const String copy = 'copy';
  static const String paste = 'paste';
  static const String send = 'send';
  static const String reply = 'reply';
  static const String forward = 'forward';

  // ════════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION
  // ════════════════════════════════════════════════════════════════════════════

  static const String login = 'login';
  static const String signup = 'signup';
  static const String logout = 'logout';
  static const String logoutConfirm = 'logout_confirm';
  static const String register = 'register';
  static const String forgotPassword = 'forgot_password';
  static const String resetPassword = 'reset_password';
  static const String changePassword = 'change_password';
  static const String enterPhoneNumber = 'enter_phone_number';
  static const String enterOtp = 'enter_otp';
  static const String verifyOtp = 'verify_otp';
  static const String resendOtp = 'resend_otp';
  static const String otpSent = 'otp_sent';
  static const String invalidOtp = 'invalid_otp';
  static const String selectRole = 'select_role';
  static const String worker = 'worker';
  static const String supporter = 'supporter';
  static const String both = 'both';

  // ════════════════════════════════════════════════════════════════════════════
  // PROFILE
  // ════════════════════════════════════════════════════════════════════════════

  static const String profile = 'profile';
  static const String profileTitle = 'profile_title';
  static const String editProfile = 'edit_profile';
  static const String viewProfile = 'view_profile';
  static const String myProfile = 'my_profile';
  static const String publicProfile = 'public_profile';
  static const String privateProfile = 'private_profile';
  static const String fullName = 'full_name';
  static const String username = 'username';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String bio = 'bio';
  static const String about = 'about';
  static const String skills = 'skills';
  static const String experience = 'experience';
  static const String education = 'education';
  static const String location = 'location';
  static const String address = 'address';
  static const String city = 'city';
  static const String country = 'country';
  static const String profilePhoto = 'profile_photo';
  static const String coverPhoto = 'cover_photo';
  static const String changePhoto = 'change_photo';
  static const String removePhoto = 'remove_photo';
  static const String followers = 'followers';
  static const String following = 'following';
  static const String follow = 'follow';
  static const String unfollow = 'unfollow';
  static const String block = 'block';
  static const String unblock = 'unblock';
  static const String report = 'report';
  static const String share_profile = 'share_profile';

  // ════════════════════════════════════════════════════════════════════════════
  // JOBS & WORK
  // ════════════════════════════════════════════════════════════════════════════

  static const String jobs = 'jobs';
  static const String myJobs = 'my_jobs';
  static const String findJobs = 'find_jobs';
  static const String postJob = 'post_job';
  static const String jobTitle = 'job_title';
  static const String jobDescription = 'job_description';
  static const String jobCategory = 'job_category';
  static const String jobType = 'job_type';
  static const String jobLocation = 'job_location';
  static const String jobBudget = 'job_budget';
  static const String jobDeadline = 'job_deadline';
  static const String applyNow = 'apply_now';
  static const String applications = 'applications';
  static const String applicants = 'applicants';
  static const String hired = 'hired';
  static const String completed = 'completed';
  static const String inProgress = 'in_progress';
  static const String pending = 'pending';
  static const String cancelled = 'cancelled';
  static const String rejected = 'rejected';
  static const String accepted = 'accepted';
  static const String completedJobs = 'completed_jobs';
  static const String activeJobs = 'active_jobs';
  static const String jobDetails = 'job_details';
  static const String viewApplications = 'view_applications';
  static const String hireWorker = 'hire_worker';
  static const String markComplete = 'mark_complete';
  static const String cancelJob = 'cancel_job';

  // ════════════════════════════════════════════════════════════════════════════
  // TEAM MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════════

  static const String team = 'team';
  static const String myTeam = 'my_team';
  static const String teamManagement = 'team_management';
  static const String teamMembers = 'team_members';
  static const String inviteMember = 'invite_member';
  static const String removeMember = 'remove_member';
  static const String teamLeader = 'team_leader';
  static const String member = 'member';
  static const String invitations = 'invitations';
  static const String pendingInvitations = 'pending_invitations';
  static const String acceptInvitation = 'accept_invitation';
  static const String rejectInvitation = 'reject_invitation';
  static const String totalEarnings = 'total_earnings';
  static const String teamEarnings = 'team_earnings';
  static const String memberEarnings = 'member_earnings';
  static const String leaveTeam = 'leave_team';
  static const String disbandTeam = 'disband_team';

  // ════════════════════════════════════════════════════════════════════════════
  // WALLET & PAYMENTS
  // ════════════════════════════════════════════════════════════════════════════

  static const String wallet = 'wallet';
  static const String myWallet = 'my_wallet';
  static const String balance = 'balance';
  static const String currentBalance = 'current_balance';
  static const String addMoney = 'add_money';
  static const String withdraw = 'withdraw';
  static const String withdrawFunds = 'withdraw_funds';
  static const String transaction = 'transaction';
  static const String transactions = 'transactions';
  static const String transactionHistory = 'transaction_history';
  static const String paymentMethod = 'payment_method';
  static const String paymentMethods = 'payment_methods';
  static const String addPaymentMethod = 'add_payment_method';
  static const String bkash = 'bkash';
  static const String nagad = 'nagad';
  static const String rocket = 'rocket';
  static const String bankTransfer = 'bank_transfer';
  static const String amount = 'amount';
  static const String enterAmount = 'enter_amount';
  static const String accountNumber = 'account_number';
  static const String transactionId = 'transaction_id';
  static const String paymentSuccess = 'payment_success';
  static const String paymentFailed = 'payment_failed';
  static const String insufficientBalance = 'insufficient_balance';
  static const String minimumAmount = 'minimum_amount';
  static const String maximumAmount = 'maximum_amount';

  // ════════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════════

  static const String notifications = 'notifications';
  static const String newNotification = 'new_notification';
  static const String noNotifications = 'no_notifications';
  static const String markAsRead = 'mark_as_read';
  static const String markAllRead = 'mark_all_read';
  static const String clearAll = 'clear_all';
  static const String notificationSettings = 'notification_settings';
  static const String enableNotifications = 'enable_notifications';
  static const String disableNotifications = 'disable_notifications';
  static const String jobNotifications = 'job_notifications';
  static const String messageNotifications = 'message_notifications';
  static const String teamNotifications = 'team_notifications';

  // ════════════════════════════════════════════════════════════════════════════
  // RATINGS & REVIEWS
  // ════════════════════════════════════════════════════════════════════════════

  static const String rating = 'rating';
  static const String ratings = 'ratings';
  static const String review = 'review';
  static const String reviews = 'reviews';
  static const String writeReview = 'write_review';
  static const String editReview = 'edit_review';
  static const String deleteReview = 'delete_review';
  static const String rateNow = 'rate_now';
  static const String averageRating = 'average_rating';
  static const String totalReviews = 'total_reviews';
  static const String noReviews = 'no_reviews';
  static const String helpful = 'helpful';
  static const String notHelpful = 'not_helpful';

  // ════════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ════════════════════════════════════════════════════════════════════════════

  static const String settings = 'settings';
  static const String accountSettings = 'account_settings';
  static const String privacySettings = 'privacy_settings';
  static const String securitySettings = 'security_settings';
  static const String notificationControlSettings =
      'notification_control_settings';
  static const String languageSettings = 'language_settings';
  static const String changeLanguage = 'change_language';
  static const String selectLanguage = 'select_language';
  static const String themeSettings = 'theme_settings';
  static const String lightTheme = 'light_theme';
  static const String darkTheme = 'dark_theme';
  static const String systemTheme = 'system_theme';
  static const String amoledTheme = 'amoled_theme';
  static const String aboutApp = 'about_app';
  static const String appVersion = 'app_version';
  static const String termsConditions = 'terms_conditions';
  static const String privacyPolicy = 'privacy_policy';
  static const String communityStandards = 'community_standards';
  static const String helpCenter = 'help_center';
  static const String faq = 'faq';
  static const String contactSupport = 'contact_support';
  static const String reportProblem = 'report_problem';
  static const String deleteAccount = 'delete_account';
  static const String deleteAccountConfirm = 'delete_account_confirm';

  // ════════════════════════════════════════════════════════════════════════════
  // VERIFICATION & KYC
  // ════════════════════════════════════════════════════════════════════════════

  static const String verification = 'verification';
  static const String verified = 'verified';
  static const String notVerified = 'not_verified';
  static const String verifyAccount = 'verify_account';
  static const String kyc = 'kyc';
  static const String kycVerification = 'kyc_verification';
  static const String uploadDocuments = 'upload_documents';
  static const String nid = 'nid';
  static const String passport = 'passport';
  static const String drivingLicense = 'driving_license';
  static const String birthCertificate = 'birth_certificate';
  static const String verificationPending = 'verification_pending';
  static const String verificationApproved = 'verification_approved';
  static const String verificationRejected = 'verification_rejected';

  static const String analytics = 'analytics';
  static const String views = 'views';
  static const String clicks = 'clicks';
  static const String conversions = 'conversions';

  // ════════════════════════════════════════════════════════════════════════════
  // ACHIEVEMENTS & BADGES
  // ════════════════════════════════════════════════════════════════════════════

  static const String achievements = 'achievements';
  static const String badges = 'badges';
  static const String myBadges = 'my_badges';
  static const String earnedBadges = 'earned_badges';
  static const String lockedBadges = 'locked_badges';
  static const String bronzeBadge = 'bronze_badge';
  static const String silverBadge = 'silver_badge';
  static const String goldBadge = 'gold_badge';
  static const String platinumBadge = 'platinum_badge';
  static const String diamondBadge = 'diamond_badge';
  static const String leaderboard = 'leaderboard';
  static const String topWorkers = 'top_workers';
  static const String topSupporters = 'top_supporters';

  // ════════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION
  // ════════════════════════════════════════════════════════════════════════════

  static const String subscription = 'subscription';
  static const String subscribe = 'subscribe';
  static const String subscribed = 'subscribed';
  static const String freeplan = 'free_plan';
  static const String basicPlan = 'basic_plan';
  static const String premiumPlan = 'premium_plan';
  static const String proPlan = 'pro_plan';
  static const String monthlyPlan = 'monthly_plan';
  static const String yearlyPlan = 'yearly_plan';
  static const String upgradePlan = 'upgrade_plan';
  static const String cancelSubscription = 'cancel_subscription';
  static const String renewSubscription = 'renew_subscription';
  static const String subscriptionExpires = 'subscription_expires';

  // ════════════════════════════════════════════════════════════════════════════
  // VALIDATION MESSAGES
  // ════════════════════════════════════════════════════════════════════════════

  static const String validationRequired = 'validation_required';
  static const String validationInvalid = 'validation_invalid';
  static const String validationMinLength = 'validation_min_length';
  static const String validationMaxLength = 'validation_max_length';
  static const String validationInvalidEmail = 'validation_invalid_email';
  static const String validationInvalidPhone = 'validation_invalid_phone';
  static const String validationPasswordMismatch =
      'validation_password_mismatch';
  static const String validationWeakPassword = 'validation_weak_password';
  static const String validationInvalidUrl = 'validation_invalid_url';
  static const String validationInvalidNumber = 'validation_invalid_number';

  // ════════════════════════════════════════════════════════════════════════════
  // ERROR MESSAGES
  // ════════════════════════════════════════════════════════════════════════════

  static const String errorGeneric = 'error_generic';
  static const String errorNetwork = 'error_network';
  static const String errorTimeout = 'error_timeout';
  static const String errorServerError = 'error_server_error';
  static const String errorNotFound = 'error_not_found';
  static const String errorUnauthorized = 'error_unauthorized';
  static const String errorForbidden = 'error_forbidden';
  static const String errorNoInternet = 'error_no_internet';
  static const String errorFileUpload = 'error_file_upload';
  static const String errorInvalidData = 'error_invalid_data';

  // ════════════════════════════════════════════════════════════════════════════
  // SUCCESS MESSAGES
  // ════════════════════════════════════════════════════════════════════════════

  static const String successGeneric = 'success_generic';
  static const String successSaved = 'success_saved';
  static const String successUpdated = 'success_updated';
  static const String successDeleted = 'success_deleted';
  static const String successCreated = 'success_created';
  static const String successUploaded = 'success_uploaded';
  static const String successSent = 'success_sent';
  static const String successApplied = 'success_applied';
  static const String successCompleted = 'success_completed';

  // ════════════════════════════════════════════════════════════════════════════
  // CONFIRMATION MESSAGES
  // ════════════════════════════════════════════════════════════════════════════

  static const String confirmDelete = 'confirm_delete';
  static const String confirmCancel = 'confirm_cancel';
  static const String confirmLogout = 'confirm_logout';
  static const String confirmExit = 'confirm_exit';
  static const String confirmBlock = 'confirm_block';
  static const String confirmUnblock = 'confirm_unblock';
  static const String confirmReport = 'confirm_report';
  static const String confirmRemove = 'confirm_remove';

  // ════════════════════════════════════════════════════════════════════════════
  // TIME & DATE
  // ════════════════════════════════════════════════════════════════════════════

  static const String today = 'today';
  static const String yesterday = 'yesterday';
  static const String tomorrow = 'tomorrow';
  static const String justNow = 'just_now';
  static const String minutesAgo = 'minutes_ago';
  static const String hoursAgo = 'hours_ago';
  static const String daysAgo = 'days_ago';
  static const String weeksAgo = 'weeks_ago';
  static const String monthsAgo = 'months_ago';
  static const String yearsAgo = 'years_ago';

  // ════════════════════════════════════════════════════════════════════════════
  // MISC
  // ════════════════════════════════════════════════════════════════════════════

  static const String more = 'more';
  static const String less = 'less';
  static const String all = 'all';
  static const String none = 'none';
  static const String other = 'other';
  static const String custom = 'custom';
  static const String required = 'required';
  static const String optional = 'optional';
  static const String recommended = 'recommended';
  static const String popular = 'popular';
  static const String featured = 'featured';
  static const String new_ = 'new';
  static const String hot = 'hot';
  static const String trending = 'trending';
  static const String best = 'best';
  static const String top = 'top';

  // Prevent instantiation
  TranslationKeys._();
}
