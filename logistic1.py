import pandas as pd
import math
df = pd.read_csv("diabetes.csv")
org  = df.Outcome
total_obs=len(org)
predictions=[]
for i in range(total_obs):
	logit = float(-8.4047+0.1232*df.iloc[i,0]+0.0352*df.iloc[i,1]-0.0133*df.iloc[i,2]+0.000619*df.iloc[i,3]-0.00119*df.iloc[i,4]+0.0897*df.iloc[i,5]+0.9452*df.iloc[i,6]+0.0149*df.iloc[i,7])
	odds = math.exp(logit)
	pi = float(odds/(1+odds))
	if pi>=0.5:
		pred = 1
	else:
		pred=0
	predictions.append(pred)
#evaluate accuracy
correct=0
for i in range(len(org)):
	if predictions[i]==org.iat[i]:
		correct+=1
correct = float(correct)
accuracy = float(correct/total_obs) * 100
print 'The accuracy of the predictor is:'+str(accuracy)+'%'

