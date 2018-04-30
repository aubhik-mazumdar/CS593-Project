import pandas as pd
df1 = pd.read_csv("terrible.csv") # 3) predictionsLinearReg.csv 2) allPrins.csv
df2 = pd.read_csv("diabetes.csv")
preds = df1.prediction
org = df2.Outcome
correct=0
for i in range(len(org)):
	if preds.iat[i]==org.iat[i]:
		correct+=1
total_obs=float(len(org))
correct = float(correct)
accuracy = float(correct/total_obs)
accuracy = accuracy * 100
print str(accuracy) + '%'