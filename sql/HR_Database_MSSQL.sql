-- ============================================================
--  HR Employee Database System
--  Microsoft SQL Server (T-SQL) Version
--  Complete Script: Tables + Stored Procedures + Sample Data
-- ============================================================

-- Create and use the database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'HR_System_upd')
    CREATE DATABASE HR_System_upd;
GO

USE HR_System_upd;
GO

-- ============================================================
--  SECTION 1: DROP EXISTING OBJECTS (for re-run safety)
-- ============================================================

-- Drop stored procedures if they exist
IF OBJECT_ID('rpt_TrainingReport',         'P') IS NOT NULL DROP PROCEDURE rpt_TrainingReport;
IF OBJECT_ID('rpt_LeaveBalanceReport',      'P') IS NOT NULL DROP PROCEDURE rpt_LeaveBalanceReport;
IF OBJECT_ID('rpt_PayrollSummary',          'P') IS NOT NULL DROP PROCEDURE rpt_PayrollSummary;
IF OBJECT_ID('rpt_AttendanceSummary',       'P') IS NOT NULL DROP PROCEDURE rpt_AttendanceSummary;
IF OBJECT_ID('rpt_EmployeeMasterList',      'P') IS NOT NULL DROP PROCEDURE rpt_EmployeeMasterList;
IF OBJECT_ID('sp_CompleteTraining',         'P') IS NOT NULL DROP PROCEDURE sp_CompleteTraining;
IF OBJECT_ID('sp_EnrollTraining',           'P') IS NOT NULL DROP PROCEDURE sp_EnrollTraining;
IF OBJECT_ID('sp_GetPayHistory',            'P') IS NOT NULL DROP PROCEDURE sp_GetPayHistory;
IF OBJECT_ID('sp_InsertPayroll',            'P') IS NOT NULL DROP PROCEDURE sp_InsertPayroll;
IF OBJECT_ID('sp_GetLeaveBalance',          'P') IS NOT NULL DROP PROCEDURE sp_GetLeaveBalance;
IF OBJECT_ID('sp_ProcessLeaveRequest',      'P') IS NOT NULL DROP PROCEDURE sp_ProcessLeaveRequest;
IF OBJECT_ID('sp_SubmitLeaveRequest',       'P') IS NOT NULL DROP PROCEDURE sp_SubmitLeaveRequest;
IF OBJECT_ID('sp_GetAttendanceByMonth',     'P') IS NOT NULL DROP PROCEDURE sp_GetAttendanceByMonth;
IF OBJECT_ID('sp_RecordCheckOut',           'P') IS NOT NULL DROP PROCEDURE sp_RecordCheckOut;
IF OBJECT_ID('sp_LogAttendance',            'P') IS NOT NULL DROP PROCEDURE sp_LogAttendance;
IF OBJECT_ID('sp_SearchEmployees',          'P') IS NOT NULL DROP PROCEDURE sp_SearchEmployees;
IF OBJECT_ID('sp_DeleteEmployee',           'P') IS NOT NULL DROP PROCEDURE sp_DeleteEmployee;
IF OBJECT_ID('sp_UpdateEmployee',           'P') IS NOT NULL DROP PROCEDURE sp_UpdateEmployee;
IF OBJECT_ID('sp_InsertEmployee',           'P') IS NOT NULL DROP PROCEDURE sp_InsertEmployee;
IF OBJECT_ID('sp_GetEmployeeByID',          'P') IS NOT NULL DROP PROCEDURE sp_GetEmployeeByID;
IF OBJECT_ID('sp_GetAllEmployees',          'P') IS NOT NULL DROP PROCEDURE sp_GetAllEmployees;
GO

-- Drop tables in correct FK order
IF OBJECT_ID('Users',               'U') IS NOT NULL DROP TABLE Users;
IF OBJECT_ID('TrainingEnrollment',  'U') IS NOT NULL DROP TABLE TrainingEnrollment;
IF OBJECT_ID('TrainingPrograms',    'U') IS NOT NULL DROP TABLE TrainingPrograms;
IF OBJECT_ID('LeaveBalance',        'U') IS NOT NULL DROP TABLE LeaveBalance;
IF OBJECT_ID('LeaveRequests',       'U') IS NOT NULL DROP TABLE LeaveRequests;
IF OBJECT_ID('LeaveTypes',          'U') IS NOT NULL DROP TABLE LeaveTypes;
IF OBJECT_ID('Attendance',          'U') IS NOT NULL DROP TABLE Attendance;
IF OBJECT_ID('Payroll',             'U') IS NOT NULL DROP TABLE Payroll;
-- Drop FK on Departments.ManagerID before dropping Employees
IF OBJECT_ID('FK_Dept_Manager', 'F') IS NOT NULL
    ALTER TABLE Departments DROP CONSTRAINT FK_Dept_Manager;
IF OBJECT_ID('Employees',           'U') IS NOT NULL DROP TABLE Employees;
IF OBJECT_ID('Departments',         'U') IS NOT NULL DROP TABLE Departments;
GO

-- ============================================================
--  SECTION 2: TABLE DEFINITIONS
-- ============================================================

-- Departments
CREATE TABLE Departments (
    DeptID      INT IDENTITY(1,1) PRIMARY KEY,
    DeptName    NVARCHAR(100) NOT NULL,
    ManagerID   INT NULL,                      -- FK added after Employees
    Location    NVARCHAR(100) NULL,
    CreatedAt   DATETIME2 DEFAULT GETDATE()
);
GO

-- Employees
CREATE TABLE Employees (
    EmpID           INT IDENTITY(1,1) PRIMARY KEY,
    FirstName       NVARCHAR(50)  NOT NULL,
    LastName        NVARCHAR(50)  NOT NULL,
    NationalID      NVARCHAR(20)  NOT NULL UNIQUE,
    BirthDate       DATE          NULL,
    Gender          NVARCHAR(10)  NULL CHECK (Gender IN ('Male','Female','Other')),
    Email           NVARCHAR(100) NULL UNIQUE,
    Phone           NVARCHAR(20)  NULL,
    Address         NVARCHAR(255) NULL,
    HireDate        DATE          NOT NULL,
    JobTitle        NVARCHAR(100) NULL,
    DeptID          INT           NULL,
    GradeLevel      NVARCHAR(10)  NULL,
    EmploymentType  NVARCHAR(20)  NOT NULL DEFAULT 'Full-Time'
                        CHECK (EmploymentType IN ('Full-Time','Part-Time','Contract')),
    Status          NVARCHAR(20)  NOT NULL DEFAULT 'Active'
                        CHECK (Status IN ('Active','Inactive','Terminated')),
    CONSTRAINT FK_Emp_Dept FOREIGN KEY (DeptID) REFERENCES Departments(DeptID)
);
GO

