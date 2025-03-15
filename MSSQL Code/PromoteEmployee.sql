CREATE OR ALTER PROCEDURE PromoteEmployee
    @empID INT,
    @newJobType NVARCHAR(20)
AS
BEGIN
    DECLARE @newHourlySalary INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM salaries WHERE jobType = @newJobType)
        BEGIN
            THROW 50003, 'Invalid job type. Please provide a valid job type from the salaries table.', 1;
        END
        
        SELECT @newHourlySalary = hourlySalary FROM salaries WHERE jobType = @newJobType;
        UPDATE employee
        SET jobType = @newJobType,
            paycheck = paycheck + (@newHourlySalary * hoursWorked)
        WHERE empID = @empID;
        
        COMMIT TRANSACTION;
        
        PRINT 'Employee promoted successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH;
END;
