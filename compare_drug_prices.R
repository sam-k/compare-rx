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
library(reshape2)
library(ggplot2)


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
# .state_data <- read.csv(SDUD_FP, stringsAsFactors=FALSE)
# .amp_data   <- read.csv(AMP_FP, stringsAsFactors=FALSE)
# .nadac_data <- read.csv(NADAC_FP, stringsAsFactors=FALSE)
state_data <- .state_data
amp_data   <- .amp_data
nadac_data <- .nadac_data

# Clean state drug utilization data.

state_data %<>%
  mutate_at(c("Suppression.Used"), as.logical) %>%
  mutate_at(c("Product.Name"), tolower) %>%
  .[which(.$Suppression.Used==FALSE & nchar(.$Product.Name) > 0 & !is.na(.$Units.Reimbursed)), ] %>%
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


#### ----------- analyze and visualize data ------------ ####

drug_price_data %<>%
  group_by(NDC.Description) %>%
  filter(abs(Cost.Per.Unit - median(Cost.Per.Unit)) <= 4*sd(Cost.Per.Unit)) %>%
  ungroup()

highest_diffs <- drug_price_data %>%
  group_by(NDC.Description) %>%
  summarize(NDC=mode(NDC), Pricing_Unit=mode(Pricing_Unit), Price.Diff=max(Cost.Per.Unit)-min(Cost.Per.Unit),
            Avg.Cost.Per.Unit=mean(Cost.Per.Unit), Avg.NADAC_Per_Unit=mean(NADAC_Per_Unit),
            Effective_Date=mode(Effective_Date)) %>%
  ungroup() %>%
  arrange(desc(Price.Diff), NDC.Description)

.top_highest_diffs <- drug_price_data %>%
  select(NDC.Description, State, Cost.Per.Unit) %>%
  filter(NDC.Description %in% c("neulasta 6 mg/0.6 ml syringe", "stelara 90 mg/ml syringe", "simponi 50 mg/0.5 ml pen injec",
                                "lupron depot 22.5 mg 3mo kit", "avonex pen 30 mcg/0.5 ml kit")) %>%
  group_by(NDC.Description) %>%
  filter(Cost.Per.Unit==min(Cost.Per.Unit) | Cost.Per.Unit==max(Cost.Per.Unit)) %>%
  ungroup()

Drugs <- factor(c(rep("Neulasta",2), rep("Stelara",2), rep("Simponi",2), rep("Lupron",2), rep("Avonex",2)),
                levels=c("Stelara","Neulasta","Simponi","Avonex","Lupron"))
HL    <- factor(rep(c("High","Low"),5),
                levels=c("High","Low"))
Cost  <- c(14795.6532,2626.0237, 21988.0563,12847.9312, 9323.6800,4186.0580, 4010.3519,297.6197, 4252.3943,1209.5197)
top_highest_diffs <- data.frame(Drugs, HL, Cost)
ggplot(melt(top_highest_diffs), aes(Drugs, Cost, fill=HL)) + 
  geom_bar(position="dodge", stat="identity") +
  labs(x="", y="Cost ($)") +
  theme(legend.position="none", panel.grid.major.x=element_blank()) +
  scale_y_continuous(expand=c(0,0))
ggsave("top_5_highest_diffs.png")
