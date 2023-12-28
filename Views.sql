USE Portfolio_Tracker;

CREATE VIEW Business_Holdings AS
    SELECT 
        Business.Portfolio,
        Business.Ticker, 
        Business.Company_Name, 
        Business.Currency,
        T.Total_Quantity,
        D.Cumulative_Dividends,
        T.Weighted_Average_Price,
        T.Total_Value_Of_Investment,
        T.Total_USD_Value_Of_Investment
    FROM Business
        LEFT JOIN --LEFT JOIN takes all values from business and places NULLs where there is no matching value in the joined columns
            ( SELECT
                Business.Company_Name,
                FORMAT( SUM( Transaction.Quantity ), 2 ) AS Total_Quantity, --Format ensures data is presented easy-to-interpret
                CONCAT( Business.Currency, ' ', FORMAT( --CONCAT to add currency before the number value
                /*CASE WHEN... THEN... END is a conditional choosing rows which meet certain conditions
                Below it functions as a SUMIF which is not present in MYSQL
                */
                    SUM( CASE WHEN Transaction.Quantity > 0 THEN Transaction.Value_Of_Investment END) /
                    SUM( CASE WHEN Transaction.Quantity > 0 THEN Transaction.Quantity END) * -1 -
                , 2 ) ) AS Weighted_Average_Price,
                CONCAT( Business.Currency, ' ', FORMAT( - SUM( Transaction.Value_Of_Investment ), 2) ) AS Total_Value_Of_Investment,
                CONCAT( 'USD ', FORMAT( - SUM( Transaction.USD_Value_Of_Investment ),2 ) ) AS Total_USD_Value_Of_Investment
            FROM Business
                LEFT JOIN 
                    Transaction
                    ON Business.Ticker = Transaction.Ticker --Ensures records between two tables are matched based on Tickers
            GROUP BY Business.Company_Name ) --Aggregated columns take the sum for each company rather than entire column
            AS T --Short form of transaction to easily reference in the original selection
            ON Business.Company_Name = T.Company_Name
        LEFT JOIN 
            ( SELECT
                    Business.Company_Name,
                    CONCAT( Business.Currency, ' ', FORMAT( SUM( Dividend.Dividend_Amount ), 2 ) ) AS Cumulative_Dividends
            FROM Business
                LEFT JOIN 
                    Dividend
                    ON Business.Ticker = Dividend.Ticker
            GROUP BY Business.Company_Name ) 
            AS D 
            ON Business.Company_Name = D.Company_Name
    ORDER BY Business.Portfolio ASC, Business.Currency ASC, T.Total_USD_Value_Of_Investment ASC; --Sorts the records

