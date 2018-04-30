import pandas as pd
import math
df = pd.read_csv("diabetes2.csv")
org  = df.Outcome
total_obs=len(org)
predictions=[]
for i in range(total_obs):
	logit = float(-5.8688+0.0347*df.iloc[i,1]+0.7068*df.iloc[i,10]+0.8786*df.iloc[i,6]+0.0025*df.iloc[i,0]*df.iloc[i,7])
	odds = math.exp(logit)
	pi = float(odds/(1+odds))
	if pi>0.5:
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

