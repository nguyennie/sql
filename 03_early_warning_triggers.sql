-- ══════════════════════════════════════════════════════════
-- EARLY WARNING SYSTEM
-- Question: Which ACTIVE borrowers show the highest
--           combination of risk signals right now?
-- 
-- Logic: score each risk factor independently,
--        then sum into a composite risk score.
-- This is the basis for a proactive outreach program.
-- ══════════════════════════════════════════════════════════

WITH risk_scored AS (
    SELECT
        client_id,
        person_income,
        loan_amnt,
        loan_grade,
        loan_intent,
        loan_int_rate,
        loan_to_income_ratio,
        debt_to_income_ratio,
        person_home_ownership,
        cb_person_default_on_file,
        person_emp_length,
        past_delinquencies,
        loan_status,

        -- ── Individual risk flags (0 or 1 each) ──────────────
        -- LTI > 35%: approaching hard cap threshold
        CASE WHEN loan_to_income_ratio > 0.35  THEN 1 ELSE 0 END AS flag_high_lti,

        -- DTI > 40%: high total debt burden
        CASE WHEN debt_to_income_ratio > 0.40  THEN 1 ELSE 0 END AS flag_high_dti,

        -- Grade D or worse: elevated default risk tier
        CASE WHEN loan_grade IN ('D','E','F','G') THEN 1 ELSE 0 END AS flag_bad_grade,

        -- Interest rate > 16%: historically correlates with 60%+ default
        CASE WHEN loan_int_rate > 16             THEN 1 ELSE 0 END AS flag_high_rate,

        -- Prior default on record
        CASE WHEN cb_person_default_on_file = 'Y' THEN 1 ELSE 0 END AS flag_prior_default,

        -- Renter (no housing asset as implicit collateral signal)
        CASE WHEN person_home_ownership = 'RENT' THEN 1 ELSE 0 END AS flag_renter,

        -- New employee (< 1 year tenure)
        CASE WHEN person_emp_length < 1          THEN 1 ELSE 0 END AS flag_new_employee,

        -- Past delinquencies on record
        CASE WHEN past_delinquencies > 0         THEN 1 ELSE 0 END AS flag_past_delinq

    FROM loans
    WHERE loan_status = 0  -- active (non-defaulted) loans only
),
scored AS (
    SELECT
        *,
        -- Composite risk score: sum of all flags (0–8)
        flag_high_lti + flag_high_dti + flag_bad_grade + flag_high_rate
        + flag_prior_default + flag_renter + flag_new_employee
        + flag_past_delinq                      AS composite_risk_score
    FROM risk_scored
)
SELECT
    client_id,
    loan_grade,
    loan_intent,
    ROUND(loan_to_income_ratio * 100, 1)        AS lti_pct,
    ROUND(debt_to_income_ratio * 100, 1)        AS dti_pct,
    loan_int_rate,
    composite_risk_score,

    -- Action recommendation based on total score
    CASE
        WHEN composite_risk_score >= 5 THEN 'IMMEDIATE OUTREACH'
        WHEN composite_risk_score >= 3 THEN 'SCHEDULE REVIEW'
        WHEN composite_risk_score >= 2 THEN 'MONITOR MONTHLY'
        ELSE                               'ROUTINE'
    END AS recommended_action,

    -- Which flags were triggered (for outreach team context)
    CONCAT_WS(', ',
        CASE WHEN flag_high_lti      = 1 THEN 'High LTI'       END,
        CASE WHEN flag_high_dti      = 1 THEN 'High DTI'        END,
        CASE WHEN flag_bad_grade     = 1 THEN 'Grade D-G'       END,
        CASE WHEN flag_high_rate     = 1 THEN 'High Rate'       END,
        CASE WHEN flag_prior_default = 1 THEN 'Prior Default'   END,
        CASE WHEN flag_renter        = 1 THEN 'Renter'          END,
        CASE WHEN flag_new_employee  = 1 THEN 'New Employee'    END,
        CASE WHEN flag_past_delinq   = 1 THEN 'Past Delinq'     END
    )                                           AS triggered_flags

FROM scored
WHERE composite_risk_score >= 2
ORDER BY composite_risk_score DESC, lti_pct DESC
LIMIT 100;
