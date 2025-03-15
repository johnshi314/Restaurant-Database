CREATE PROCEDURE AddCustomer
    @fname NVARCHAR(50),
    @lname NVARCHAR(50),
    @birthdate DATE,
    @resID INT
AS
BEGIN
    DECLARE @customerID INT;
    DECLARE @numPeopleInReservation INT;
    DECLARE @numPeopleAlreadyAdded INT;
    DECLARE @remainingCapacity INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @numPeopleInReservation = numPeople 
        FROM reservation
        WHERE resID = @resID;

        SELECT @numPeopleAlreadyAdded = COUNT(*)
        FROM customer
        WHERE resID = @resID;

        SET @remainingCapacity = @numPeopleInReservation - @numPeopleAlreadyAdded;

        IF @remainingCapacity <= 0
        BEGIN
            PRINT 'Reservation has reached its maximum capacity. Cannot add more customers.';
            ROLLBACK TRANSACTION;
            RETURN; 
        END

        INSERT INTO customer (fname, lname, birthdate, resID)
        VALUES (@fname, @lname, @birthdate, @resID);

        SET @customerID = SCOPE_IDENTITY();

        PRINT 'Customer successfully added. Customer ID: ' + CAST(@customerID AS NVARCHAR(10));
        PRINT 'Customer Details:';
        PRINT 'Name: ' + @fname + ' ' + @lname;
        PRINT 'Birthdate: ' + CONVERT(VARCHAR(10), @birthdate);
        PRINT 'Reservation ID: ' + CAST(@resID AS NVARCHAR(10));

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        PRINT 'Error occurred: ' + ERROR_MESSAGE();
    END CATCH;
END;
