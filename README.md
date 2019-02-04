# compare-rx
Cleaning and preliminary analysis of state drug price data, to show variations in drug prices across different states.

Created for the 2019 [Triangle Health Innovation Challenge](http://www.thincweekend.org/) (THInC), a medical hackathon hosted by Duke University.

## Data sources
- [State Drug Utilization Data](https://www.medicaid.gov/medicaid/prescription-drugs/state-drug-utilization-data) (SDUD), which documents the Medicaid Drug Rebate Program's reimbursements to drug manufacturers who dispense prescription drugs to Medicaid patients.
- [National Average Drug Acquisition Cost](https://www.medicaid.gov/medicaid/prescription-drugs/pharmacy-pricing/index.html) (NADAC), which posts weekly average acquisition costs of prescription drugs as reported by pharmacy surveys.

## Data processing

### Cleaning data
- Reformat all columns and clean all drug names.
- Remove redacted entries from the SDUD dataset.
- Consolidate the SDUD dataset so that each drug corresponds to a single row.
- Consolidate the NADAC dataset to include only the most recent prices.

### Merging data
- Merge the SDUD prices with the NADAC drug descriptions.

## Preliminary data analysis

### Analysis
- Remove outliers (distance from median ≥ 4σ) that were likely from mis-entered entries.
- Identify drugs with the largest price differences between states.

## Visualization
- Identify the top 5 drugs with the largest interstate price variations: Stelara, Neulasta, Simponi, Avonex, and Lupron Depot.
- Compare the highest-priced state with the lowest-priced for each drug.