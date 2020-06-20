---
layout: post
title: Reading Excel files in R
---

## Reading Excel Files: A comparison of R packages


### Background   

Recently a person posed a [question on Stackoverflow](https://bit.ly/3cYXVOm) about four of the packages that are used to read Microsoft Excel files, including:

* readxl,
* openxlsx,
* xlsx, and
* XLConnect.

The person who wrote the question wanted to know about functionality that was unique to a single package, such as the the ability of `readxl` to obtain a list of worksheets in a spreadsheet. S/he was also interested in the relative performance of each of these packages.

Since a question like this leads to primarily opinion-based answers (i.e *"I prefer package <x> to <y> for this reason..."*), it was voted for closure by three people with the `close vote` privilege on Stackoverflow.

Complicating matters is the fact that when one navigates to this question on Stackoverflow, one of the questions that is listed in the *Related Questions* area on the lower right side of the web page is [data.table vs. dplyr](https://bit.ly/3hvVNRR), an opinion-based question that as of June 13, 2020 has 761 upvotes, and includes an answer from Hadley Wickham at RStudio.

In the spirit of being helpful to the person who asked the question, I decided to write this article to address the topics noted in the original question and the user's comments to the question after it was closed.

### Key need: statistical capabilities beyond Excel

Microsoft Excel became the dominant technology for spreadsheets in the 1990s, as its graphical user interface and availability across Windows and Macintosh platforms supplanted Lotus 1-2-3 in the market.

Over the past 30 years Microsoft has added a variety of statistical and graphics capabilities to the product, but due to its focus as an application for finance professionals, Excel will never be a replacement for a commercial statistics package (e.g. SAS, SPSS, Minitab, etc.) or the dominant data science languages, Python and R.

Since there is a frequent need to analyze data stored in Excel, a variety of R packages have been created to read and write Excel files. These packages were developed over a number of years, and varying strengths and weaknesses.

We will discuss four R packages in this article.

|Package|Description|
|:------|:----------|
|Openxlsx|The [Openxlsx package](https://cran.r-project.org/web/packages/openxlsx/openxlsx.pdf) provides a high level interface for reading and writing Excel files. Since it uses the Rcpp C interface to R, Openxlsx does not rely on Java.|
|readxl|The [readxl package](https://cran.r-project.org/web/packages/readxl/readxl.pdf) is solely designed for reading Excel files into R.It provides a number of functions that are useful for dealing with a variety of idiosyncracies in Excel that complicate loading data into another programming environment. |
|XLConnect| The [XLConnect package](https://cran.r-project.org/web/packages/XLConnect/vignettes/XLConnect.pdf) is designed to not only read and write Excel files, but also to manipulate them from R. It uses the [Apache POI API](https://poi.apache.org) for Excel, so this package also requires rJava and a Java Runtime installation in order to function.|
|xlsx|The [xlsx package](https://cran.r-project.org/web/packages/xlsx/xlsx.pdf) provides programmatic control of Excel spreadsheets through R. Like XLConnect, it also uses the [Apache POI API](https://poi.apache.org) for Excel. As such, xlsx depends on the Java runtime and rJava in order to fucntion.|

## Key capabilities for reading Excel files

Given the large diversity of spreadsheets that exist, the following features are essential for reading data from Excel.

* Ability to skip rows at the top of a worksheet to avoid multi-row heading names
* Ability to extract data via cell range
* Ability to extract data from a specific worksheet in a workbook that contains multiple worksheets
* Ability to specify column names and data types

All four of these packages support the above listed capabilities except for the ability to specify column names as an argument to the read function, which is only supported by `readxl`.  This is not a major deficiency since columns can be easily renamed via the `colnames()` Base R function once a spreadsheet has been loaded as an R data frame.

## Java: the first big hurdle

If these R packages all can do the basic job of converting Excel data into R, how does one distinguish package A from package B? In my view, the Java requirement is a huge strike against the `xlsx` and `XLConnect` packages.

First, many R users find it difficult to install Java and configure it to work with R. Installation procedures vary by operating system, and the process to install Java and get it working with R is particularly complicated on OS X. Thousands of students in the Johns Hopkins University *Getting and Cleaning Data* course have struggled with this issue due to the fact that the second quiz requires students to read and manipulate an Excel spreadsheet. See [Common problems: Java runtime and the xlsx package](http://bit.ly/2jjtyXM) for details.

Second, one must directly allocate sufficient heap space for Java in order to use it within an R session for anything beyond trivial work. For example, when I initially loaded `xlsx` in order to run a performance test on loading a large Excel spreadsheet, I received the following error.


    > library(xlsx)
    > system.time(xldata <- read.xlsx2("./data/largeFile.xlsx",sheetIndex=1))
    Error in .jcall("RJavaTools", "Ljava/lang/Object;", "invokeMethod", cl,  :
      java.lang.OutOfMemoryError: Java heap space
    Timing stopped at: 2.127 0.389 2.348
    >

I ran this code on a Macbook Pro with 16Gb of RAM, loading a spreadsheet with 100,000 rows and 100 columns, as we'll discuss in the **Performance** section of this article. The Excel file consumes 144Mb of disk space. I did not expect the JVM to run out of heap space processing a 145Mb Excel file. After figuring out how to increase the heap size for Java within R (thanks, [Stackoverflow](https://stackoverflow.com/questions/34624002/r-error-java-lang-outofmemoryerror-java-heap-space)), I restarted the R session in order to reload Java with sufficient heap space.

The next run of the script generated some interesting warning messages, but it did load the Excel file.

    > options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx8192m"))
    > library(xlsx)
    Java HotSpot(TM) 64-Bit Server VM warning: Option UseConcMarkSweepGC was deprecated in version 9.0 and will likely be removed in a future release.
    > system.time(xldata <- read.xlsx2("./data/largeFile.xlsx",sheetIndex=1))
    WARNING: An illegal reflective access operation has occurred
    WARNING: Illegal reflective access by org.apache.poi.util.SAXHelper (file:/Library/Frameworks/R.framework/Versions/4.0/Resources/library/xlsxjars/java/poi-ooxml-3.10.1-20140818.jar) to constructor com.sun.org.apache.xerces.internal.util.SecurityManager()
    WARNING: Please consider reporting this to the maintainers of org.apache.poi.util.SAXHelper
    WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
    WARNING: All illegal access operations will be denied in a future release
       user  system elapsed
    150.623   8.116  73.224
    >

The third problem with packages that rely on Java is that not all R packages work with the most recent versions of Java. I am running the 64-bit version of Java 13.0.2 on my Macbook. Here's what happened when I tried to load the above listed large Excel file with `XLConnect`.

    > options(java.parameters = c( "-Xmx8192m"))
    > library(XLConnect)
    Error: package or namespace load failed for ‘XLConnect’:
     .onLoad failed in loadNamespace() for 'XLConnect', details:
      call: fun(libname, pkgname)
      error: Installed java version 13.0.2+8 is not between Java>=8 and <=11! This is needed for this package
    > system.time(xlFile <- loadWorkbook(xldata <- "./data/largeFile.xlsx"))
    Error in loadWorkbook(xldata <- "./data/largeFile.xlsx") :
      could not find function "loadWorkbook"
    Timing stopped at: 0.028 0 0.028
    >

**Bottom line:** for most R users who simply want tor read spreadsheet data, packages that rely on Java aren't worth the hassle.

### Performance

To test the performance of the Excel reader R packages I created a data frame with random data, 10 million numbers between 0 and 100 randomly drwan from a uniform distribution. We converted the vector of numbers into a data frame consisting of 100,000 rows and 100 columns. Then we used `writexl::write_xlsx()` to write the data as an Excel Workbook.

    system.time(data <- data.frame(matrix(runif(10000000,0,100),ncol=100)))
    library(writexl)
    system.time(write_xlsx(data,"./data/largeFile.xlsx"))

Timings on the Macbook 15 were relatively fast, as it took less than 30 seconds to create the data frame and write it to disk as an Excel workbook.

    > system.time(data <- data.frame(matrix(runif(10000000,0,100),ncol=100)))
       user  system elapsed
      0.515   0.069   0.583
    > library(writexl)
    > system.time(write_xlsx(data,"./data/largeFile.xlsx"))
       user  system elapsed
     24.370   1.941  26.334
    >

I proceeded to read the data back into R, using each of the four Excel packages. Since I didn't want to downgrade the version of Java on my Macbook to test `XLConnect`, I installed Java 8 on an HP Spectre x360-15 with 16Gb of RAM, and ran the tests.  `readxl` was the speed winner.

|Package|Elapsed Time|
|:----|-----:|
|readxl|15.21 seconds|
|openxlsx|56.93 seconds|
|xlsx|57.46 seconds|
|XLConnect|54.22 seconds|


## Conclusions

The `readxl` package is not only provides a high degree of control for reading a variety of spreadsheet data, but it also performs best on a load test with a large spreadsheet. However, if one is interested in using R to generate Excel spreadsheets, the packages need to be re-evaluated with an objective set of criteria suited to the types of operations used to write, as opposed to read, Excel files. Specifically, the tidyverse software to write Excel files, `writexl` is a very new package and therefore has significantly fewer features than `xlsx`, `openxlsx`, or `XLConnect` that have been available for at least 5 years. 
