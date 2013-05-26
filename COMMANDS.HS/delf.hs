import System.Environment
import System.IO
import Text.ParserCombinators.Parsec
import Control.Monad

{--
delf（Open usp Tukubai）

designed by Nobuaki Tounaka
written by Ryuichi Ueda

The MIT License

Copyright (C) 2012 Universal Shell Programming Laboratory

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--}

showUsage :: IO ()
showUsage = do hPutStr stderr
		("Usage    : delf <f1> <f2> ... <file>\n" ++ 
		"Sun May 26 21:14:17 JST 2013\n" ++
		"Open usp Tukubai (LINUX+FREEBSD), Haskell ver.\n")

main :: IO ()
main = do
	args <- getArgs
	case args of
		["-h"]     -> showUsage
		["--help"] -> showUsage
		_          -> do if f == "-"
                                     then getContents >>= mainProc fields
                                     else readFile f >>= mainProc fields
                                     where f = getFileName opts
                                           fields = getFields opts
                                           opts = setOpts args
                                   
------------
-- output --
------------

mainProc :: [(Int,Int)] -> String -> IO ()
mainProc fs cs = putStr $ unlines [ lineProc fs c | c <- lines cs ]

lineProc :: [(Int,Int)] -> String -> String
lineProc fs ln = unwords $ deleteFields (fieldNormalize fs (length wds)) (zip [1..] wds)
                 where wds = words ln

fieldNormalize :: [(Int,Int)] -> Int -> [Int]
fieldNormalize ((a,b):fs) fnum = [c..d] ++ (fieldNormalize fs fnum)
                 where c = if a > 0 then a else fnum + a
                       d = if b > 0 then b else fnum + b
fieldNormalize [] fnum = []

deleteFields :: [Int] -> [(Int,String)] -> [String]
deleteFields fs ((n,w):nws) = if n `elem` fs
                              then deleteFields fs nws
                              else w : deleteFields fs nws 
deleteFields fs [] = []

------------------------
-- parsing of options --
------------------------

data Field = Field Int
data Option = FRange Field Field | FileName String | Error String

getFields :: [Option] -> [(Int,Int)]
getFields ((FRange a b):opts) = (getF a,getF b) : getFields opts
	                        where getF (Field c) = c
getFields (opt:opts)       = getFields opts
getFields []               = []

getFileName :: [Option] -> String
getFileName ((FileName s):opts) = s
getFileName (opt:opts)          = getFileName opts
getFileName []                  = "-"

setOpts :: [String] -> [Option]
setOpts as = [ fnc a | a <- as ]
             where fnc str = case parse parseOption "" str of
                                  Right opt -> opt
                                  Left err -> Error ( show err ) 

parseMonoRange :: Parser Option
parseMonoRange = do f <- parseField
                    return (FRange f f)

parseField :: Parser Field
parseField = try(parseNormalField) <|> try(parseNFMinusField) <|> try(parseNFField)

parseCompRange :: Parser Option
parseCompRange = do first <- parseField
                    char '/'
                    second <- parseField
                    return ( FRange first second )

parseOption :: Parser Option
parseOption = try(parseCompRange) <|> try(parseMonoRange) <|> try(parseFileName)

parseNormalField :: Parser Field
parseNormalField =  liftM (Field . read) $ many1 digit

parseNFMinusField :: Parser Field
parseNFMinusField =  do string "NF-"
			num <- many1 digit
                        return $ Field ( -1 * (read num) )

parseNFField :: Parser Field
parseNFField =  do string "NF"
                   return $ Field 0

parseFileName :: Parser Option
parseFileName =  do s <- many1 ( letter <|> digit <|> symbol ) 
                    return $ FileName s

symbol :: Parser Char
symbol = oneOf "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
