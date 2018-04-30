import pandas as pd
import math
df1 = pd.read_csv("dpf.csv")
df2 = pd.read_csv("diabetes.csv")
preds = df1.MODEL1
org = df2.DiabetesPedigreeFunction
error=0
for i in range(len(org)):
	x = float(preds.iat[i]-org.iat[i])
	y = float(x**2)
	error+=y
total_obs=float(len(org))
error = error/total_obs
rmsd = math.sqrt(error)
print rmsd