// Suvarna Swarna Sirulu — 11 Instalment Advance Purchase Plan
// Terms & Conditions — structured point-wise for TalkBack accessibility.
//
// WHY THIS SHAPE (instead of one big triple-quoted String):
// A single long string forces TalkBack to read the whole T&C as one
// continuous blob, or forces you to split it by sentence punctuation,
// which is unreliable. Modeling each clause as its own list item lets
// you wrap each item in its own Semantics node (matching the pattern
// already used elsewhere in the app — see TermsAndConditionsScreen
// below), so a TalkBack user can swipe point-by-point through a section
// instead of getting a wall of text read aloud in one pass.

class TermsSection {
  final String title;
  final List<String> points;
  final List<TermsTable>? tables;

  const TermsSection({
    required this.title,
    required this.points,
    this.tables,
  });
}

/// Simple table representation for the "Scheme at a Glance" and
/// "Schedule" sections. Rendered as a labeled list (not a visual grid)
/// so TalkBack reads "label, value" per row instead of skipping across
/// table cells.
class TermsTable {
  final String? caption;
  final List<TermsTableRow> rows;

  const TermsTable({this.caption, required this.rows});
}

class TermsTableRow {
  final String label;
  final String value;

  const TermsTableRow(this.label, this.value);
}

const String kTermsDocTitle = 'SUVARNA JEWELLERS';
const String kTermsSchemeName =
    'SUVARNA SWARNA SIRULU — 11 INSTALMENT ADVANCE PURCHASE PLAN';
const String kTermsAddress = '#13-1-12, Main Road, Gajuwaka, Visakhapatnam';
const String kTermsGstin =
    'GSTIN: 37AMVPV7184K1ZR · BIS Registration No.: [BIS Reg. No.]';

