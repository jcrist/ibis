SELECT
  SUM(`t0`.`d`) OVER (ORDER BY `t0`.`f` ASC ROWS BETWEEN 5 preceding AND CURRENT ROW) AS `foo`
FROM `alltypes` AS `t0`