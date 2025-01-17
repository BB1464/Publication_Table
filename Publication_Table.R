#' ---
#' title: "Publication ready ANOVA table in R"
#' author: "by Farhan Khalid"
#' date: ""
#' ---

#+ warning=FALSE, message=FALSE, echo=FALSE

# Library ----

library(readxl)
library(dplyr)
library(tibble)
library(flextable)
library(here)

# Importing data ----
data<-read_excel('data_anova.xlsx',col_names = TRUE)


# Convert categorical variables to factor variables
data$Rep = as.factor(data$Rep)
data$Water = as.factor(data$Water)
data$Priming = as.factor(data$Priming)


attach(data)

# Analysis of variance ----

for(i in 1:ncol(data[-c(1:3)])) {
  cols <- names(data)[4:ncol(data)]
  aov.model <- lapply(X = cols, FUN = function(x)
    aov(reformulate(termlabels = "Rep + Water*Priming",
                    response = x),
        data = data))

  # print df, MS and Pvalue
  final = anova(aov.model[[i]])[,c(1,3,5)]

  # Getting rownames
  rnames = rownames(final)

  # Setting column names
  colnames(final) = c("DF", "MS", "P-value")
  colnames(final)[2] = cols[i]

  # Rounding values to 3 decimal place
  final = as.data.frame(round(final, digits = 2))

  # Assign astericks according to p values
  final$sign[final$`P-value` < 0.05] <- "*"
  final$sign[final$`P-value` < 0.01] <- "**"
  final$sign[final$`P-value` > 0.05] <- "ns"

  # Merge MS and significance column together
  final[[2]] = paste(final[[2]],
                     ifelse(is.na(final[[4]]), "", final[[4]]))
  final = final[-c(3,4)]
  anova = writexl::write_xlsx(final,
                              path = paste(cols[i], '-ANOVA.xlsx'))

  # Print final ANOVA table ----
  file.list <- list.files(pattern='*-ANOVA.xlsx')

  df.list <- lapply(X = file.list, FUN = read_excel)

  # Combined ANOVA table for all variables
  aov.table = rlist::list.cbind(df.list)

  # Remove duplicate columns for DF
          dup.cols = which(duplicated(names(aov.table)))
          aov.table = aov.table[,-dup.cols]

          # Names for sources of variation in ANOVA
          rownames(aov.table) = rnames
}

# Printing ANOVA table
table = flextable(data = aov.table %>%
                    rownames_to_column("SOV"))

bold(table, bold = TRUE, part = "header")


