CREATE PROCEDURE AddTime
    @empID INT,
    @hoursToAdd INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @hoursToAdd <= 0
        BEGIN
            THROW 51003, 'Hours to add must be greater than zero.', 1;
        END

        IF NOT EXISTS (
            SELECT 1
            FROM employee
            WHERE empID = @empID
        )
        BEGIN
            THROW 51004, 'Employee ID does not exist.', 1;
        END

        UPDATE employee
        SET hoursWorked = hoursWorked + @hoursToAdd
        WHERE empID = @empID;

        PRINT 'Successfully added ' + CAST(@hoursToAdd AS NVARCHAR(10)) + ' hours to employee ID ' + CAST(@empID AS NVARCHAR(10)) + '.';

        DECLARE @newHoursWorked INT;
        SELECT @newHoursWorked = hoursWorked
        FROM employee
        WHERE empID = @empID;

        PRINT 'Updated hours worked: ' + CAST(@newHoursWorked AS NVARCHAR(10)) + '.';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
