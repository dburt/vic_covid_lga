# Coronavirus cases by LGA in Victoria, Australia

Starting on 12 June 2020 the Victorian Department of Health and Human Services
has published a table listing total and current coronavirus cases by LGA on
each day's media release page.

https://www.dhhs.vic.gov.au/coronavirus-update-victoria-12-june-2020

The aim of this project is to make that data more accessible.

It will download all the HTML from the media pages, extract the content of
the LGA cases tables as CSV files, and compile a master CSV with all the data,
including a 'new cases' metric calculated as the difference from the previous total.

Install dependencies with Bundler, run with Ruby, open master.csv with Excel or Power BI. e.g.:

```
bundle
bundle exec ruby scrape_vic_covid_lga.rb
launchy ./master.csv
```
