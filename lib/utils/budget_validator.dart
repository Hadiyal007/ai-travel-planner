/// Client-side sanity check for the budget entered on Create Trip, run
/// before calling the AI at all — catches obviously unrealistic amounts
/// (e.g. ₹500 for a 7-day trip) for free and instantly, instead of
/// spending a Gemini/Groq call on a plan that can't work.
class BudgetValidator {
  /// Rough floor for a bare-bones domestic trip: basic stay, street
  /// food/dhaba-level meals, and local transport. Deliberately NOT
  /// destination-aware (Goa vs. a smaller town cost differently) — this
  /// is just a floor to catch clearly unrealistic entries, not a real
  /// cost estimate. Tune this number if it feels off in testing.
  static const int minPerDayPerTraveller = 1500;

  /// Returns null if [budget] looks realistic for the trip length and
  /// traveller count, otherwise a user-facing message suggesting a
  /// minimum to try instead.
  static String? check({
    required double budget,
    required int durationInDays,
    required int travellers,
  }) {
    final minRequired = minPerDayPerTraveller * durationInDays * travellers;
    if (budget >= minRequired) return null;
    return 'That budget looks too tight for $durationInDays day(s) with '
        '$travellers traveller${travellers == 1 ? '' : 's'} — try at least '
        '₹$minRequired for a realistic plan.';
  }
}