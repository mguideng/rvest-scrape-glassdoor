# Reference: https://www.glassdoor.com/Reviews/Tesla-Reviews-E43129.htm

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

#### EXPORT ####
write.csv(df, "scrape-glassdoor-tesla.csv")

