# 🏢 HR Employee Database System
### Microsoft SQL Server (T-SQL) Edition

![SQL Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-2019%2F2022-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-Language-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Complete-green?style=for-the-badge)

> A fully implemented HR database system built with Microsoft SQL Server (T-SQL), covering employee management, attendance, leave, payroll, training, and role-based access control.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Database Schema](#-database-schema)
- [Features](#-features)
- [Getting Started](#-getting-started)
- [Stored Procedures](#-stored-procedures)
- [Reports](#-reports)
- [Role-Based Access](#-role-based-access)
- [Sample Data](#-sample-data)
- [Project Files](#-project-files)

---

## 📌 Overview

The **HR Employee Database System** is a relational database solution designed to centralize and manage all essential Human Resources information for an organization.

| Item | Details |
|------|---------|
| 🗄️ Database Engine | Microsoft SQL Server 2019 / 2022 |
| 💬 Language | T-SQL (Transact-SQL) |
| 🗃️ Database Name | `HR_System` |
| 📊 Total Tables | 10 Tables |
| ⚙️ Stored Procedures | 17 Procedures |
| 👥 Sample Employees | 8 Employees across 5 Departments |

---

## 🗂️ Database Schema

```
HR_System
│
├── 👥 Employees          ← Core table (linked to all others)
├── 🏢 Departments        ← Department info + manager FK
├── 💰 Payroll            ← Monthly salary records
├── 📅 Attendance         ← Daily check-in / check-out
├── 📋 LeaveTypes         ← Annual / Sick / Maternity ...
├── 📝 LeaveRequests      ← Employee leave applications
├── ⚖️  LeaveBalance       ← Days allocated vs. used
├── 🎓 TrainingPrograms   ← Available training courses
├── 📌 TrainingEnrollment ← Employee ↔ Program (M:N)
└── 🔐 Users              ← Login accounts + roles
```

### Entity Relationships

```
Departments  ──1:N──▶  Employees  ──1:N──▶  Payroll
                │                  ──1:N──▶  Attendance
                │                  ──1:N──▶  LeaveRequests
                │                  ──1:N──▶  LeaveBalance
                │                  ──M:N──▶  TrainingPrograms
                │                  ──1:1──▶  Users
                └──── ManagerID (self-ref FK)

LeaveTypes  ──1:N──▶  LeaveRequests
LeaveTypes  ──1:N──▶  LeaveBalance
TrainingPrograms  ──1:N──▶  TrainingEnrollment
```

---

## ✨ Features

### ✅ Employee Management
- Add, update, search, and soft-delete employee records
- Full personal and job details stored with constraints

### ✅ Attendance Tracking
- Daily check-in / check-out logging
- MERGE-based UPSERT prevents duplicate records
- Monthly attendance summaries

### ✅ Leave Management
- Leave request submission with automatic balance validation
- Manager approval / rejection workflow
- Real-time balance tracking via `PERSISTED` computed columns

### ✅ Payroll Processing
- Monthly payroll records with all allowances and deductions
- `NetSalary` auto-calculated as a `PERSISTED` computed column
- Full pay history per employee

### ✅ Training & Development
- Training program catalog with capacity control
- Employee enrollment with duplicate prevention
- Score and certificate tracking

### ✅ Role-Based Access Control
- Four roles: `Admin`, `HR`, `Manager`, `Employee`
- Enforced via `CHECK` constraint on `Users` table
- Each stored procedure validates caller's role before executing

---

## 🚀 Getting Started

### Prerequisites
- Microsoft SQL Server 2019 or 2022 *(Express edition is free)*
- [SQL Server Management Studio — SSMS](https://aka.ms/ssmsfullsetup)

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/your-username/hr-database-system.git
cd hr-database-system
```

**2. Open SSMS and connect to your SQL Server instance**

**3. Open the SQL file**
```
File → Open → File → HR_Database_MSSQL.sql
```

**4. Execute the script**
```
Press F5  (or click Execute)
```

The script will automatically:
- ✅ Create the `HR_System` database
- ✅ Create all 10 tables with constraints
- ✅ Insert sample data (8 employees, 5 departments)
- ✅ Create all 17 stored procedures

---

## ⚙️ Stored Procedures

### Employee Management

| Procedure | Description |
|-----------|-------------|
| `sp_GetAllEmployees` | Returns all active employees with department info |
| `sp_GetEmployeeByID @EmpID` | Returns full details for one employee |
| `sp_InsertEmployee @...` | Adds a new employee, returns new ID via `SCOPE_IDENTITY()` |
| `sp_UpdateEmployee @...` | Updates job details, contact info, and status |
| `sp_DeleteEmployee @EmpID` | Soft-delete: sets `Status = Terminated` |
| `sp_SearchEmployees @Keyword` | Full-text search across name, email, job, department |

### Attendance

| Procedure | Description |
|-----------|-------------|
| `sp_LogAttendance @...` | UPSERT daily attendance using T-SQL `MERGE` |
| `sp_RecordCheckOut @...` | Records employee check-out time |
| `sp_GetAttendanceByMonth @...` | Retrieves attendance by employee / year / month |

### Leave Management

| Procedure | Description |
|-----------|-------------|
| `sp_SubmitLeaveRequest @...` | Validates balance then submits request |
| `sp_ProcessLeaveRequest @...` | Approves or rejects, updates balance automatically |
| `sp_GetLeaveBalance @EmpID, @Year` | Returns remaining days per leave type |

### Payroll

| Procedure | Description |
|-----------|-------------|
| `sp_InsertPayroll @...` | Records monthly payroll entry |
| `sp_GetPayHistory @EmpID` | Returns full pay history, newest first |

### Training

| Procedure | Description |
|-----------|-------------|
| `sp_EnrollTraining @EmpID, @ProgramID` | Enrolls employee, checks capacity |
| `sp_CompleteTraining @...` | Marks completed, stores score and certificate |

---

## 📊 Reports

| Procedure | Output |
|-----------|--------|
| `rpt_EmployeeMasterList` | All active employees with years of service |
| `rpt_AttendanceSummary @Year, @Month` | Monthly attendance counts per employee |
| `rpt_PayrollSummary @PayPeriod` | Payroll with allowances, deductions, net salary |
| `rpt_LeaveBalanceReport @Year` | Leave balance per employee per type |
| `rpt_TrainingReport` | Enrollment status, scores, Pass/Fail results |

### Example Calls

```sql
-- Employee master list
EXEC rpt_EmployeeMasterList;

-- January 2024 attendance
EXEC rpt_AttendanceSummary @Year = 2024, @Month = 1;

-- January 2024 payroll
EXEC rpt_PayrollSummary @PayPeriod = '2024-01-01';

-- Leave balances for 2024
EXEC rpt_LeaveBalanceReport @Year = 2024;

-- Training report
EXEC rpt_TrainingReport;
```

---

## 🔐 Role-Based Access

| Role | Add/Edit Employees | Approve Leave | View Payroll | Submit Leave | Enroll Training |
|------|:-----------------:|:-------------:|:------------:|:------------:|:---------------:|
| **Admin** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HR** | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Manager** | ❌ | ✅ | ❌ | ✅ | ✅ |
| **Employee** | ❌ | ❌ | ❌ | ✅ | ✅ |

Roles are enforced in two ways:
1. **CHECK constraint** on `Users.Role` column — prevents invalid role values
2. **Stored procedure validation** — each procedure checks `@CallerUserID` role before executing

```sql
-- Example: only Admin or HR can add employees
EXEC sp_InsertEmployeeSecure
    @CallerUserID = 1,        -- Must be Admin or HR
    @FirstName    = N'Layla',
    @LastName     = N'Nasser',
    ...
```

---

## 🗃️ Sample Data

| # | Name | Department | Role |
|---|------|-----------|------|
| 1 | Ahmed Hassan | Human Resources | HR Manager |
| 2 | Sara Mohamed | Human Resources | HR Specialist |
| 3 | Khaled Ali | Information Technology | IT Manager |
| 4 | Nour Ibrahim | Information Technology | Software Developer |
| 5 | Omar Saeed | Finance | Finance Manager |
| 6 | Fatma Youssef | Finance | Accountant |
| 7 | Mostafa Kamel | Operations | Operations Lead |
| 8 | Rana Hamdy | Marketing | Marketing Specialist |

---

## 📁 Project Files

```
hr-database-system/
│
├── 📄 HR_Database_MSSQL.sql        ← Main SQL script (run this)
├── 📄 HR_Database_Project_MSSQL.docx  ← Full project documentation
├── 🌐 HR_ERD_Diagram.html          ← Interactive ERD diagram
└── 📄 README.md                    ← This file
```

---

## 🔑 Key T-SQL Features Used

| Feature | Usage |
|---------|-------|
| `IDENTITY(1,1)` | Auto-increment primary keys |
| `NVARCHAR` | Unicode string support (Arabic text) |
| `AS (...) PERSISTED` | Computed columns: NetSalary, TotalDays, Remaining |
| `MERGE ... USING` | UPSERT for attendance logging |
| `SCOPE_IDENTITY()` | Returns last inserted ID |
| `CHECK` constraints | Replaces MySQL ENUM type |
| `BIT` | Replaces MySQL BOOLEAN |
| `DATETIME2` | High-precision datetime |
| `NVARCHAR(MAX)` | Replaces MySQL TEXT |
| `GO` | Batch separator in SSMS |

---

## 👨‍💻 Author
[hatem_dotnet](https://github.com/hatem-dotnet/HR_Database_Project_MSSQL/commits?author=hatem-dotnet)


---

> 💡 **Tip:** Open `HR_ERD_Diagram.html` in your browser to view the full interactive Entity Relationship Diagram.
