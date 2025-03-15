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
