CREATE OR ALTER PROCEDURE DisplayMenuItems
    @customerID INT
AS
BEGIN
    BEGIN TRANSACTION;

    DECLARE @currentDate DATE = GETDATE();
    DECLARE @birthdate DATE;
   
    SELECT @birthdate = birthdate
    FROM customer
    WHERE customerID = @customerID;

    IF @birthdate IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'Customer not found or birthdate is missing.';
        RETURN;
    END

    DECLARE @age INT;
    SET @age = DATEDIFF(YEAR, @birthdate, @currentDate) - 
               CASE WHEN MONTH(@birthdate) > MONTH(@currentDate) OR 
                         (MONTH(@birthdate) = MONTH(@currentDate) AND DAY(@birthdate) > DAY(@currentDate)) 
                    THEN 1 ELSE 0 END;

    SELECT menuItem.itemID, menuItem.menuItemName, menuItem.price, menuItem.dishType, menuItem.isAlcoholic
    FROM menuItem
    WHERE NOT EXISTS (
        SELECT 1
        FROM usedIn
        JOIN ingredients ON usedIn.ingredientID = ingredients.ingredientID
        WHERE usedIn.dishID = menuItem.itemID AND ingredients.amount <= 0
    )
    AND NOT EXISTS (
        SELECT 1
        FROM usedIn
        JOIN ingredients ON usedIn.ingredientID = ingredients.ingredientID
        WHERE usedIn.dishID = menuItem.itemID AND ingredients.allergyID IN (
            SELECT hasAllergy.allergyID
            FROM hasAllergy
            WHERE hasAllergy.customerID = @customerID
        )
    )
    AND (@age >= 21 OR menuItem.isAlcoholic = 0);

    COMMIT TRANSACTION;
END;
