import pandas as pd
df2 = pd.read_csv("diabetes.csv")
org = df2.Outcome
null0 = [0] * len(org)
null1 = [1] * len(org)
correct=0
for i in range(len(org)):
	if null0[i]==org.iat[i]:
		correct+=1
total_obs=float(len(org))
correct = float(correct)
accuracy0 = float(correct/total_obs)
accuracy0 = accuracy0 * 100
correct=0		
for i in range(len(org)):
	if null1[i]==org.iat[i]:
		correct+=1
correct = float(correct)
accuracy1 = float(correct/total_obs)
accuracy1 = accuracy1 * 100
print 'For 0 prediction, accuracy:' + str(accuracy0) + '%'
print 'For 1 prediction, accuracy:' + str(accuracy1) + '%'
