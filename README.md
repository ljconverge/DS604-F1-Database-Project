# DS604 – Formula 1 World Championship Database

DS604 Introduction to Data Management, Autumn 2026 – Group Project

Team: 202618052, 202618016, 202618013

Dataset: [Formula 1 World Championship (1950–2020), Kaggle](https://www.kaggle.com/datasets/rohanrao/formula-1-world-championship-1950-2020)

## Repository structure

```
DS604-F1-Database-Project/
├── data/raw/                  # Kaggle CSV files (not committed)
├── 00_exploration/            # Data exploration before schema design
├── 01_dataset_and_queries/    # Milestone 1: dataset description + query list
├── 02_schema/                 # Milestone 2: ER diagram, relational schema, DDL
├── 03_data_loading/           # Milestone 3: pandas + sqlalchemy to_sql (append)
├── 04_analytical_queries/     # Milestone 4: read_sql_query, head(10)
└── 05_views/                  # Milestone 5: SQL views
```

## Milestones

| # | Milestone | Deliverable | Due |
|---|-----------|-------------|-----|
| 1 | Identify dataset and tentative queries | Document | 03-Oct-2026 |
| 2 | ER diagram, relational schema diagram, DDL scripts | Single PDF | 15-Oct-2026 |
| 3 | Load data into PostgreSQL (10.100.71.21) using pandas `to_sql` (append) with sqlalchemy | Jupyter Notebook as PDF | 17-Oct-2026 |
| 4 | Run analytical queries with `read_sql_query`, print `head(10)` | Jupyter Notebook as PDF | 06-Nov-2026 |
| 5 | Save selected queries as views | SQL code as PDF | 06-Nov-2026 |
| – | Final submission (all documents, updated) | All PDFs | 15-Nov-2026 |

## Setup

```bash
git clone https://github.com/<your-username>/DS604-F1-Database-Project.git
cd DS604-F1-Database-Project

python -m venv venv
# Windows:      venv\Scripts\activate
# macOS/Linux:  source venv/bin/activate

pip install -r requirements.txt
```

Download the dataset and unzip all CSV files into `data/raw/`:

- Manually: download the ZIP from the Kaggle link above and extract it into `data/raw/`, or
- With the Kaggle CLI (requires `kaggle.json` API token):
  ```bash
  kaggle datasets download -d rohanrao/formula-1-world-championship-1950-2020 -p data/raw --unzip
  ```

Then run the exploration notebook:

```bash
jupyter notebook 00_exploration/data_exploration.ipynb
```
