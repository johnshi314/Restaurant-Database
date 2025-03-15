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

GO

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

GO

CREATE OR ALTER PROCEDURE AddEmployee
    @fname NVARCHAR(50),
    @lname NVARCHAR(50),
    @jobType NVARCHAR(20),
    @hoursWorked INT = 0,
    @paycheck INT = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM salaries WHERE jobType = @jobType)
        BEGIN
            INSERT INTO salaries (jobType, hourlySalary)
            VALUES (@jobType, 0); -- Default hourly salary is 0
            PRINT 'New job type added to salaries table.';
        END
        INSERT INTO employee (fname, lname, jobType, hoursWorked, paycheck)
        VALUES (@fname, @lname, @jobType, @hoursWorked, @paycheck);
        COMMIT Transaction;
        PRINT 'Employee added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error adding employee: ' + ERROR_MESSAGE();
    END CATCH;
END;

GO

CREATE OR ALTER PROCEDURE AddJobTitle
    @jobType NVARCHAR(20),
    @hourlySalary INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM salaries WHERE jobType = @jobType)
        BEGIN
            THROW 50006, 'Job type already exists in the salaries table.', 1;
        END

        INSERT INTO salaries (jobType, hourlySalary)
        VALUES (@jobType, @hourlySalary);

        UPDATE employee
        SET jobType = @jobType
        WHERE jobType IS NULL OR jobType = 'Default';

        COMMIT Transaction;

        PRINT 'Job title added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK Transaction;
        PRINT 'Error adding job title: ' + ERROR_MESSAGE();
    END CATCH;
END;

Go

CREATE OR ALTER PROCEDURE AddCustomer
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

GO

CREATE OR ALTER PROCEDURE AddAllergy
    @allergyName VARCHAR(50)
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO allergies (allergyName)
        VALUES (@allergyName);

        COMMIT TRANSACTION;
        PRINT 'Allergy added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'An error occurred. Allergy not added.';
    END CATCH
END;

GO

CREATE OR ALTER PROCEDURE CalculatePaycheck
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

GO

CREATE OR ALTER PROCEDURE AddTime
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

GO

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

GO

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

GO

CREATE OR ALTER PROCEDURE AddTip
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

GO

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