final List<TermsSection> termsAndConditionsSections = [
  TermsSection(
    title: 'Scheme at a Glance',
    points: const [],
    tables: [
      TermsTable(rows: [
        TermsTableRow('Scheme name',
            'Suvarna Swarna Sirulu – 11 Instalment Advance Purchase Plan'),
        TermsTableRow('Legal character',
            'Advance payment towards future supply of goods. Not a deposit, chit, investment or financial product.'),
        TermsTableRow('Instalments', '11 equal monthly instalments'),
        TermsTableRow('Minimum instalment',
            '₹1,000 per month (higher amounts in multiples of ₹500)'),
        TermsTableRow('Accrual basis',
            'Weight in grams of 22K (916) BIS hallmarked gold, at the Board Rate on the date each instalment is realised'),
        TermsTableRow(
            'Maturity Date', 'Day 305 from the First Instalment Date'),
        TermsTableRow('Redemption Window',
            'Maturity Date to Day 330 from the First Instalment Date (absolute, non-extendable)'),
        TermsTableRow('Maturity Benefit',
            'Discount equal to one (1) monthly instalment on the final invoice, on completion of all 11 instalments'),
        TermsTableRow('Redemption against',
            "22K gold jewellery; silver articles at the customer's option"),
        TermsTableRow('Cooling-off',
            '15 days from the First Instalment Date – full refund'),
        TermsTableRow('If not redeemed',
            'Instalments refunded through banking channel within 15 days of the Redemption Window closing'),
      ]),
    ],
  ),
  TermsSection(
    title: '1. Nature of the Scheme and What It Is Not',
    points: [
      'This Scheme is a contract for the payment of money in advance towards the future purchase of gold jewellery from Suvarna Jewellers ("the Firm"). Every rupee received is received as an advance against the supply of goods and is appropriated against the supply of goods within 365 days of its receipt.',
      'The Scheme is expressly not, and shall not be construed as, any of the following: a deposit; a public deposit; an unregulated deposit scheme; a chit or chit fund; a money circulation or prize chit scheme; a collective investment scheme; a commodity derivative or forward contract; or any regulated financial product.',
      'No interest, dividend, profit, assured return or guaranteed appreciation of any kind is offered, promised or payable under this Scheme. The Maturity Benefit described in Clause 7 is a trade discount on a purchase of goods. It is not a return on money and is available only if and when a purchase is actually made.',
      'The Firm does not accept, and the customer shall not tender, more than one instalment in any calendar month, nor prepayment of the whole or a substantial part of the tenure in a single payment. Any such payment tendered will be declined or returned.',
      'The customer is not lending money to the Firm and acquires no debt, security, unit or beneficial interest in any asset of the Firm. The entitlement is a contractual right to take delivery of goods, and, in the circumstances set out in Clause 10, to a refund of the amounts paid.',
    ],
  ),
  TermsSection(
    title: '2. Definitions',
    points: [
      '"Board Rate" means the per-gram selling rate for 22K (916) gold declared by the Firm and displayed at the showroom counter and on the Firm\'s published channels, exclusive of making charges, wastage, and taxes.',
      '"First Instalment Date" means the date on which the first instalment is realised by the Firm. All periods in this document are counted in calendar days from this date, and this date is printed on the Passbook at enrolment.',
      '"Maturity Date" means Day 305 counted from the First Instalment Date, or the date on which the eleventh instalment is realised, whichever is later, but in no case later than Day 310.',
      '"Redemption Window" means the period from the Maturity Date to Day 330 counted from the First Instalment Date, both days inclusive.',
      '"Accrued Gold Weight" means the aggregate weight in grams of 22K gold credited to the account under Clause 5.',
      '"Passbook" means the scheme passbook or its digital equivalent issued to the customer, recording every instalment, the Board Rate applied, and the grams credited.',
      '"Maturity Benefit" means the discount described in Clause 7.',
    ],
  ),
  TermsSection(
    title: '3. Eligibility and Enrolment',
    points: [
      'Enrolment is open to individuals resident in India who are competent to contract under the Indian Contract Act, 1872.',
      "An account for the benefit of a minor shall be opened in the name of a parent or lawful guardian as the contracting party, holding the account for the minor's benefit. The guardian, and not the minor, is the customer for all purposes under these terms, including payment, redemption and dispute resolution, because an agreement entered into by a minor is void and cannot be enforced by either party.",
      'The customer shall submit, at enrolment, one valid officially valid document of identity (Aadhaar, PAN, Passport, Driving Licence or Voter ID), proof of address, a recent photograph, and a mobile number and, where available, an e-mail address for scheme communications.',
      'PAN is mandatory where the aggregate value of the transaction reaches or exceeds ₹2,00,000, in accordance with Rule 159 of the Income-tax Rules, 2026. Where the customer does not hold a PAN, Form No. 97 must be furnished.',
      'On enrolment the Firm shall issue the Passbook, carrying the account number, the First Instalment Date, the instalment amount, the Maturity Date, and the last date of the Redemption Window, each stated as an actual calendar date.',
      "A copy of these Terms and Conditions shall be handed to the customer at enrolment and the customer's acknowledgement obtained on the Declaration at the end of this document.",
    ],
  ),
  TermsSection(
    title: '4. Instalments, Due Dates and Payment Modes',
    points: [
      'The customer shall pay 11 equal monthly instalments. The instalment amount is fixed at enrolment and cannot be varied during the tenure.',
      'Each instalment falls due on the same day of the month as the First Instalment Date. Where that day does not exist in a given month, the last day of that month is the due date.',
      'A grace period of 10 days applies to every instalment. An instalment paid within the grace period carries no adverse consequence of any kind.',
      "Accepted payment modes are UPI, NEFT, RTGS, IMPS, net banking, debit card, credit card, and cash at authorised Suvarna Jewellers showrooms. For any electronic mode, the date of realisation in the Firm's account is the date of payment for the purposes of Clause 5.",
      'Cash payments are limited to comply with Sections 185–186 of the Income-tax Act, 2025: any instalment exceeding ₹20,000 must be paid through a banking or electronic channel; the aggregate cash received from one customer across all accounts and purchases in a single financial year shall not reach ₹2,00,000; and the final invoice, if a balance is payable, must be settled through a banking or electronic channel wherever that aggregate would otherwise be reached. Contravention may attract penalty under Section 451 of the Income-tax Act, 2025, equal to the amount received in cash in violation of this limit.',
      'Every instalment is receipted. The receipt records the amount, the mode, the date of realisation, the Board Rate applied and the grams credited. The Passbook is updated at the same time; the customer should verify the entry before leaving the counter.',
    ],
  ),
  TermsSection(
    title: '5. Gold Weight Accrual and Rate',
    points: [
      "Each instalment is converted into a weight in grams of 22K (916) gold by dividing the instalment amount by the Board Rate prevailing on the date the instalment is realised. The result is rounded to three decimal places in the customer's favour.",
      'The Board Rate is declared once each working day at 10:00 a.m. IST and remains unchanged for that day for the purposes of this Scheme, irrespective of intra-day movement in bullion markets.',
      "The Board Rate is displayed at the showroom counter and on the Firm's published channels, and is recorded on each receipt. Historical Board Rates for the customer's own account are available on request at any time.",
      'Accrual is in 22K gold only. No accrual is computed in 24K gold, bullion, coins or bars.',
      'The Accrued Gold Weight represents gold value only. Making charges, wastage or value addition, stone and diamond value, and taxes are separate components of the final invoice and are not covered by the Accrued Gold Weight (see Clause 8).',
    ],
  ),
  TermsSection(
    title: '6. Taxes',
    points: [
      'No Goods and Services Tax is charged on any instalment. Under Notification No. 66/2017 – Central Tax dated 15 November 2017, GST is not payable on advances received against the supply of goods; the tax liability arises at the time of supply.',
      'GST at the rate applicable on the date of supply is charged on the final invoice, on the value of the goods actually supplied. The customer is shown the tax computation on the invoice.',
      'If, during the tenure of an account, a statutory levy becomes payable on advances or on the supply by force of law, the Firm shall bear it in respect of instalments already received and shall notify the customer in writing before applying it to any future instalment. The customer may in that event close the account under Clause 9 without loss of the Maturity Benefit accrued up to that point.',
    ],
  ),
  TermsSection(
    title: '7. Maturity, Redemption and the Maturity Benefit',
    points: [
      'The Scheme matures on the Maturity Date. There is no waiting period after the final instalment — the customer may redeem on the Maturity Date itself.',
      'The Redemption Window runs from the Maturity Date to Day 330 from the First Instalment Date. This outer date is absolute and is not extended by any grace period under Clause 4.3, by late payment of any instalment, or by any event under Clause 16.',
      'On completing all 11 instalments and redeeming within the Redemption Window, the customer receives the Maturity Benefit: a discount on the final invoice equal to the amount of one monthly instalment.',
      'On redemption the Firm shall apply, in order: (a) the Accrued Gold Weight against the gold weight of the jewellery selected; (b) the Maturity Benefit as a discount on the invoice value; and (c) any balance payable by, or refundable to, the customer. The invoice shows each of these lines separately.',
      'Where the jewellery selected weighs more than the Accrued Gold Weight, the difference is charged at the Board Rate on the date of invoice. Where it weighs less, the surplus is converted at the Board Rate on the date of invoice and refunded through a banking channel within 15 days, or applied to a further purchase at the customer\'s option.',
      "Redemption is against 22K gold jewellery. At the customer's option, the Accrued Gold Weight may instead be converted to its rupee value at the Board Rate on the date of invoice and applied to the purchase of silver articles stocked by the Firm. Hallmarking of silver is at present voluntary in India, and the Firm's purity representations for silver rest on its own assay and invoice description.",
      'The Maturity Benefit is not payable in cash, is not convertible into gold weight, and cannot be transferred, sold or assigned.',
      "Redemption requires production of the original Passbook and the customer's photo identification. Clause 14 governs a lost Passbook.",
    ],
  ),
  TermsSection(
    title: '8. What the Maturity Benefit Does and Does Not Cover',
    points: [
      "Making charges and wastage or value addition are payable in full on the jewellery selected, at the Firm's standard published rates for that category of article, unless a separate written waiver is given.",
      "The Firm's standard making charge and wastage rates applicable to scheme redemptions are displayed at the counter and will not be increased for a scheme customer between the First Instalment Date and the close of the Redemption Window.",
      'Stone value, diamond value and certification charges on studded jewellery are payable in full.',
      'GST is payable on the invoice value after the Maturity Benefit has been applied.',
      'The Maturity Benefit cannot be combined with any other festival, seasonal or promotional discount on the same article unless expressly stated in that promotion.',
      'At enrolment, the Firm hands the customer a one-page illustration showing a worked example of a redemption at a representative instalment amount, including making charges, wastage and GST, so the customer can see what the Maturity Benefit is worth in rupees.',
    ],
  ),
  TermsSection(
    title: '9. Delay, Default and Early Closure',
    points: [
      'The Firm does not forfeit money. The consequences of delay or non-completion are limited to the Maturity Benefit, and are graduated in proportion to what was actually paid.',
      'Delay in an instalment beyond the grace period does not cancel the account. The instalment may be paid at any time up to Day 305, and gold accrues at the Board Rate on the date it is actually realised — the customer bears the rate movement over the period of delay; no separate penalty is levied.',
      'Where fewer than 11 instalments have been paid by Day 305, or where the customer chooses to close the account early, the entitlement is as set out in Schedule B.',
      'Cooling-off: the customer may cancel the account within 15 days of the First Instalment Date and receive a full refund of the amount paid, without giving reasons and without deduction. Refund is made through a banking channel within 7 working days.',
      'On any early closure after the cooling-off period, the customer may elect either: (a) to take delivery of jewellery against the Accrued Gold Weight immediately, at the making charge and wastage rates then applicable, with the Maturity Benefit as per Schedule B; or (b) to receive a refund of the total rupee amount paid, without interest, through a banking channel within 15 days — where the rupee value of the Accrued Gold Weight at the Board Rate on the closure date exceeds the amount paid, the higher of the two is refunded.',
      "An account is not converted into store credit, a voucher, or any other instrument on account of missed instalments. Any such conversion would extinguish the customer's rights without consideration and is not part of this Scheme.",
      'A dormant account, meaning one with no instalment received for three consecutive months, is not closed by the Firm. The Firm shall contact the customer in writing, and the account shall be dealt with under Clause 10 at the close of the Redemption Window.',
    ],
  ),
  TermsSection(
    title: '10. If the Redemption Window Closes Unredeemed',
    points: [
      "If the customer has not redeemed by the last day of the Redemption Window, the Firm shall, within 15 days of that date and without requiring any application from the customer, refund the total rupee amount paid, without interest, by account payee cheque or electronic transfer to the customer's registered bank account. No refund is made in cash.",
      'The Maturity Benefit is not payable on a refund under this Clause. The Firm shall instead issue a credit note for the Maturity Benefit amount, valid for 6 months against any purchase, which the customer is free to use or ignore.',
      'The Firm shall send at least three reminders — at Day 275, Day 305 and Day 320 — by SMS and, where available, e-mail, so the customer is not taken by surprise by the closing of the Redemption Window.',
      'This Clause exists so that no amount received by the Firm remains unappropriated and unrefunded beyond 365 days from its receipt. It is a core term of the Scheme and cannot be waived by either party.',
    ],
  ),
  TermsSection(
    title: '11. Nomination and Settlement on Death',
    points: [
      "The customer shall nominate one individual at enrolment, giving the nominee's name, relationship, date of birth, address, contact number and a copy of a photo identity document. The nomination may be changed at any time in writing.",
      'On the death of the customer, on production of the death certificate, the original Passbook, and the nominee\'s photo identification, the account is treated as matured on the date of death, the Accrued Gold Weight up to the last realised instalment stands to the credit of the account, and the Maturity Benefit is allowed on the scale in Schedule B, reckoned by the number of instalments actually paid.',
      'The nominee may elect delivery of jewellery against the Accrued Gold Weight, or a refund of the amount paid through a banking channel. Refund is not made in cash.',
      'The nominee receives the entitlement in a fiduciary capacity and does not become its absolute owner by virtue of the nomination. Nomination under this Scheme does not create a mode of succession and does not override the law of succession or any will.',
      "Delivery or payment made in good faith to the registered nominee constitutes a full and valid discharge of the Firm's obligations under the account. The nominee shall furnish an indemnity in the Firm's standard form. The Firm does not adjudicate competing claims of title; any dispute among heirs is a matter between them.",
      'Where the Firm has received written notice of a dispute, or where no nomination is on record, the account is settled in favour of the legal heirs on production of a succession certificate, legal heir certificate, or an order of a competent court.',
      "Where the nominee is a minor at the date of the customer's death, settlement is made to the minor's lawful guardian, to be held for the minor's benefit.",
    ],
  ),
  TermsSection(
    title: '12. Purity, Hallmarking and Delivery',
    points: [
      'All gold jewellery supplied under this Scheme is 22K, of 916 fineness, and carries the BIS Standard Mark, the purity grade, and a six-digit alphanumeric Hallmark Unique Identification (HUID) number.',
      'The HUID of every article supplied is printed on the invoice. The customer may verify it independently on the BIS CARE application or the BIS website, and is encouraged to do so before leaving the showroom.',
      'The invoice states, separately, the net weight of gold, the purity, the Board Rate applied, making charges, wastage or value addition, stone or diamond value if any, GST, and the Maturity Benefit applied.',
      "Delivery is at the Firm's showroom against signature. Where an article is to be made to order, the Firm shall state the delivery date in writing at the time of order, and that date shall fall within the Redemption Window.",
      "Nothing in this Scheme limits the customer's rights in respect of defective goods, short weight, or purity below the represented standard. Those rights are governed by law and are not affected by participation in this Scheme.",
    ],
  ),
  TermsSection(
    title: '13. Risk Disclosure',
    points: [
      'The customer is asked to read this Clause before enrolling. It is stated plainly and is not qualified elsewhere in this document.',
      'If the price of gold falls during the tenure, the rupee value of the Accrued Gold Weight falls with it. The Firm does not protect the customer against a fall in the gold price and does not guarantee the return of the rupee amount paid, except in the specific circumstances set out in Clauses 9.4, 9.5(b), 10.1 and 11.3.',
      "Conversely, if the price of gold rises, the customer has already secured the grams purchased at the earlier, lower rates. Accrual by weight is designed to average the customer's purchase price across the tenure.",
      'The Maturity Benefit is a discount on a purchase. Its value in rupees is materially reduced if the customer selects an article carrying high making charges or wastage. The illustration under Clause 8.2 is given for this reason.',
      "The customer's entitlement is a contractual claim against the Firm. It is not insured, not guaranteed by any government or regulator, and not secured against any specific asset.",
      'This Scheme is a means of planning a jewellery purchase. It is not an investment product and should not be compared with, or substituted for, a regulated savings or investment instrument.',
    ],
  ),
  TermsSection(
    title: '14. Passbook, Records and Statements',
    points: [
      "The Passbook is the primary record of the account. The Firm's electronic records are maintained in parallel and, in the event of a discrepancy, the two are reconciled against the underlying receipts and banking records.",
      'On loss of the Passbook the customer shall notify the Firm in writing. A duplicate is issued within 7 working days on verification of identity, against an indemnity, at a fee not exceeding ₹100. Loss of the Passbook does not affect the customer\'s entitlement.',
      'The Firm shall furnish a statement of account, showing every instalment, rate and gram credit, on request at any time and free of charge, and in any event at the Maturity Date.',
    ],
  ),
  TermsSection(
    title: '15. Personal Data',
    points: [
      "The Firm collects and processes the customer's personal data for operating the account, statutory identification and record-keeping, and communications relating to the account, in accordance with the Digital Personal Data Protection Act, 2023.",
      "The customer's data is not sold. It is not shared with third parties except where necessary to process a payment or refund, where required by law, or with the customer's consent.",
      'The customer may withdraw consent to marketing communications at any time without affecting the account, and may request correction of inaccurate data. Data is retained for the period required by law after closure of the account and is then erased.',
      'Grievances concerning personal data may be addressed to the Grievance Officer named in Clause 17.',
    ],
  ),
  TermsSection(
    title: '16. Force Majeure and Amendment',
    points: [
      'The Firm is not liable for delay in performance caused by an event beyond its reasonable control, including natural disaster, civil disturbance, government restriction, or failure of banking or payment infrastructure.',
      'Where such an event prevents redemption within the Redemption Window, the Firm shall, at the customer\'s option, either extend the Window by the period of the disruption up to a maximum that keeps the account within 355 days of the First Instalment Date, or refund the amount paid under Clause 10.1 together with the Maturity Benefit as a credit note. The 365-day outer limit cannot be extended by force majeure.',
      "The Firm may amend these Terms and Conditions only prospectively. An account is governed throughout its life by the terms in force on its First Instalment Date. No amendment shall reduce the entitlement of an existing account holder.",
      "The Scheme is non-transferable, save that the Firm shall permit one transfer of an account to the customer's spouse, parent, child or sibling on written request signed by both, with identification of the transferee — so that a customer unable to attend within the Redemption Window is not prejudiced.",
    ],
  ),
  TermsSection(
    title: '18. Governing Law and Dispute Resolution',
    points: [
      'These terms are governed by the laws of India.',
      'The parties shall attempt to resolve any dispute by discussion, and thereafter through mediation, before commencing proceedings.',
      'Subject to the next point, the courts at Visakhapatnam, Andhra Pradesh shall have jurisdiction.',
      "Nothing in this document restricts, waives or excludes the customer's right to approach a Consumer Disputes Redressal Commission, or any other forum conferred on the customer by statute, at the place and in the manner permitted by that statute. Any clause inconsistent with this point is to be read as if omitted.",
    ],
  ),
  TermsSection(
    title: '19. General',
    points: [
      'If any provision of these terms is held to be unenforceable, that provision shall be severed and the remainder shall continue in force.',
      'These terms, the Passbook, the receipts, the illustration under Clause 8.2 and the Declaration together constitute the entire agreement between the parties in respect of the account, and supersede any oral representation.',
      'Notices to the customer are validly given at the address, mobile number or e-mail recorded in the account. The customer shall notify the Firm in writing of any change.',
      'The English text of these terms shall prevail over any translation, save that where a customer has signed a Telugu version supplied by the Firm, the Telugu version shall prevail in any dispute with that customer.',
      'Failure by the Firm to enforce a provision on one occasion is not a waiver of that provision.',
    ],
  ),
  TermsSection(
    title: 'Schedule A — Timeline',
    points: [
      'All periods are counted in calendar days from the First Instalment Date. The actual dates for each account are printed on the Passbook.',
    ],
    tables: [
      TermsTable(rows: [
        TermsTableRow('Day 0',
            'First Instalment Date. Passbook issued with all key dates entered.'),
        TermsTableRow('Days 0–15',
            'Cooling-off period. Full refund on request, no reasons required.'),
        TermsTableRow('Day 0 to Day 305',
            '11 monthly instalments, each with a 10-day grace period.'),
        TermsTableRow('Day 275', 'First reminder issued.'),
        TermsTableRow(
            'Day 305', 'Maturity Date. Redemption may be taken from this day.'),
        TermsTableRow('Day 305', 'Second reminder issued.'),
        TermsTableRow('Day 320', 'Third and final reminder issued.'),
        TermsTableRow(
            'Day 330', 'Redemption Window closes. Absolute; not extendable.'),
        TermsTableRow('By Day 345',
            'Refund of amounts paid, if unredeemed, through banking channel.'),
        TermsTableRow('Day 365',
            'Statutory outer limit. No amount remains with the Firm unappropriated or unrefunded beyond this date.'),
      ]),
    ],
  ),
  TermsSection(
    title: 'Schedule B — Maturity Benefit on Early Closure or Incomplete Payment',
    points: [
      'The Accrued Gold Weight always belongs to the customer in full, in every row of this table. This Schedule governs only the Maturity Benefit.',
      'Where an account is settled under Clause 11 following the death of the customer, this Schedule is applied by reference to the number of instalments actually paid, and no adverse inference is drawn from non-payment after the date of death.',
    ],
    tables: [
      TermsTable(rows: [
        TermsTableRow('Within cooling-off (Clause 9.4)',
            'Not applicable. Full refund of the amount paid.'),
        TermsTableRow('1 to 3 instalments paid',
            'Nil. Accrued Gold Weight redeemable in full, or refund under Clause 9.5(b).'),
        TermsTableRow('4 to 6 instalments paid', '25% of one instalment.'),
        TermsTableRow('7 to 9 instalments paid', '50% of one instalment.'),
        TermsTableRow('10 instalments paid', '75% of one instalment.'),
        TermsTableRow('11 (complete), redeemed within the Window',
            '100% of one instalment — the full Maturity Benefit.'),
        TermsTableRow('11 (complete), not redeemed within the Window',
            'Credit note for one instalment, valid 6 months (Clause 10.2).'),
      ]),
    ],
  ),
  TermsSection(
    title: 'Contact Information',
    points: [
      'Suvarna Jewellers, D.No. 13-1-12, Main Road, Near YSR Statue, New Gajuwaka, Visakhapatnam - 530026, Andhra Pradesh, India.',
      'Email: suvarnajewellers12@gmail.com',
      '© 2026 Suvarna Jewellers. All Rights Reserved.',
    ],
  ),
];