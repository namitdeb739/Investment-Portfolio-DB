USE Portfolio_Tracker;

CREATE TABLE IF NOT EXISTS Currency ( --IF NOT EXISTS prevents duplicate tables
    Currency_Code  CHAR(3) NOT NULL UNIQUE, --NOT NULL prevents null values from being entered, UNIQUE ensures no repeat records are entered
    PRIMARY KEY ( Currency_Code ), --Defines the primary key
    CONSTRAINT CHK_Currency_Code_1 CHECK ( Currency_Code REGEXP '[A-Z][A-Z][A-Z]' ), --Ensures all currencies are 3 alphabets
    CONSTRAINT CHK_Currency_Code_2 CHECK ( Currency_Code = UPPER( Currency_Code ) ) --Prevents input of lowercase letters
);

CREATE TABLE IF NOT EXISTS Portfolio (
    Portfolio_Name  VARCHAR(255) NOT NULL UNIQUE,
    PRIMARY KEY ( Portfolio_Name )
);

CREATE TABLE IF NOT EXISTS Business (
    Ticker        VARCHAR(255) NOT NULL UNIQUE,
    Company_Name  VARCHAR(255) NOT NULL UNIQUE,
    Currency      CHAR(3) NOT NULL,
    Portfolio     VARCHAR(255) NOT NULL,
    PRIMARY KEY ( Company_Name ),
    
    /*FOREIGN KEY determines a relationship
    As it is referencing the Primary Keys of Currency/Portfolio it becomes many-to-one
    ON UPDATE/DELETE CASCADE ensures changes in parent tables are also made in child tables
    ON UPDATE/DELETE RESTRICT prevents changes from being made in parent tables */
    FOREIGN KEY ( Currency ) REFERENCES Currency ( Currency_Code ) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY ( Portfolio ) REFERENCES Portfolio ( Portfolio_Name ) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT CHK_Ticker CHECK ( Ticker = UPPER( Ticker ) )
);

CREATE TABLE IF NOT EXISTS Transaction (
    Transaction_ID                INTEGER NOT NULL UNIQUE AUTO_INCREMENT, --AUTO_INCREMENT ensures values are automatically assigned for PK
    Ticker                        VARCHAR(255) NOT NULL,
    Transaction_Date              DATE NOT NULL,
    Quantity                      DOUBLE NOT NULL,
    Price                         DOUBLE NOT NULL,
    Commission                    DOUBLE NOT NULL,
    USD_XR                        DOUBLE NOT NULL,
        Value_Of_Investment       DOUBLE GENERATED ALWAYS AS ( - ( Quantity * Price + Commission ) ), --Generated columns are calculated
        USD_Value_Of_Investment   DOUBLE GENERATED ALWAYS AS ( Value_Of_Investment / USD_XR ),
    PRIMARY KEY (Transaction_ID ),
    FOREIGN KEY ( Ticker ) REFERENCES Business ( Ticker ) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT CHK_Price CHECK ( Price >= 0 ), --ensures data is in correct range
    CONSTRAINT CHK_Transaction_USD_XR CHECK ( USD_XR >= 0 )
);

CREATE TABLE IF NOT EXISTS Dividend (
    Dividend_ID       INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    Ticker            VARCHAR(255) NOT NULL,
    Dividend_Date     DATE NOT NULL,
    Dividend_Amount   DOUBLE NOT NULL,
    SGD_XR            DOUBLE NOT NULL,
    PRIMARY KEY ( Dividend_ID ),
    FOREIGN KEY ( Ticker ) REFERENCES Business ( Ticker ) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT CHK_SGD_XR CHECK ( SGD_XR >= 0 )
);

CREATE TABLE IF NOT EXISTS Financial_Ratio (
    Financial_Ratio_ID   INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    Ticker               VARCHAR(255) NOT NULL,
    Year_Of_Ratios       INTEGER NOT NULL,
    Capital_Used         DOUBLE,
    D_E_Ratio            DOUBLE,
    EV_FCF               DOUBLE,
    FCF                  DOUBLE,
    Gross_Margin         DOUBLE,
    Net_Margin           DOUBLE,
    Operating_Margin     DOUBLE,
    ROE                  DOUBLE,
    PRIMARY KEY ( Financial_Ratio_ID ),
    FOREIGN KEY ( Ticker ) REFERENCES Business ( Ticker ) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT UQ_Name_Year_Pair UNIQUE NONCLUSTERED (Ticker,Year_Of_Ratios) --Ensures no pair of Ticker, Year_Of_Ratios is repeated
);

CREATE TABLE IF NOT EXISTS Year_End_Data ( 
    Market_Price_ID   INTEGER NOT NULL UNIQUE AUTO_INCREMENT,
    Ticker            VARCHAR(255) NOT NULL,
    Year_Of_Price     INTEGER NOT NULL,
    Market_Price      DOUBLE NOT NULL,
    USD_XR            DOUBLE NOT NULL,
    PRIMARY KEY ( Market_Price_ID ),
    FOREIGN KEY ( Ticker ) REFERENCES Business ( Ticker ) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT UQ_Name_Year_Pair UNIQUE NONCLUSTERED ( Ticker, Year_Of_Price ),
    CONSTRAINT CHK_Market_Price CHECK ( Market_Price >= 0 ),
    CONSTRAINT CHK_Market_Price_USD_XR CHECK ( USD_XR >= 0 )
);
