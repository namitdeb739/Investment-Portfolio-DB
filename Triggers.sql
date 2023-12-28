USE Portfolio_Tracker;

CREATE TRIGGER UpperCaseOnInsertCurrency BEFORE INSERT ON Currency FOR EACH ROW
   SET NEW.Currency_Code = UPPER(NEW.Currency_Code); --automatically capitalises inputs before insertion to maintain format

CREATE TRIGGER UpperCaseOnInsertBusiness BEFORE INSERT ON Business FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER UpperCaseOnInsertTransaction BEFORE INSERT ON Transaction FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER DateCheckOnInsertTransaction BEFORE INSERT ON Transaction FOR EACH ROW
   BEGIN
     IF NEW.Transaction_Date > CURDATE() THEN --Constraints can't reference CURDATE() so trigger is needed to prevent dates which have not happened
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Date!'; 
     END IF;
   END;

CREATE TRIGGER UpperCaseOnInsertDividend BEFORE INSERT ON Dividend FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER DateCheckOnInsertDividend BEFORE INSERT ON Dividend FOR EACH ROW
   BEGIN
     IF NEW.Dividend_Date > CURDATE() THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Date!';
     END IF;
   END;

CREATE TRIGGER UpperCaseOnInsertFinancialRatio BEFORE INSERT ON Financial_Ratio FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER YearCheckOnInsertFinancialRatio BEFORE INSERT ON Financial_Ratio FOR EACH ROW
   BEGIN
     IF NEW.Year_Of_Ratios > YEAR( CURDATE() ) THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Year!';
     END IF;
   END;

CREATE TRIGGER UpperCaseOnInsertYearEndData BEFORE INSERT ON Year_End_Data FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER YearCheckOnInsertYearEndData BEFORE INSERT ON Year_End_Data FOR EACH ROW
   BEGIN
     IF NEW.Year_Of_Price > YEAR( CURDATE() ) THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Year!';
     END IF;
     END;

CREATE TRIGGER UpperCaseOnUpdateCurrency BEFORE UPDATE ON Currency FOR EACH ROW --Functions as above but acts upon update of records
   SET NEW.Currency_Code = UPPER(NEW.Currency_Code);

CREATE TRIGGER UpperCaseOnUpdateBusiness BEFORE UPDATE ON Business FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER UpperCaseOnUpdateTransaction BEFORE UPDATE ON Transaction FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER DateCheckOnUpdateTransaction BEFORE UPDATE ON Transaction FOR EACH ROW
   BEGIN
     IF NEW.Transaction_Date > CURDATE() THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Date!';
     END IF;
   END;

CREATE TRIGGER UpperCaseOnUpdateDividend BEFORE UPDATE ON Dividend FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER DateCheckOnUpdateDividend BEFORE UPDATE ON Dividend FOR EACH ROW
   BEGIN
     IF NEW.Dividend_Date > CURDATE() THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Date!';
     END IF;
   END;

CREATE TRIGGER UpperCaseOnUpdateFinancialRatio BEFORE UPDATE ON Financial_Ratio FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER YearCheckOnUpdateFinancialRatio BEFORE UPDATE ON Financial_Ratio FOR EACH ROW
   BEGIN
     IF NEW.Year_Of_Ratios > YEAR( CURDATE() ) THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Year!';
     END IF;
   END;

CREATE TRIGGER UpperCaseOnUpdateYearEndData BEFORE UPDATE ON Year_End_Data FOR EACH ROW
   SET NEW.Ticker = UPPER(NEW.Ticker);

CREATE TRIGGER YearCheckOnUpdateYearEndData BEFORE UPDATE ON Year_End_Data FOR EACH ROW
   BEGIN
     IF NEW.Year_Of_Price > YEAR( CURDATE() ) THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Year!';
     END IF;
     END;