-- Add ManagerID FK now that Employees exists
ALTER TABLE Departments
    ADD CONSTRAINT FK_Dept_Manager
    FOREIGN KEY (ManagerID) REFERENCES Employees(EmpID);
GO

-- Payroll
CREATE TABLE Payroll (
    PayrollID       INT IDENTITY(1,1) PRIMARY KEY,
    EmpID           INT            NOT NULL,
    PayPeriod       DATE           NOT NULL,   -- First day of pay month
    BasicSalary     DECIMAL(10,2)  NOT NULL,
    HousingAllow    DECIMAL(10,2)  NOT NULL DEFAULT 0,
    TransportAllow  DECIMAL(10,2)  NOT NULL DEFAULT 0,
    OtherAllow      DECIMAL(10,2)  NOT NULL DEFAULT 0,
    TaxDeduction    DECIMAL(10,2)  NOT NULL DEFAULT 0,
    InsuranceDed    DECIMAL(10,2)  NOT NULL DEFAULT 0,
    OtherDeduct     DECIMAL(10,2)  NOT NULL DEFAULT 0,
    NetSalary AS (BasicSalary + HousingAllow + TransportAllow + OtherAllow
                  - TaxDeduction - InsuranceDed - OtherDeduct) PERSISTED,
    ProcessedDate   DATETIME2      DEFAULT GETDATE(),
    CONSTRAINT FK_Payroll_Emp FOREIGN KEY (EmpID) REFERENCES Employees(EmpID)
);
GO

-- Attendance
CREATE TABLE Attendance (
    AttendID    INT IDENTITY(1,1) PRIMARY KEY,
    EmpID       INT         NOT NULL,
    AttDate     DATE        NOT NULL,
    CheckIn     TIME        NULL,
    CheckOut    TIME        NULL,
    Status      NVARCHAR(20) NOT NULL DEFAULT 'Present'
                    CHECK (Status IN ('Present','Absent','Late','Half-Day','Holiday')),
    Notes       NVARCHAR(255) NULL,
    CONSTRAINT UQ_Att_EmpDate UNIQUE (EmpID, AttDate),
    CONSTRAINT FK_Att_Emp FOREIGN KEY (EmpID) REFERENCES Employees(EmpID)
);
GO

-- Leave Types
CREATE TABLE LeaveTypes (
    LeaveTypeID    INT IDENTITY(1,1) PRIMARY KEY,
    TypeName       NVARCHAR(50) NOT NULL,
    MaxDaysPerYear INT          NOT NULL DEFAULT 0,
    IsPaid         BIT          NOT NULL DEFAULT 1
);
GO

-- Leave Requests
CREATE TABLE LeaveRequests (
    LeaveID      INT IDENTITY(1,1) PRIMARY KEY,
    EmpID        INT          NOT NULL,
    LeaveTypeID  INT          NOT NULL,
    StartDate    DATE         NOT NULL,
    EndDate      DATE         NOT NULL,
    TotalDays    AS (DATEDIFF(DAY, StartDate, EndDate) + 1) PERSISTED,
    Reason       NVARCHAR(500) NULL,
    Status       NVARCHAR(20)  NOT NULL DEFAULT 'Pending'
                     CHECK (Status IN ('Pending','Approved','Rejected')),
    ApprovedBy   INT          NULL,
    RequestDate  DATETIME2    DEFAULT GETDATE(),
    CONSTRAINT FK_Leave_Emp      FOREIGN KEY (EmpID)       REFERENCES Employees(EmpID),
    CONSTRAINT FK_Leave_Type     FOREIGN KEY (LeaveTypeID) REFERENCES LeaveTypes(LeaveTypeID),
    CONSTRAINT FK_Leave_Approver FOREIGN KEY (ApprovedBy)  REFERENCES Employees(EmpID)
);
GO

-- Leave Balance
CREATE TABLE LeaveBalance (
    BalanceID      INT IDENTITY(1,1) PRIMARY KEY,
    EmpID          INT NOT NULL,
    LeaveTypeID    INT NOT NULL,
    Year           INT NOT NULL,
    TotalAllocated INT NOT NULL DEFAULT 0,
    TotalUsed      INT NOT NULL DEFAULT 0,
    Remaining      AS (TotalAllocated - TotalUsed) PERSISTED,
    CONSTRAINT UQ_Balance UNIQUE (EmpID, LeaveTypeID, Year),
    CONSTRAINT FK_Bal_Emp   FOREIGN KEY (EmpID)       REFERENCES Employees(EmpID),
    CONSTRAINT FK_Bal_Type  FOREIGN KEY (LeaveTypeID) REFERENCES LeaveTypes(LeaveTypeID)
);
GO

-- Training Programs
CREATE TABLE TrainingPrograms (
    ProgramID    INT IDENTITY(1,1) PRIMARY KEY,
    ProgramName  NVARCHAR(150) NOT NULL,
    Description  NVARCHAR(MAX) NULL,
    StartDate    DATE          NULL,
    EndDate      DATE          NULL,
    Location     NVARCHAR(100) NULL,
    Trainer      NVARCHAR(100) NULL,
    MaxCapacity  INT           NULL
);
GO

-- Training Enrollment
CREATE TABLE TrainingEnrollment (
    EnrollID    INT IDENTITY(1,1) PRIMARY KEY,
    EmpID       INT           NOT NULL,
    ProgramID   INT           NOT NULL,
    EnrollDate  DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status      NVARCHAR(20)  NOT NULL DEFAULT 'Enrolled'
                    CHECK (Status IN ('Enrolled','Completed','Cancelled')),
    Score       DECIMAL(5,2)  NULL,
    Certificate NVARCHAR(255) NULL,
    CONSTRAINT UQ_Enroll UNIQUE (EmpID, ProgramID),
    CONSTRAINT FK_Enroll_Emp     FOREIGN KEY (EmpID)      REFERENCES Employees(EmpID),
    CONSTRAINT FK_Enroll_Program FOREIGN KEY (ProgramID)  REFERENCES TrainingPrograms(ProgramID)
);
GO

