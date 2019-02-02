# ----------------------------------------- #
#             THInC CompareRx               #
#             Drug Price Data               #
#             February 2, 2018              #
#                  Team 29                  #
# ----------------------------------------- #

#### ------------------ load packages ------------------ ####
library(readr)
library(dplyr)
library(tidyr)
library(magrittr)
library(lubridate)


#### ---------------- set up environment --------------- ####
.wd <- "~/Projects/THInC/"
SDUD_FP  <- paste0(.wd, "Data/State_Drug_Utilization_Data_2018.csv")
AMP_FP   <- paste0(.wd, "Data/Drug_AMP_Reporting_-_Monthly.csv")
NADAC_FP <- paste0(.wd, "Data/NADAC__National_Average_Drug_Acquisition_Cost_.csv")
mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}


#### --------------- read and clean data --------------- ####
.state_data <- read.csv(SDUD_FP, stringsAsFactors=FALSE)
.amp_data   <- read.csv(AMP_FP, stringsAsFactors=FALSE)
.nadac_data <- read.csv(NADAC_FP, stringsAsFactors=FALSE)
state_data <- .state_data
amp_data   <- .amp_data
nadac_data <- .nadac_data

# Clean state drug utilization data.

state_data %<>%
  mutate_at(c("Suppression.Used"), as.logical) %>%
  mutate_at(c("Product.Name"), tolower) %>%
  .[which(.$Suppression.Used==FALSE), ] %>%
  .[which(nchar(.$Product.Name) > 0), ] %>%
  select(State, Product.Name, Units.Reimbursed, Number.of.Prescriptions, Total.Amount.Reimbursed, Latitude, Longitude, NDC)

state_data$Cost.Per.Unit = state_data$Total.Amount.Reimbursed / state_data$Units.Reimbursed

state_data %<>%
  group_by(NDC, State) %>%
  summarize(Product.Name=mode(Product.Name), Cost.Per.Unit=mean(Cost.Per.Unit)) %>%
  ungroup() %>%
  arrange(Product.Name, State)

# Clean national average drug acquisition cost data.

nadac_data %<>%
  mutate_at(c("Effective_Date"), mdy) %>%
  mutate_at(c("NDC.Description"), tolower) %>%
  select(NDC.Description, NDC, NADAC_Per_Unit, Effective_Date, Pricing_Unit) %>%
  arrange(NDC, desc(Effective_Date)) %>%
  .[which(!duplicated(.$NDC)), ] %>%
  arrange(NDC.Description)


#### ------------------- merge data -------------------- ####

drug_price_data <- left_join(state_data, nadac_data, by="NDC") %>%
  filter(!is.na(NDC.Description) & State!="XX" & Cost.Per.Unit>0) %>%
  group_by(NDC.Description, State) %>%
  summarize(NDC=mode(NDC), Pricing_Unit=mode(Pricing_Unit), Cost.Per.Unit=mean(Cost.Per.Unit),
            NADAC_Per_Unit=mean(NADAC_Per_Unit), Effective_Date=mode(Effective_Date)) %>%
  ungroup() %>%
  arrange(NDC.Description, State)