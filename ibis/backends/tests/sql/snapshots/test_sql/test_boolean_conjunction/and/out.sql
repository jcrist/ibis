SELECT
  (
    "t0"."double_col" > CAST(0 AS TINYINT)
  )
  AND (
    "t0"."double_col" < CAST(5 AS TINYINT)
  ) AS "tmp"
FROM "functional_alltypes" AS "t0"