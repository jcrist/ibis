SELECT
  t0.foo_id AS foo_id,
  SUM(t0.f) AS total
FROM star1 AS t0
GROUP BY
  1