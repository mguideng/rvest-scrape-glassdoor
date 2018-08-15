README
================
Maria Guideng

scrape-glassdoor
================

About
-----

Web scrape *Glassdoor.com* for company reviews in R (using rvest). Prep text data for text analytics.

Demo
----

Take Tesla for example. The url to scrape will be:
<https://www.glassdoor.com/Reviews/Tesla-Reviews-E43129.htm>

Here's a screen shot of the text to extract:

![gd-tesla](https://raw.githubusercontent.com/mguideng/rvest-scrape-glassdoor/master/images/gd-tesla.PNG)

**Web scraper function**

Extract company reviews for the following:

-   Total reviews - by full & part-time workers only
-   Date - of when review was posted
-   Summary - e.g., "I have none"
-   Title - e.g., "Former Employee - Class A Truck Driver in Oakland, CA"
-   Pros - upsides of the workplace
-   Cons - downsides of the workplace
-   Helpful - number marked as being helpful, if any

``` r
#### SCRAPE ####
# Packages
library(rvest)    #scrape
library(purrr)    #iterate scraping by map_df()

# Set URL
baseurl <- "https://www.glassdoor.com/Reviews/"
company <- "Tesla-Reviews-E43129"
sort <- ".htm?sort.sortType=RD&sort.ascending=true"

# How many total number of reviews? It will determine the maximum page results to iterate over.
totalreviews <- read_html(paste(baseurl, company, sort, sep="")) %>% 
  html_nodes(".margBot.minor") %>% 
  html_text() %>% 
  sub(" reviews", "", .) %>% 
  sub(",", "", .) %>% 
  as.integer()

maxresults <- as.integer(ceiling(totalreviews/10))    #10 reviews per page, round up to whole number

# Scraping function to create dataframe of: Date, Summary, Title, Pros, Cons, Helpful
df <- map_df(1:maxresults, function(i) {
  
  Sys.sleep(5)    #be a polite bot. Will take ~13 mins to run with system sleeper.
  
  cat("boom! ")   #progress indicator
  
  pg <- read_html(paste(baseurl, company, "_P", i, sort, sep=""))   #pagination (_P1 to _P152)
  
  data.frame(rev.date = html_text(html_nodes(pg, ".date.subtle.small, .featuredFlag")),
             rev.sum = html_text(html_nodes(pg, ".reviewLink .summary:not([class*='hidden'])")),
             rev.title = html_text(html_nodes(pg, "#ReviewsFeed .hideHH")),
             rev.pros = html_text(html_nodes(pg, "#ReviewsFeed .pros:not([class*='hidden'])")),
             rev.cons = html_text(html_nodes(pg, "#ReviewsFeed .cons:not([class*='hidden'])")),
             rev.helpf = html_text(html_nodes(pg, ".tight")),
             stringsAsFactors=F)
})
```

**RegEx**

Use regular expressions to clean and extract additonal variables:

-   Reviewer ID (1 to N reviewers by date, sorted from first to last)
-   Year (from Date)
-   Location (e.g., Oakland, CA)
-   Position (e.g., Class A Truck Driver)
-   Status (current or former employee)

``` r
#### REGEX ####
# Packages
library(stringr)    #pattern matching functions

# Clean: Helpful
df$rev.helpf <- as.numeric(gsub("\\D", "", df$rev.helpf))

# Add: ID
df$rev.id <- as.numeric(rownames(df))

# Extract: Year, Position, Location, Status
df$rev.year <- as.numeric(sub(".*, ","", df$rev.date))

df$rev.pos <- sub(".* Employee - ", "", df$rev.title)
df$rev.pos <- sub(" in .*", "", df$rev.pos)

df$rev.loc <- sub(".*\\ in ", "", df$rev.title)
df$rev.loc <- ifelse(df$rev.loc %in% 
                       (grep("Former Employee|Current Employee", df$rev.loc, value = T)), 
                     "Not Given", df$rev.loc)

df$rev.stat <- str_extract(df$rev.title, ".* Employee -")
df$rev.stat <- sub(" Employee -", "", df$rev.stat)
```

**Output**

![df-tesla](https://raw.githubusercontent.com/mguideng/rvest-scrape-glassdoor/master/images/df-tesla.PNG)

``` r
#### EXPORT ####
write.csv(df, "scrape-glassdoor-tesla.csv")  #to csv
```

**Exploration ideas**

Analyze the unstructured text, extract relevant information and transform it into useful insights:

-   Apply text analytics through Natural Language Processing (NLP) methods to show what is being written about the most.
-   Sentiment analysis by categorizing the text data to determine whether a review is considered positive, negative or neutral as a way of deriving the emotions and attitudes of employees.
-   I highly recommend the ["Text Mining with R" book](https://www.tidytextmining.com/) by Julia Silge and David Robinson for further ideas.

**Project purpose**

Develop R skills and leverage for another project: [text mining applied to Big 3 Consulting](https://mguideng.github.io/2018-07-16-text-mining-glassdoor-big3/).