-- Users (Role-Based Access Control)
CREATE TABLE Users (
    UserID       INT IDENTITY(1,1) PRIMARY KEY,
    EmpID        INT           NOT NULL UNIQUE,
    Username     NVARCHAR(50)  NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role         NVARCHAR(20)  NOT NULL DEFAULT 'Employee'
                     CHECK (Role IN ('Admin','HR','Manager','Employee')),
    IsActive     BIT           NOT NULL DEFAULT 1,
    LastLogin    DATETIME2     NULL,
    CONSTRAINT FK_User_Emp FOREIGN KEY (EmpID) REFERENCES Employees(EmpID)
);
GO

-- ============================================================
--  SECTION 3: SAMPLE DATA
-- ============================================================

INSERT INTO Departments (DeptName, Location) VALUES
(N'Human Resources',        N'Floor 1'),
(N'Information Technology', N'Floor 2'),
(N'Finance',                N'Floor 3'),
(N'Operations',             N'Floor 4'),
(N'Marketing',              N'Floor 5');
GO

SET IDENTITY_INSERT Employees ON;
INSERT INTO Employees (EmpID,FirstName,LastName,NationalID,BirthDate,Gender,Email,Phone,Address,HireDate,JobTitle,DeptID,GradeLevel,EmploymentType,Status) VALUES
(1,N'Ahmed',  N'Hassan',  N'EG-001-2001','1990-03-15',N'Male',  N'ahmed.hassan@company.com', N'01001234567',N'Cairo, Egypt',      '2018-01-10',N'HR Manager',          1,N'G5',N'Full-Time',N'Active'),
(2,N'Sara',   N'Mohamed', N'EG-002-2002','1992-07-22',N'Female',N'sara.mohamed@company.com', N'01012345678',N'Giza, Egypt',       '2019-03-15',N'HR Specialist',       1,N'G3',N'Full-Time',N'Active'),
(3,N'Khaled', N'Ali',     N'EG-003-2003','1988-11-05',N'Male',  N'khaled.ali@company.com',   N'01023456789',N'Alexandria, Egypt', '2017-06-01',N'IT Manager',          2,N'G5',N'Full-Time',N'Active'),
(4,N'Nour',   N'Ibrahim', N'EG-004-2004','1995-01-30',N'Female',N'nour.ibrahim@company.com', N'01034567890',N'Cairo, Egypt',      '2020-09-01',N'Software Developer',  2,N'G3',N'Full-Time',N'Active'),
(5,N'Omar',   N'Saeed',   N'EG-005-2005','1985-05-18',N'Male',  N'omar.saeed@company.com',   N'01045678901',N'Suez, Egypt',       '2015-04-20',N'Finance Manager',     3,N'G5',N'Full-Time',N'Active'),
(6,N'Fatma',  N'Youssef', N'EG-006-2006','1993-09-12',N'Female',N'fatma.youssef@company.com',N'01056789012',N'Cairo, Egypt',      '2021-01-05',N'Accountant',          3,N'G2',N'Full-Time',N'Active'),
(7,N'Mostafa',N'Kamel',   N'EG-007-2007','1991-04-25',N'Male',  N'mostafa.kamel@company.com',N'01067890123',N'Giza, Egypt',       '2019-11-15',N'Operations Lead',     4,N'G4',N'Full-Time',N'Active'),
(8,N'Rana',   N'Hamdy',   N'EG-008-2008','1996-08-08',N'Female',N'rana.hamdy@company.com',   N'01078901234',N'Cairo, Egypt',      '2022-03-01',N'Marketing Specialist',5,N'G2',N'Part-Time',N'Active');
SET IDENTITY_INSERT Employees OFF;
GO

-- Set department managers
UPDATE Departments SET ManagerID = 1 WHERE DeptID = 1;
UPDATE Departments SET ManagerID = 3 WHERE DeptID = 2;
UPDATE Departments SET ManagerID = 5 WHERE DeptID = 3;
UPDATE Departments SET ManagerID = 7 WHERE DeptID = 4;
UPDATE Departments SET ManagerID = 8 WHERE DeptID = 5;
GO

INSERT INTO LeaveTypes (TypeName, MaxDaysPerYear, IsPaid) VALUES
(N'Annual Leave',    21, 1),
(N'Sick Leave',      15, 1),
(N'Maternity Leave', 90, 1),
(N'Unpaid Leave',    30, 0),
(N'Emergency Leave',  3, 1);
GO

INSERT INTO LeaveBalance (EmpID, LeaveTypeID, Year, TotalAllocated, TotalUsed) VALUES
(1,1,2024,21,5),(1,2,2024,15,2),
(2,1,2024,21,8),(2,2,2024,15,0),
(3,1,2024,21,3),(3,2,2024,15,1),
(4,1,2024,21,10),(4,2,2024,15,3),
(5,1,2024,21,7),(5,2,2024,15,0),
(6,1,2024,21,2),(6,2,2024,15,5),
(7,1,2024,21,4),(7,2,2024,15,2),
(8,1,2024,21,6),(8,2,2024,15,1);
GO

INSERT INTO Payroll (EmpID,PayPeriod,BasicSalary,HousingAllow,TransportAllow,OtherAllow,TaxDeduction,InsuranceDed) VALUES
(1,'2024-01-01',15000,3000,500,0,1500,750),
(2,'2024-01-01',8000, 1500,500,0,800, 400),
(3,'2024-01-01',18000,3500,500,0,1800,900),
(4,'2024-01-01',10000,2000,500,0,1000,500),
(5,'2024-01-01',20000,4000,500,0,2000,1000),
(6,'2024-01-01',7000, 1500,500,0,700, 350),
(7,'2024-01-01',14000,2500,500,0,1400,700),
(8,'2024-01-01',6000, 1000,500,0,600, 300),
(1,'2024-02-01',15000,3000,500,0,1500,750),
(2,'2024-02-01',8000, 1500,500,0,800, 400),
(3,'2024-02-01',18000,3500,500,0,1800,900);
GO

