CREATE or ALTER PROCEDURE AddReservation
    @reserverFname NVARCHAR(50),
    @reserverLname NVARCHAR(50),
    @numPeople INT,
    @resDate DATE,
    @resTime TIME,
    @mealPrice INT = 0,
    @tip INT = 0,
    @reservationDetails NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @maxCapacity INT = 100;
    DECLARE @openingTime TIME = '09:00:00';
    DECLARE @closingTime TIME = '22:00:00';
    DECLARE @empID INT;
    DECLARE @resID INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT TOP 1 @empID = empID
        FROM employee
        WHERE jobType = 'waiter'
        ORDER BY NEWID();

        IF @empID IS NULL
        BEGIN
            RAISERROR ('No available waiter to assign to the reservation.', 16, 1);
        END

        IF EXISTS (
            SELECT 1
            FROM reservation
            WHERE date = @resDate
            GROUP BY date
            HAVING SUM(numPeople) + @numPeople > @maxCapacity
        )
        BEGIN
            RAISERROR ('Reservation exceeds the restaurant capacity.', 16, 1);
        END

        IF NOT (@resTime >= @openingTime AND @resTime <= @closingTime)
        BEGIN
            RAISERROR ('Reservation time is outside of service hours.', 16, 1);
        END

        INSERT INTO reservation (fname, lname, numPeople, time, date, empID, mealPrice, tip)
        VALUES (@reserverFname, @reserverLname, @numPeople, @resTime, @resDate, @empID, @mealPrice, @tip);

        SET @resID = SCOPE_IDENTITY();

        DECLARE @employeeName NVARCHAR(100);
        SELECT @employeeName = fname + ' ' + lname
        FROM employee
        WHERE empID = @empID;

        SET @reservationDetails = CONCAT(
            'Reservation ID: ', @resID, CHAR(10),
            'Reserver Name: ', @reserverFname, ' ', @reserverLname, CHAR(10),
            'Number of People: ', @numPeople, CHAR(10),
            'Date: ', CONVERT(VARCHAR(10), @resDate), CHAR(10),
            'Time: ', CONVERT(VARCHAR(8), @resTime), CHAR(10),
            'Assigned Employee: ', @employeeName
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
