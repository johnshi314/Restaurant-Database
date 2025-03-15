CREATE OR ALTER PROCEDURE ProcessOrder
    @customerID INT,
    @itemID INT
AS
BEGIN
    BEGIN TRANSACTION;

    DECLARE @birthdate DATE, @age INT, @isAlcoholic BIT;

    SELECT @birthdate = birthdate
    FROM customer
    WHERE customerID = @customerID;

    SET @age = DATEDIFF(YEAR, @birthdate, GETDATE()) - 
               CASE WHEN MONTH(@birthdate) > MONTH(GETDATE()) OR 
                         (MONTH(@birthdate) = MONTH(GETDATE()) AND DAY(@birthdate) > DAY(GETDATE())) 
                    THEN 1 ELSE 0 END;

    SELECT @isAlcoholic = isAlcoholic
    FROM menuItem
    WHERE itemID = @itemID;

    IF EXISTS (
        SELECT 1
        FROM usedIn
        JOIN ingredients ON usedIn.ingredientID = ingredients.ingredientID
        WHERE usedIn.dishID = @itemID
          AND ingredients.allergyID IN (
              SELECT allergyID
              FROM hasAllergy
              WHERE customerID = @customerID
          )
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR ('Order denied: Customer is allergic to this menu item.', 16, 1);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM usedIn
        JOIN ingredients ON usedIn.ingredientID = ingredients.ingredientID
        WHERE usedIn.dishID = @itemID AND ingredients.amount <= 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR ('Order denied: Insufficient ingredients for this menu item.', 16, 1);
        RETURN;
    END;

    IF @isAlcoholic = 1 AND @age < 21
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR ('Order denied: Customer is under 21 and cannot order alcoholic items.', 16, 1);
        RETURN;
    END;

    INSERT INTO ordered (customerID, itemID)
    VALUES (@customerID, @itemID);

    COMMIT TRANSACTION;
    PRINT 'Order placed successfully!';
END;
