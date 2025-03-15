CREATE OR ALTER PROCEDURE AddMenuItem
    @menuItemName VARCHAR(50),
    @price INT,
    @dishType VARCHAR(50),
    @isAlcoholic BIT,
    @cost INT
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO menuItem (menuItemName, price, dishType, isAlcoholic, cost)
        VALUES (@menuItemName, @price, @dishType, @isAlcoholic, @cost);

        COMMIT TRANSACTION;
        PRINT 'Menu item added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'An error occurred. Menu item not added.';
    END CATCH
END;