INSERT INTO Attendance (EmpID,AttDate,CheckIn,CheckOut,Status) VALUES
(1,'2024-01-15','09:00','17:00',N'Present'),
(2,'2024-01-15','09:10','17:05',N'Present'),
(3,'2024-01-15','08:55','17:00',N'Present'),
(4,'2024-01-15','09:30','17:00',N'Late'),
(5,'2024-01-15','09:00','17:00',N'Present'),
(6,'2024-01-15',NULL,  NULL,   N'Absent'),
(7,'2024-01-15','09:00','17:00',N'Present'),
(8,'2024-01-15','09:00','13:00',N'Half-Day'),
(1,'2024-01-16','09:00','17:00',N'Present'),
(2,'2024-01-16','09:05','17:00',N'Present');
GO

INSERT INTO LeaveRequests (EmpID,LeaveTypeID,StartDate,EndDate,Reason,Status,ApprovedBy) VALUES
(2,1,'2024-02-05','2024-02-09',N'Family vacation', N'Approved',1),
(4,2,'2024-02-12','2024-02-14',N'Medical treatment',N'Approved',3),
(6,2,'2024-01-20','2024-01-25',N'Illness',         N'Approved',5),
(8,1,'2024-03-01','2024-03-05',N'Personal leave',  N'Pending', NULL);
GO

INSERT INTO TrainingPrograms (ProgramName,Description,StartDate,EndDate,Location,Trainer,MaxCapacity) VALUES
(N'SQL & Database Fundamentals',N'Introduction to relational databases and SQL',  '2024-03-01','2024-03-03',N'Training Room A',N'Dr. Mohamed Fawzy', 20),
(N'Leadership Development',     N'Management and leadership skills for team leads','2024-04-10','2024-04-12',N'Training Room B',N'Ms. Layla Adel',    15),
(N'HR Best Practices',          N'Modern HR methodologies and compliance',         '2024-05-05','2024-05-06',N'Training Room A',N'Mr. Sameh Nour',    25),
(N'Cybersecurity Awareness',    N'Data protection and security practices',         '2024-06-01','2024-06-01',N'Online',         N'IT Security Team',  50);
GO

INSERT INTO TrainingEnrollment (EmpID,ProgramID,EnrollDate,Status,Score) VALUES
(1,3,'2024-04-20',N'Completed',92.5),
(2,3,'2024-04-20',N'Completed',88.0),
(3,1,'2024-02-15',N'Completed',95.0),
(4,1,'2024-02-15',N'Completed',87.5),
(5,2,'2024-03-25',N'Completed',90.0),
(7,2,'2024-03-25',N'Completed',85.0),
(1,4,'2024-05-28',N'Enrolled', NULL),
(2,4,'2024-05-28',N'Enrolled', NULL),
(3,4,'2024-05-28',N'Enrolled', NULL);
GO

INSERT INTO Users (EmpID,Username,PasswordHash,Role) VALUES
(1,N'ahmed.hr', N'$2b$12$hashedpassword1',N'HR'),
(2,N'sara.hr',  N'$2b$12$hashedpassword2',N'HR'),
(3,N'khaled.it',N'$2b$12$hashedpassword3',N'Manager'),
(5,N'omar.fin', N'$2b$12$hashedpassword5',N'Manager');
GO

-- ============================================================
--  SECTION 4: STORED PROCEDURES
-- ============================================================

-- -------------------------------------------------------
--  EMPLOYEES: GET ALL
-- -------------------------------------------------------
CREATE PROCEDURE sp_GetAllEmployees
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  e.EmpID,
            e.FirstName,
            e.LastName,
            e.NationalID,
            e.Email,
            e.Phone,
            e.JobTitle,
            d.DeptName,
            e.GradeLevel,
            e.HireDate,
            e.EmploymentType,
            e.Status
    FROM    Employees e
    LEFT JOIN Departments d ON e.DeptID = d.DeptID
    ORDER BY e.EmpID;
END;
GO

-- -------------------------------------------------------
--  EMPLOYEES: GET BY ID
-- -------------------------------------------------------
CREATE PROCEDURE sp_GetEmployeeByID
    @EmpID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  e.*,
            d.DeptName
    FROM    Employees e
    LEFT JOIN Departments d ON e.DeptID = d.DeptID
    WHERE   e.EmpID = @EmpID;
END;
GO

-- -------------------------------------------------------
--  EMPLOYEES: INSERT
-- -------------------------------------------------------
CREATE PROCEDURE sp_InsertEmployee
    @FirstName      NVARCHAR(50),
    @LastName       NVARCHAR(50),
    @NationalID     NVARCHAR(20),
    @BirthDate      DATE,
    @Gender         NVARCHAR(10),
    @Email          NVARCHAR(100),
    @Phone          NVARCHAR(20),
    @Address        NVARCHAR(255),
    @HireDate       DATE,
    @JobTitle       NVARCHAR(100),
    @DeptID         INT,
    @GradeLevel     NVARCHAR(10),
    @EmploymentType NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Employees
        (FirstName, LastName, NationalID, BirthDate, Gender, Email, Phone,
         Address, HireDate, JobTitle, DeptID, GradeLevel, EmploymentType)
    VALUES
        (@FirstName, @LastName, @NationalID, @BirthDate, @Gender, @Email, @Phone,
         @Address, @HireDate, @JobTitle, @DeptID, @GradeLevel, @EmploymentType);

    SELECT SCOPE_IDENTITY() AS NewEmpID;
END;
GO

-- -------------------------------------------------------
--  EMPLOYEES: UPDATE
-- -------------------------------------------------------
CREATE PROCEDURE sp_UpdateEmployee
    @EmpID          INT,
    @JobTitle       NVARCHAR(100),
    @DeptID         INT,
    @GradeLevel     NVARCHAR(10),
    @Email          NVARCHAR(100),
    @Phone          NVARCHAR(20),
    @Address        NVARCHAR(255),
    @Status         NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Employees
    SET    JobTitle    = @JobTitle,
           DeptID      = @DeptID,
           GradeLevel  = @GradeLevel,
           Email       = @Email,
           Phone       = @Phone,
           Address     = @Address,
           Status      = @Status
    WHERE  EmpID = @EmpID;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

-- -------------------------------------------------------
--  EMPLOYEES: SOFT DELETE (mark as Terminated)
-- -------------------------------------------------------
CREATE PROCEDURE sp_DeleteEmployee
    @EmpID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Employees
    SET    Status = N'Terminated'
    WHERE  EmpID = @EmpID;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