CREATE VIEW Year_To_Date_Dividends AS
    SELECT
        IFNULL( Business.Portfolio, 'All Portfolios' ) AS Portfolio, --IFNULL used in conjunction with the ROLLUP to present a summary row
        IFNULL( Business.Ticker, ' ' ) AS Ticker,
        A.Company_Name,
        IFNULL( Business.Currency, 'SGD' ) AS Currency,
        CONCAT( Business.Currency, ' ', FORMAT( B.Year_To_Date_Dividends, 2 ) ) AS Year_To_Date_Dividends,
        CONCAT( 'SGD ', FORMAT( A.SGD_Year_To_Date_Dividends, 2 ) ) AS SGD_Year_To_Date_Dividends
    FROM Business
        RIGHT JOIN 
            ( SELECT
                IFNULL( Business.Company_Name,'Total Year To Date Dividends' ) AS Company_Name,
                IFNULL( 
                    SUM( 
                        /*this sum ensures date is within current year-to-date by converting Jan 1 current year to date format
                        by converting the concatenated string into the Jan 1 current year date format*/
                        CASE WHEN Dividend.Dividend_Date >= STR_TO_DATE( CONCAT( '1 January ', YEAR(CURDATE()) ), '%d %M %Y' ) -
                        AND Dividend.Dividend_Date <= CURDATE() 
                        THEN Dividend.Dividend_Amount / Dividend.SGD_XR 
                    END ), 0 ) AS SGD_Year_To_Date_Dividends 
            FROM Business
                LEFT JOIN 
                    Dividend
                    ON Business.Ticker = Dividend.Ticker
            GROUP BY Business.Company_Name WITH ROLLUP
            /*ROLLUPs produce aggregated rows
            If a column takes SUMS grouped by each business, rollups produce a summary row taking the sum of all businesses
            This allows for an auto-calculated summary
            Non aggregated columns such as strings are presented as NULL which are then converted to descriptive text
            using the IFNULL statement
            */
            HAVING SGD_Year_To_Date_Dividends > 0 ) --Filters out all values where dividend is 0, only shows relevant results
            AS A 
            ON Business.Company_Name = A.Company_Name
        LEFT JOIN 
            ( SELECT
                Business.Company_Name,
                IFNULL( 
                    SUM(
                        CASE WHEN Dividend.Dividend_Date >= STR_TO_DATE( CONCAT( '1 January ', YEAR(CURDATE()) ), '%d %M %Y' )
                        AND Dividend.Dividend_Date <= CURDATE() 
                        THEN Dividend.Dividend_Amount 
                    END),0) AS Year_To_Date_Dividends
            FROM Business
                LEFT JOIN 
                    Dividend
                    ON Business.Ticker = Dividend.Ticker
            GROUP BY Business.Company_Name
            HAVING Year_To_Date_Dividends > 0 ) 
            AS B 
            ON Business.Company_Name = B.Company_Name
    GROUP BY A.Company_Name, A.SGD_Year_To_Date_Dividends
    ORDER BY Business.Portfolio ASC, Business.Currency ASC, A.Company_Name ASC;
    
