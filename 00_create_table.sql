-- Nova Bank Credit Risk — Table Definition
-- Source: cleaned_credit_risk.csv (exported from Python notebook)
-- Database: PostgreSQL 15+

CREATE TABLE IF NOT EXISTS loans (
    client_id               VARCHAR(20) PRIMARY KEY,
    person_age              INTEGER,
    person_income           NUMERIC(12, 2),
    person_home_ownership   VARCHAR(20),
    person_emp_length       NUMERIC(5, 1),
    loan_intent             VARCHAR(30),
    loan_grade              CHAR(1),
    loan_amnt               NUMERIC(12, 2),
    loan_int_rate           NUMERIC(5, 2),
    loan_status             SMALLINT,       -- 0 = performing, 1 = default
    loan_percent_income     NUMERIC(6, 4),
    cb_person_default_on_file CHAR(1),      -- Y / N
    cb_person_cred_hist_length INTEGER,
    employment_type         VARCHAR(20),
    loan_term_months        INTEGER,
    loan_to_income_ratio    NUMERIC(8, 4),
    debt_to_income_ratio    NUMERIC(8, 4),
    open_accounts           INTEGER,
    credit_utilization_ratio NUMERIC(6, 4),
    past_delinquencies      INTEGER,
    country                 VARCHAR(20),
    gender                  VARCHAR(10),
    education_level         VARCHAR(20),
    marital_status          VARCHAR(20)
);

-- Load from CSV (adjust path as needed)
-- COPY loans FROM '/path/to/cleaned_credit_risk.csv'
-- CSV HEADER ENCODING 'UTF8';