-- -------------------------------------------------------
--  EMPLOYEES: SEARCH
-- -------------------------------------------------------
CREATE PROCEDURE sp_SearchEmployees
    @Keyword NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  e.EmpID,
            e.FirstName,
            e.LastName,
            e.Email,
            e.JobTitle,
            d.DeptName,
            e.Status
    FROM    Employees e
    LEFT JOIN Departments d ON e.DeptID = d.DeptID
    WHERE   e.FirstName LIKE N'%' + @Keyword + N'%'
       OR   e.LastName  LIKE N'%' + @Keyword + N'%'
       OR   e.Email     LIKE N'%' + @Keyword + N'%'
       OR   e.JobTitle  LIKE N'%' + @Keyword + N'%'
       OR   d.DeptName  LIKE N'%' + @Keyword + N'%';
END;
GO

-- -------------------------------------------------------
--  ATTENDANCE: LOG (UPSERT using MERGE)
-- -------------------------------------------------------
CREATE PROCEDURE sp_LogAttendance
    @EmpID   INT,
    @AttDate DATE,
    @CheckIn TIME,
    @Status  NVARCHAR(20),
    @Notes   NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    MERGE Attendance AS target
    USING (SELECT @EmpID AS EmpID, @AttDate AS AttDate) AS source
    ON (target.EmpID = source.EmpID AND target.AttDate = source.AttDate)
    WHEN MATCHED THEN
        UPDATE SET CheckIn = @CheckIn, Status = @Status, Notes = @Notes
    WHEN NOT MATCHED THEN
        INSERT (EmpID, AttDate, CheckIn, Status, Notes)
        VALUES (@EmpID, @AttDate, @CheckIn, @Status, @Notes);
END;
GO

-- -------------------------------------------------------
--  ATTENDANCE: RECORD CHECKOUT
-- -------------------------------------------------------
CREATE PROCEDURE sp_RecordCheckOut
    @EmpID    INT,
    @AttDate  DATE,
    @CheckOut TIME
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Attendance
    SET    CheckOut = @CheckOut
    WHERE  EmpID = @EmpID AND AttDate = @AttDate;
END;
GO

-- -------------------------------------------------------
--  ATTENDANCE: GET BY EMPLOYEE AND MONTH
-- -------------------------------------------------------
CREATE PROCEDURE sp_GetAttendanceByMonth
    @EmpID INT,
    @Year  INT,
    @Month INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  AttDate,
            CheckIn,
            CheckOut,
            Status,
            Notes
    FROM    Attendance
    WHERE   EmpID    = @EmpID
      AND   YEAR(AttDate)  = @Year
      AND   MONTH(AttDate) = @Month
    ORDER BY AttDate;
END;
GO

-- -------------------------------------------------------
--  LEAVE: SUBMIT REQUEST
-- -------------------------------------------------------
CREATE PROCEDURE sp_SubmitLeaveRequest
    @EmpID       INT,
    @LeaveTypeID INT,
    @StartDate   DATE,
    @EndDate     DATE,
    @Reason      NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Available  INT = 0;
    DECLARE @Requested  INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;
    DECLARE @Year       INT = YEAR(@StartDate);

    SELECT @Available = Remaining
    FROM   LeaveBalance
    WHERE  EmpID = @EmpID
      AND  LeaveTypeID = @LeaveTypeID
      AND  Year = @Year;

    IF @Available >= @Requested
    BEGIN
        INSERT INTO LeaveRequests (EmpID, LeaveTypeID, StartDate, EndDate, Reason)
        VALUES (@EmpID, @LeaveTypeID, @StartDate, @EndDate, @Reason);

        SELECT N'Success'            AS Result,
               SCOPE_IDENTITY()      AS LeaveID,
               @Available            AS BalanceBefore,
               @Available-@Requested AS BalanceAfterApproval;
    END
    ELSE
    BEGIN
        SELECT N'Insufficient leave balance' AS Result,
               @Available                   AS AvailableDays,
               @Requested                   AS RequestedDays;
    END;
END;
GO

-- -------------------------------------------------------
--  LEAVE: APPROVE OR REJECT
-- -------------------------------------------------------
CREATE PROCEDURE sp_ProcessLeaveRequest
    @LeaveID    INT,
    @ApproverID INT,
    @Decision   NVARCHAR(20)   -- 'Approved' or 'Rejected'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmpID       INT;
    DECLARE @LeaveTypeID INT;
    DECLARE @TotalDays   INT;
    DECLARE @Year        INT;

    SELECT  @EmpID       = EmpID,
            @LeaveTypeID = LeaveTypeID,
            @TotalDays   = TotalDays,
            @Year        = YEAR(StartDate)
    FROM    LeaveRequests
    WHERE   LeaveID = @LeaveID
      AND   Status  = N'Pending';

    IF @EmpID IS NOT NULL
    BEGIN
        UPDATE LeaveRequests
        SET    Status     = @Decision,
               ApprovedBy = @ApproverID
        WHERE  LeaveID = @LeaveID;

        IF @Decision = N'Approved'
        BEGIN
            UPDATE LeaveBalance
            SET    TotalUsed = TotalUsed + @TotalDays
            WHERE  EmpID       = @EmpID
              AND  LeaveTypeID = @LeaveTypeID
              AND  Year        = @Year;
        END;

        SELECT N'Leave request ' + @Decision AS Result;
    END
    ELSE
    BEGIN
        SELECT N'Leave request not found or already processed' AS Result;
    END;
END;
GO

-- -------------------------------------------------------
--  LEAVE: GET BALANCE FOR EMPLOYEE
-- -------------------------------------------------------
CREATE PROCEDURE sp_GetLeaveBalance
    @EmpID INT,
    @Year  INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  lt.TypeName,
            lb.TotalAllocated,
            lb.TotalUsed,
            lb.Remaining
    FROM    LeaveBalance lb
    JOIN    LeaveTypes   lt ON lb.LeaveTypeID = lt.LeaveTypeID
    WHERE   lb.EmpID = @EmpID
      AND   lb.Year  = @Year;
END;
GO

