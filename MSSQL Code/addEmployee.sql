CREATE OR ALTER PROCEDURE AddEmployee
    @fname NVARCHAR(50),
    @lname NVARCHAR(50),
    @jobType NVARCHAR(20),
    @hoursWorked INT = 0,
    @paycheck INT = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM salaries WHERE jobType = @jobType)
        BEGIN
            INSERT INTO salaries (jobType, hourlySalary)
            VALUES (@jobType, 0); -- Default hourly salary is 0
            PRINT 'New job type added to salaries table.';
        END
        INSERT INTO employee (fname, lname, jobType, hoursWorked, paycheck)
        VALUES (@fname, @lname, @jobType, @hoursWorked, @paycheck);
        COMMIT Transaction;
        PRINT 'Employee added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error adding employee: ' + ERROR_MESSAGE();
    END CATCH;
END;
