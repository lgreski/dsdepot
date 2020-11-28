---
layout: post
title: caret::createFolds() vs. createMultiFolds()
tag: R-bloggers
---

## Summary

Recently a user posted a [question on Stackoverflow](https://bit.ly/3o2rR20), asserting that  `caret::createFolds()` behaves differently than `createMultiFolds()`. The questioner argued that while `createFolds()` samples without replacement, `createMultiFolds()` samples with replacement. Our analysis demonstrates that the two functions behave consistently, creating `k` folds where each observation in the data frame participates in one of the `k` hold out groups. That said, by default `createFolds()` returns a list containing the indexes of held out observations for each fold, whereas `createMultiFolds()` returns a list of observations included in each fold for each repetition.

## Behavior of createFolds()

`createFolds()` splits the data into `k` folds. Output from the function is a list of observation indices that are **held out** from each fold, not the rows included in each fold. We can see this by creating a table of all the fold data using the `mtcars` data frame as follows.

    set.seed(123)
    folds <- createFolds(mtcars$am, k = 5)
    table(unlist(folds))

...and the output:

    > table(unlist(folds))

     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26
     1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1
    27 28 29 30 31 32
     1  1  1  1  1  1

If we use the `returnTrain = TRUE` argument with `createFolds()`, it returns the index of observations **included** in each fold, as illustrated in the other answer. For `k = 5`, we expect each observation to be used in 4 of the folds, and confirm this with the following code.

    set.seed(123)
    folds <- createFolds(mtcars$am, k = 5, returnTrain = TRUE)
    table(unlist(folds))

...and the output:

    > table(unlist(folds))

     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26
     4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4
    27 28 29 30 31 32
     4  4  4  4  4  4

## Behavior of createMultiFolds()

The `createMultiFolds()` function is used to to define resampling plans for studies with repeated k-fold cross validation. By default, `createMultiFolds()` returns a list containing one element for each level of `k=` and each repetition of `times=`

We can illustrate that each observation is used in 4 of the 5 folds as follows.

    set.seed(123)
    folds1 <- createMultiFolds(y = mtcars$am, k = 5, times = 1)
    table(unlist(folds1))

...and the output:

    > table(unlist(folds1))

     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26
     4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4
    27 28 29 30 31 32
     4  4  4  4  4  4

## Generating equivalent results with createFolds() and createMultiFolds()

Setting `returnTrain = TRUE` with `createFolds()` causes it to return the same output as [`createMultiFolds()`][1] with `times = 1`.

We can compare the contents of `folds` and `folds` with `lapply()` and `all()` as follows.

    # compare folds to folds1
    lapply(1:5,function(x){
         all(folds1[[x]],folds[[x]])
    })

    [[1]]
    [1] TRUE

    [[2]]
    [1] TRUE

    [[3]]
    [1] TRUE

    [[4]]
    [1] TRUE

    [[5]]
    [1] TRUE

If we set `times = 2`, we expect each observation to be included in 8 of the 10 folds.

    set.seed(123)
    folds <- createMultiFolds(y = mtcars$am, k = 5, times = 2)
    table(unlist(folds))


...and the output:

    > table(unlist(folds))

     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26
     8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8
    27 28 29 30 31 32
     8  8  8  8  8  8

## Conclusions

In both functions `caret` uses sampling to ensure that each observation is included in the hold out group 1 time across the `k` folds for each repetition of `times =`, within the constraint that observations for each value of the dependent variable passed to the function are proportionally distributed in the in sample and out of sample components of each fold.

In the case of a small data set such as `mtcars`, it's not easy for the algorithm to split effectively, as we can see when we run tables to compare in sample / holdout vs. `mtcars$am`.  

    set.seed(123)
    folds <- createFolds(mtcars$am, k = 5)
    table(unlist(folds))
    lapply(folds,function(x){
         holdout <- rep(FALSE,nrow(mtcars))
         holdout[x] <- TRUE
         table(holdout,mtcars$am)
    })

    $Fold1

    holdout  0  1
      FALSE 16 10
      TRUE   3  3

    $Fold2

    holdout  0  1
      FALSE 15 10
      TRUE   4  3

    $Fold3

    holdout  0  1
      FALSE 14 11
      TRUE   5  2

    $Fold4

    holdout  0  1
      FALSE 15 11
      TRUE   4  2

    $Fold5

    holdout  0  1
      FALSE 16 10
      TRUE   3  3

Each fold contains 6 or 7 observations in the hold out set, with a minimum of 2 manual transmission cars (`am = 1`) in each hold out set.

With default arguments, `createFolds()` returns the indexes of held out observations rather than included observations. `createFolds(x,k,returnTrain=TRUE)` behaves exactly the same as `createMultiFolds(x,k,times=1)`.


[1]: https://bit.ly/36gNCoH "createFolds() with returnTrain=TRUE"