-- -------------------------------------------------------
--  PAYROLL: INSERT MONTHLY RECORD
-- -------------------------------------------------------
CREATE PROCEDURE sp_InsertPayroll
    @EmpID          INT,
    @PayPeriod      DATE,
    @BasicSalary    DECIMAL(10,2),
    @HousingAllow   DECIMAL(10,2),
    @TransportAllow DECIMAL(10,2),
    @OtherAllow     DECIMAL(10,2),
    @TaxDeduction   DECIMAL(10,2),
    @InsuranceDed   DECIMAL(10,2),
    @OtherDeduct    DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Payroll
        (EmpID, PayPeriod, BasicSalary, HousingAllow, TransportAllow,
         OtherAllow, TaxDeduction, InsuranceDed, OtherDeduct)
    VALUES
        (@EmpID, @PayPeriod, @BasicSalary, @HousingAllow, @TransportAllow,
         @OtherAllow, @TaxDeduction, @InsuranceDed, @OtherDeduct);

    SELECT SCOPE_IDENTITY() AS PayrollID;
END;
GO

-- -------------------------------------------------------
--  PAYROLL: GET PAY HISTORY
-- -------------------------------------------------------
CREATE PROCEDURE sp_GetPayHistory
    @EmpID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  PayPeriod,
            BasicSalary,
            HousingAllow + TransportAllow + OtherAllow  AS TotalAllowances,
            TaxDeduction + InsuranceDed   + OtherDeduct AS TotalDeductions,
            NetSalary,
            ProcessedDate
    FROM    Payroll
    WHERE   EmpID = @EmpID
    ORDER BY PayPeriod DESC;
END;
GO

-- -------------------------------------------------------
--  TRAINING: ENROLL EMPLOYEE
-- -------------------------------------------------------
CREATE PROCEDURE sp_EnrollTraining
    @EmpID     INT,
    @ProgramID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Capacity INT;
    DECLARE @Enrolled INT;

    SELECT @Capacity = MaxCapacity FROM TrainingPrograms WHERE ProgramID = @ProgramID;
    SELECT @Enrolled = COUNT(*)    FROM TrainingEnrollment
    WHERE  ProgramID = @ProgramID AND Status != N'Cancelled';

    IF @Enrolled < @Capacity
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM TrainingEnrollment
            WHERE EmpID = @EmpID AND ProgramID = @ProgramID)
        BEGIN
            INSERT INTO TrainingEnrollment (EmpID, ProgramID, EnrollDate, Status)
            VALUES (@EmpID, @ProgramID, CAST(GETDATE() AS DATE), N'Enrolled');
            SELECT N'Enrolled successfully' AS Result;
        END
        ELSE
            SELECT N'Employee already enrolled' AS Result;
    END
    ELSE
        SELECT N'Training program is at full capacity' AS Result;
END;
GO

-- -------------------------------------------------------
--  TRAINING: COMPLETE WITH SCORE
-- -------------------------------------------------------
CREATE PROCEDURE sp_CompleteTraining
    @EmpID       INT,
    @ProgramID   INT,
    @Score       DECIMAL(5,2),
    @Certificate NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE TrainingEnrollment
    SET    Status      = N'Completed',
           Score       = @Score,
           Certificate = @Certificate
    WHERE  EmpID = @EmpID AND ProgramID = @ProgramID;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

-- ============================================================
--  SECTION 5: REPORT STORED PROCEDURES
-- ============================================================

-- -------------------------------------------------------
--  REPORT: Employee Master List
-- -------------------------------------------------------
CREATE PROCEDURE rpt_EmployeeMasterList
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  e.EmpID,
            e.FirstName + N' ' + e.LastName     AS FullName,
            e.NationalID,
            e.Email,
            e.Phone,
            e.JobTitle,
            d.DeptName,
            e.GradeLevel,
            e.HireDate,
            e.EmploymentType,
            e.Status,
            DATEDIFF(YEAR, e.HireDate, GETDATE()) AS YearsOfService
    FROM    Employees e
    LEFT JOIN Departments d ON e.DeptID = d.DeptID
    WHERE   e.Status = N'Active'
    ORDER BY d.DeptName, e.LastName;
END;
GO

-- -------------------------------------------------------
--  REPORT: Monthly Attendance Summary
-- -------------------------------------------------------
CREATE PROCEDURE rpt_AttendanceSummary
    @Year  INT,
    @Month INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  e.FirstName + N' ' + e.LastName AS FullName,
            d.DeptName,
            SUM(CASE WHEN a.Status = N'Present'  THEN 1 ELSE 0 END) AS PresentDays,
            SUM(CASE WHEN a.Status = N'Absent'   THEN 1 ELSE 0 END) AS AbsentDays,
            SUM(CASE WHEN a.Status = N'Late'     THEN 1 ELSE 0 END) AS LateDays,
            SUM(CASE WHEN a.Status = N'Half-Day' THEN 1 ELSE 0 END) AS HalfDays,
            COUNT(a.AttendID)                                        AS TotalRecorded
    FROM    Employees e
    LEFT JOIN Departments d ON e.DeptID  = d.DeptID
    LEFT JOIN Attendance  a ON e.EmpID   = a.EmpID
                           AND YEAR(a.AttDate)  = @Year
                           AND MONTH(a.AttDate) = @Month
    WHERE   e.Status = N'Active'
    GROUP BY e.EmpID, e.FirstName, e.LastName, d.DeptName
    ORDER BY d.DeptName, e.LastName;
END;
GO

-- -------------------------------------------------------
--  REPORT: Monthly Payroll Summary
-- -------------------------------------------------------
CREATE PROCEDURE rpt_PayrollSummary
    @PayPeriod DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  e.FirstName + N' ' + e.LastName              AS FullName,
            d.DeptName,
            e.JobTitle,
            p.BasicSalary,
            p.HousingAllow + p.TransportAllow + p.OtherAllow  AS TotalAllowances,
            p.TaxDeduction + p.InsuranceDed   + p.OtherDeduct AS TotalDeductions,
            p.NetSalary
    FROM    Payroll p
    JOIN    Employees   e ON p.EmpID  = e.EmpID
    LEFT JOIN Departments d ON e.DeptID = d.DeptID
    WHERE   p.PayPeriod = @PayPeriod
    ORDER BY d.DeptName, e.LastName;
END;
GO

-- -------------------------------------------------------
--  REPORT: Leave Balance Report
-- -------------------------------------------------------
CREATE PROCEDURE rpt_LeaveBalanceReport
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  e.FirstName + N' ' + e.LastName AS FullName,
            d.DeptName,
            lt.TypeName       AS LeaveType,
            lb.TotalAllocated,
            lb.TotalUsed,
            lb.Remaining
    FROM    LeaveBalance lb
    JOIN    Employees   e  ON lb.EmpID      = e.EmpID
    JOIN    LeaveTypes  lt ON lb.LeaveTypeID = lt.LeaveTypeID
    LEFT JOIN Departments d ON e.DeptID     = d.DeptID
    WHERE   lb.Year    = @Year
      AND   e.Status   = N'Active'
    ORDER BY d.DeptName, e.LastName, lt.TypeName;