CREATE VIEW Present_Market_Value AS
    SELECT
        IFNULL( Business.Portfolio, 'All Portfolios' ) AS Portfolio,
        IFNULL( Business.Ticker, ' ' ) AS Ticker,
        USD.Company_Name, 
        IFNULL( Business.Currency, 'USD' ) AS Currency,
        CONCAT(Business.Currency, ' ', FORMAT( IFNULL( D.Cumulative_Dividends, 0 ), 2 ) ) AS Cumulative_Dividends,
        FORMAT( IFNULL( T.Total_Quantity, 0 ), 2 ) AS Total_Quantity,
        CONCAT(Business.Currency, ' ', FORMAT( IFNULL( - T.Total_Value_Of_Investment, 0 ), 2 ) ) AS Total_Value_Of_Investment,
        USD.USD_Total_Value_Of_Investment,
        USD.USD_Market_Value_5_Years_Ago,
        USD.USD_Market_Value_4_Years_Ago,
        USD.USD_Market_Value_3_Years_Ago,
        USD.USD_Market_Value_2_Years_Ago,
        USD.USD_Market_Value_1_Years_Ago
    FROM Business
        LEFT JOIN 
            ( SELECT
                Business.Company_Name,
                SUM( Transaction.Quantity ) AS Total_Quantity,
                SUM( Transaction.Value_Of_Investment ) AS Total_Value_Of_Investment
            FROM Business
                LEFT JOIN 
                    Transaction
                    ON Business.Ticker = Transaction.Ticker
            GROUP BY Business.Company_Name )
            AS T 
            ON Business.Company_Name = T.Company_Name
        LEFT JOIN 
            ( SELECT
                Business.Company_Name,
                SUM( Dividend.Dividend_Amount ) AS Cumulative_Dividends
            FROM Business
                LEFT JOIN 
                    Dividend
                    ON Business.Ticker = Dividend.Ticker
            GROUP BY Business.Company_Name )
            AS D 
            ON Business.Company_Name = D.Company_Name
        RIGHT JOIN /*A right join was used here as the ROLLUP is used in the below SELECT not the parent select,
        so a right join is used to ensure that the summary row is present in the final view */
            ( SELECT 
            /* All of the USD values have been isolated from the Transactions and Dividends in above selects as these 
            Will be the values which are shown in the summary row, not the transactions or dividends above
            */
                IFNULL( Business.Company_Name,'Total Portfolio Market Value' ) AS Company_Name,
                CONCAT('USD ', FORMAT( IFNULL( - SUM( USD_T.Total_USD_Value_Of_Investment ), 0 ), 2 ) ) AS USD_Total_Value_Of_Investment,
                CONCAT('USD ', FORMAT( IFNULL( SUM( USD_T.Quantity_5 * USD_M.Price_5 + IFNULL( USD_D.Dividend_5, 0 ) / USD_M.XR_5 ), 0 ), 2 ) ) 
                AS USD_Market_Value_5_Years_Ago,
                CONCAT('USD ', FORMAT( IFNULL( SUM( USD_T.Quantity_4 * USD_M.Price_4 + IFNULL( USD_D.Dividend_4, 0 ) / USD_M.XR_4 ), 0 ), 2 ) ) 
                AS USD_Market_Value_4_Years_Ago,
                CONCAT('USD ', FORMAT( IFNULL( SUM( USD_T.Quantity_3 * USD_M.Price_3 + IFNULL( USD_D.Dividend_3, 0 ) / USD_M.XR_3 ), 0 ), 2 ) ) 
                AS USD_Market_Value_3_Years_Ago,
                CONCAT('USD ', FORMAT( IFNULL( SUM( USD_T.Quantity_2 * USD_M.Price_2 + IFNULL( USD_D.Dividend_2, 0 ) / USD_M.XR_2 ), 0 ), 2 ) ) 
                AS USD_Market_Value_2_Years_Ago,
                CONCAT('USD ', FORMAT( IFNULL( SUM( USD_T.Quantity_1 * USD_M.Price_1 + IFNULL( USD_D.Dividend_1, 0 ) / USD_M.XR_1 ), 0 ), 2 ) ) 
                AS USD_Market_Value_1_Years_Ago
            FROM Business
                LEFT JOIN 
                    ( SELECT
                        Business.Company_Name,
                        SUM( CASE WHEN YEAR( Transaction.Transaction_Date ) <= YEAR( CURDATE() ) - 5 THEN Transaction.Quantity END ) AS Quantity_5,
                        SUM( CASE WHEN YEAR( Transaction.Transaction_Date ) <= YEAR( CURDATE() ) - 4 THEN Transaction.Quantity END ) AS Quantity_4,
                        SUM( CASE WHEN YEAR( Transaction.Transaction_Date ) <= YEAR( CURDATE() ) - 3 THEN Transaction.Quantity END ) AS Quantity_3,
                        SUM( CASE WHEN YEAR( Transaction.Transaction_Date ) <= YEAR( CURDATE() ) - 2 THEN Transaction.Quantity END ) AS Quantity_2,
                        SUM( CASE WHEN YEAR( Transaction.Transaction_Date ) <= YEAR( CURDATE() ) - 1 THEN Transaction.Quantity END ) AS Quantity_1,
                        SUM( Transaction.USD_Value_Of_Investment ) AS Total_USD_Value_Of_Investment
                    FROM Business
                        LEFT JOIN 
                            Transaction
                            ON Business.Ticker = Transaction.Ticker
                    GROUP BY Business.Company_Name ) 
                    AS USD_T 
                    ON Business.Company_Name = USD_T.Company_Name
                LEFT JOIN 
                    ( SELECT
                        Business.Company_Name,
                        SUM( CASE WHEN YEAR( Dividend.Dividend_Date ) <= YEAR( CURDATE() ) - 5 THEN Dividend.Dividend_Amount END ) AS Dividend_5,
                        SUM( CASE WHEN YEAR( Dividend.Dividend_Date ) <= YEAR( CURDATE() ) - 4 THEN Dividend.Dividend_Amount END ) AS Dividend_4,
                        SUM( CASE WHEN YEAR( Dividend.Dividend_Date ) <= YEAR( CURDATE() ) - 3 THEN Dividend.Dividend_Amount END ) AS Dividend_3,
                        SUM( CASE WHEN YEAR( Dividend.Dividend_Date ) <= YEAR( CURDATE() ) - 2 THEN Dividend.Dividend_Amount END ) AS Dividend_2,
                        SUM( CASE WHEN YEAR( Dividend.Dividend_Date ) <= YEAR( CURDATE() ) - 1 THEN Dividend.Dividend_Amount END ) AS Dividend_1
                    FROM Business
                        LEFT JOIN 
                            Dividend
                            ON Business.Ticker = Dividend.Ticker
                    GROUP BY Business.Company_Name ) 
                    AS USD_D 
                    ON Business.Company_Name = USD_D.Company_Name
                LEFT JOIN 
                    ( SELECT
                        Business.Company_Name,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 5 THEN Year_End_Data.Market_Price END ) AS Price_5,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 4 THEN Year_End_Data.Market_Price END ) AS Price_4,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 3 THEN Year_End_Data.Market_Price END ) AS Price_3,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 2 THEN Year_End_Data.Market_Price END ) AS Price_2,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 1 THEN Year_End_Data.Market_Price END ) AS Price_1,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 5 THEN Year_End_Data.USD_XR END ) AS XR_5,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 4 THEN Year_End_Data.USD_XR END ) AS XR_4,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 3 THEN Year_End_Data.USD_XR END ) AS XR_3,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 2 THEN Year_End_Data.USD_XR END ) AS XR_2,
                        SUM( CASE WHEN Year_End_Data.Year_Of_Price = YEAR( CURDATE() ) - 1 THEN Year_End_Data.USD_XR END ) AS XR_1
                    FROM Business
                        LEFT JOIN 
                            Year_End_Data
                            ON Business.Ticker = Year_End_Data.Ticker
                    GROUP BY Business.Company_Name ) 
                    AS USD_M
                    ON Business.Company_Name = USD_M.Company_Name 
            GROUP BY Business.Company_Name WITH ROLLUP )
            AS USD
            ON Business.Company_Name = USD.Company_Name
    ORDER BY Portfolio ASC, Currency ASC, Total_Value_Of_Investment ASC;

