# 🏗️ Building a Modern Data Warehouse with SQL

> An end-to-end data engineering portfolio project — from raw data ingestion to analytical reporting — built using industry-standard architecture and best practices.

---

## 📌 Project Overview

This project demonstrates the design and implementation of a **modern data warehouse** using SQL, following real-world data engineering workflows. It covers the full lifecycle of data — from source ingestion through transformation to analytics-ready datasets — structured across the classic **Bronze → Silver → Gold** layered architecture.
---

## 🎯 Objectives

- Design and build a scalable, production-grade SQL data warehouse from scratch
- Implement a structured **ETL pipeline** across multiple data layers
- Apply **data modeling** best practices including dimensional and fact table design
- Produce clean, analytics-ready datasets for business intelligence and reporting

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    DATA SOURCES                         │
│            (CSV Files / ERP & CRM Systems)              │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  BRONZE LAYER                           │
│         Raw ingestion — data loaded as-is               │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  SILVER LAYER                           │
│     Cleansed, standardised, and validated data          │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   GOLD LAYER                            │
│     Business-ready dimensional models & aggregates      │
└─────────────────────────────────────────────────────────┘
```

---

## 🗂️ Repository Structure

```
├── datasets/                  # Raw source data files (CSV)
├── docs/                      # Architecture diagrams & documentation
│   ├── data_architecture.png
│   ├── data_catalog.md
│   └── data_flow.png
├── scripts/
│   ├── bronze/                # Raw ingestion scripts
│   ├── silver/                # Data cleansing & transformation scripts
│   └── gold/                  # Dimensional model & reporting layer scripts
├── tests/                     # Data quality & validation checks
├── README.md
└── LICENSE
```

---

## 🔧 Tech Stack

| Tool / Technology | Purpose |
|---|---|
| **SQL Server / T-SQL** | Core database engine and scripting |
| **SQL Server Management Studio (SSMS)** | Development & query environment |
| **DrawIO / Lucidchart** | Architecture & data flow diagrams |
| **Git & GitHub** | Version control & project hosting |
| **CSV / Flat Files** | Source data format |

---

## 📐 Data Modeling

The **Gold Layer** follows a **Star Schema** design:

- **Fact Tables** — transactional, measurable business events
- **Dimension Tables** — descriptive context for facts (customers, products, dates, etc.)

This structure is optimised for analytical queries and BI tool compatibility.

---

## 🚀 Getting Started

### Prerequisites

- SQL Server (2019 or later) or any compatible SQL environment
- SQL Server Management Studio (SSMS) or equivalent client
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/your-repo-name.git
   cd your-repo-name
   ```

2. **Set up the database**
   ```sql
   -- Run the initialisation script to create the database and schemas
   scripts/init_database.sql
   ```

3. **Load the Bronze Layer**
   ```sql
   -- Ingest raw source data
   scripts/bronze/load_bronze.sql
   ```

4. **Transform to Silver Layer**
   ```sql
   -- Apply cleansing and standardisation
   scripts/silver/load_silver.sql
   ```

5. **Build the Gold Layer**
   ```sql
   -- Create dimensional models
   scripts/gold/load_gold.sql
   ```

---

## 📊 Data Sources

The project uses two simulated business data sources:

| Source | Description |
|---|---|
| **ERP System** | Sales transactions, product data, and order records |
| **CRM System** | Customer profiles, demographics, and contact information |

---

## 📋 Project Scope

| Scope Item | Details |
|---|---|
| **Data Volume** | Small-to-medium (suitable for portfolio demonstration) |
| **Refresh Strategy** | Full load (batch) |
| **Historical Data** | Included for trend and time-series analysis |
| **Target Audience** | Data Engineers, Data Analysts, BI Developers |

---

## 🤝 Contributing

Contributions, suggestions, and improvements are welcome. Please open an issue or submit a pull request.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements
- The broader data engineering and SQL community

---

*Built with precision. Designed for clarity. Engineered for scale.*