END;
GO

-- -------------------------------------------------------
--  REPORT: Training Report
-- -------------------------------------------------------
CREATE PROCEDURE rpt_TrainingReport
AS
BEGIN
    SET NOCOUNT ON;
    SELECT  e.FirstName + N' ' + e.LastName AS FullName,
            d.DeptName,
            tp.ProgramName,
            tp.StartDate,
            tp.EndDate,
            te.Status  AS EnrollmentStatus,
            te.Score,
            CASE
                WHEN te.Score >= 80 THEN N'Pass'
                WHEN te.Score <  80 THEN N'Fail'
                ELSE N'Pending'
            END AS Result
    FROM    TrainingEnrollment te
    JOIN    Employees      e  ON te.EmpID     = e.EmpID
    LEFT JOIN Departments  d  ON e.DeptID     = d.DeptID
    JOIN    TrainingPrograms tp ON te.ProgramID = tp.ProgramID
    ORDER BY tp.ProgramName, d.DeptName, e.LastName;
END;
GO
-- ════════════════════════════════════════
--Section6--STEP 1: إنشاء Database Roles
-- ════════════════════════════════════════

-- إنشاء الـ 4 roles
CREATE ROLE HR_Admin;
CREATE ROLE HR_Staff;
CREATE ROLE HR_Manager;
CREATE ROLE HR_Employee;
GO

-- ════════════════════════════════════════
-- STEP 2: منح الصلاحيات لكل Role
-- ════════════════════════════════════════

-- ── Admin: كل حاجة ──
GRANT SELECT, INSERT, UPDATE, DELETE ON Employees         TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON Departments       TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON Payroll           TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON Attendance        TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON LeaveRequests     TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON LeaveBalance      TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON LeaveTypes        TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TrainingPrograms  TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TrainingEnrollment TO HR_Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON Users             TO HR_Admin;
-- Admin بيقدر يشغل كل الـ Stored Procedures
GRANT EXECUTE ON sp_GetAllEmployees       TO HR_Admin;
GRANT EXECUTE ON sp_InsertEmployee        TO HR_Admin;
GRANT EXECUTE ON sp_UpdateEmployee        TO HR_Admin;
GRANT EXECUTE ON sp_DeleteEmployee        TO HR_Admin;
GRANT EXECUTE ON rpt_EmployeeMasterList   TO HR_Admin;
GRANT EXECUTE ON rpt_PayrollSummary       TO HR_Admin;
GO

-- ── HR Staff: موظف HR ──
GRANT SELECT, INSERT, UPDATE ON Employees          TO HR_Staff;
GRANT SELECT, INSERT, UPDATE ON Attendance         TO HR_Staff;
GRANT SELECT, INSERT, UPDATE ON LeaveRequests      TO HR_Staff;
GRANT SELECT, INSERT, UPDATE ON LeaveBalance       TO HR_Staff;
GRANT SELECT, INSERT, UPDATE ON TrainingEnrollment TO HR_Staff;
GRANT SELECT                 ON Departments        TO HR_Staff;
GRANT SELECT                 ON LeaveTypes         TO HR_Staff;
GRANT SELECT                 ON TrainingPrograms   TO HR_Staff;
DENY  SELECT, INSERT, UPDATE, DELETE ON Users      TO HR_Staff; -- مش شايف Users
DENY  SELECT, INSERT, UPDATE, DELETE ON Payroll    TO HR_Staff; -- مش شايف Payroll
GRANT EXECUTE ON sp_GetAllEmployees        TO HR_Staff;
GRANT EXECUTE ON sp_InsertEmployee         TO HR_Staff;
GRANT EXECUTE ON sp_SearchEmployees        TO HR_Staff;
GRANT EXECUTE ON sp_LogAttendance          TO HR_Staff;
GRANT EXECUTE ON sp_SubmitLeaveRequest     TO HR_Staff;
GRANT EXECUTE ON rpt_EmployeeMasterList    TO HR_Staff;
GRANT EXECUTE ON rpt_AttendanceSummary     TO HR_Staff;
GRANT EXECUTE ON rpt_LeaveBalanceReport    TO HR_Staff;
GO

-- ── Manager: المدير ──
GRANT SELECT                 ON Employees          TO HR_Manager;
GRANT SELECT                 ON Attendance         TO HR_Manager;
GRANT SELECT, UPDATE         ON LeaveRequests      TO HR_Manager; -- يقدر يوافق
GRANT SELECT                 ON LeaveBalance       TO HR_Manager;
GRANT SELECT                 ON TrainingEnrollment TO HR_Manager;
GRANT SELECT                 ON Departments        TO HR_Manager;
DENY  SELECT, INSERT, UPDATE, DELETE ON Users      TO HR_Manager;
DENY  SELECT, INSERT, UPDATE, DELETE ON Payroll    TO HR_Manager;
GRANT EXECUTE ON sp_GetAllEmployees        TO HR_Manager;
GRANT EXECUTE ON sp_ProcessLeaveRequest    TO HR_Manager; -- الأهم
GRANT EXECUTE ON sp_GetAttendanceByMonth   TO HR_Manager;
GRANT EXECUTE ON rpt_AttendanceSummary     TO HR_Manager;
GRANT EXECUTE ON rpt_LeaveBalanceReport    TO HR_Manager;
GO

-- ── Employee: الموظف العادي ──
-- بيشوف بياناته بس (Row-Level Security بيتعمل في الـ App Layer)
GRANT SELECT ON Employees          TO HR_Employee;
GRANT SELECT ON Attendance         TO HR_Employee;
GRANT SELECT ON LeaveBalance       TO HR_Employee;
GRANT SELECT ON LeaveTypes         TO HR_Employee;
GRANT SELECT ON TrainingPrograms   TO HR_Employee;
GRANT INSERT ON LeaveRequests      TO HR_Employee;  -- يقدر يطلب إجازة
GRANT INSERT ON TrainingEnrollment TO HR_Employee;  -- يقدر يسجل في تدريب
DENY  SELECT, INSERT, UPDATE, DELETE ON Users      TO HR_Employee;
DENY  SELECT, INSERT, UPDATE, DELETE ON Payroll    TO HR_Employee;
GRANT EXECUTE ON sp_SubmitLeaveRequest  TO HR_Employee;
GRANT EXECUTE ON sp_GetLeaveBalance     TO HR_Employee;
GRANT EXECUTE ON sp_EnrollTraining      TO HR_Employee;
GO

