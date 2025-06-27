proc iml;
submit / R ;
#ip = as.data.frame(installed.packages()[,c(1,3:4)])
#print(mtcars)
library(xgboost)
data(agaricus.train, package='xgboost')
data(agaricus.test, package='xgboost')
train <- agaricus.train
test <- agaricus.test
bstSparse <- xgboost(data = train$data, label = train$label, max.depth = 2, eta = 1, nthread = 2, nrounds = 2, objective = "binary:logistic")

endsubmit;
run;

/* proc iml; */
/* submit /R; */
/* pred <- predict(bstSparse, test$data) */
/*  */only 
/* # size of the prediction vector */
/* print(length(pred)) */
/* endsubmit; */
/* run; */