CREATE VIEW Yearly_Performance AS
    SELECT
        Business.Portfolio,
        Business.Ticker,
        Business.Company_Name,
        Business.Currency,
        Financial_Ratio.Year_Of_Ratios,
        CONCAT( Business.Currency, ' ', FORMAT( Financial_Ratio.Capital_Used, 2 ) ) AS Capital_Used,
        FORMAT( Financial_Ratio.D_E_Ratio, 2 ) AS D_E_Ratio,
        FORMAT( Financial_Ratio.EV_FCF, 2 ) AS EV_FCF,
        CONCAT( FORMAT( Financial_Ratio.Gross_Margin * 100, 2 ), '%' ) AS Gross_Margin, --formats it as a percentage
        CONCAT( FORMAT( Financial_Ratio.Net_Margin * 100, 2 ), '%' ) AS Net_Margin,
        CONCAT( FORMAT( Financial_Ratio.Operating_Margin * 100, 2 ), '%' ) AS Operating_Margin,
        CONCAT( FORMAT( Financial_Ratio.ROE * 100, 2 ), '%' ) AS ROE
    FROM Business
        LEFT JOIN
            Financial_Ratio
            ON Business.Ticker = Financial_Ratio.Ticker
    ORDER BY Business.Portfolio ASC, Business.Currency ASC, Business.Company_Name ASC, Financial_Ratio.Year_Of_Ratios DESC;
    
CREATE VIEW Transaction_History AS
    SELECT
        Business.Portfolio,
        Business.Ticker,
        Business.Company_Name,
        Business.Currency,
        Transaction.Transaction_Date,
        FORMAT( Transaction.Quantity, 2 ) AS Quantity,
        CONCAT( Business.Currency, ' ', FORMAT( Transaction.Price, 2 ) ) AS Price,
        CONCAT( Business.Currency, ' ', FORMAT( Transaction.Commission, 2 ) ) AS Commission,
        CONCAT( Business.Currency, ' ', FORMAT( Transaction.Value_Of_Investment, 2 ) ) AS Value_Of_Investment,
        CONCAT( 'USD ', FORMAT( Transaction.USD_Value_Of_Investment, 2 ) ) AS USD_Value_Of_Investment
    FROM Business
        INNER JOIN
            Transaction
            ON Business.Ticker = Transaction.Ticker
    ORDER BY Transaction_Date DESC; 