-- ════════════════════════════════════════
-- STEP 3: إنشاء SQL Server Logins
-- ════════════════════════════════════════

-- إنشاء Login على مستوى SQL Server
CREATE LOGIN Ahmed_HR   WITH PASSWORD = 'P@ssw0rd_Ahmed!';
CREATE LOGIN Sara_HR    WITH PASSWORD = 'P@ssw0rd_Sara!';
CREATE LOGIN Khaled_MGR WITH PASSWORD = 'P@ssw0rd_Khaled!';
CREATE LOGIN Nour_EMP   WITH PASSWORD = 'P@ssw0rd_Nour!';
GO

-- ════════════════════════════════════════
-- STEP 4: ربط الـ Logins بالـ Database Users
-- ════════════════════════════════════════


CREATE USER Ahmed_HR   FOR LOGIN Ahmed_HR;
CREATE USER Sara_HR    FOR LOGIN Sara_HR;
CREATE USER Khaled_MGR FOR LOGIN Khaled_MGR;
CREATE USER Nour_EMP   FOR LOGIN Nour_EMP;
GO

-- ════════════════════════════════════════
-- STEP 5: إضافة كل User للـ Role المناسب
-- ════════════════════════════════════════
ALTER ROLE HR_Admin   ADD MEMBER Ahmed_HR;   -- Ahmed = Admin
ALTER ROLE HR_Staff   ADD MEMBER Sara_HR;    -- Sara  = HR Staff
ALTER ROLE HR_Manager ADD MEMBER Khaled_MGR; -- Khaled = Manager
ALTER ROLE HR_Employee ADD MEMBER Nour_EMP;  -- Nour  = Employee
GO

-- ════════════════════════════════════════
-- STEP 6: التحقق من الصلاحيات
-- ════════════════════════════════════════

-- شوف الـ Roles الموجودة في الداتابيز
SELECT name, type_desc 
FROM sys.database_principals 
WHERE type = 'R' AND is_fixed_role = 0;

-- شوف مين في كل Role
SELECT 
    r.name  AS RoleName,
    m.name  AS MemberName
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
ORDER BY r.name;

-- شوف صلاحيات Role معين
SELECT 
    perm.permission_name,
    perm.state_desc,
    obj.name AS ObjectName
FROM sys.database_permissions perm
JOIN sys.objects obj ON perm.major_id = obj.object_id
JOIN sys.database_principals prin ON perm.grantee_principal_id = prin.principal_id
WHERE prin.name = 'HR_Manager'
ORDER BY obj.name;
-- ============================================================
--  SECTION 7: EXAMPLE CALLS
-- ============================================================

-- Get all employees
EXEC sp_GetAllEmployees;

-- Get employee by ID
EXEC sp_GetEmployeeByID @EmpID = 1;

-- Insert a new employee
EXEC sp_InsertEmployee
    @FirstName      = N'Layla',
    @LastName       = N'Nasser',
    @NationalID     = N'EG-009-2009',
    @BirthDate      = '1998-06-20',
    @Gender         = N'Female',
    @Email          = N'layla.nasser@company.com',
    @Phone          = N'01089012345',
    @Address        = N'Cairo, Egypt',
    @HireDate       = '2024-01-01',
    @JobTitle       = N'Junior Developer',
    @DeptID         = 2,
    @GradeLevel     = N'G1',
    @EmploymentType = N'Full-Time';

-- Update employee (EmpID = 9 if inserted above)
EXEC sp_UpdateEmployee
    @EmpID      = 9,
    @JobTitle   = N'Mid Developer',
    @DeptID     = 2,
    @GradeLevel = N'G2',
    @Email      = N'layla.nasser@company.com',
    @Phone      = N'01089012345',
    @Address    = N'Cairo, Egypt',
    @Status     = N'Active';
   

-- Search employees
EXEC sp_SearchEmployees @Keyword = N'Ahmed';

-- Log attendance
EXEC sp_LogAttendance
    @EmpID   = 1,
    @AttDate = '2024-03-01',
    @CheckIn = '09:00',
    @Status  = N'Present',
    @Notes   = NULL;

-- Record checkout
EXEC sp_RecordCheckOut @EmpID = 1, @AttDate = '2024-03-01', @CheckOut = '17:00';

-- Get attendance by month
EXEC sp_GetAttendanceByMonth @EmpID = 1, @Year = 2024, @Month = 1;

-- Submit leave request
EXEC sp_SubmitLeaveRequest
    @EmpID       = 4,
    @LeaveTypeID = 1,
    @StartDate   = '2024-07-01',
    @EndDate     = '2024-07-05',
    @Reason      = N'Summer vacation';

-- Approve leave (manager EmpID=3 approves LeaveID=5)
EXEC sp_ProcessLeaveRequest @LeaveID = 5, @ApproverID = 3, @Decision = N'Approved';

-- Get leave balance
EXEC sp_GetLeaveBalance @EmpID = 4, @Year = 2024;

-- Insert payroll
EXEC sp_InsertPayroll
    @EmpID          = 1,
    @PayPeriod      = '2024-03-01',
    @BasicSalary    = 15000,
    @HousingAllow   = 3000,
    @TransportAllow = 500,
    @OtherAllow     = 0,
    @TaxDeduction   = 1500,
    @InsuranceDed   = 750,
    @OtherDeduct    = 0;

-- Get pay history
EXEC sp_GetPayHistory @EmpID = 3;

-- Enroll in training
EXEC sp_EnrollTraining @EmpID = 5, @ProgramID = 4;

-- Complete training with score
EXEC sp_CompleteTraining
    @EmpID       = 1,
    @ProgramID   = 4,
    @Score       = 95.0,
    @Certificate = N'CERT-2024-001';

-- ---- REPORTS ----
EXEC rpt_EmployeeMasterList;
EXEC rpt_AttendanceSummary     @Year = 2024, @Month = 1;
EXEC rpt_PayrollSummary        @PayPeriod = '2024-01-01';
EXEC rpt_LeaveBalanceReport    @Year = 2024;
EXEC rpt_TrainingReport;
