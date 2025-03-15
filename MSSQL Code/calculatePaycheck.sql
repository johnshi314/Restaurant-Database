CREATE PROCEDURE CalculatePaycheck
    @empID INT,
    @basePay INT OUTPUT,
    @tips INT OUTPUT,
    @totalPay INT OUTPUT
AS
BEGIN
    BEGIN TRANSACTION;

    DECLARE @hoursWorked INT = 0;
    DECLARE @hourlySalary INT = 0;
    DECLARE @totalTips INT = 0;

    BEGIN TRY
        SELECT @hoursWorked = hoursWorked, @hourlySalary = s.hourlySalary
        FROM employee e
        JOIN salaries s ON e.jobType = s.jobType
        WHERE e.empID = @empID;

        IF @hoursWorked IS NULL OR @hourlySalary IS NULL
        BEGIN
            THROW 51000, 'Employee data is incomplete. Cannot calculate paycheck.', 1;
        END

        SET @basePay = @hoursWorked * @hourlySalary;

        IF EXISTS (
            SELECT 1
            FROM employee
            WHERE empID = @empID AND jobType = 'waiter'
        )
        BEGIN
            SELECT @totalTips = COALESCE(SUM(r.tip), 0)
            FROM reservation r
            WHERE r.empID = @empID;
        END

        SET @totalPay = @basePay + @totalTips;

        UPDATE employee
        SET paycheck = @totalPay
        WHERE empID = @empID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
