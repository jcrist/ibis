SELECT
  FIRST_VALUE(`t0`.`double_col`) OVER (ORDER BY `t0`.`id` ASC) AS `First(double_col)`
FROM `functional_alltypes` AS `t0`