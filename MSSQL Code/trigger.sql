CREATE TRIGGER UpdatePaycheckOnPromotion
ON employee
AFTER UPDATE
AS
BEGIN
    IF UPDATE(jobType)
    BEGIN
        DECLARE @jobType NVARCHAR(20);
        DECLARE @empID INT;

        SELECT @jobType = jobType, @empID = empID FROM inserted;

        -- Update paycheck based on the new job type's hourly salary
        UPDATE employee
        SET paycheck = hoursWorked * (
            SELECT hourlySalary FROM salaries WHERE jobType = @jobType
        )
        WHERE empID = @empID;

        PRINT 'Paycheck updated automatically after promotion.';
    END
END;
