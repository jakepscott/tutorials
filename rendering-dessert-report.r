library(here)

rmarkdown::render(here("reports/00_markdown.Rmd"),
                  params = list(
                    var1 = "Pie",
                    var2 = 'Apple',
                    date = as.Date("2016-10-01")),
                  output_file = here("reports/apple-pie.pdf"))

rmarkdown::render(here("reports/00_markdown.Rmd"),
                  params = list(
                    var1 = "Pie",
                    var2 = 'Punpkin',
                    date = as.Date("2016-10-01")),
                  output_file = here("reports/pumpkin-pie.pdf"))
