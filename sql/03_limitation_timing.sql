-- ===========================================================================
-- 03_limitation_timing.sql
--
-- Supplement to 02_build_analytic_dataset.sql. One row per unit stay with the
-- offset, in minutes from unit admission, of the FIRST care limitation order
-- at each tier within the first 24 hours. The main extraction records only
-- the first limitation of any kind, so a patient documented DNR at hour 1 and
-- comfort measures at hour 20 carries an offset of 60. This query separates
-- the tiers so the timing of the most restrictive order can be analyzed.
--
-- Save as data_private/limitation_timing.csv. Patient level: never commit.
-- ===========================================================================
SELECT
    patientunitstayid,
    MIN(CASE WHEN cplitemvalue IN ('Do not resuscitate','No CPR','No intubation',
                                   'No cardioversion')
             THEN cplitemoffset END)                    AS first_dnr_offset,
    MIN(CASE WHEN cplitemvalue IN ('No augmentation of care','No vasopressors/inotropes',
                                   'No blood products','No blood draws')
             THEN cplitemoffset END)                    AS first_partial_offset,
    MIN(CASE WHEN cplitemvalue = 'Comfort measures only'
             THEN cplitemoffset END)                    AS first_cmo_offset,
    MIN(CASE WHEN cplitemvalue = 'Full therapy'
             THEN cplitemoffset END)                    AS first_full_offset,
    COUNT(*)                                            AS n_cpl_items_24h
FROM `physionet-data.eicu_crd.careplangeneral`
WHERE LOWER(cplgroup) LIKE '%care limitation%'
  AND cplitemoffset <= 1440
GROUP BY patientunitstayid
