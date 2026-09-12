-- ══════════════════════════════════════════════════════════
-- RISK SEGMENTATION MATRIX
-- Question: Which borrower combinations are safest
--           and which are critical?
-- Combines home ownership × prior default history
-- — the two variables with the widest risk spread
-- ══════════════════════════════════════════════════════════

WITH segment_stats AS (
    SELECT
        person_home_ownership,
        cb_person_default_on_file,
        COUNT(*)                                    AS borrower_count,
        ROUND(AVG(loan_status::NUMERIC) * 100, 1)  AS default_rate_pct,
        ROUND(AVG(person_income), 0)                AS avg_income,
        ROUND(AVG(loan_amnt), 0)                    AS avg_loan_amount,
        ROUND(AVG(loan_to_income_ratio), 3)         AS avg_lti_ratio,
        ROUND(AVG(debt_to_income_ratio), 3)         AS avg_dti_ratio
    FROM loans
    GROUP BY person_home_ownership, cb_person_default_on_file
),
baseline AS (
    SELECT ROUND(AVG(loan_status::NUMERIC) * 100, 1) AS portfolio_avg
    FROM loans
)
SELECT
    s.person_home_ownership,
    s.cb_person_default_on_file     AS prior_default_on_file,
    s.borrower_count,
    ROUND(s.borrower_count * 100.0 / SUM(s.borrower_count) OVER (), 1)
                                    AS portfolio_share_pct,
    s.default_rate_pct,
    b.portfolio_avg                 AS portfolio_avg_pct,
    s.default_rate_pct - b.portfolio_avg AS vs_avg_pp,
    s.avg_income,
    s.avg_loan_amount,
    s.avg_lti_ratio,

    -- Risk tier label for dashboard use
    CASE
        WHEN s.default_rate_pct < 10 THEN '🟢 Low Risk'
        WHEN s.default_rate_pct < 25 THEN '🟡 Moderate'
        WHEN s.default_rate_pct < 40 THEN '🟠 High Risk'
        ELSE                              '🔴 Critical'
    END AS risk_tier

FROM segment_stats s
CROSS JOIN baseline b
ORDER BY s.default_rate_pct DESC;
