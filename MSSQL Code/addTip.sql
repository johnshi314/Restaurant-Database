CREATE PROCEDURE AddTip
    @resID INT,
    @tip INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tip < 0
        BEGIN
            THROW 51005, 'Tip cannot be negative.', 1;
        END

        DECLARE @mealPrice INT;
        DECLARE @totalAmount INT;

        SELECT @mealPrice = mealPrice
        FROM reservation
        WHERE resID = @resID;

        IF @mealPrice IS NULL
        BEGIN
            THROW 51002, 'Reservation not found.', 1;
        END

        SET @totalAmount = @mealPrice + @tip;

        UPDATE reservation
        SET tip = @tip
        WHERE resID = @resID;

        PRINT 'Meal Price: $' + CAST(@mealPrice / 100.0 AS NVARCHAR(10));
        PRINT 'Tip: $' + CAST(@tip / 100.0 AS NVARCHAR(10));
        PRINT 'Total (Meal + Tip): $' + CAST(@totalAmount / 100.0 AS NVARCHAR(10));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
